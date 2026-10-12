import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:drift_flutter/drift_flutter.dart';

import '../../domain/entities/alert.dart';
import '../../domain/entities/refrigeration_log.dart';
import 'converters.dart';
import 'seed_ids.dart';
import 'tables.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    Products,
    Fridges,
    RefrigerationLogs,
    Alerts,
    SyncOutbox,
    LocalSettings,
    DailyReports,
    SyncFeed,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(driftDatabase(name: 'cooling_down'));

  AppDatabase.memory() : super(NativeDatabase.memory());

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (migrator) async {
      await migrator.createAll();
      await _seed();
    },
    onUpgrade: (migrator, from, to) async {
      if (from < 2) {
        await migrator.addColumn(
          refrigerationLogs,
          refrigerationLogs.originDeviceId,
        );
        await migrator.createTable(localSettings);
        await migrator.createTable(dailyReports);
        await migrator.alterTable(
          TableMigration(alerts, newColumns: [alerts.originDeviceId]),
        );
      }
      if (from < 3) {
        await migrator.addColumn(localSettings, localSettings.hubEnabled);
        await migrator.addColumn(localSettings, localSettings.smtpHost);
        await migrator.addColumn(localSettings, localSettings.smtpPort);
        await migrator.addColumn(localSettings, localSettings.smtpUser);
        await migrator.addColumn(localSettings, localSettings.smtpPassword);
        await migrator.addColumn(localSettings, localSettings.smtpFrom);
        await migrator.createTable(syncFeed);
      }
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
      try {
        await customStatement('PRAGMA journal_mode = WAL');
      } on Object {
        // In-memory databases keep the default journal mode.
      }
      await _installImmutabilityTriggers();
    },
  );

  Future<void> _installImmutabilityTriggers() async {
    await customStatement('''
CREATE TRIGGER IF NOT EXISTS refrigeration_logs_no_update
BEFORE UPDATE ON refrigeration_logs
BEGIN
  SELECT RAISE(ABORT, 'refrigeration_logs are immutable');
END
''');
    await customStatement('''
CREATE TRIGGER IF NOT EXISTS refrigeration_logs_no_delete
BEFORE DELETE ON refrigeration_logs
BEGIN
  SELECT RAISE(ABORT, 'refrigeration_logs are immutable');
END
''');
    await customStatement('''
CREATE INDEX IF NOT EXISTS idx_refrigeration_logs_movement
ON refrigeration_logs (movement_id)
''');
    await customStatement('''
CREATE INDEX IF NOT EXISTS idx_sync_outbox_status
ON sync_outbox (status, created_at)
''');
  }

  Future<void> _seed() async {
    final createdAt = DateTime.utc(2026, 1, 1);
    await batch((batch) {
      batch.insertAll(fridges, [
        FridgesCompanion.insert(
          id: SeedIds.kitchenFridge,
          name: 'Kitchen fridge',
          minCelsius: 0,
          maxCelsius: 5,
        ),
        FridgesCompanion.insert(
          id: SeedIds.pharmacyFridge,
          name: 'Pharmacy fridge',
          minCelsius: 2,
          maxCelsius: 8,
        ),
        FridgesCompanion.insert(
          id: SeedIds.freezer,
          name: 'Freezer',
          minCelsius: -25,
          maxCelsius: -18,
        ),
      ]);
      batch.insertAll(products, [
        ProductsCompanion.insert(
          id: SeedIds.wholeMilk,
          name: 'Whole milk',
          sku: const Value('MILK'),
          createdAt: createdAt,
        ),
        ProductsCompanion.insert(
          id: SeedIds.chickenBreast,
          name: 'Chicken breast',
          sku: const Value('CHKN'),
          createdAt: createdAt,
        ),
        ProductsCompanion.insert(
          id: SeedIds.insulin,
          name: 'Insulin',
          sku: const Value('INSL'),
          createdAt: createdAt,
        ),
        ProductsCompanion.insert(
          id: SeedIds.vaccine,
          name: 'Vaccine',
          sku: const Value('VACC'),
          createdAt: createdAt,
        ),
      ]);
    });
  }
}
