import 'dart:io';

import 'package:cooling_down_server/env_file.dart';
import 'package:cooling_down_server/mailer.dart';
import 'package:cooling_down_server/server_config.dart';
import 'package:test/test.dart';

void main() {
  test('an env file keeps comments and a quoted password', () {
    final file = File(
      '${Directory.systemTemp.path}/cooling-env-${DateTime.now().microsecondsSinceEpoch}.env',
    );
    addTearDown(() {
      if (file.existsSync()) {
        file.deleteSync();
      }
    });
    file.writeAsStringSync('''
# shop computer
SYNC_TOKEN=tablet-secret
SMTP_PASSWORD="p a s s"
''');

    expect(loadEnvFile(file)['SYNC_TOKEN'], 'tablet-secret');
    expect(loadEnvFile(file)['SMTP_PASSWORD'], 'p a s s');

    writeEnvKeys(file, {
      'OWNER_EMAIL': 'owner@shop.test',
      'SMTP_PASSWORD': 'new pass',
    });

    final text = file.readAsStringSync();
    expect(text, contains('# shop computer'));
    expect(text, contains('SYNC_TOKEN=tablet-secret'));
    expect(text, contains('OWNER_EMAIL=owner@shop.test'));
    expect(loadEnvFile(file)['SMTP_PASSWORD'], 'new pass');
  });

  test('a process variable overrides the env file', () {
    final config = ServerConfig.fromMaps(
      file: {
        'PORT': '9090',
        'OWNER_EMAIL': 'file@shop.test',
        'SYNC_TOKEN': 'file',
      },
      platform: {'OWNER_EMAIL': 'shell@shop.test'},
    );

    expect(config.port, 9090);
    expect(config.syncToken, 'file');
    expect(config.mail.ownerEmail, 'shell@shop.test');
  });

  test('email stays off until a mail host is saved', () async {
    final mailer = EnvReportMailer(MailSettings());
    final sent = await mailer.send(
      to: 'a@b.test',
      subject: 'Day',
      body: 'Quiet',
    );
    expect(sent, isFalse);
  });
}
