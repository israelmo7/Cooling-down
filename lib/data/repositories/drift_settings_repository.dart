import 'package:drift/drift.dart';

import '../../domain/repositories/settings_repository.dart';
import '../../domain/settings/device_settings.dart';
import '../db/app_database.dart';
import '../db/ensure_settings.dart';
import '../sync/server_url.dart';

class DriftSettingsRepository implements SettingsRepository {
  DriftSettingsRepository(this._db);

  final AppDatabase _db;

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
    await (_db.update(
      _db.localSettings,
    )..where((table) => table.id.equals(localSettingsId))).write(
      LocalSettingsCompanion(
        deviceName: Value(deviceName.isEmpty ? 'This tablet' : deviceName),
        environmentName: Value(environment.isEmpty ? 'Kitchen' : environment),
        serverUrl: Value(serverUrl),
        serverToken: Value(settings.serverToken.trim()),
        ownerEmail: Value(settings.ownerEmail.trim()),
        dailyReportEnabled: Value(settings.dailyReportEnabled),
        reportHour: Value(settings.reportHour.clamp(0, 23).toInt()),
        reportMinute: Value(settings.reportMinute.clamp(0, 59).toInt()),
        syncCursor: serverUrl == previous.serverUrl
            ? const Value.absent()
            : const Value(0),
        hubEnabled: Value(settings.hubEnabled),
        smtpHost: Value(settings.smtpHost.trim()),
        smtpPort: Value(settings.smtpPort.clamp(1, 65535).toInt()),
        smtpUser: Value(settings.smtpUser.trim()),
        smtpPassword: Value(settings.smtpPassword),
        smtpFrom: Value(settings.smtpFrom.trim()),
      ),
    );
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
      hubEnabled: row.hubEnabled,
      smtpHost: row.smtpHost,
      smtpPort: row.smtpPort,
      smtpUser: row.smtpUser,
      smtpPassword: row.smtpPassword,
      smtpFrom: row.smtpFrom,
    );
  }
}
