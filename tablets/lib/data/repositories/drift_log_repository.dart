import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../core/clock.dart';
import '../../core/temperature.dart';
import '../../domain/entities/open_holding.dart';
import '../../domain/entities/refrigeration_log.dart';
import '../../domain/failures.dart';
import '../../domain/quantity.dart';
import '../../domain/repositories/log_repository.dart';
import '../db/app_database.dart';
import '../db/ensure_settings.dart';
import '../sync/enqueue.dart';

class DriftLogRepository implements LogRepository {
  DriftLogRepository(this._db, {Clock? clock, Uuid? uuid})
    : _clock = clock ?? const Clock(),
      _uuid = uuid ?? const Uuid();

  final AppDatabase _db;
  final Clock _clock;
  final Uuid _uuid;

  @override
  Future<RefrigerationLog> insertCheckIn({
    required String productId,
    required String fridgeId,
    required double temperatureCelsius,
    DateTime? occurredAt,
    required String workerName,
    DateTime? dueAt,
    int quantity = 1,
  }) {
    final recordedWorker = workerName.trim();
    if (recordedWorker.isEmpty) {
      throw const CatalogEntryNotFound('יש לבחור עובד.');
    }
    _requireQuantity(quantity);
    _requireTemperature(temperatureCelsius);
    return _db.transaction(() async {
      final product = await (_db.select(
        _db.products,
      )..where((table) => table.id.equals(productId))).getSingleOrNull();
      if (product == null) {
        throw const CatalogEntryNotFound('המוצר לא נמצא.');
      }
      final fridge = await (_db.select(
        _db.fridges,
      )..where((table) => table.id.equals(fridgeId))).getSingleOrNull();
      if (fridge == null) {
        throw const CatalogEntryNotFound('המקרר לא נמצא.');
      }

      final capturedAt = (occurredAt ?? _clock.now()).toUtc();
      final deviceId = await ensureDeviceId(_db);
      final log = RefrigerationLog(
        id: _uuid.v4(),
        movementId: _uuid.v4(),
        productId: product.id,
        productNameSnapshot: product.name,
        fridgeId: fridge.id,
        eventType: LogEventType.checkIn,
        temperatureCelsius: temperatureCelsius,
        occurredAt: capturedAt,
        createdAt: capturedAt,
        originDeviceId: deviceId,
        workerNameSnapshot: recordedWorker,
        dueAt: dueAt?.toUtc(),
        quantity: quantity,
      );
      await _insertLog(log);
      return log;
    });
  }

  @override
  Future<RefrigerationLog> insertCheckOut({
    required String movementId,
    required double temperatureCelsius,
    DateTime? occurredAt,
    required String workerName,
    int quantity = 1,
  }) {
    final recordedWorker = workerName.trim();
    if (recordedWorker.isEmpty) {
      throw const CatalogEntryNotFound('יש לבחור עובד.');
    }
    _requireQuantity(quantity);
    _requireTemperature(temperatureCelsius);
    return _db.transaction(() async {
      final checkIn =
          await (_db.select(_db.refrigerationLogs)..where(
                (table) =>
                    table.movementId.equals(movementId) &
                    table.eventType.equalsValue(LogEventType.checkIn),
              ))
              .getSingleOrNull();
      if (checkIn == null) {
        throw NoOpenHoldingException(movementId);
      }
      // Part of the batch may already be out. What is still inside is the
      // checked-in quantity minus everything taken out so far.
      final previousCheckOuts =
          await (_db.select(_db.refrigerationLogs)..where(
                (table) =>
                    table.movementId.equals(movementId) &
                    table.eventType.equalsValue(LogEventType.checkOut),
              ))
              .get();
      final alreadyOut = previousCheckOuts.fold<int>(
        0,
        (sum, row) => sum + row.quantity,
      );
      final remaining = checkIn.quantity - alreadyOut;
      if (remaining <= 0) {
        throw NoOpenHoldingException(movementId);
      }
      if (quantity > remaining) {
        throw InvalidQuantityException(
          'אי אפשר להוציא $quantity. נשארו $remaining במקרר.',
        );
      }

      final fridge = await (_db.select(
        _db.fridges,
      )..where((table) => table.id.equals(checkIn.fridgeId))).getSingleOrNull();
      if (fridge == null) {
        throw const CatalogEntryNotFound('המקרר לא נמצא.');
      }

      final product =
          await (_db.select(_db.products)
                ..where((table) => table.id.equals(checkIn.productId)))
              .getSingleOrNull();
      final capturedAt = (occurredAt ?? _clock.now()).toUtc();
      final deviceId = await ensureDeviceId(_db);
      final log = RefrigerationLog(
        id: _uuid.v4(),
        movementId: movementId,
        productId: checkIn.productId,
        productNameSnapshot: product?.name ?? checkIn.productNameSnapshot,
        fridgeId: checkIn.fridgeId,
        eventType: LogEventType.checkOut,
        temperatureCelsius: temperatureCelsius,
        occurredAt: capturedAt,
        createdAt: capturedAt,
        originDeviceId: deviceId,
        workerNameSnapshot: recordedWorker,
        quantity: quantity,
      );
      await _insertLog(log);
      return log;
    });
  }

