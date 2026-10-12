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
    this.hubEnabled = false,
    this.smtpHost = '',
    this.smtpPort = 587,
    this.smtpUser = '',
    this.smtpPassword = '',
    this.smtpFrom = '',
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
  final bool hubEnabled;
  final String smtpHost;
  final int smtpPort;
  final String smtpUser;
  final String smtpPassword;
  final String smtpFrom;

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
    bool? hubEnabled,
    String? smtpHost,
    int? smtpPort,
    String? smtpUser,
    String? smtpPassword,
    String? smtpFrom,
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
      hubEnabled: hubEnabled ?? this.hubEnabled,
      smtpHost: smtpHost ?? this.smtpHost,
      smtpPort: smtpPort ?? this.smtpPort,
      smtpUser: smtpUser ?? this.smtpUser,
      smtpPassword: smtpPassword ?? this.smtpPassword,
      smtpFrom: smtpFrom ?? this.smtpFrom,
    );
  }
}
