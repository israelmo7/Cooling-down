import 'dart:convert';
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

  test('shop.json writes .env and keeps a generated token', () {
    final dir = Directory.systemTemp.createTempSync('cooling-shop-');
    addTearDown(() {
      dir.deleteSync(recursive: true);
    });
    final shop = File('${dir.path}/shop.json');
    final env = File('${dir.path}/.env');
    shop.writeAsStringSync('''
{
  "_readme": "kept",
  "SYNC_TOKEN": "",
  "ADMIN_USER": "owner",
  "ADMIN_PASSWORD": "secret pass",
  "OWNER_EMAIL": "owner@shop.test",
  "SMTP_HOST": "",
  "SMTP_PORT": 587,
  "TZ": ""
}
''');

    applyShopJson(shopFile: shop, envFile: env);

    final token = loadEnvFile(env)['SYNC_TOKEN']!;
    expect(
      token,
      matches(
        RegExp(
          r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
        ),
      ),
    );
    expect(loadEnvFile(env)['ADMIN_PASSWORD'], 'secret pass');
    expect(loadEnvFile(env)['SMTP_HOST'], '');
    expect(loadEnvFile(env)['SMTP_PORT'], '587');
    expect(loadEnvFile(env)['TZ'], 'Asia/Jerusalem');
    expect(loadEnvFile(env)['OWNER_EMAIL'], 'owner@shop.test');
    expect(env.readAsStringSync(), startsWith('# Written from shop.json.'));

    final saved = jsonDecode(shop.readAsStringSync()) as Map<String, dynamic>;
    expect(saved['SYNC_TOKEN'], token);
    expect(saved['_readme'], 'kept');

    saved['SYNC_TOKEN'] = '';
    saved['ADMIN_PASSWORD'] = '';
    saved['OWNER_EMAIL'] = 'other@shop.test';
    shop.writeAsStringSync(jsonEncode(saved));
    applyShopJson(shopFile: shop, envFile: env);

    expect(loadEnvFile(env)['SYNC_TOKEN'], token);
    expect(loadEnvFile(env)['ADMIN_PASSWORD'], '');
    expect(loadEnvFile(env)['OWNER_EMAIL'], 'other@shop.test');
    expect((jsonDecode(shop.readAsStringSync()) as Map)['SYNC_TOKEN'], token);

    saved['SYNC_TOKEN'] = 'tablet-secret';
    shop.writeAsStringSync(jsonEncode(saved));
    applyShopJson(shopFile: shop, envFile: env);
    expect(loadEnvFile(env)['SYNC_TOKEN'], 'tablet-secret');
  });

  test('shop.json leaves keys it does not mention', () {
    final dir = Directory.systemTemp.createTempSync('cooling-shop-keep-');
    addTearDown(() => dir.deleteSync(recursive: true));
    final shop = File('${dir.path}/shop.json')
      ..writeAsStringSync('{"TZ":"UTC"}');
    final env = File('${dir.path}/.env')
      ..writeAsStringSync('OWNER_EMAIL=keep@shop.test\nPORT=9090\n');

    applyShopJson(shopFile: shop, envFile: env);

    expect(loadEnvFile(env)['OWNER_EMAIL'], 'keep@shop.test');
    expect(loadEnvFile(env)['PORT'], '9090');
    expect(loadEnvFile(env)['TZ'], 'UTC');
  });

  test('a broken shop.json is refused', () {
    final dir = Directory.systemTemp.createTempSync('cooling-shop-bad-');
    addTearDown(() => dir.deleteSync(recursive: true));
    final shop = File('${dir.path}/shop.json')..writeAsStringSync('{');
    final env = File('${dir.path}/.env');

    expect(
      () => applyShopJson(shopFile: shop, envFile: env),
      throwsA(
        isA<FormatException>().having(
          (error) => error.message,
          'message',
          'shop.json is not valid JSON.',
        ),
      ),
    );
    expect(env.existsSync(), isFalse);

    shop.writeAsStringSync('{"ADMIN_PASSWORD": {"no": true}}');
    expect(
      () => applyShopJson(shopFile: shop, envFile: env),
      throwsA(
        isA<FormatException>().having(
          (error) => error.message,
          'message',
          'ADMIN_PASSWORD in shop.json must be text.',
        ),
      ),
    );
  });

  test('an empty report hour is midnight', () {
    final dir = Directory.systemTemp.createTempSync('cooling-shop-hour-');
    addTearDown(() => dir.deleteSync(recursive: true));
    final shop = File('${dir.path}/shop.json')
      ..writeAsStringSync('{"REPORT_HOUR":"","TZ":"UTC"}');
    final env = File('${dir.path}/.env');

    applyShopJson(shopFile: shop, envFile: env);
    expect(loadEnvFile(env)['REPORT_HOUR'], '0');
    expect(loadEnvFile(env)['TZ'], 'UTC');

    shop.writeAsStringSync('{"REPORT_HOUR":"7"}');
    applyShopJson(shopFile: shop, envFile: env);
    expect(loadEnvFile(env)['REPORT_HOUR'], '7');

    shop.writeAsStringSync('{"REPORT_HOUR":"99"}');
    applyShopJson(shopFile: shop, envFile: env);
    expect(loadEnvFile(env)['REPORT_HOUR'], '0');
  });

  test('a panel edit stays in shop.json for the next apply', () {
    final dir = Directory.systemTemp.createTempSync('cooling-shop-panel-');
    addTearDown(() => dir.deleteSync(recursive: true));
    final shop = File('${dir.path}/shop.json')
      ..writeAsStringSync(
        '{"_readme":"kept","SYNC_TOKEN":"","OWNER_EMAIL":"","TZ":"Asia/Jerusalem"}',
      );
    final env = File('${dir.path}/.env');
    applyShopJson(shopFile: shop, envFile: env);
    final token = loadEnvFile(env)['SYNC_TOKEN']!;

    writeShopKeys(shop, {
      'OWNER_EMAIL': 'panel@shop.test',
      'REPORT_HOUR': '6',
      'ADMIN_PASSWORD': 'new pass',
      'SYNC_TOKEN': 'should-not-replace',
    });
    writeEnvKeys(env, {
      'OWNER_EMAIL': 'panel@shop.test',
      'REPORT_HOUR': '6',
      'ADMIN_PASSWORD': 'new pass',
    });

    final saved = jsonDecode(shop.readAsStringSync()) as Map<String, dynamic>;
    expect(saved['SYNC_TOKEN'], token);
    expect(saved['_readme'], 'kept');
    expect(saved['OWNER_EMAIL'], 'panel@shop.test');

    applyShopJson(shopFile: shop, envFile: env);
    expect(loadEnvFile(env)['SYNC_TOKEN'], token);
    expect(loadEnvFile(env)['OWNER_EMAIL'], 'panel@shop.test');
    expect(loadEnvFile(env)['REPORT_HOUR'], '6');
    expect(loadEnvFile(env)['ADMIN_PASSWORD'], 'new pass');
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
