/// Tablet-local preferences. They are not uploaded with the audit log.
class DeviceSettings {
  const DeviceSettings({
    required this.deviceId,
    required this.deviceName,
    required this.environmentName,
    required this.serverUrl,
    required this.serverToken,
    required this.ownerEmail,
    required this.dailyReportEnabled,
    required this.reportHour,
    required this.reportMinute,
    required this.syncCursor,
    this.lastSyncAt,
    this.lastSyncError,
  });

  final String deviceId;
  final String deviceName;
  final String environmentName;
  final String serverUrl;
  final String serverToken;
  final String ownerEmail;
  final bool dailyReportEnabled;
  final int reportHour;
  final int reportMinute;
  final int syncCursor;
  final DateTime? lastSyncAt;
  final String? lastSyncError;

  bool get hasServer => serverUrl.trim().isNotEmpty;

  DeviceSettings copyWith({
    String? deviceName,
    String? environmentName,
    String? serverUrl,
    String? serverToken,
    String? ownerEmail,
    bool? dailyReportEnabled,
    int? reportHour,
    int? reportMinute,
    int? syncCursor,
    DateTime? lastSyncAt,
    String? lastSyncError,
    bool clearLastSyncAt = false,
    bool clearLastSyncError = false,
  }) {
    return DeviceSettings(
      deviceId: deviceId,
      deviceName: deviceName ?? this.deviceName,
      environmentName: environmentName ?? this.environmentName,
      serverUrl: serverUrl ?? this.serverUrl,
      serverToken: serverToken ?? this.serverToken,
      ownerEmail: ownerEmail ?? this.ownerEmail,
      dailyReportEnabled: dailyReportEnabled ?? this.dailyReportEnabled,
      reportHour: reportHour ?? this.reportHour,
      reportMinute: reportMinute ?? this.reportMinute,
      syncCursor: syncCursor ?? this.syncCursor,
      lastSyncAt: clearLastSyncAt ? null : lastSyncAt ?? this.lastSyncAt,
      lastSyncError: clearLastSyncError
          ? null
          : lastSyncError ?? this.lastSyncError,
    );
  }
}
