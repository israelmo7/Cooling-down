import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../core/clock.dart';
import '../../domain/entities/alert.dart';
import '../../domain/entities/fridge.dart';
import '../../domain/entities/open_holding.dart';
import '../../domain/entities/refrigeration_log.dart';
import '../../domain/failures.dart';
import '../../domain/repositories/log_repository.dart';
import '../db/app_database.dart';
import '../db/ensure_settings.dart';
import '../mappers.dart';
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
  }) {
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
      );
      await _insertLog(log);
      await _maybeAlert(
        log: log,
        fridge: mapFridge(fridge),
        eventLabel: 'נקלט',
        capturedAt: capturedAt,
      );
      return log;
    });
  }

  @override
  Future<RefrigerationLog> insertCheckOut({
    required String movementId,
    required double temperatureCelsius,
    DateTime? occurredAt,
  }) {
    return _db.transaction(() async {
      final checkIn =
          await (_db.select(_db.refrigerationLogs)..where(
                (table) =>
                    table.movementId.equals(movementId) &
                    table.eventType.equalsValue(LogEventType.checkIn),
              ))
              .getSingleOrNull();
      final existingCheckOut =
          await (_db.select(_db.refrigerationLogs)..where(
                (table) =>
                    table.movementId.equals(movementId) &
                    table.eventType.equalsValue(LogEventType.checkOut),
              ))
              .getSingleOrNull();
      if (checkIn == null || existingCheckOut != null) {
        throw NoOpenHoldingException(movementId);
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
      );
      await _insertLog(log);
      await _maybeAlert(
        log: log,
        fridge: mapFridge(fridge),
        eventLabel: 'הוצא',
        capturedAt: capturedAt,
      );
      return log;
    });
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
          ..where(
            checkIn.eventType.equalsValue(LogEventType.checkIn) &
                checkOut.id.isNull(),
          )
          ..orderBy([
            OrderingTerm(
              expression: checkIn.occurredAt,
              mode: OrderingMode.desc,
            ),
          ]);

    return query.watch().map((rows) {
      return [
        for (final row in rows)
          OpenHolding(
            movementId: row.readTable(checkIn).movementId,
            productId: row.readTable(checkIn).productId,
            productName: row.readTable(checkIn).productNameSnapshot,
            fridgeId: row.readTable(checkIn).fridgeId,
            fridgeName: row.readTable(_db.fridges).name,
            checkInTemperatureCelsius: row
                .readTable(checkIn)
                .temperatureCelsius,
            checkedInAt: row.readTable(checkIn).occurredAt,
          ),
      ];
    });
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
      },
      createdAt: log.createdAt,
    );
  }

  Future<void> _maybeAlert({
    required RefrigerationLog log,
    required Fridge fridge,
    required String eventLabel,
    required DateTime capturedAt,
  }) async {
    if (fridge.contains(log.temperatureCelsius)) {
      return;
    }
    final alert = Alert(
      id: _uuid.v4(),
      severity: AlertSeverity.warning,
      kind: AlertKind.temperatureOutOfRange,
      productId: log.productId,
      logId: log.id,
      message:
          '${log.productNameSnapshot} $eventLabel ב-${log.temperatureCelsius.toStringAsFixed(1)}°C, מחוץ לטווח של ${fridge.name} (${fridge.minCelsius.toStringAsFixed(1)}–${fridge.maxCelsius.toStringAsFixed(1)}°C).',
      createdAt: capturedAt,
      originDeviceId: log.originDeviceId,
    );
    await _db
        .into(_db.alerts)
        .insert(
          AlertsCompanion.insert(
            id: alert.id,
            severity: alert.severity,
            kind: alert.kind,
            productId: Value(alert.productId),
            logId: Value(alert.logId),
            message: alert.message,
            createdAt: alert.createdAt,
            originDeviceId: Value(alert.originDeviceId),
          ),
        );
    await enqueueInsert(
      _db,
      entityType: 'alert',
      entityId: alert.id,
      payload: {
        'id': alert.id,
        'severity': alert.severity.storageValue,
        'kind': alert.kind.storageValue,
        'product_id': alert.productId,
        'log_id': alert.logId,
        'message': alert.message,
        'created_at': alert.createdAt.toIso8601String(),
        'origin_device_id': alert.originDeviceId,
      },
      createdAt: alert.createdAt,
    );
  }
}
