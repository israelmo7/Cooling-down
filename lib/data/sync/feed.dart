import 'dart:convert';

import 'package:drift/drift.dart';

import '../db/app_database.dart';

/// Records one entity so other tablets can pull it from this one.
Future<void> rememberFeed(
  AppDatabase db, {
  required String entityType,
  required String entityId,
  required String originDeviceId,
  required Map<String, Object?> payload,
}) {
  return db
      .into(db.syncFeed)
      .insert(
        SyncFeedCompanion.insert(
          entityType: entityType,
          entityId: entityId,
          originDeviceId: Value(originDeviceId),
          payloadJson: jsonEncode(payload),
        ),
        mode: InsertMode.insertOrIgnore,
      );
}

/// Puts logs and alerts that already exist into the feed once.
Future<void> backfillSyncFeed(AppDatabase db) async {
  final logs = await db.select(db.refrigerationLogs).get();
  final fridges = await db.select(db.fridges).get();
  final fridgeNames = {for (final fridge in fridges) fridge.id: fridge.name};
  for (final row in logs) {
    await rememberFeed(
      db,
      entityType: 'refrigeration_log',
      entityId: row.id,
      originDeviceId: row.originDeviceId,
      payload: {
        'id': row.id,
        'movement_id': row.movementId,
        'product_id': row.productId,
        'product_name_snapshot': row.productNameSnapshot,
        'fridge_id': row.fridgeId,
        'fridge_name': fridgeNames[row.fridgeId] ?? '',
        'event_type': row.eventType.storageValue,
        'temperature_celsius': row.temperatureCelsius,
        'occurred_at': row.occurredAt.toUtc().toIso8601String(),
        'created_at': row.createdAt.toUtc().toIso8601String(),
        'origin_device_id': row.originDeviceId,
        'worker_name_snapshot': row.workerNameSnapshot,
      },
    );
  }
  final alerts = await db.select(db.alerts).get();
  for (final row in alerts) {
    await rememberFeed(
      db,
      entityType: 'alert',
      entityId: row.id,
      originDeviceId: row.originDeviceId,
      payload: {
        'id': row.id,
        'severity': row.severity.storageValue,
        'kind': row.kind.storageValue,
        'product_id': row.productId,
        'log_id': row.logId,
        'message': row.message,
        'created_at': row.createdAt.toUtc().toIso8601String(),
        'origin_device_id': row.originDeviceId,
      },
    );
  }
}
