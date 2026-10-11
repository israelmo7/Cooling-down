import 'package:drift/drift.dart';

import 'converters.dart';

@DataClassName('ProductRow')
class Products extends Table {
  @override
  String get tableName => 'products';

  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get sku => text().nullable()();
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

  @override
  Set<Column<Object>> get primaryKey => {id};

  @override
  List<String> get customConstraints => [
    "CHECK (event_type IN ('check_in', 'check_out'))",
  ];
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

  @override
  Set<Column<Object>> get primaryKey => {id};

  @override
  List<String> get customConstraints => [
    "CHECK (severity IN ('info', 'warning', 'critical'))",
    "CHECK (kind IN ('temperature_out_of_range'))",
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
