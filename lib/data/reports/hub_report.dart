import 'package:drift/drift.dart';
import 'package:mailer/mailer.dart' as mail;
import 'package:mailer/smtp_server.dart';

import '../../domain/reports/daily_report.dart';
import '../../domain/settings/device_settings.dart';
import '../db/app_database.dart';
import '../sync/sync_gateway.dart';

/// Stores one daily report on this tablet and emails it when mail is set up.
Future<ReportPostResult> acceptOwnerReport({
  required AppDatabase db,
  required DeviceSettings settings,
  required ReportPost report,
  Future<bool> Function()? send,
}) async {
  final existing =
      await (db.select(db.dailyReports)..where(
            (table) =>
                table.environmentName.equals(report.environment) &
                table.reportDate.equals(report.reportDate),
          ))
          .getSingleOrNull();
  if (existing != null &&
      (existing.status == ReportStatus.sent ||
          existing.status == ReportStatus.alreadySent)) {
    return const ReportPostResult(status: ReportStatus.alreadySent);
  }

  if (existing == null) {
    await db
        .into(db.dailyReports)
        .insert(
          DailyReportsCompanion.insert(
            id: report.id,
            environmentName: report.environment,
            reportDate: report.reportDate,
            ownerEmail: report.ownerEmail,
            subject: report.subject,
            body: report.body,
            status: ReportStatus.waiting,
            createdAt: DateTime.now().toUtc(),
          ),
        );
  } else {
    await (db.update(
      db.dailyReports,
    )..where((table) => table.id.equals(existing.id))).write(
      DailyReportsCompanion(
        ownerEmail: Value(report.ownerEmail),
        subject: Value(report.subject),
        body: Value(report.body),
        status: const Value(ReportStatus.waiting),
        lastError: const Value(null),
      ),
    );
  }

  try {
    final emailed = await (send ?? () => sendHubEmail(settings, report))();
    final status = emailed ? ReportStatus.sent : ReportStatus.stored;
    await (db.update(db.dailyReports)..where(
          (table) =>
              table.environmentName.equals(report.environment) &
              table.reportDate.equals(report.reportDate),
        ))
        .write(
          DailyReportsCompanion(
            status: Value(status),
            lastError: const Value(null),
          ),
        );
    return ReportPostResult(status: status);
  } on Object catch (error) {
    await (db.update(db.dailyReports)..where(
          (table) =>
              table.environmentName.equals(report.environment) &
              table.reportDate.equals(report.reportDate),
        ))
        .write(
          DailyReportsCompanion(
            status: const Value(ReportStatus.failed),
            lastError: Value(error.toString()),
          ),
        );
    return ReportPostResult(
      status: ReportStatus.failed,
      error: error.toString(),
    );
  }
}

Future<bool> sendHubEmail(DeviceSettings settings, ReportPost report) async {
  final host = settings.smtpHost.trim();
  final from = settings.smtpFrom.trim();
  if (host.isEmpty || from.isEmpty) {
    return false;
  }
  final user = settings.smtpUser.trim();
  final password = settings.smtpPassword;
  final smtp = SmtpServer(
    host,
    port: settings.smtpPort,
    username: user.isEmpty ? null : user,
    password: password.isEmpty ? null : password,
    ssl: settings.smtpPort == 465,
  );
  final message = mail.Message()
    ..from = mail.Address(from)
    ..recipients.add(report.ownerEmail)
    ..subject = report.subject
    ..text = report.body;
  await mail.send(message, smtp);
  return true;
}
