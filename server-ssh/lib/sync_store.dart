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
    _db.execute('''
CREATE TABLE IF NOT EXISTS device_sync_state (
  environment TEXT NOT NULL,
  device_id TEXT NOT NULL,
  last_seen_at TEXT NOT NULL,
  last_full_sync_at TEXT,
  PRIMARY KEY (environment, device_id)
)
''');
    _db.execute('''
CREATE TABLE IF NOT EXISTS device_day_presence (
  environment TEXT NOT NULL,
  device_id TEXT NOT NULL,
  day TEXT NOT NULL,
  PRIMARY KEY (environment, device_id, day)
)
''');
    _db.execute('''
CREATE TABLE IF NOT EXISTS supplier_deliveries (
  id TEXT PRIMARY KEY,
  status TEXT NOT NULL,
  opened_at TEXT NOT NULL,
  closed_at TEXT,
  mail_status TEXT
)
''');
    _db.execute('''
CREATE TABLE IF NOT EXISTS supplier_participants (
  session_id TEXT PRIMARY KEY,
  delivery_id TEXT NOT NULL,
  device_id TEXT NOT NULL,
  environment TEXT NOT NULL,
  active INTEGER NOT NULL
)
''');
    _addColumn('daily_reports', 'sent_time', 'TEXT');
    _addColumn('refrigeration_logs', 'temperature', 'REAL');
    _addColumn('refrigeration_logs', 'fridge_name', 'TEXT');
    _addColumn('refrigeration_logs', 'worker_name', 'TEXT');
    _addColumn('refrigeration_logs', 'quantity', 'INTEGER');
    _addColumn('refrigeration_logs', 'package_id', 'TEXT');
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

  /// Records that [deviceId] reached the shop computer.
  /// [fullySynced] is true when the tablet outbox was empty after this exchange.
  void _noteDeviceContact({
    required String environment,
    required String deviceId,
    required bool fullySynced,
    required DateTime now,
  }) {
    final instant = now.toUtc().toIso8601String();
    final day = _reportDate(now.toLocal());
    final existing = _db.select(
      '''
SELECT last_full_sync_at FROM device_sync_state
WHERE environment = ? AND device_id = ?
''',
      [environment, deviceId],
    );
    if (existing.isEmpty) {
      _db.execute(
        '''
INSERT INTO device_sync_state (
  environment, device_id, last_seen_at, last_full_sync_at
) VALUES (?, ?, ?, ?)
''',
        [environment, deviceId, instant, fullySynced ? instant : null],
      );
    } else {
      _db.execute(
        '''
UPDATE device_sync_state
SET last_seen_at = ?, last_full_sync_at = CASE WHEN ? THEN ? ELSE last_full_sync_at END
WHERE environment = ? AND device_id = ?
''',
        [
          instant,
          fullySynced ? 1 : 0,
          instant,
          environment,
          deviceId,
        ],
      );
    }
    _db.execute(
      '''
INSERT OR IGNORE INTO device_day_presence (environment, device_id, day)
VALUES (?, ?, ?)
''',
      [environment, deviceId, day],
    );
  }

  /// Environments that were on during [day] but had not fully synced by
  /// the end of that local day. Late sync after midnight clears the gap.
  List<SyncGapNote> syncGapsForDay(
    DateTime day, {
    String? environment,
    DateTime? asOf,
  }) {
    final start = DateTime(day.year, day.month, day.day);
    final end = start.add(const Duration(days: 1));
    final date = _reportDate(day);
    final now = asOf ?? DateTime.now();
    // Morning report: only attach a gap once the reported day has ended.
    if (now.isBefore(end)) {
      return const [];
    }
    final rows = environment == null
        ? _db.select(
            '''
SELECT p.environment, s.last_full_sync_at
FROM device_day_presence p
LEFT JOIN device_sync_state s
  ON s.environment = p.environment AND s.device_id = p.device_id
WHERE p.day = ?
''',
            [date],
          )
        : _db.select(
            '''
SELECT p.environment, s.last_full_sync_at
FROM device_day_presence p
LEFT JOIN device_sync_state s
  ON s.environment = p.environment AND s.device_id = p.device_id
WHERE p.day = ? AND p.environment = ?
''',
            [date, environment],
          );
    final worst = <String, Duration>{};
    for (final row in rows) {
      final name = row['environment']?.toString() ?? '';
      if (name.isEmpty) {
        continue;
      }
      final raw = row['last_full_sync_at']?.toString();
      final lastFull = raw == null || raw.isEmpty
          ? null
          : DateTime.tryParse(raw)?.toLocal();
      // Synced at or after the day closed — morning mail has the full day.
      if (lastFull != null && !lastFull.isBefore(end)) {
        continue;
      }
      final from = lastFull == null || lastFull.isBefore(start)
          ? start
          : lastFull;
      final gap = end.difference(from);
      if (gap <= Duration.zero) {
        continue;
      }
      final previous = worst[name];
      if (previous == null || gap > previous) {
        worst[name] = gap;
      }
    }
    return [
      for (final entry in worst.entries)
        SyncGapNote(environmentName: entry.key, unsynced: entry.value),
    ];
  }

  Future<Map<String, Object?>> exchange({
    required String deviceId,
    required String environment,
    required int cursor,
    required List<Map<String, dynamic>> push,
    String? ownerEmail,
    int? pendingCount,
    DateTime? now,
  }) async {
    _rememberOwner(environment, ownerEmail);
    final accepted = <String>[];
    final conflicts = <Map<String, String>>[];
    final deliveriesToMail = <String>[];
    _db.execute('BEGIN');
    try {
      for (final item in push) {
        final entityId = _applyPush(
          deviceId: deviceId,
          environment: environment,
          item: item,
          conflicts: conflicts,
          deliveriesToMail: deliveriesToMail,
        );
        accepted.add(entityId);
      }
      _db.execute('COMMIT');
    } on Object {
      _db.execute('ROLLBACK');
      rethrow;
    }

    for (final deliveryId in deliveriesToMail) {
      await _sendClosedDeliveryMail(deliveryId);
    }

    // Tablet sends every pending row in one push. Older builds omit
    // pending_count; a successful exchange then means the outbox was cleared.
    final fullySynced = pendingCount == null
        ? true
        : pendingCount <= push.length;
    _noteDeviceContact(
      environment: environment,
      deviceId: deviceId,
      fullySynced: fullySynced,
      now: now ?? DateTime.now(),
    );

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
    bool force = false,
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
    if (_sending.contains(key) ||
        (!force && (existingStatus == 'sent' || existingStatus == 'sending'))) {
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

  /// Emails closed days once the local clock has reached [reportTime].
  /// Always covers yesterday; also walks up to [backlogDays] older unsent days
  /// so a multi-day PC outage still catches up after restart.
  Future<List<String>> sendClosedDay(
    DateTime nowLocal, {
    ReportTime reportTime = ReportTime.midnight,
    String reportFormat = 'builtin',
    String? template,
    int backlogDays = 7,
  }) async {
    if (!reportTime.reached(nowLocal)) {
      return const [];
    }
    final startOfToday = DateTime(nowLocal.year, nowLocal.month, nowLocal.day);
    final statuses = <String>[];
    final depth = backlogDays < 1 ? 1 : backlogDays;
    for (var ago = depth; ago >= 1; ago--) {
      final day = startOfToday.subtract(Duration(days: ago));
      // Yesterday always; older days only if this shop actually had activity.
      if (ago > 1 && !_dayHasLogs(day)) {
        continue;
      }
      final batch = await sendDay(
        day,
        reportFormat: reportFormat,
        template: template,
        reportTime: reportTime,
        asOf: nowLocal,
      );
      statuses.addAll(batch);
    }
    return statuses;
  }

  bool _dayHasLogs(DateTime day) {
    final start = DateTime(day.year, day.month, day.day);
    final end = start.add(const Duration(days: 1));
    final rows = _db.select(
      '''
SELECT 1 AS n FROM refrigeration_logs
WHERE datetime(occurred_at) >= datetime(?) AND datetime(occurred_at) < datetime(?)
LIMIT 1
''',
      [start.toUtc().toIso8601String(), end.toUtc().toIso8601String()],
    );
    return rows.isNotEmpty;
  }

  /// Sends one mail for [day], with one table per environment.
  /// A day already sent for [reportTime] is skipped, unless [force] is set.
  Future<List<String>> sendDay(
    DateTime day, {
    String reportFormat = 'builtin',
    String? template,
    bool force = false,
    ReportTime? reportTime,
    DateTime? asOf,
  }) async {
    final custom = normalizeReportFormat(reportFormat) == 'custom';
    final wording = template?.trim() ?? '';
    final date = _reportDate(day);
    final email = ownerEmail.trim();
    if (!email.contains('@')) {
      return const [];
    }
    final names = [
      for (final row in environmentSummaries()) row['name'] as String,
    ];
    final due =
        force ||
        names.any((environment) => !_blocksSend(environment, date, reportTime));
    if (!due) {
      _adoptSentTime(date, reportTime);
      return const [];
    }
    final sections = <({String environment, ClosedDayReport content})>[];
    for (final environment in names) {
      final logs = _logs(environment);
      final gaps = syncGapsForDay(
        day,
        environment: environment,
        asOf: asOf ?? DateTime.now(),
      );
      final content = custom && wording.isNotEmpty
          ? buildCustomReport(
              template: wording,
              environmentName: environment,
              day: day,
              logs: logs,
              notices: _notices(environment),
              syncGaps: gaps,
            )
          : buildClosedDayReport(
              environmentName: environment,
              day: day,
              logs: logs,
              syncGaps: gaps,
            );
      sections.add((environment: environment, content: content));
    }
    if (sections.isEmpty) {
      return const [];
    }
    final subject = sections.length == 1
        ? sections.single.content.subject
        : 'דוח קירור · $date';
    final body = sections.map((item) => item.content.body).join('\n\n');
    final html = sections.map((item) => item.content.html).join('\n');
    try {
      final emailed = await _mailer.send(
        to: email,
        subject: subject,
        body: body,
        html: html,
      );
      final status = emailed ? 'sent' : 'stored';
      for (final item in sections) {
        _writeReport(
          environment: item.environment,
          reportDate: date,
          ownerEmail: email,
          subject: subject,
          body: item.content.body,
          status: status,
          sentTime: reportTime?.text,
        );
      }
      return [status];
    } on Object catch (error) {
      for (final item in sections) {
        _writeReport(
          environment: item.environment,
          reportDate: date,
          ownerEmail: email,
          subject: subject,
          body: item.content.body,
          status: 'failed',
          error: error.toString(),
        );
      }
      return ['failed'];
    }
  }

  /// A sent row blocks another mail for the same clock time.
  /// A row stored before clock times were kept still blocks, until a new time.
  bool _blocksSend(String environment, String date, ReportTime? reportTime) {
    final existing = _db.select(
      '''
SELECT status, sent_time FROM daily_reports
WHERE environment = ? AND report_date = ?
''',
      [environment, date],
    );
    if (existing.isEmpty || existing.first['status']?.toString() != 'sent') {
      return false;
    }
    if (reportTime == null) {
      return true;
    }
    final saved = existing.first['sent_time']?.toString() ?? '';
    return saved.isEmpty || saved == reportTime.text;
  }

  void _adoptSentTime(String date, ReportTime? reportTime) {
    final stamp = reportTime?.text;
    if (stamp == null || stamp.isEmpty) {
      return;
    }
    _db.execute(
      '''
UPDATE daily_reports
SET sent_time = ?
WHERE report_date = ? AND status = 'sent' AND (sent_time IS NULL OR sent_time = '')
''',
      [stamp, date],
    );
  }

  void _writeReport({
    required String environment,
    required String reportDate,
    required String ownerEmail,
    required String subject,
    required String body,
    required String status,
    String? sentTime,
    String? error,
  }) {
    final existing = _db.select(
      '''
SELECT id FROM daily_reports
WHERE environment = ? AND report_date = ?
''',
      [environment, reportDate],
    );
    if (existing.isEmpty) {
      _db.execute(
        '''
INSERT INTO daily_reports (
  id, environment, report_date, owner_email, subject, body, status, sent_time, last_error
) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
''',
        [
          _uuid.v4(),
          environment,
          reportDate,
          ownerEmail,
          subject,
          body,
          status,
          sentTime,
          error,
        ],
      );
      return;
    }
    _db.execute(
      '''
UPDATE daily_reports
SET owner_email = ?, subject = ?, body = ?, status = ?, sent_time = ?, last_error = ?
WHERE environment = ? AND report_date = ?
''',
      [
        ownerEmail,
        subject,
        body,
        status,
        sentTime,
        error,
        environment,
        reportDate,
      ],
    );
  }

  void setOwnerEmail(String environment, String email) {
    final name = environment.trim();
    final address = email.trim();
    if (name.isEmpty || !address.contains('@')) {
      return;
    }
    _writeOwner(name, address);
  }

  /// The one address that receives every environment's report.
  void setDefaultOwnerEmail(String email) {
    final next = email.trim();
    ownerEmail = next;
    if (!next.contains('@')) {
      return;
    }
    for (final row in environmentSummaries()) {
      _writeOwner(row['name'] as String, next);
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

  /// Stored daily report rows for [environment], newest first.
  List<Map<String, Object?>> reportsFor(String environment) {
    final rows = _db.select(
      '''
SELECT id, environment, report_date, owner_email, subject, body, status, sent_time, last_error
FROM daily_reports
WHERE environment = ?
ORDER BY report_date DESC
''',
      [environment],
    );
    return [
      for (final row in rows)
        {
          for (final column in row.keys) column: row[column],
        },
    ];
  }

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
SELECT movement_id, event_type, occurred_at, product_name, temperature, fridge_name, worker_name, quantity
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
          quantity: (row['quantity'] as num?)?.toInt() ?? 1,
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
    required List<String> deliveriesToMail,
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
    if (entityType == 'receiving_package' && inserted) {
      final deliveryId = _applyReceivingSession(
        environment: environment,
        deviceId: deviceId,
        payload: body,
      );
      if (deliveryId != null && !deliveriesToMail.contains(deliveryId)) {
        deliveriesToMail.add(deliveryId);
      }
    }
    return entityId;
  }

  /// Joins or leaves the open shop delivery. Returns a delivery id to mail
  /// when this leave was the last active tablet.
  String? _applyReceivingSession({
    required String environment,
    required String deviceId,
    required Map<String, Object?> payload,
  }) {
    final status = payload['status'];
    final sessionRaw = payload['session_id'] ?? payload['id'];
    if (sessionRaw is! String || sessionRaw.trim().isEmpty) {
      throw const FormatException('A receiving session needs an id.');
    }
    final sessionId = sessionRaw.trim();
    if (status == 'open') {
      _joinSupplierDelivery(
        sessionId: sessionId,
        deviceId: deviceId,
        environment: environment,
      );
      return null;
    }
    if (status != 'closed') {
      return null;
    }
    return _leaveSupplierDelivery(
      sessionId: sessionId,
      deviceId: deviceId,
      closedAtRaw: payload['closed_at'],
    );
  }

  void _joinSupplierDelivery({
    required String sessionId,
    required String deviceId,
    required String environment,
  }) {
    final open = _db.select(
      "SELECT id FROM supplier_deliveries WHERE status = 'open' ORDER BY opened_at LIMIT 1",
    );
    final deliveryId = open.isEmpty
        ? _uuid.v4()
        : open.first['id'] as String;
    if (open.isEmpty) {
      _db.execute(
        '''
INSERT INTO supplier_deliveries (id, status, opened_at, closed_at, mail_status)
VALUES (?, 'open', ?, NULL, NULL)
''',
        [deliveryId, DateTime.now().toUtc().toIso8601String()],
      );
    }
    final existing = _db.select(
      'SELECT session_id FROM supplier_participants WHERE session_id = ?',
      [sessionId],
    );
    if (existing.isEmpty) {
      _db.execute(
        '''
INSERT INTO supplier_participants (
  session_id, delivery_id, device_id, environment, active
) VALUES (?, ?, ?, ?, 1)
''',
        [sessionId, deliveryId, deviceId, environment],
      );
    } else {
      _db.execute(
        '''
UPDATE supplier_participants
SET delivery_id = ?, device_id = ?, environment = ?, active = 1
WHERE session_id = ?
''',
        [deliveryId, deviceId, environment, sessionId],
      );
    }
  }

  String? _leaveSupplierDelivery({
    required String sessionId,
    required String deviceId,
    required Object? closedAtRaw,
  }) {
    final rows = _db.select(
      '''
SELECT delivery_id FROM supplier_participants
WHERE session_id = ? OR (device_id = ? AND active = 1)
ORDER BY CASE WHEN session_id = ? THEN 0 ELSE 1 END
LIMIT 1
''',
      [sessionId, deviceId, sessionId],
    );
    if (rows.isEmpty) {
      return null;
    }
    final deliveryId = rows.first['delivery_id'] as String;
    _db.execute(
      '''
UPDATE supplier_participants SET active = 0
WHERE delivery_id = ? AND (session_id = ? OR device_id = ?)
''',
      [deliveryId, sessionId, deviceId],
    );
    final stillActive = _db.select(
      '''
SELECT COUNT(*) AS n FROM supplier_participants
WHERE delivery_id = ? AND active = 1
''',
      [deliveryId],
    );
    final activeCount = (stillActive.first['n'] as int?) ?? 0;
    if (activeCount > 0) {
      return null;
    }
    final closedAt = closedAtRaw is String
        ? DateTime.tryParse(closedAtRaw)?.toUtc().toIso8601String()
        : null;
    _db.execute(
      '''
UPDATE supplier_deliveries
SET status = 'closed', closed_at = COALESCE(?, closed_at, ?)
WHERE id = ? AND status = 'open'
''',
      [
        closedAt,
        DateTime.now().toUtc().toIso8601String(),
        deliveryId,
      ],
    );
    final mailed = _db.select(
      'SELECT mail_status FROM supplier_deliveries WHERE id = ?',
      [deliveryId],
    );
    final status = mailed.isEmpty
        ? null
        : mailed.first['mail_status']?.toString();
    // `failed` is retried on the next leave path; only terminal successes skip.
    if (status == 'sent' || status == 'stored' || status == 'empty') {
      return null;
    }
    return deliveryId;
  }

  Future<String> _sendClosedDeliveryMail(String deliveryId) async {
    final entries = _deliveryEntries(deliveryId);
    if (entries.isEmpty) {
      _db.execute(
        'UPDATE supplier_deliveries SET mail_status = ? WHERE id = ?',
        ['empty', deliveryId],
      );
      return 'empty';
    }
    final email = ownerEmail.trim();
    final closedRow = _db.select(
      'SELECT closed_at FROM supplier_deliveries WHERE id = ?',
      [deliveryId],
    );
    final closedRaw = closedRow.isEmpty
        ? null
        : closedRow.first['closed_at']?.toString();
    final closedAt = closedRaw == null || closedRaw.isEmpty
        ? DateTime.now()
        : DateTime.tryParse(closedRaw)?.toLocal() ?? DateTime.now();
    final report = buildSupplierPackageReport(
      entries: entries,
      closedAt: closedAt,
    );
    if (!email.contains('@')) {
      _db.execute(
        'UPDATE supplier_deliveries SET mail_status = ? WHERE id = ?',
        ['stored', deliveryId],
      );
      return 'stored';
    }
    try {
      final emailed = await _mailer.send(
        to: email,
        subject: report.subject,
        body: report.body,
        html: report.html,
      );
      final status = emailed ? 'sent' : 'stored';
      _db.execute(
        'UPDATE supplier_deliveries SET mail_status = ? WHERE id = ?',
        [status, deliveryId],
      );
      return status;
    } on Object {
      _db.execute(
        'UPDATE supplier_deliveries SET mail_status = ? WHERE id = ?',
        ['failed', deliveryId],
      );
      return 'failed';
    }
  }

  List<SupplierEntry> _deliveryEntries(String deliveryId) {
    final rows = _db.select(
      '''
SELECT environment, movement_id, event_type, occurred_at, product_name,
       temperature, fridge_name, worker_name, quantity
FROM refrigeration_logs
WHERE package_id = ? AND event_type = 'check_in'
ORDER BY environment, occurred_at
''',
      [deliveryId],
    );
    return [
      for (final row in rows)
        SupplierEntry(
          environmentName: row['environment'] as String? ?? '',
          line: StoredLogLine(
            movementId: row['movement_id'] as String? ?? '',
            eventType: row['event_type'] as String? ?? '',
            occurredAt: DateTime.parse(row['occurred_at'] as String),
            productName: row['product_name'] as String? ?? '',
            temperature: (row['temperature'] as num?)?.toDouble(),
            fridgeName: row['fridge_name'] as String? ?? '',
            workerName: row['worker_name'] as String? ?? '',
            quantity: (row['quantity'] as num?)?.toInt() ?? 1,
          ),
        ),
    ];
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
        movementId.trim().isEmpty ||
        eventType is! String ||
        (eventType != 'check_in' && eventType != 'check_out') ||
        occurredAt is! String ||
        DateTime.tryParse(occurredAt) == null ||
        productName is! String ||
        productName.trim().isEmpty ||
        productName.length > 200) {
      throw const FormatException('A refrigeration log payload is incomplete.');
    }
    final temperature = payload['temperature_celsius'];
    if (temperature != null &&
        (temperature is! num ||
            !temperature.isFinite ||
            temperature < -40 ||
            temperature > 30)) {
      throw const FormatException(
        'A refrigeration log temperature is out of range.',
      );
    }
    final fridgeName = payload['fridge_name'];
    final workerName = payload['worker_name_snapshot'];
    if ((fridgeName != null && fridgeName is! String) ||
        (workerName != null && workerName is! String)) {
      throw const FormatException('A refrigeration log payload is incomplete.');
    }
    // Old tablets send no quantity: that is 1. Anything sent must be a
    // whole number in range; it is never silently turned into 1.
    final rawQuantity = payload['quantity'];
    final int quantity;
    if (rawQuantity == null) {
      quantity = 1;
    } else if (rawQuantity is num &&
        rawQuantity.isFinite &&
        rawQuantity == rawQuantity.toInt() &&
        rawQuantity >= 1 &&
        rawQuantity <= 9999) {
      quantity = rawQuantity.toInt();
    } else {
      throw const FormatException('A refrigeration log quantity is invalid.');
    }
    // While this device is in מצב אספקה, tag the check-in with the shared
    // open delivery so the final mail spans every fridge that took part.
    final activeDelivery = _db.select(
      '''
SELECT delivery_id FROM supplier_participants
WHERE device_id = ? AND active = 1
ORDER BY session_id
LIMIT 1
''',
      [deviceId],
    );
    final rawPackage = payload['package_id'];
    final packageId = activeDelivery.isNotEmpty
        ? activeDelivery.first['delivery_id'] as String?
        : (rawPackage is String && rawPackage.trim().isNotEmpty
              ? rawPackage.trim()
              : null);
    _db.execute(
      '''
INSERT INTO refrigeration_logs (
  id, environment, movement_id, event_type, occurred_at, product_name,
  temperature, fridge_name, worker_name, quantity, package_id
) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
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
        quantity,
        eventType == 'check_in' ? packageId : null,
      ],
    );
    if (eventType != 'check_out') {
      return;
    }
    // Partial check-outs are fine while the total taken out stays within
    // what was checked in. Past that, keep the row (as before) but flag it.
    final checkIns = _db.select(
      '''
SELECT quantity FROM refrigeration_logs
WHERE environment = ? AND movement_id = ? AND event_type = 'check_in'
ORDER BY occurred_at
LIMIT 1
''',
      [environment, movementId],
    );
    final checkouts = _db.select(
      '''
SELECT quantity FROM refrigeration_logs
WHERE environment = ? AND movement_id = ? AND event_type = 'check_out'
''',
      [environment, movementId],
    );
    final totalOut = checkouts.fold<int>(
      0,
      (sum, row) => sum + ((row['quantity'] as num?)?.toInt() ?? 1),
    );
    final String? conflictReason;
    final String conflictMessage;
    if (checkIns.isEmpty) {
      conflictReason = checkouts.length >= 2
          ? 'movement already checked out'
          : null;
      conflictMessage = checkoutConflictMessage(productName);
    } else {
      final checkedIn = (checkIns.first['quantity'] as num?)?.toInt() ?? 1;
      if (totalOut <= checkedIn) {
        return;
      }
      final alreadyOut = totalOut - quantity;
      conflictReason = alreadyOut >= checkedIn
          ? 'movement already checked out'
          : 'checkout quantity exceeds check-in';
      conflictMessage = alreadyOut >= checkedIn
          ? checkoutConflictMessage(productName)
          : checkoutQuantityConflictMessage(productName);
    }
    if (conflictReason == null) {
      return;
    }
    conflicts.add({'entity_id': id, 'reason': conflictReason});
    final alertId = checkoutConflictAlertId(movementId);
    final alertPayload = <String, Object?>{
      'id': alertId,
      'severity': 'warning',
      'kind': 'sync_conflict',
      'product_id': payload['product_id'],
      'log_id': id,
      'message': conflictMessage,
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
