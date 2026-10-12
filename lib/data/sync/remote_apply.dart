import 'package:drift/drift.dart';

import '../../domain/entities/alert.dart';
import '../../domain/entities/refrigeration_log.dart';
import '../../domain/sync/checkout_conflict.dart';
import '../db/app_database.dart';
import 'feed.dart';
import 'sync_gateway.dart';

/// Copies another tablet's rows into this database without queueing them again.
class RemoteApplier {
  RemoteApplier(this._db);

  final AppDatabase _db;

  Future<void> apply(
    List<SyncChange> changes, {
    List<SyncConflict> conflicts = const [],
  }) {
    return _db.transaction(() async {
      for (final change in changes) {
        await _applyOne(change);
      }
      for (final conflict in conflicts) {
        await _ensureConflictForLog(conflict.entityId);
      }
    });
  }

  Future<void> _applyOne(SyncChange change) async {
    switch (change.entityType) {
      case 'refrigeration_log':
        await _applyLog(change);
      case 'alert':
        await _applyAlert(change);
      case 'product':
        await _applyProduct(change);
      case 'fridge':
        await _applyFridge(change);
      default:
        return;
    }
  }

  Future<void> _applyLog(SyncChange change) async {
    final payload = change.payload;
    final id = _string(payload, 'id');
    final existing = await (_db.select(
      _db.refrigerationLogs,
    )..where((table) => table.id.equals(id))).getSingleOrNull();
    if (existing != null) {
      return;
    }

    final eventType = LogEventType.values.firstWhere(
      (value) => value.storageValue == _string(payload, 'event_type'),
    );
    final occurredAt = _time(payload, 'occurred_at');
    final createdAt = _time(payload, 'created_at');
    await _db
        .into(_db.refrigerationLogs)
        .insert(
          RefrigerationLogsCompanion.insert(
            id: id,
            movementId: _string(payload, 'movement_id'),
            productId: _string(payload, 'product_id'),
            productNameSnapshot: _string(payload, 'product_name_snapshot'),
            fridgeId: _string(payload, 'fridge_id'),
            eventType: eventType,
            temperatureCelsius: _number(payload, 'temperature_celsius'),
            occurredAt: occurredAt,
            createdAt: createdAt,
            originDeviceId: Value(
              _optionalString(payload, 'origin_device_id') ?? change.deviceId,
            ),
            workerNameSnapshot: Value(
              _optionalString(payload, 'worker_name_snapshot') ?? '',
            ),
          ),
        );
    await rememberFeed(
      _db,
      entityType: 'refrigeration_log',
      entityId: id,
      originDeviceId:
          _optionalString(payload, 'origin_device_id') ?? change.deviceId,
      payload: payload,
    );

    if (eventType == LogEventType.checkOut) {
      await _ensureConflictForLog(id);
    }
  }

  Future<void> _applyAlert(SyncChange change) async {
    final payload = change.payload;
    final id = _string(payload, 'id');
    final existing = await (_db.select(
      _db.alerts,
    )..where((table) => table.id.equals(id))).getSingleOrNull();
    if (existing != null) {
      return;
    }
    await _db
        .into(_db.alerts)
        .insert(
          AlertsCompanion.insert(
            id: id,
            severity: AlertSeverity.values.firstWhere(
              (value) => value.storageValue == _string(payload, 'severity'),
            ),
            kind: AlertKind.values.firstWhere(
              (value) => value.storageValue == _string(payload, 'kind'),
            ),
            productId: Value(_optionalString(payload, 'product_id')),
            logId: Value(_optionalString(payload, 'log_id')),
            message: _string(payload, 'message'),
            createdAt: _time(payload, 'created_at'),
            originDeviceId: Value(
              _optionalString(payload, 'origin_device_id') ?? change.deviceId,
            ),
          ),
        );
    await rememberFeed(
      _db,
      entityType: 'alert',
      entityId: id,
      originDeviceId:
          _optionalString(payload, 'origin_device_id') ?? change.deviceId,
      payload: payload,
    );
  }

