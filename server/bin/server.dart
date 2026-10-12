import 'dart:async';
import 'dart:io';

import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:sqlite3/sqlite3.dart';
import 'package:uuid/uuid.dart';

import 'package:cooling_down_server/handler.dart';
import 'package:cooling_down_server/mailer.dart';
import 'package:cooling_down_server/sync_store.dart';

Future<void> main() async {
  final port = int.tryParse(Platform.environment['PORT'] ?? '') ?? 8080;
  final dataPath =
      Platform.environment['DATA_PATH'] ?? 'cooling_down_server.sqlite';
  final token = await _loadToken();
  final ownerEmail = Platform.environment['OWNER_EMAIL']?.trim() ?? '';
  final database = sqlite3.open(dataPath);
  final store = SyncStore(
    database,
    mailer: const EnvReportMailer(),
    ownerEmail: ownerEmail,
  );
  final server = await shelf_io.serve(
    buildHandler(store: store, token: token),
    InternetAddress.anyIPv4,
    port,
  );
  stdout.writeln(
    'Cooling down server on http://${server.address.host}:${server.port}',
  );
  final smtpHost = Platform.environment['SMTP_HOST'];
  if (smtpHost == null || smtpHost.isEmpty) {
    stdout.writeln(
      'Email is off. Set SMTP_HOST, SMTP_PORT, SMTP_USER, SMTP_PASSWORD, and SMTP_FROM to send reports.',
    );
  } else {
    stdout.writeln('Email is on via $smtpHost.');
  }
  if (ownerEmail.contains('@')) {
    stdout.writeln('Midnight reports go to $ownerEmail.');
  } else {
    stdout.writeln(
      'Set OWNER_EMAIL to the address that receives the midnight report.',
    );
  }
  stdout.writeln('A daily report is emailed at 00:00 for the day that just ended.');
  unawaited(store.sendClosedDay(DateTime.now()));
  Timer.periodic(const Duration(minutes: 1), (_) {
    unawaited(store.sendClosedDay(DateTime.now()));
  });
}

Future<String> _loadToken() async {
  final fromEnv = Platform.environment['SYNC_TOKEN'];
  if (fromEnv != null && fromEnv.trim().isNotEmpty) {
    stdout.writeln('Using the access token from SYNC_TOKEN.');
    return fromEnv.trim();
  }
  final file = File('sync_token.txt');
  if (file.existsSync()) {
    final existing = file.readAsStringSync().trim();
    if (existing.isNotEmpty) {
      stdout.writeln('Using the access token in sync_token.txt.');
      return existing;
    }
  }
  final created = const Uuid().v4();
  file.writeAsStringSync('$created\n');
  stdout.writeln('Wrote a new access token to sync_token.txt');
  stdout.writeln(created);
  return created;
}
