import 'dart:convert';

import 'package:uuid/uuid.dart';

import '../db/app_database.dart';
import '../db/converters.dart';

const _uuid = Uuid();

Future<void> enqueueInsert(
  AppDatabase db, {
  required String entityType,
  required String entityId,
  required Map<String, Object?> payload,
  required DateTime createdAt,
}) {
  return db
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
}
