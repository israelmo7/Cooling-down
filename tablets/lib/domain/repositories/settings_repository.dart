import '../settings/device_settings.dart';

/// Tablet-local name, server, and report schedule.
abstract class SettingsRepository {
  Stream<DeviceSettings?> watch();

  Future<DeviceSettings> ensure();

  Future<void> save(DeviceSettings settings);

  Future<void> recordSync({
    int? cursor,
    DateTime? at,
    String? error,
    bool clearError = false,
  });
}
