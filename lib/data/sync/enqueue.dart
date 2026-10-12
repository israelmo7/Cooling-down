import 'dart:convert';

import 'package:uuid/uuid.dart';

import '../db/app_database.dart';
import '../db/converters.dart';
import 'feed.dart';

const _uuid = Uuid();

Future<void> enqueueInsert(
  AppDatabase db, {
  required String entityType,
  required String entityId,
  required Map<String, Object?> payload,
  required DateTime createdAt,
  String originDeviceId = '',
}) async {
  await db
      .into(db.syncOutbox)
      .insert(
        SyncOutboxCompanion.insert(
          id: _uuid.v4(),
          entityType: entityType,
          entityId: entityId,
          operation: 'insert',
          payloadJson: jsonEncode(payload),
          status: SyncStatus.pending,
          createdAt: createdAt,
        ),
      );
  final origin = payload['origin_device_id'];
  await rememberFeed(
    db,
    entityType: entityType,
    entityId: entityId,
    originDeviceId: origin is String ? origin : originDeviceId,
    payload: payload,
  );
}