  void _requireQuantity(int quantity) {
    if (!isValidQuantity(quantity)) {
      throw InvalidQuantityException(
        'הכמות חייבת להיות מספר שלם בין 1 ל-$maxQuantity.',
      );
    }
  }

  void _requireTemperature(double temperatureCelsius) {
    if (!isValidTemperature(temperatureCelsius)) {
      throw const CatalogEntryNotFound('הטמפרטורה מחוץ לטווח האפשרי.');
    }
  }

  @override
  Stream<List<OpenHolding>> watchOpenHoldings() {
    final checkIn = _db.alias(_db.refrigerationLogs, 'ci');
    final checkOut = _db.alias(_db.refrigerationLogs, 'co');
    final query =
        _db.select(checkIn).join([
            innerJoin(_db.fridges, _db.fridges.id.equalsExp(checkIn.fridgeId)),
            leftOuterJoin(
              checkOut,
              checkOut.movementId.equalsExp(checkIn.movementId) &
                  checkOut.eventType.equalsValue(LogEventType.checkOut),
            ),
          ])
          ..where(checkIn.eventType.equalsValue(LogEventType.checkIn))
          ..orderBy([
            OrderingTerm(
              expression: checkIn.occurredAt,
              mode: OrderingMode.desc,
            ),
          ]);

    return query.watch().map((rows) {
      // One joined row per check-out (or one row with no check-out). Fold
      // them into one holding per movement, with the units still inside.
      final holdings = <String, OpenHolding>{};
      final takenOut = <String, int>{};
      for (final row in rows) {
        final inside = row.readTable(checkIn);
        final outside = row.readTableOrNull(checkOut);
        holdings.putIfAbsent(
          inside.movementId,
          () => OpenHolding(
            movementId: inside.movementId,
            productId: inside.productId,
            productName: inside.productNameSnapshot,
            fridgeId: inside.fridgeId,
            fridgeName: row.readTable(_db.fridges).name,
            checkInTemperatureCelsius: inside.temperatureCelsius,
            checkedInAt: inside.occurredAt,
            dueAt: inside.dueAt,
            quantity: inside.quantity,
            checkedInQuantity: inside.quantity,
          ),
        );
        if (outside != null) {
          takenOut[inside.movementId] =
              (takenOut[inside.movementId] ?? 0) + outside.quantity;
        }
      }
      return [
        for (final holding in holdings.values)
          if (holding.checkedInQuantity - (takenOut[holding.movementId] ?? 0) >
              0)
            OpenHolding(
              movementId: holding.movementId,
              productId: holding.productId,
              productName: holding.productName,
              fridgeId: holding.fridgeId,
              fridgeName: holding.fridgeName,
              checkInTemperatureCelsius: holding.checkInTemperatureCelsius,
              checkedInAt: holding.checkedInAt,
              dueAt: holding.dueAt,
              quantity:
                  holding.checkedInQuantity -
                  (takenOut[holding.movementId] ?? 0),
              checkedInQuantity: holding.checkedInQuantity,
            ),
      ];
    });
  }

  @override
  Future<double?> averageCheckInCelsius(String productId) async {
    final average = _db.refrigerationLogs.temperatureCelsius.avg();
    final query = _db.selectOnly(_db.refrigerationLogs)
      ..addColumns([average])
      ..where(
        _db.refrigerationLogs.productId.equals(productId) &
            _db.refrigerationLogs.eventType.equalsValue(LogEventType.checkIn),
      );
    final row = await query.getSingle();
    return row.read(average);
  }

  Future<void> _insertLog(RefrigerationLog log) async {
    await _db
        .into(_db.refrigerationLogs)
        .insert(
          RefrigerationLogsCompanion.insert(
            id: log.id,
            movementId: log.movementId,
            productId: log.productId,
            productNameSnapshot: log.productNameSnapshot,
            fridgeId: log.fridgeId,
            eventType: log.eventType,
            temperatureCelsius: log.temperatureCelsius,
            occurredAt: log.occurredAt,
            createdAt: log.createdAt,
            originDeviceId: Value(log.originDeviceId),
            workerNameSnapshot: Value(log.workerNameSnapshot),
            dueAt: Value(log.dueAt),
            quantity: Value(log.quantity),
          ),
        );
    final fridge = await (_db.select(
      _db.fridges,
    )..where((table) => table.id.equals(log.fridgeId))).getSingleOrNull();
    await enqueueInsert(
      _db,
      entityType: 'refrigeration_log',
      entityId: log.id,
      payload: {
        'id': log.id,
        'movement_id': log.movementId,
        'product_id': log.productId,
        'product_name_snapshot': log.productNameSnapshot,
        'fridge_id': log.fridgeId,
        'fridge_name': fridge?.name ?? '',
        'event_type': log.eventType.storageValue,
        'temperature_celsius': log.temperatureCelsius,
        'occurred_at': log.occurredAt.toIso8601String(),
        'created_at': log.createdAt.toIso8601String(),
        'origin_device_id': log.originDeviceId,
        'worker_name_snapshot': log.workerNameSnapshot,
        'quantity': log.quantity,
        if (log.dueAt != null) 'due_at': log.dueAt!.toUtc().toIso8601String(),
      },
      createdAt: log.createdAt,
    );
  }
}
