import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../core/clock.dart';
import '../data/db/app_database.dart';
import '../data/maintenance/tablet_maintenance.dart';
import '../data/reports/daily_report_service.dart';
import '../data/repositories/drift_alert_repository.dart';
import '../data/repositories/drift_log_repository.dart';
import '../data/repositories/drift_product_repository.dart';
import '../data/repositories/drift_settings_repository.dart';
import '../data/repositories/drift_sync_repository.dart';
import '../data/repositories/drift_worker_repository.dart';
import '../data/sync/gateway_factory.dart';
import '../data/sync/sync_gateway.dart';
import '../domain/entities/alert.dart';
import '../domain/entities/fridge.dart';
import '../domain/entities/open_holding.dart';
import '../domain/entities/product.dart';
import '../domain/entities/worker.dart';
import '../domain/workers/worker_session.dart';
import '../domain/reports/daily_report.dart';
import '../domain/repositories/alert_repository.dart';
import '../domain/repositories/log_repository.dart';
import '../domain/repositories/product_repository.dart';
import '../domain/repositories/settings_repository.dart';
import '../domain/repositories/sync_repository.dart';
import '../domain/repositories/worker_repository.dart';
import '../domain/settings/device_settings.dart';

final clockProvider = Provider<Clock>((ref) => const Clock());

final httpClientProvider = Provider<http.Client>((ref) {
  final client = http.Client();
  ref.onDispose(client.close);
  return client;
});

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final database = AppDatabase();
  ref.onDispose(database.close);
  return database;
});

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return DriftSettingsRepository(ref.watch(appDatabaseProvider));
});

final syncGatewayFactoryProvider =
    Provider<SyncGateway Function(DeviceSettings)>((ref) {
      final client = ref.watch(httpClientProvider);
      return (settings) => gatewayForSettings(settings, client: client);
    });

final productRepositoryProvider = Provider<ProductRepository>((ref) {
  return DriftProductRepository(ref.watch(appDatabaseProvider));
});

final workerRepositoryProvider = Provider<WorkerRepository>((ref) {
  return DriftWorkerRepository(ref.watch(appDatabaseProvider));
});

final logRepositoryProvider = Provider<LogRepository>((ref) {
  return DriftLogRepository(
    ref.watch(appDatabaseProvider),
    clock: ref.watch(clockProvider),
  );
});

final alertRepositoryProvider = Provider<AlertRepository>((ref) {
  return DriftAlertRepository(ref.watch(appDatabaseProvider));
});

final syncRepositoryProvider = Provider<SyncRepository>((ref) {
  return DriftSyncRepository(
    ref.watch(appDatabaseProvider),
    settings: ref.watch(settingsRepositoryProvider),
    clock: ref.watch(clockProvider),
    gatewayFor: ref.watch(syncGatewayFactoryProvider),
  );
});

final dailyReportServiceProvider = Provider<DailyReportService>((ref) {
  return DailyReportService(
    ref.watch(appDatabaseProvider),
    settings: ref.watch(settingsRepositoryProvider),
    clock: ref.watch(clockProvider),
    gatewayFor: ref.watch(syncGatewayFactoryProvider),
  );
});

final tabletMaintenanceProvider = Provider<TabletMaintenance>((ref) {
  return TabletMaintenance(
    settings: ref.watch(settingsRepositoryProvider),
    sync: ref.watch(syncRepositoryProvider),
    reports: ref.watch(dailyReportServiceProvider),
  );
});

final settingsProvider = StreamProvider<DeviceSettings?>((ref) {
  return ref.watch(settingsRepositoryProvider).watch();
});

final latestReportProvider = StreamProvider<StoredDailyReport?>((ref) {
  return ref.watch(dailyReportServiceProvider).watchLatest();
});

final productCatalogProvider = StreamProvider<List<Product>>((ref) {
  return ref.watch(productRepositoryProvider).watchAll();
});

final workersProvider = StreamProvider<List<Worker>>((ref) {
  return ref.watch(workerRepositoryProvider).watchAll();
});

final workerSessionProvider = StreamProvider<WorkerSession>((ref) {
  return ref.watch(workerRepositoryProvider).watchSession();
});

final productSearchProvider = StreamProvider.family<List<Product>, String>(
  (ref, query) => ref.watch(productRepositoryProvider).watchSearch(query),
  isAutoDispose: true,
);

final fridgesProvider = StreamProvider<List<Fridge>>((ref) {
  return ref.watch(productRepositoryProvider).watchFridges();
});

final openHoldingsProvider = StreamProvider<List<OpenHolding>>((ref) {
  return ref.watch(logRepositoryProvider).watchOpenHoldings();
});

final unacknowledgedAlertsProvider = StreamProvider<List<Alert>>((ref) {
  return ref.watch(alertRepositoryProvider).watchUnacknowledged();
});

final pendingSyncCountProvider = StreamProvider<int>((ref) {
  return ref.watch(syncRepositoryProvider).watchPendingCount();
});
