import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:drift_flutter/drift_flutter.dart';

import '../../domain/entities/alert.dart';
import '../../domain/entities/refrigeration_log.dart';
import '../../domain/settings/device_settings.dart';
import 'converters.dart';
import 'seed_ids.dart';
import 'tables.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    Products,
    Fridges,
    Workers,
    RefrigerationLogs,
    Alerts,
    SyncOutbox,
    LocalSettings,
    DailyReports,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(driftDatabase(name: 'cooling_down'));

  AppDatabase.memory() : super(NativeDatabase.memory());

  @override
  int get schemaVersion => 12;

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
      if (from < 4) {
        await customStatement('''
UPDATE local_settings
SET daily_report_enabled = 1, report_hour = 0, report_minute = 0
''');
      }
      if (from < 5) {
        await migrator.addColumn(localSettings, localSettings.confirmAction);
      }
      if (from < 6) {
        await migrator.addColumn(products, products.listed);
      }
      if (from < 7) {
        await migrator.createTable(workers);
        await migrator.addColumn(
          refrigerationLogs,
          refrigerationLogs.workerNameSnapshot,
        );
        await migrator.addColumn(localSettings, localSettings.currentWorkerId);
        await migrator.addColumn(localSettings, localSettings.workerActiveAt);
      }
      if (from < 8) {
        await migrator.addColumn(
          localSettings,
          localSettings.workerIdleSeconds,
        );
      }
      if (from < 9) {
        await migrator.addColumn(
          localSettings,
          localSettings.workerRefreshMode,
        );
        await migrator.addColumn(
          localSettings,
          localSettings.workerPromptStyle,
        );
        await migrator.addColumn(
          localSettings,
          localSettings.workerRefreshStartMinute,
        );
        await migrator.addColumn(
          localSettings,
          localSettings.workerRefreshIntervalHours,
        );
        await migrator.addColumn(
          localSettings,
          localSettings.workerRefreshEndMinute,
        );
      }
      if (from < 10) {
        await migrator.addColumn(localSettings, localSettings.settingsPassword);
      }
      if (from < 12) {
        await _keepOneEnvironmentFridge();
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
      await _useHebrewCatalogNames();
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

  Future<void> _useHebrewCatalogNames() async {
    const names = <String, String>{
      SeedIds.wholeMilk: 'חלב',
      SeedIds.chickenBreast: 'חזה עוף',
      SeedIds.insulin: 'אינסולין',
      SeedIds.vaccine: 'חיסון',
    };
    for (final entry in names.entries) {
      await customStatement(
        'UPDATE products SET name = ? WHERE id = ? AND name != ?',
        [entry.value, entry.key, entry.value],
      );
    }
  }

  /// One fridge, named like the environment. Extra seeded fridges stay only
  /// when a log already points at them.
  Future<void> _keepOneEnvironmentFridge() async {
    final rows = await customSelect(
      'SELECT environment_name FROM local_settings WHERE id = ? LIMIT 1',
      variables: [Variable.withString('local')],
    ).get();
    final stored = rows.isEmpty
        ? ''
        : rows.first.read<String>('environment_name');
    final name = clipEnvironmentName(stored);
    final kitchen = await customSelect(
      'SELECT id FROM fridges WHERE id = ?',
      variables: [Variable.withString(SeedIds.kitchenFridge)],
    ).get();
    if (kitchen.isEmpty) {
      await customStatement(
        '''
INSERT INTO fridges (id, name, min_celsius, max_celsius)
VALUES (?, ?, 0, 5)
''',
        [SeedIds.kitchenFridge, name],
      );
    } else {
      await customStatement('UPDATE fridges SET name = ? WHERE id = ?', [
        name,
        SeedIds.kitchenFridge,
      ]);
    }
    await customStatement(
      '''
DELETE FROM fridges
WHERE id IN (?, ?)
  AND NOT EXISTS (
    SELECT 1 FROM refrigeration_logs WHERE fridge_id = fridges.id
  )
''',
      [SeedIds.pharmacyFridge, SeedIds.freezer],
    );
  }

  Future<void> _seed() async {
    final createdAt = DateTime.utc(2026, 1, 1);
    await batch((batch) {
      batch.insertAll(fridges, [
        FridgesCompanion.insert(
          id: SeedIds.kitchenFridge,
          name: 'מטבח',
          minCelsius: 0,
          maxCelsius: 5,
        ),
      ]);
      batch.insertAll(products, [
        ProductsCompanion.insert(
          id: SeedIds.wholeMilk,
          name: 'חלב',
          sku: const Value('MILK'),
          createdAt: createdAt,
        ),
        ProductsCompanion.insert(
          id: SeedIds.chickenBreast,
          name: 'חזה עוף',
          sku: const Value('CHKN'),
          createdAt: createdAt,
        ),
        ProductsCompanion.insert(
          id: SeedIds.insulin,
          name: 'אינסולין',
          sku: const Value('INSL'),
          createdAt: createdAt,
        ),
        ProductsCompanion.insert(
          id: SeedIds.vaccine,
          name: 'חיסון',
          sku: const Value('VACC'),
          createdAt: createdAt,
        ),
      ]);
    });
  }
}
