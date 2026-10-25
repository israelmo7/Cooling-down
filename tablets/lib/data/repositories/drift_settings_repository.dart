import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../domain/repositories/settings_repository.dart';
import '../../domain/settings/device_settings.dart';
import '../../domain/workers/worker_refresh.dart';
import '../db/app_database.dart';
import '../db/converters.dart';
import '../db/ensure_settings.dart';
import '../db/seed_ids.dart';
import '../sync/enqueue.dart';
import '../sync/server_url.dart';

class DriftSettingsRepository implements SettingsRepository {
  DriftSettingsRepository(this._db, {Uuid? uuid}) : _uuid = uuid ?? const Uuid();

  final AppDatabase _db;
  final Uuid _uuid;

  @override
  Stream<DeviceSettings?> watch() {
    final query = _db.select(_db.localSettings)
      ..where((table) => table.id.equals(localSettingsId));
    return query.watch().map((rows) {
      if (rows.isEmpty) {
        return null;
      }
      return _map(rows.single);
    });
  }

  @override
  Future<DeviceSettings> ensure() async {
    return _map(await ensureLocalSettingsRow(_db));
  }

  @override
  Future<void> save(DeviceSettings settings) async {
    final previous = await ensure();
    final environment = settings.environmentName.trim();
    final deviceName = settings.deviceName.trim();
    final serverUrl = normalizeServerUrl(settings.serverUrl);
    final serverToken = settings.serverToken.trim();
    final shopChanged =
        serverUrl != previous.serverUrl ||
        serverToken != previous.serverToken.trim();
    if (shopChanged) {
      final pending = await (_db.selectOnly(_db.syncOutbox)
            ..addColumns([_db.syncOutbox.id.count()])
            ..where(
              _db.syncOutbox.status.equalsValue(SyncStatus.pending) |
                  _db.syncOutbox.status.equalsValue(SyncStatus.inFlight),
            ))
          .getSingle();
      final waiting = pending.read(_db.syncOutbox.id.count()) ?? 0;
      if (waiting > 0) {
        throw FormatException(
          'יש $waiting ממתינים לסנכרון. סנכרנו לפני שינוי כתובת או אסימון.',
        );
      }
    }
    await (_db.update(
      _db.localSettings,
    )..where((table) => table.id.equals(localSettingsId))).write(
      LocalSettingsCompanion(
        deviceName: Value(deviceName.isEmpty ? 'This tablet' : deviceName),
        environmentName: Value(clipEnvironmentName(environment)),
        serverUrl: Value(serverUrl),
        serverToken: Value(serverToken),
        ownerEmail: Value(settings.ownerEmail.trim()),
        dailyReportEnabled: Value(settings.dailyReportEnabled),
        reportHour: Value(settings.reportHour.clamp(0, 23).toInt()),
        reportMinute: Value(settings.reportMinute.clamp(0, 59).toInt()),
        syncCursor: shopChanged ? const Value(0) : const Value.absent(),
        confirmAction: Value(settings.confirmAction),
        workerIdleSeconds: Value(
          settings.workerIdleSeconds < 1
              ? defaultWorkerIdleSeconds
              : settings.workerIdleSeconds,
        ),
        workerRefreshMode: Value(settings.workerRefreshMode.name),
        workerPromptStyle: Value(settings.workerPromptStyle.name),
        workerRefreshStartMinute: Value(
          settings.workerRefreshStartMinute.clamp(0, 23 * 60 + 59).toInt(),
        ),
        workerRefreshIntervalHours: Value(
          settings.workerRefreshIntervalHours.clamp(1, 24).toInt(),
        ),
        workerRefreshEndMinute: Value(
          settings.workerRefreshEndMinute.clamp(0, 23 * 60 + 59).toInt(),
        ),
        settingsPassword: Value(settings.settingsPassword.trim()),
        receivingPackageId: Value(settings.receivingPackageId.trim()),
        showQuantity: Value(settings.showQuantity),
      ),
    );
    await _nameEnvironmentFridge(clipEnvironmentName(environment));
  }

