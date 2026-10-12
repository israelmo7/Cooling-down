import 'dart:async';
import 'dart:io';

import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:sqlite3/sqlite3.dart';
import 'package:uuid/uuid.dart';

import 'package:cooling_down_server/env_file.dart';
import 'package:cooling_down_server/handler.dart';
import 'package:cooling_down_server/mailer.dart';
import 'package:cooling_down_server/server_config.dart';
import 'package:cooling_down_server/sync_store.dart';

Future<void> main() async {
  final envFile = resolveEnvFile();
  final config = ServerConfig.fromMaps(
    file: loadEnvFile(envFile),
    platform: Platform.environment,
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
    ),
    InternetAddress.anyIPv4,
    config.port,
  );
  stdout.writeln(
    'Cooling down server on http://${server.address.host}:${server.port}',
  );
  stdout.writeln('Settings file: ${envFile.path}');
  if (!config.mail.emailEnabled) {
    stdout.writeln('Email is off. Set the mail fields in .env or on /admin.');
  } else {
    stdout.writeln('Email is on via ${config.mail.smtpHost}.');
  }
  if (config.mail.ownerEmail.contains('@')) {
    stdout.writeln('Midnight reports go to ${config.mail.ownerEmail}.');
  } else {
    stdout.writeln('Set the owner email in .env or on /admin.');
  }
  if (config.adminUser.isEmpty || config.adminPassword.isEmpty) {
    stdout.writeln(
      'Admin page is off. Set ADMIN_USER and ADMIN_PASSWORD in .env.',
    );
  } else {
    stdout.writeln('Admin page is /admin for ${config.adminUser}.');
  }
  stdout.writeln(
    'A daily report is emailed at 00:00 for the day that just ended.',
  );
  unawaited(store.sendClosedDay(DateTime.now()));
  Timer.periodic(const Duration(minutes: 1), (_) {
    unawaited(store.sendClosedDay(DateTime.now()));
  });
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
  stdout.writeln('Wrote a new access token to ${envFile.path}');
  stdout.writeln(created);
  return created;
}
