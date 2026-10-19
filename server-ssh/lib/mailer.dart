import 'package:mailer/mailer.dart' as mail;
import 'package:mailer/smtp_server.dart';

/// Sends the owner report. Returns false when SMTP is not configured.
abstract class ReportMailer {
  const ReportMailer();

  Future<bool> send({
    required String to,
    required String subject,
    required String body,
    String? html,
  });
}

class DisabledMailer implements ReportMailer {
  const DisabledMailer();

  @override
  Future<bool> send({
    required String to,
    required String subject,
    required String body,
    String? html,
  }) async {
    return false;
  }
}

/// Mail values the admin page can change. The server keeps them in `.env`.
class MailSettings {
  MailSettings({
    this.ownerEmail = '',
    this.smtpHost = '',
    this.smtpPort = 587,
    this.smtpUser = '',
    this.smtpPassword = '',
    this.smtpFrom = '',
  });

  String ownerEmail;
  String smtpHost;
  int smtpPort;
  String smtpUser;
  String smtpPassword;
  String smtpFrom;

  bool get emailEnabled => smtpHost.trim().isNotEmpty;

  void replaceWith(MailSettings other) {
    ownerEmail = other.ownerEmail;
    smtpHost = other.smtpHost;
    smtpPort = other.smtpPort;
    smtpUser = other.smtpUser;
    smtpPassword = other.smtpPassword;
    smtpFrom = other.smtpFrom;
  }

  Map<String, String> toEnv() {
    return {
      'OWNER_EMAIL': ownerEmail,
      'SMTP_HOST': smtpHost,
      'SMTP_PORT': '$smtpPort',
      'SMTP_USER': smtpUser,
      'SMTP_PASSWORD': smtpPassword,
      'SMTP_FROM': smtpFrom,
    };
  }
}

class EnvReportMailer implements ReportMailer {
  const EnvReportMailer(this.settings);

  final MailSettings settings;

  @override
  Future<bool> send({
    required String to,
    required String subject,
    required String body,
    String? html,
  }) async {
    final host = settings.smtpHost.trim();
    if (host.isEmpty) {
      return false;
    }
    final port = settings.smtpPort;
    final username = settings.smtpUser;
    final password = settings.smtpPassword;
    final from = settings.smtpFrom.trim();
    if (from.isEmpty) {
      throw StateError('Set SMTP_FROM to the address reports are sent from.');
    }
    final smtp = SmtpServer(
      host,
      port: port,
      username: username.isEmpty ? null : username,
      password: password.isEmpty ? null : password,
      ssl: port == 465,
    );
    final message = mail.Message()
      ..from = mail.Address(from)
      ..recipients.add(to)
      ..subject = subject
      ..text = body;
    final markup = html?.trim() ?? '';
    if (markup.isNotEmpty) {
      message.html = markup;
    }
    await mail.send(message, smtp);
    return true;
  }
}
