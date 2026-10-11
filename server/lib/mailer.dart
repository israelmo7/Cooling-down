import 'dart:io';

import 'package:mailer/mailer.dart' as mail;
import 'package:mailer/smtp_server.dart';

/// Sends the owner report. Returns false when SMTP is not configured.
abstract class ReportMailer {
  const ReportMailer();

  Future<bool> send({
    required String to,
    required String subject,
    required String body,
  });
}

class DisabledMailer implements ReportMailer {
  const DisabledMailer();

  @override
  Future<bool> send({
    required String to,
    required String subject,
    required String body,
  }) async {
    return false;
  }
}

class EnvReportMailer implements ReportMailer {
  const EnvReportMailer();

  @override
  Future<bool> send({
    required String to,
    required String subject,
    required String body,
  }) async {
    final host = Platform.environment['SMTP_HOST'];
    if (host == null || host.isEmpty) {
      return false;
    }
    final port = int.tryParse(Platform.environment['SMTP_PORT'] ?? '') ?? 587;
    final username = Platform.environment['SMTP_USER'] ?? '';
    final password = Platform.environment['SMTP_PASSWORD'] ?? '';
    final from = Platform.environment['SMTP_FROM'];
    if (from == null || from.isEmpty) {
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
    await mail.send(message, smtp);
    return true;
  }
}
