/// Seconds without a tap before the next tap asks who is working.
const defaultWorkerIdleSeconds = 600;

/// A typed timeout becomes a positive number of seconds, at most one day.
int normalizeWorkerIdleSeconds(String raw) {
  final parsed = int.tryParse(raw.trim());
  if (parsed == null || parsed < 1) {
    return defaultWorkerIdleSeconds;
  }
  if (parsed > 86400) {
    return 86400;
  }
  return parsed;
}

/// Environment names shown on the tablet stay within 20 characters.
String clipEnvironmentName(String value) {
  final trimmed = value.trim();
  final name = trimmed.isEmpty ? 'מטבח' : trimmed;
  if (name.length <= 20) {
    return name;
  }
  return name.substring(0, 20);
}

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
    this.confirmAction = false,
    this.workerIdleSeconds = defaultWorkerIdleSeconds,
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
  final bool confirmAction;
  final int workerIdleSeconds;
  final String smtpHost;
  final int smtpPort;
  final String smtpUser;
  final String smtpPassword;
  final String smtpFrom;

  bool get hasServer => serverUrl.trim().isNotEmpty;

  Duration get workerIdleLimit => Duration(
    seconds: workerIdleSeconds < 1
        ? defaultWorkerIdleSeconds
        : workerIdleSeconds,
  );

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
    bool? confirmAction,
    int? workerIdleSeconds,
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
      confirmAction: confirmAction ?? this.confirmAction,
      workerIdleSeconds: workerIdleSeconds ?? this.workerIdleSeconds,
      smtpHost: smtpHost ?? this.smtpHost,
      smtpPort: smtpPort ?? this.smtpPort,
      smtpUser: smtpUser ?? this.smtpUser,
      smtpPassword: smtpPassword ?? this.smtpPassword,
      smtpFrom: smtpFrom ?? this.smtpFrom,
    );
  }
}
