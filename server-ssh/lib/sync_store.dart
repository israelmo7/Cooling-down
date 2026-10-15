import 'dart:convert';

import 'package:sqlite3/sqlite3.dart';
import 'package:uuid/uuid.dart';

import 'conflict.dart';
import 'daily_mail.dart';
import 'mailer.dart';
import 'report_time.dart';

class SyncStore {
  SyncStore(this._db, {ReportMailer? mailer, this.ownerEmail = ''})
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
    _db.execute('''
CREATE TABLE IF NOT EXISTS environments (
  name TEXT PRIMARY KEY,
  owner_email TEXT NOT NULL
)
''');
    _addColumn('refrigeration_logs', 'temperature', 'REAL');
    _addColumn('refrigeration_logs', 'fridge_name', 'TEXT');
    _addColumn('refrigeration_logs', 'worker_name', 'TEXT');
  }

  factory SyncStore.memory({ReportMailer? mailer, String ownerEmail = ''}) {
    return SyncStore(
      sqlite3.openInMemory(),
      mailer: mailer,
      ownerEmail: ownerEmail,
    );
  }

  final Database _db;
  final ReportMailer _mailer;
  String ownerEmail;
  final Set<String> _sending = {};
  final Uuid _uuid = const Uuid();

  void _addColumn(String table, String column, String type) {
    final columns = _db.select('PRAGMA table_info($table)');
    final exists = columns.any((row) => row['name'] == column);
    if (!exists) {
      _db.execute('ALTER TABLE $table ADD COLUMN $column $type');
    }
  }

  void close() => _db.close();

  Map<String, Object?> exchange({
    required String deviceId,
    required String environment,
    required int cursor,
    required List<Map<String, dynamic>> push,
    String? ownerEmail,
  }) {
    _rememberOwner(environment, ownerEmail);
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
WHERE environment = ? AND device_id = ? AND seq > ?
ORDER BY seq
LIMIT 500
''',
      [environment, deviceId, cursor],
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
    String? html,
  }) async {
    final existing = _db.select(
      '''
SELECT id, status FROM daily_reports
WHERE environment = ? AND report_date = ?
''',
      [environment, reportDate],
    );
    final key = '$environment|$reportDate';
    final existingStatus = existing.isEmpty
        ? null
        : existing.first['status']?.toString();
    if (existingStatus == 'sent' ||
        existingStatus == 'sending' ||
        _sending.contains(key)) {
      return {'status': 'already_sent'};
    }
    _sending.add(key);

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
        html: html,
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
    } finally {
      _sending.remove(key);
    }
  }

  /// Emails yesterday's report once the local clock has reached [reportTime].
  /// Tablets that were offline keep their rows and sync them when the computer
  /// is reachable again. A report already marked sent is not mailed twice.
  /// A custom [template] is used only when [reportFormat] is `custom` and the
  /// text is non-empty. Otherwise the built-in table is sent.
  Future<List<String>> sendClosedDay(
    DateTime nowLocal, {
    ReportTime reportTime = ReportTime.midnight,
    String reportFormat = 'builtin',
    String? template,
  }) async {
    if (!reportTime.reached(nowLocal)) {
      return const [];
    }
    final custom = normalizeReportFormat(reportFormat) == 'custom';
    final wording = template?.trim() ?? '';
    final startOfToday = DateTime(nowLocal.year, nowLocal.month, nowLocal.day);
    final day = startOfToday.subtract(const Duration(days: 1));
    final date = _reportDate(day);
    final targets = _db.select(
      "SELECT name, owner_email FROM environments WHERE owner_email LIKE '%@%'",
    );
    final statuses = <String>[];
    for (final target in targets) {
      final environment = target['name'] as String;
      final email = target['owner_email'] as String;
      final existing = _db.select(
        '''
SELECT status FROM daily_reports
WHERE environment = ? AND report_date = ?
''',
        [environment, date],
      );
      final status = existing.isEmpty
          ? null
          : existing.first['status']?.toString();
      if (status == 'sent') {
        continue;
      }
      final logs = _logs(environment);
      final notices = _notices(environment);
      final content = custom && wording.isNotEmpty
          ? buildCustomReport(
              template: wording,
              environmentName: environment,
              day: day,
              logs: logs,
              notices: notices,
            )
          : buildClosedDayReport(
              environmentName: environment,
              day: day,
              logs: logs,
              notices: notices,
            );
      final result = await submitReport(
        id: _uuid.v4(),
        environment: environment,
        reportDate: date,
        ownerEmail: email,
        subject: content.subject,
        body: content.body,
        html: content.html,
      );
      statuses.add(result['status']?.toString() ?? 'failed');
    }
    return statuses;
  }

  void setOwnerEmail(String environment, String email) {
    final name = environment.trim();
    final address = email.trim();
    if (name.isEmpty || !address.contains('@')) {
      return;
    }
    _writeOwner(name, address);
  }

  /// The address new environments inherit. Places still using the previous
  /// default, or with no address yet, follow the new one.
  void setDefaultOwnerEmail(String email) {
    final next = email.trim();
    final previous = ownerEmail.trim();
    ownerEmail = next;
    if (!next.contains('@')) {
      return;
    }
    for (final row in environmentSummaries()) {
      final current = (row['owner_email'] as String?)?.trim() ?? '';
      final followsDefault =
          current.isEmpty || !current.contains('@') || current == previous;
      if (followsDefault) {
        _writeOwner(row['name'] as String, next);
      }
    }
  }

  List<Map<String, Object?>> environmentSummaries() {
    final named = _db.select(
      'SELECT name, owner_email FROM environments ORDER BY name',
    );
    final fromLogs = _db.select(
      'SELECT DISTINCT environment FROM refrigeration_logs ORDER BY environment',
    );
    final byName = <String, String>{
      for (final row in named)
        row['name'] as String: row['owner_email'] as String? ?? '',
    };
    for (final row in fromLogs) {
      byName.putIfAbsent(row['environment'] as String, () => '');
    }
    final names = byName.keys.toList()..sort();
    return [
      for (final name in names)
        {
          'name': name,
          'owner_email': byName[name] ?? '',
          'logs': _logs(name).length,
        },
    ];
  }

  List<StoredLogLine> logsFor(String environment) => _logs(environment);

  void _rememberOwner(String environment, String? fromTablet) {
    final existing = _db.select(
      'SELECT owner_email FROM environments WHERE name = ?',
      [environment],
    );
    if (existing.isNotEmpty) {
      final saved = existing.first['owner_email'] as String? ?? '';
      if (saved.contains('@')) {
        return;
      }
    }
    final configured = ownerEmail.trim();
    final email = configured.contains('@')
        ? configured
        : (fromTablet?.trim() ?? '');
    if (!email.contains('@')) {
      return;
    }
    _writeOwner(environment, email);
  }

  void _writeOwner(String environment, String email) {
    _db.execute(
      '''
INSERT INTO environments (name, owner_email) VALUES (?, ?)
ON CONFLICT(name) DO UPDATE SET owner_email = excluded.owner_email
''',
      [environment, email],
    );
  }

  List<StoredLogLine> _logs(String environment) {
    final rows = _db.select(
      '''
SELECT movement_id, event_type, occurred_at, product_name, temperature, fridge_name, worker_name
FROM refrigeration_logs
WHERE environment = ?
''',
      [environment],
    );
    return [
      for (final row in rows)
        StoredLogLine(
          movementId: row['movement_id'] as String? ?? '',
          eventType: row['event_type'] as String,
          occurredAt: DateTime.parse(row['occurred_at'] as String),
          productName: row['product_name'] as String,
          temperature: (row['temperature'] as num?)?.toDouble(),
          fridgeName: row['fridge_name'] as String? ?? '',
          workerName: row['worker_name'] as String? ?? '',
        ),
    ];
  }

  List<StoredNotice> _notices(String environment) {
    final rows = _db.select(
      '''
SELECT payload_json FROM sync_events
WHERE environment = ? AND entity_type = 'alert'
''',
      [environment],
    );
    final notices = <StoredNotice>[];
    for (final row in rows) {
      final decoded = jsonDecode(row['payload_json'] as String);
      if (decoded is! Map) {
        continue;
      }
      final message = decoded['message'];
      final createdAt = decoded['created_at'];
      if (message is! String || createdAt is! String) {
        continue;
      }
      notices.add(
        StoredNotice(message: message, createdAt: DateTime.parse(createdAt)),
      );
    }
    return notices;
  }

  String _reportDate(DateTime day) {
    final year = day.year.toString().padLeft(4, '0');
    final month = day.month.toString().padLeft(2, '0');
    final date = day.day.toString().padLeft(2, '0');
    return '$year-$month-$date';
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
    final temperature = payload['temperature_celsius'];
    final fridgeName = payload['fridge_name'];
    final workerName = payload['worker_name_snapshot'];
    _db.execute(
      '''
INSERT INTO refrigeration_logs (
  id, environment, movement_id, event_type, occurred_at, product_name,
  temperature, fridge_name, worker_name
) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
''',
      [
        id,
        environment,
        movementId,
        eventType,
        occurredAt,
        productName,
        temperature is num ? temperature.toDouble() : null,
        fridgeName is String ? fridgeName : '',
        workerName is String ? workerName : '',
      ],
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
