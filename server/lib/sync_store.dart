import 'dart:convert';

import 'package:sqlite3/sqlite3.dart';

import 'conflict.dart';
import 'mailer.dart';

class SyncStore {
  SyncStore(this._db, {ReportMailer? mailer})
    : _mailer = mailer ?? const DisabledMailer() {
    _db.execute('''
CREATE TABLE IF NOT EXISTS sync_events (
  seq INTEGER PRIMARY KEY AUTOINCREMENT,
  environment TEXT NOT NULL,
  entity_type TEXT NOT NULL,
  entity_id TEXT NOT NULL,
  device_id TEXT NOT NULL,
  payload_json TEXT NOT NULL,
  UNIQUE (environment, entity_type, entity_id)
)
''');
    _db.execute('''
CREATE INDEX IF NOT EXISTS sync_events_env_seq
ON sync_events (environment, seq)
''');
    _db.execute('''
CREATE TABLE IF NOT EXISTS refrigeration_logs (
  id TEXT PRIMARY KEY,
  environment TEXT NOT NULL,
  movement_id TEXT NOT NULL,
  event_type TEXT NOT NULL,
  occurred_at TEXT NOT NULL,
  product_name TEXT NOT NULL
)
''');
    _db.execute('''
CREATE TABLE IF NOT EXISTS daily_reports (
  id TEXT PRIMARY KEY,
  environment TEXT NOT NULL,
  report_date TEXT NOT NULL,
  owner_email TEXT NOT NULL,
  subject TEXT NOT NULL,
  body TEXT NOT NULL,
  status TEXT NOT NULL,
  last_error TEXT,
  UNIQUE (environment, report_date)
)
''');
  }

  factory SyncStore.memory({ReportMailer? mailer}) {
    return SyncStore(sqlite3.openInMemory(), mailer: mailer);
  }

  final Database _db;
  final ReportMailer _mailer;

  void close() => _db.close();

  Map<String, Object?> exchange({
    required String deviceId,
    required String environment,
    required int cursor,
    required List<Map<String, dynamic>> push,
  }) {
    final accepted = <String>[];
    final conflicts = <Map<String, String>>[];
    _db.execute('BEGIN');
    try {
      for (final item in push) {
        final entityId = _applyPush(
          deviceId: deviceId,
          environment: environment,
          item: item,
          conflicts: conflicts,
        );
        accepted.add(entityId);
      }
      _db.execute('COMMIT');
    } on Object {
      _db.execute('ROLLBACK');
      rethrow;
    }

    final changes = _db.select(
      '''
SELECT seq, entity_type, entity_id, device_id, payload_json
FROM sync_events
WHERE environment = ? AND seq > ?
ORDER BY seq
LIMIT 500
''',
      [environment, cursor],
    );
    final maxRow = _db.select(
      'SELECT COALESCE(MAX(seq), 0) AS max_seq FROM sync_events WHERE environment = ?',
      [environment],
    );
    final maxSeq = (maxRow.first['max_seq'] as int?) ?? 0;
    final lastSeq = changes.isEmpty
        ? maxSeq
        : (changes.last['seq'] as int? ?? maxSeq);

    return {
      'cursor': lastSeq,
      'accepted': accepted,
      'conflicts': conflicts,
      'changes': [
        for (final row in changes)
          {
            'seq': row['seq'],
            'entity_type': row['entity_type'],
            'entity_id': row['entity_id'],
            'device_id': row['device_id'],
            'payload': jsonDecode(row['payload_json'] as String),
          },
      ],
    };
  }

  Future<Map<String, Object?>> submitReport({
    required String id,
    required String environment,
    required String reportDate,
    required String ownerEmail,
    required String subject,
    required String body,
  }) async {
    final existing = _db.select(
      '''
SELECT id, status FROM daily_reports
WHERE environment = ? AND report_date = ?
''',
      [environment, reportDate],
    );
    if (existing.isNotEmpty && existing.first['status'] == 'sent') {
      return {'status': 'already_sent'};
    }

    if (existing.isEmpty) {
      _db.execute(
        '''
INSERT INTO daily_reports (
  id, environment, report_date, owner_email, subject, body, status
) VALUES (?, ?, ?, ?, ?, ?, 'waiting')
''',
        [id, environment, reportDate, ownerEmail, subject, body],
      );
    } else {
      _db.execute(
        '''
UPDATE daily_reports
SET owner_email = ?, subject = ?, body = ?, status = 'waiting', last_error = NULL
WHERE environment = ? AND report_date = ?
''',
        [ownerEmail, subject, body, environment, reportDate],
      );
    }

    try {
      final emailed = await _mailer.send(
        to: ownerEmail,
        subject: subject,
        body: body,
      );
      final status = emailed ? 'sent' : 'stored';
      _db.execute(
        '''
UPDATE daily_reports SET status = ?, last_error = NULL
WHERE environment = ? AND report_date = ?
''',
        [status, environment, reportDate],
      );
      return {'status': status};
    } on Object catch (error) {
      _db.execute(
        '''
UPDATE daily_reports SET status = 'failed', last_error = ?
WHERE environment = ? AND report_date = ?
''',
        [error.toString(), environment, reportDate],
      );
      return {'status': 'failed', 'error': error.toString()};
    }
  }

