import '../settings/device_settings.dart';

/// Tablet-local name, server, and report schedule.
abstract class SettingsRepository {
  Stream<DeviceSettings?> watch();

  Future<DeviceSettings> ensure();

  Future<void> save(DeviceSettings settings);

  /// Opens supplier receiving on this tablet. Returns the new package id.
  Future<String> startReceivingPackage();

  /// Closes receiving on this tablet and queues a close event for the server.
  /// Returns the closed package id, or null when none was open.
  Future<String?> endReceivingPackage();

  Future<void> recordSync({
    int? cursor,
    DateTime? at,
    String? error,
    bool clearError = false,
  });
}
