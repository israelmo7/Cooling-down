import 'package:drift/drift.dart';

import 'converters.dart';

@DataClassName('ProductRow')
class Products extends Table {
  @override
  String get tableName => 'products';

  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get sku => text().nullable()();
  BoolColumn get listed => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime().named('created_at')();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('FridgeRow')
class Fridges extends Table {
  @override
  String get tableName => 'fridges';

  TextColumn get id => text()();
  TextColumn get name => text()();
  RealColumn get minCelsius => real().named('min_celsius')();
  RealColumn get maxCelsius => real().named('max_celsius')();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('RefrigerationLogRow')
class RefrigerationLogs extends Table {
  @override
  String get tableName => 'refrigeration_logs';

  TextColumn get id => text()();
  TextColumn get movementId => text().named('movement_id')();
  TextColumn get productId =>
      text().named('product_id').references(Products, #id)();
  TextColumn get productNameSnapshot => text().named('product_name_snapshot')();
  TextColumn get fridgeId =>
      text().named('fridge_id').references(Fridges, #id)();
  TextColumn get eventType =>
      text().named('event_type').map(const LogEventTypeConverter())();
  RealColumn get temperatureCelsius => real().named('temperature_celsius')();
  DateTimeColumn get occurredAt => dateTime().named('occurred_at')();
  DateTimeColumn get createdAt => dateTime().named('created_at')();
  TextColumn get originDeviceId =>
      text().named('origin_device_id').withDefault(const Constant(''))();
  TextColumn get workerNameSnapshot =>
      text().named('worker_name_snapshot').withDefault(const Constant(''))();

  @override
  Set<Column<Object>> get primaryKey => {id};

  @override
  List<String> get customConstraints => [
    "CHECK (event_type IN ('check_in', 'check_out'))",
  ];
}

@DataClassName('WorkerRow')
class Workers extends Table {
  @override
  String get tableName => 'workers';

  TextColumn get id => text()();
  TextColumn get name => text()();
  DateTimeColumn get createdAt => dateTime().named('created_at')();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('AlertRow')
class Alerts extends Table {
  @override
  String get tableName => 'alerts';

  TextColumn get id => text()();
  TextColumn get severity => text().map(const AlertSeverityConverter())();
  TextColumn get kind => text().map(const AlertKindConverter())();
  TextColumn get productId =>
      text().named('product_id').nullable().references(Products, #id)();
  TextColumn get logId =>
      text().named('log_id').nullable().references(RefrigerationLogs, #id)();
  TextColumn get message => text()();
  DateTimeColumn get createdAt => dateTime().named('created_at')();
  DateTimeColumn get acknowledgedAt =>
      dateTime().named('acknowledged_at').nullable()();
  TextColumn get originDeviceId =>
      text().named('origin_device_id').withDefault(const Constant(''))();

  @override
  Set<Column<Object>> get primaryKey => {id};

  @override
  List<String> get customConstraints => [
    "CHECK (severity IN ('info', 'warning', 'critical'))",
    "CHECK (kind IN ('temperature_out_of_range', 'sync_conflict'))",
  ];
}

/// One row per tablet. These fields stay on the device and are not synced.
@DataClassName('LocalSettingsRow')
class LocalSettings extends Table {
  @override
  String get tableName => 'local_settings';

  TextColumn get id => text()();
  TextColumn get deviceId => text().named('device_id')();
  TextColumn get deviceName => text().named('device_name')();
  TextColumn get environmentName => text().named('environment_name')();
  TextColumn get serverUrl =>
      text().named('server_url').withDefault(const Constant(''))();
  TextColumn get serverToken =>
      text().named('server_token').withDefault(const Constant(''))();
  TextColumn get ownerEmail =>
      text().named('owner_email').withDefault(const Constant(''))();
  BoolColumn get dailyReportEnabled => boolean()
      .named('daily_report_enabled')
      .withDefault(const Constant(true))();
  IntColumn get reportHour =>
      integer().named('report_hour').withDefault(const Constant(0))();
  IntColumn get reportMinute =>
      integer().named('report_minute').withDefault(const Constant(0))();
  IntColumn get syncCursor =>
      integer().named('sync_cursor').withDefault(const Constant(0))();
  DateTimeColumn get lastSyncAt =>
      dateTime().named('last_sync_at').nullable()();
  TextColumn get lastSyncError => text().named('last_sync_error').nullable()();
  BoolColumn get hubEnabled =>
      boolean().named('hub_enabled').withDefault(const Constant(false))();
  BoolColumn get confirmAction =>
      boolean().named('confirm_action').withDefault(const Constant(false))();
  IntColumn get workerIdleSeconds =>
      integer().named('worker_idle_seconds').withDefault(const Constant(600))();
  TextColumn get smtpHost =>
      text().named('smtp_host').withDefault(const Constant(''))();
  IntColumn get smtpPort =>
      integer().named('smtp_port').withDefault(const Constant(587))();
  TextColumn get smtpUser =>
      text().named('smtp_user').withDefault(const Constant(''))();
  TextColumn get smtpPassword =>
      text().named('smtp_password').withDefault(const Constant(''))();
  TextColumn get smtpFrom =>
      text().named('smtp_from').withDefault(const Constant(''))();
  TextColumn get currentWorkerId =>
      text().named('current_worker_id').nullable()();
  DateTimeColumn get workerActiveAt =>
      dateTime().named('worker_active_at').nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('DailyReportRow')
class DailyReports extends Table {
  @override
  String get tableName => 'daily_reports';

  TextColumn get id => text()();
  TextColumn get environmentName => text().named('environment_name')();
  TextColumn get reportDate => text().named('report_date')();
  TextColumn get ownerEmail => text().named('owner_email')();
  TextColumn get subject => text()();
  TextColumn get body => text()();
  TextColumn get status => text()();
  DateTimeColumn get createdAt => dateTime().named('created_at')();
  DateTimeColumn get sentAt => dateTime().named('sent_at').nullable()();
  TextColumn get lastError => text().named('last_error').nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};

  @override
  List<Set<Column<Object>>> get uniqueKeys => [
    {environmentName, reportDate},
  ];

  @override
  List<String> get customConstraints => [
    "CHECK (status IN ('waiting', 'sent', 'already_sent', 'stored', 'failed'))",
  ];
}

@DataClassName('SyncOutboxRow')
class SyncOutbox extends Table {
  @override
  String get tableName => 'sync_outbox';

  TextColumn get id => text()();
  TextColumn get entityType => text().named('entity_type')();
  TextColumn get entityId => text().named('entity_id')();
  TextColumn get operation => text()();
  TextColumn get payloadJson => text().named('payload_json')();
  TextColumn get status => text().map(const SyncStatusConverter())();
  IntColumn get attemptCount =>
      integer().named('attempt_count').withDefault(const Constant(0))();
  TextColumn get lastError => text().named('last_error').nullable()();
  DateTimeColumn get createdAt => dateTime().named('created_at')();

  @override
  Set<Column<Object>> get primaryKey => {id};

  @override
  List<String> get customConstraints => [
    "CHECK (operation IN ('insert'))",
    "CHECK (status IN ('pending', 'in_flight', 'synced', 'failed'))",
  ];
}

/// Ordered copy of every log and alert this tablet can hand to others.
@DataClassName('SyncFeedRow')
class SyncFeed extends Table {
  @override
  String get tableName => 'sync_feed';

  IntColumn get seq => integer().autoIncrement()();
  TextColumn get entityType => text().named('entity_type')();
  TextColumn get entityId => text().named('entity_id')();
  TextColumn get originDeviceId =>
      text().named('origin_device_id').withDefault(const Constant(''))();
  TextColumn get payloadJson => text().named('payload_json')();

  @override
  List<Set<Column<Object>>> get uniqueKeys => [
    {entityType, entityId},
  ];
}