  String _applyPush({
    required String deviceId,
    required String environment,
    required Map<String, dynamic> item,
    required List<Map<String, String>> conflicts,
  }) {
    final entityType = item['entity_type'];
    final entityId = item['entity_id'];
    final payload = item['payload'];
    if (entityType is! String || entityType.isEmpty) {
      throw const FormatException('Each push item needs an entity type.');
    }
    if (entityId is! String || entityId.isEmpty) {
      throw const FormatException('Each push item needs an entity id.');
    }
    if (payload is! Map) {
      throw const FormatException('Each push item needs a payload object.');
    }
    final body = Map<String, Object?>.from(payload);
    final payloadId = body['id'];
    if (payloadId != entityId) {
      throw const FormatException('The payload id must match the entity id.');
    }

    final inserted = _insertEvent(
      environment: environment,
      entityType: entityType,
      entityId: entityId,
      deviceId: deviceId,
      payload: body,
    );
    if (entityType == 'refrigeration_log' && inserted) {
      _insertLog(environment, body, deviceId, conflicts);
    }
    return entityId;
  }

  bool _insertEvent({
    required String environment,
    required String entityType,
    required String entityId,
    required String deviceId,
    required Map<String, Object?> payload,
  }) {
    final existing = _db.select(
      '''
SELECT seq FROM sync_events
WHERE environment = ? AND entity_type = ? AND entity_id = ?
''',
      [environment, entityType, entityId],
    );
    if (existing.isNotEmpty) {
      return false;
    }
    _db.execute(
      '''
INSERT INTO sync_events (
  environment, entity_type, entity_id, device_id, payload_json
) VALUES (?, ?, ?, ?, ?)
''',
      [environment, entityType, entityId, deviceId, jsonEncode(payload)],
    );
    return true;
  }

  void _insertLog(
    String environment,
    Map<String, Object?> payload,
    String deviceId,
    List<Map<String, String>> conflicts,
  ) {
    final id = payload['id'] as String;
    final movementId = payload['movement_id'];
    final eventType = payload['event_type'];
    final occurredAt = payload['occurred_at'];
    final productName = payload['product_name_snapshot'];
    if (movementId is! String ||
        eventType is! String ||
        occurredAt is! String ||
        productName is! String) {
      throw const FormatException('A refrigeration log payload is incomplete.');
    }
    _db.execute(
      '''
INSERT INTO refrigeration_logs (
  id, environment, movement_id, event_type, occurred_at, product_name
) VALUES (?, ?, ?, ?, ?, ?)
''',
      [id, environment, movementId, eventType, occurredAt, productName],
    );
    if (eventType != 'check_out') {
      return;
    }
    final checkouts = _db.select(
      '''
SELECT id FROM refrigeration_logs
WHERE environment = ? AND movement_id = ? AND event_type = 'check_out'
ORDER BY occurred_at
''',
      [environment, movementId],
    );
    if (checkouts.length < 2) {
      return;
    }
    conflicts.add({'entity_id': id, 'reason': 'movement already checked out'});
    final alertId = checkoutConflictAlertId(movementId);
    final alertPayload = <String, Object?>{
      'id': alertId,
      'severity': 'warning',
      'kind': 'sync_conflict',
      'product_id': payload['product_id'],
      'log_id': id,
      'message': checkoutConflictMessage(productName),
      'created_at': occurredAt,
      'origin_device_id': payload['origin_device_id'] ?? deviceId,
    };
    final inserted = _insertEvent(
      environment: environment,
      entityType: 'alert',
      entityId: alertId,
      deviceId: deviceId,
      payload: alertPayload,
    );
    if (!inserted) {
      return;
    }
  }
}
