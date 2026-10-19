import 'mailer.dart';
import 'report_time.dart';

/// Clock and report choice the admin page can change. The report time is used
/// the next time the alarm is set. The time zone applies on the next start.
class ShopSchedule {
  ShopSchedule({
    this.timeZone = 'Asia/Jerusalem',
    this.reportTime = ReportTime.midnight,
    this.reportFormat = 'builtin',
  });

  String timeZone;
  ReportTime reportTime;
  String reportFormat;

  void replaceClock({
    required String timeZone,
    required ReportTime reportTime,
  }) {
    this.timeZone = timeZone;
    this.reportTime = reportTime;
  }

  void replaceFormat(String format) {
    reportFormat = normalizeReportFormat(format);
  }
}

/// Values from `.env`, with a non-empty process variable taking precedence.
class ServerConfig {
  ServerConfig({
    required this.port,
    required this.dataPath,
    required this.syncToken,
    required this.adminUser,
    required this.adminPassword,
    required this.mail,
  });

  factory ServerConfig.fromMaps({
    required Map<String, String> file,
    required Map<String, String> platform,
  }) {
    String value(String key, [String fallback = '']) {
      final fromPlatform = platform[key];
      if (fromPlatform != null && fromPlatform.isNotEmpty) {
        return fromPlatform;
      }
      return file[key] ?? fallback;
    }

    return ServerConfig(
      port: int.tryParse(value('PORT')) ?? 8080,
      dataPath: value('DATA_PATH', 'cooling_down_server.sqlite'),
      syncToken: value('SYNC_TOKEN').trim(),
      adminUser: value('ADMIN_USER').trim(),
      adminPassword: value('ADMIN_PASSWORD'),
      mail: MailSettings(
        ownerEmail: value('OWNER_EMAIL').trim(),
        smtpHost: value('SMTP_HOST').trim(),
        smtpPort: int.tryParse(value('SMTP_PORT')) ?? 587,
        smtpUser: value('SMTP_USER'),
        smtpPassword: value('SMTP_PASSWORD'),
        smtpFrom: value('SMTP_FROM').trim(),
      ),
    );
  }

  final int port;
  final String dataPath;
  final String syncToken;
  final String adminUser;
  final String adminPassword;
  final MailSettings mail;
}
