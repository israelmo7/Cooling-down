import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/clock.dart';
import '../data/db/app_database.dart';
import '../data/repositories/drift_alert_repository.dart';
import '../data/repositories/drift_log_repository.dart';
import '../data/repositories/drift_product_repository.dart';
import '../data/repositories/drift_sync_repository.dart';
import '../data/sync/offline_sync_gateway.dart';
import '../data/sync/sync_gateway.dart';
import '../domain/entities/alert.dart';
import '../domain/entities/fridge.dart';
import '../domain/entities/open_holding.dart';
import '../domain/entities/product.dart';
import '../domain/repositories/alert_repository.dart';
import '../domain/repositories/log_repository.dart';
import '../domain/repositories/product_repository.dart';
import '../domain/repositories/sync_repository.dart';

final clockProvider = Provider<Clock>((ref) => const Clock());

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final database = AppDatabase();
  ref.onDispose(database.close);
  return database;
});

final syncGatewayProvider = Provider<SyncGateway>(
  (ref) => const OfflineSyncGateway(),
);

final productRepositoryProvider = Provider<ProductRepository>((ref) {
  return DriftProductRepository(ref.watch(appDatabaseProvider));
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
    gateway: ref.watch(syncGatewayProvider),
  );
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