  @override
  Future<String> startReceivingPackage() async {
    final current = await ensure();
    final existing = current.receivingPackageId.trim();
    if (existing.isNotEmpty) {
      return existing;
    }
    final id = _uuid.v4();
    final openedAt = DateTime.now().toUtc();
    await enqueueInsert(
      _db,
      entityType: 'receiving_package',
      entityId: id,
      payload: {
        'id': id,
        'session_id': id,
        'status': 'open',
        'opened_at': openedAt.toIso8601String(),
        'environment': current.environmentName,
        'device_id': current.deviceId,
      },
      createdAt: openedAt,
    );
    await (_db.update(
      _db.localSettings,
    )..where((table) => table.id.equals(localSettingsId))).write(
      LocalSettingsCompanion(receivingPackageId: Value(id)),
    );
    return id;
  }

  @override
  Future<String?> endReceivingPackage() async {
    final current = await ensure();
    final id = current.receivingPackageId.trim();
    if (id.isEmpty) {
      return null;
    }
    final closedAt = DateTime.now().toUtc();
    final closeId = '$id:closed';
    await enqueueInsert(
      _db,
      entityType: 'receiving_package',
      entityId: closeId,
      payload: {
        'id': closeId,
        'session_id': id,
        'status': 'closed',
        'closed_at': closedAt.toIso8601String(),
        'environment': current.environmentName,
        'device_id': current.deviceId,
      },
      createdAt: closedAt,
    );
    await (_db.update(
      _db.localSettings,
    )..where((table) => table.id.equals(localSettingsId))).write(
      const LocalSettingsCompanion(receivingPackageId: Value('')),
    );
    return id;
  }

  Future<void> _nameEnvironmentFridge(String name) async {
    final existing =
        await (_db.select(_db.fridges)
              ..where((table) => table.id.equals(SeedIds.kitchenFridge)))
            .getSingleOrNull();
    if (existing == null) {
      await _db
          .into(_db.fridges)
          .insert(
            FridgesCompanion.insert(
              id: SeedIds.kitchenFridge,
              name: name,
              minCelsius: 0,
              maxCelsius: 5,
            ),
          );
      return;
    }
    await (_db.update(_db.fridges)
          ..where((table) => table.id.equals(SeedIds.kitchenFridge)))
        .write(FridgesCompanion(name: Value(name)));
  }

  @override
  Future<void> recordSync({
    int? cursor,
    DateTime? at,
    String? error,
    bool clearError = false,
  }) async {
    await ensure();
    await (_db.update(
      _db.localSettings,
    )..where((table) => table.id.equals(localSettingsId))).write(
      LocalSettingsCompanion(
        syncCursor: cursor == null ? const Value.absent() : Value(cursor),
        lastSyncAt: at == null ? const Value.absent() : Value(at),
        lastSyncError: clearError
            ? const Value(null)
            : error == null
            ? const Value.absent()
            : Value(error),
      ),
    );
  }

  DeviceSettings _map(LocalSettingsRow row) {
    return DeviceSettings(
      deviceId: row.deviceId,
      deviceName: row.deviceName,
      environmentName: row.environmentName,
      serverUrl: row.serverUrl,
      serverToken: row.serverToken,
      ownerEmail: row.ownerEmail,
      dailyReportEnabled: row.dailyReportEnabled,
      reportHour: row.reportHour,
      reportMinute: row.reportMinute,
      syncCursor: row.syncCursor,
      lastSyncAt: row.lastSyncAt,
      lastSyncError: row.lastSyncError,
      confirmAction: row.confirmAction,
      workerIdleSeconds: row.workerIdleSeconds,
      workerRefreshMode: WorkerRefreshMode.parse(row.workerRefreshMode),
      workerPromptStyle: WorkerPromptStyle.parse(row.workerPromptStyle),
      workerRefreshStartMinute: row.workerRefreshStartMinute,
      workerRefreshIntervalHours: row.workerRefreshIntervalHours,
      workerRefreshEndMinute: row.workerRefreshEndMinute,
      settingsPassword: row.settingsPassword,
      receivingPackageId: row.receivingPackageId,
      showQuantity: row.showQuantity,
    );
  }
}
