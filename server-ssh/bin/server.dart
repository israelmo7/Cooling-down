import 'dart:async';
import 'dart:io';

import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:sqlite3/sqlite3.dart';
import 'package:uuid/uuid.dart';

import 'package:cooling_down_server/env_file.dart';
import 'package:cooling_down_server/handler.dart';
import 'package:cooling_down_server/mailer.dart';
import 'package:cooling_down_server/report_time.dart';
import 'package:cooling_down_server/server_config.dart';
import 'package:cooling_down_server/sync_store.dart';

Future<void> main(List<String> args) async {
  if (args.contains('--apply-shop')) {
    _applyShop();
    return;
  }
  final envFile = resolveEnvFile();
  final fileValues = loadEnvFile(envFile);
  final config = ServerConfig.fromMaps(
    file: fileValues,
    platform: Platform.environment,
  );
  final schedule = ShopSchedule(
    timeZone: fileValues['TZ']?.trim().isNotEmpty == true
        ? fileValues['TZ']!.trim()
        : 'Asia/Jerusalem',
    reportTime: normalizeReportTime(
      fileValues['REPORT_TIME'] ?? fileValues['REPORT_HOUR'] ?? '',
    ),
    reportFormat: normalizeReportFormat(fileValues['REPORT_FORMAT'] ?? ''),
  );
  final reportFile = File(
    '${envFile.parent.path}${Platform.pathSeparator}report.txt',
  );
  final token = await _loadToken(config.syncToken, envFile);
  final database = sqlite3.open(config.dataPath);
  final store = SyncStore(
    database,
    mailer: EnvReportMailer(config.mail),
    ownerEmail: config.mail.ownerEmail,
  );
  final server = await shelf_io.serve(
    buildHandler(
      store: store,
      token: token,
      adminUser: config.adminUser,
      adminPassword: config.adminPassword,
      mail: config.mail,
      envFile: envFile,
      shopFile: File(
        '${envFile.parent.path}${Platform.pathSeparator}shop.json',
      ),
      reportFile: reportFile,
      schedule: schedule,
      onScheduleChanged: () {
        unawaited(_sendDue(store, schedule, reportFile));
        _armReport(store, schedule, reportFile);
      },
    ),
    InternetAddress.anyIPv4,
    config.port,
  );
  stdout.writeln(
    'Cooling down server on http://${server.address.host}:${server.port}',
  );
  stdout.writeln('Settings file: ${envFile.path}');
  stdout.writeln('Clock zone: ${Platform.environment['TZ'] ?? 'system'}');
  if (!config.mail.emailEnabled) {
    stdout.writeln('Email is off. Set SMTP_HOST in shop.json.');
  } else {
    stdout.writeln('Email is on via ${config.mail.smtpHost}.');
  }
  if (config.mail.ownerEmail.contains('@')) {
    stdout.writeln('Daily reports go to ${config.mail.ownerEmail}.');
  } else {
    stdout.writeln('Set the owner email in shop.json or on /admin.');
  }
  if (config.adminUser.isEmpty || config.adminPassword.isEmpty) {
    stdout.writeln(
      'Admin page is off. Set ADMIN_USER and ADMIN_PASSWORD in shop.json.',
    );
  } else {
    stdout.writeln('Admin page is /admin for ${config.adminUser}.');
  }
  stdout.writeln(
    'A daily report is emailed at ${schedule.reportTime.text} for the day that just ended.',
  );
  unawaited(_sendDue(store, schedule, reportFile));
  _armReport(store, schedule, reportFile);
}

Timer? _reportTimer;

void _armReport(SyncStore store, ShopSchedule schedule, File reportFile) {
  _reportTimer?.cancel();
  final next = schedule.reportTime.nextAfter(DateTime.now());
  _reportTimer = Timer(next.difference(DateTime.now()), () {
    unawaited(
      _sendDue(
        store,
        schedule,
        reportFile,
      ).whenComplete(() => _armReport(store, schedule, reportFile)),
    );
  });
}

Future<void> _sendDue(SyncStore store, ShopSchedule schedule, File reportFile) {
  final template = reportFile.existsSync()
      ? reportFile.readAsStringSync()
      : null;
  return store.sendClosedDay(
    DateTime.now(),
    reportTime: schedule.reportTime,
    reportFormat: schedule.reportFormat,
    template: template,
  );
}

Future<String> _loadToken(String configured, File envFile) async {
  if (configured.trim().isNotEmpty) {
    stdout.writeln('Using the access token from .env or SYNC_TOKEN.');
    return configured.trim();
  }
  final file = File('sync_token.txt');
  if (file.existsSync()) {
    final existing = file.readAsStringSync().trim();
    if (existing.isNotEmpty) {
      stdout.writeln('Using the access token in sync_token.txt.');
      writeEnvKeys(envFile, {'SYNC_TOKEN': existing});
      return existing;
    }
  }
  final created = const Uuid().v4();
  writeEnvKeys(envFile, {'SYNC_TOKEN': created});
  rememberShopToken(
    File('${envFile.parent.path}${Platform.pathSeparator}shop.json'),
    created,
  );
  stdout.writeln('Wrote a new access token to ${envFile.path}');
  stdout.writeln(created);
  return created;
}

void _applyShop() {
  final envFile = resolveEnvFile();
  final shop = File('${envFile.parent.path}${Platform.pathSeparator}shop.json');
  if (!shop.existsSync()) {
    stderr.writeln('shop.json was not found next to ${envFile.path}.');
    exit(1);
  }
  try {
    applyShopJson(shopFile: shop, envFile: envFile);
  } on FormatException catch (error) {
    stderr.writeln(error.message);
    exit(1);
  }
  final token = loadEnvFile(envFile)['SYNC_TOKEN'] ?? '';
  stdout.writeln('Applied ${shop.path} to ${envFile.path}.');
  if (token.isNotEmpty) {
    stdout.writeln('SYNC_TOKEN=$token');
  }
}