  Future<void> _applyProduct(SyncChange change) async {
    final payload = change.payload;
    final id = _string(payload, 'id');
    final existing = await (_db.select(
      _db.products,
    )..where((table) => table.id.equals(id))).getSingleOrNull();
    if (existing != null) {
      return;
    }
    await _db
        .into(_db.products)
        .insert(
          ProductsCompanion.insert(
            id: id,
            name: _string(payload, 'name'),
            sku: Value(_optionalString(payload, 'sku')),
            createdAt: _time(payload, 'created_at'),
          ),
        );
  }

  Future<void> _applyFridge(SyncChange change) async {
    final payload = change.payload;
    final id = _string(payload, 'id');
    final existing = await (_db.select(
      _db.fridges,
    )..where((table) => table.id.equals(id))).getSingleOrNull();
    if (existing != null) {
      return;
    }
    await _db
        .into(_db.fridges)
        .insert(
          FridgesCompanion.insert(
            id: id,
            name: _string(payload, 'name'),
            minCelsius: _number(payload, 'min_celsius'),
            maxCelsius: _number(payload, 'max_celsius'),
          ),
        );
  }

  Future<void> _ensureConflictForLog(String logId) async {
    if (logId.isEmpty) {
      return;
    }
    final log = await (_db.select(
      _db.refrigerationLogs,
    )..where((table) => table.id.equals(logId))).getSingleOrNull();
    if (log == null || log.eventType != LogEventType.checkOut) {
      return;
    }
    final count = _db.refrigerationLogs.id.count();
    final query = _db.selectOnly(_db.refrigerationLogs)
      ..addColumns([count])
      ..where(
        _db.refrigerationLogs.movementId.equals(log.movementId) &
            _db.refrigerationLogs.eventType.equalsValue(LogEventType.checkOut),
      );
    final total = (await query.getSingle()).read(count) ?? 0;
    if (total < 2) {
      return;
    }

    final alertId = checkoutConflictAlertId(log.movementId);
    final existing = await (_db.select(
      _db.alerts,
    )..where((table) => table.id.equals(alertId))).getSingleOrNull();
    if (existing != null) {
      return;
    }
    await _db
        .into(_db.alerts)
        .insert(
          AlertsCompanion.insert(
            id: alertId,
            severity: AlertSeverity.warning,
            kind: AlertKind.syncConflict,
            productId: Value(log.productId),
            logId: Value(log.id),
            message: checkoutConflictMessage(log.productNameSnapshot),
            createdAt: log.createdAt,
            originDeviceId: Value(log.originDeviceId),
          ),
        );
    await rememberFeed(
      _db,
      entityType: 'alert',
      entityId: alertId,
      originDeviceId: log.originDeviceId,
      payload: {
        'id': alertId,
        'severity': AlertSeverity.warning.storageValue,
        'kind': AlertKind.syncConflict.storageValue,
        'product_id': log.productId,
        'log_id': log.id,
        'message': checkoutConflictMessage(log.productNameSnapshot),
        'created_at': log.createdAt.toUtc().toIso8601String(),
        'origin_device_id': log.originDeviceId,
      },
    );
  }
}

String _string(Map<String, Object?> payload, String key) {
  final value = payload[key];
  if (value is! String || value.isEmpty) {
    throw FormatException('Sync payload is missing $key.');
  }
  return value;
}

String? _optionalString(Map<String, Object?> payload, String key) {
  final value = payload[key];
  if (value == null) {
    return null;
  }
  if (value is String) {
    return value.isEmpty ? null : value;
  }
  throw FormatException('Sync payload has a bad $key.');
}

double _number(Map<String, Object?> payload, String key) {
  final value = payload[key];
  if (value is num) {
    return value.toDouble();
  }
  throw FormatException('Sync payload is missing $key.');
}

DateTime _time(Map<String, Object?> payload, String key) {
  return DateTime.parse(_string(payload, key)).toUtc();
}
