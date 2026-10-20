import 'dart:convert';
import 'dart:io';

import 'package:cooling_down_server/env_file.dart';
import 'package:cooling_down_server/handler.dart';
import 'package:cooling_down_server/mailer.dart';
import 'package:cooling_down_server/report_time.dart';
import 'package:cooling_down_server/server_config.dart';
import 'package:cooling_down_server/sync_store.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:test/test.dart';

void main() {
  test('the same log id is stored once', () {
    final store = SyncStore.memory();
    addTearDown(store.close);
    final log = _log(id: 'log-1', movementId: 'move-1', eventType: 'check_in');

    final first = store.exchange(
      deviceId: 'tablet-a',
      environment: 'Kitchen',
      cursor: 0,
      push: [_push('refrigeration_log', log)],
    );
    final second = store.exchange(
      deviceId: 'tablet-a',
      environment: 'Kitchen',
      cursor: first['cursor'] as int,
      push: [_push('refrigeration_log', log)],
    );

    expect(first['accepted'], ['log-1']);
    expect(second['accepted'], ['log-1']);
    expect(second['changes'], isEmpty);
    expect((first['changes'] as List), hasLength(1));
  });

  test('a second check-out is kept and flagged', () {
    final store = SyncStore.memory();
    addTearDown(store.close);
    store.exchange(
      deviceId: 'tablet-a',
      environment: 'Kitchen',
      cursor: 0,
      push: [
        _push(
          'refrigeration_log',
          _log(id: 'in-1', movementId: 'move-1', eventType: 'check_in'),
        ),
        _push(
          'refrigeration_log',
          _log(id: 'out-1', movementId: 'move-1', eventType: 'check_out'),
        ),
      ],
    );

    final second = store.exchange(
      deviceId: 'tablet-b',
      environment: 'Kitchen',
      cursor: 0,
      push: [
        _push(
          'refrigeration_log',
          _log(id: 'out-2', movementId: 'move-1', eventType: 'check_out'),
        ),
      ],
    );

    final conflicts = second['conflicts'] as List;
    expect(conflicts, hasLength(1));
    expect((conflicts.single as Map)['reason'], 'movement already checked out');
    final changes = second['changes'] as List;
    final types = [for (final row in changes) (row as Map)['entity_type']];
    expect(types, containsAll(['refrigeration_log', 'alert']));
    final alert = changes.cast<Map>().firstWhere(
      (row) => row['entity_type'] == 'alert',
    );
    expect(alert['payload']['kind'], 'sync_conflict');
  });

  test('the first email wins and a later report is already sent', () async {
    final mailer = _RecordingMailer();
    final store = SyncStore.memory(mailer: mailer);
    addTearDown(store.close);

    final first = await store.submitReport(
      id: 'report-1',
      environment: 'Kitchen',
      reportDate: '2026-10-11',
      ownerEmail: 'owner@example.com',
      subject: 'Day',
      body: 'All quiet.',
    );
    final second = await store.submitReport(
      id: 'report-2',
      environment: 'Kitchen',
      reportDate: '2026-10-11',
      ownerEmail: 'owner@example.com',
      subject: 'Day again',
      body: 'Later tablet.',
    );

    expect(first['status'], 'sent');
    expect(second['status'], 'already_sent');
    expect(mailer.sent, 1);
  });

  test('a report is stored when email is not configured', () async {
    final store = SyncStore.memory();
    addTearDown(store.close);
    final result = await store.submitReport(
      id: 'report-1',
      environment: 'Kitchen',
      reportDate: '2026-10-11',
      ownerEmail: 'owner@example.com',
      subject: 'Day',
      body: 'All quiet.',
    );
    expect(result['status'], 'stored');
  });

  test('sync requires the bearer token', () async {
    final store = SyncStore.memory();
    addTearDown(store.close);
    final server = await shelf_io.serve(
      buildHandler(store: store, token: 'secret'),
      InternetAddress.loopbackIPv4,
      0,
    );
    addTearDown(server.close);
    final client = HttpClient();
    addTearDown(client.close);

    final denied = await _post(client, server.port, token: 'nope', body: {});
    final allowed = await _post(
      client,
      server.port,
      token: 'secret',
      body: {
        'device_id': 'tablet-a',
        'environment': 'Kitchen',
        'cursor': 0,
        'push': <Object?>[],
      },
    );

    expect(denied.status, 401);
    expect(allowed.status, 200);
    expect(allowed.json['cursor'], 0);
  });

  test('a tablet does not receive another environment', () {
    final store = SyncStore.memory();
    addTearDown(store.close);
    store.exchange(
      deviceId: 'tablet-a',
      environment: 'מטבח',
      cursor: 0,
      push: [
        _push(
          'refrigeration_log',
          _log(id: 'kitchen-in', movementId: 'move-k', eventType: 'check_in'),
        ),
      ],
    );

    final other = store.exchange(
      deviceId: 'tablet-b',
      environment: 'בית מרקחת',
      cursor: 0,
      push: const [],
    );

    expect(other['changes'], isEmpty);
    expect(store.logsFor('מטבח'), hasLength(1));
    expect(store.logsFor('בית מרקחת'), isEmpty);
  });

  test('admin login shows one owner address', () async {
    final store = SyncStore.memory();
    addTearDown(store.close);
    store.setOwnerEmail('מטבח', 'kitchen@shop.test');
    store.setOwnerEmail('בית מרקחת', 'pharmacy@shop.test');
    final server = await shelf_io.serve(
      buildHandler(
        store: store,
        token: 'secret',
        adminUser: 'owner',
        adminPassword: 'panel-secret',
      ),
      InternetAddress.loopbackIPv4,
      0,
    );
    addTearDown(server.close);
    final client = HttpClient();
    addTearDown(client.close);

    final denied = await _form(client, server.port, '/admin/login', {
      'user': 'owner',
      'password': 'wrong',
    });
    expect(denied.status, 302);
    expect(denied.cookie, isNull);

    final allowed = await _form(client, server.port, '/admin/login', {
      'user': 'owner',
      'password': 'panel-secret',
    });
    expect(allowed.status, 302);
    expect(allowed.cookie, isNotNull);

    final settings = await _get(
      client,
      server.port,
      '/admin',
      cookie: allowed.cookie,
    );
    expect('name="owner_email"'.allMatches(settings.body), hasLength(1));
    expect(settings.body, contains('שמירה'));
    expect(settings.body, contains('שליחת דוח לבדיקה'));
    expect(settings.body, isNot(contains('מטבח')));
    expect(settings.body, isNot(contains('type="time"')));
    expect(settings.body, contains('dir="ltr"'));
    expect(settings.body, contains('placeholder="18:30"'));
    final places = await _get(
      client,
      server.port,
      '/admin?tab=places',
      cookie: allowed.cookie,
    );
    expect(places.body, contains('מטבח'));
    expect(places.body, contains('בית מרקחת'));
    expect(places.body, isNot(contains('name="owner_email"')));
  });

  test('the environment list keeps the latest actions only', () async {
    final store = SyncStore.memory();
    addTearDown(store.close);
    for (var index = 0; index < 2; index++) {
      store.exchange(
        deviceId: 'tablet-a',
        environment: 'מטבח',
        cursor: 0,
        push: [
          _push('refrigeration_log', {
            ..._log(
              id: 'log-$index',
              movementId: 'move-$index',
              eventType: 'check_in',
            ),
            'product_name_snapshot': 'חלב',
            'occurred_at': DateTime(
              2026,
              10,
              11,
              8,
              index,
            ).toUtc().toIso8601String(),
          }),
        ],
      );
    }
    final server = await shelf_io.serve(
      buildHandler(
        store: store,
        token: 'secret',
        adminUser: 'owner',
        adminPassword: 'panel-secret',
      ),
      InternetAddress.loopbackIPv4,
      0,
    );
    addTearDown(server.close);
    final client = HttpClient();
    addTearDown(client.close);
    final allowed = await _form(client, server.port, '/admin/login', {
      'user': 'owner',
      'password': 'panel-secret',
    });
    final places = await _get(
      client,
      server.port,
      '/admin?tab=places',
      cookie: allowed.cookie,
    );
    expect(places.body, contains('הרשימה נעצרת ב-30'));
    expect(places.body, contains('מתוך 2'));
    expect(places.body, contains('חלב'));
  });

  test('midnight emails yesterday once from the stored logs', () async {
    final mailer = _RecordingMailer();
    final store = SyncStore.memory(
      mailer: mailer,
      ownerEmail: 'owner@shop.test',
    );
    addTearDown(store.close);
    final occurred = DateTime(2026, 10, 11, 15);
    store.exchange(
      deviceId: 'tablet-a',
      environment: 'מטבח',
      cursor: 0,
      push: [
        _push('refrigeration_log', {
          ..._log(id: 'log-day', movementId: 'move-day', eventType: 'check_in'),
          'product_name_snapshot': 'חלב',
          'fridge_name': 'מקרר מטבח',
          'worker_name_snapshot': 'דנה',
          'temperature_celsius': 4.0,
          'occurred_at': occurred.toUtc().toIso8601String(),
        }),
      ],
    );

    final first = await store.sendClosedDay(DateTime(2026, 10, 12, 0, 1));
    final second = await store.sendClosedDay(DateTime(2026, 10, 12, 8));

    expect(first, ['sent']);
    expect(second, isEmpty);
    expect(mailer.sent, 1);
    expect(mailer.lastTo, 'owner@shop.test');
    expect(mailer.lastSubject, contains('2026-10-11'));
    expect(mailer.lastBody, contains('חלב'));
    expect(mailer.lastBody, contains('דנה'));
    expect(mailer.lastBody, contains('מסקנה:'));
    expect(
      mailer.lastBody,
      contains('חלב | \u20664.0°C\u2069 · דנה · מקרר מטבח | 15:00 | - | -'),
    );
    expect(mailer.lastHtml, contains('<table'));
    expect(mailer.lastHtml, contains('>חלב</td>'));
    expect(mailer.lastHtml, contains('>-</td>'));
  });

  test('admin mail settings are saved to the env file', () async {
    final store = SyncStore.memory(ownerEmail: 'owner@shop.test');
    addTearDown(store.close);
    store.setOwnerEmail('מטבח', 'owner@shop.test');
    store.setOwnerEmail('בית מרקחת', 'pharmacy@shop.test');
    final envFile = File(
      '${Directory.systemTemp.path}/cooling-admin-${DateTime.now().microsecondsSinceEpoch}.env',
    );
    addTearDown(() {
      if (envFile.existsSync()) {
        envFile.deleteSync();
      }
    });
    envFile.writeAsStringSync(
      'SYNC_TOKEN=secret\nADMIN_USER=owner\nSMTP_PASSWORD=keep-me\n',
    );
    final mail = MailSettings(
      ownerEmail: 'owner@shop.test',
      smtpHost: 'smtp.shop.test',
      smtpPort: 587,
      smtpFrom: 'reports@shop.test',
      smtpPassword: 'keep-me',
    );
    final server = await shelf_io.serve(
      buildHandler(
        store: store,
        token: 'secret',
        adminUser: 'owner',
        adminPassword: 'panel-secret',
        mail: mail,
        envFile: envFile,
      ),
      InternetAddress.loopbackIPv4,
      0,
    );
    addTearDown(server.close);
    final client = HttpClient();
    addTearDown(client.close);

    final allowed = await _form(client, server.port, '/admin/login', {
      'user': 'owner',
      'password': 'panel-secret',
    });
    final page = await _get(
      client,
      server.port,
      '/admin',
      cookie: allowed.cookie,
    );
    expect(page.body, contains('owner@shop.test'));
    expect(page.body, contains('הדואר פעיל.'));
    expect(page.body, isNot(contains('name="smtp_password"')));
    expect(page.body, isNot(contains('smtp.shop.test')));

    final rejected = await _form(client, server.port, '/admin/save', {
      'admin_user': 'owner',
      'admin_password': 'panel-secret',
      'time_zone': 'Asia/Jerusalem',
      'report_time': '00:00',
      'report_format': 'builtin',
      'owner_email': 'not-an-email',
    }, cookie: allowed.cookie);
    expect(rejected.status, 302);
    expect(store.ownerEmail, 'owner@shop.test');
    expect(loadEnvFile(envFile)['OWNER_EMAIL'], isNull);

    final saved = await _form(client, server.port, '/admin/save', {
      'admin_user': 'owner',
      'admin_password': 'panel-secret',
      'time_zone': 'Asia/Jerusalem',
      'report_time': '00:00',
      'report_format': 'builtin',
      'owner_email': 'new-owner@shop.test',
    }, cookie: allowed.cookie);
    expect(saved.status, 302);
    expect(mail.ownerEmail, 'new-owner@shop.test');
    expect(mail.smtpPort, 587);
    expect(mail.smtpPassword, 'keep-me');
    expect(loadEnvFile(envFile)['OWNER_EMAIL'], 'new-owner@shop.test');
    expect(loadEnvFile(envFile)['SMTP_PASSWORD'], 'keep-me');
    expect(loadEnvFile(envFile)['SYNC_TOKEN'], 'secret');
    final rows = store.environmentSummaries();
    expect(
      rows.firstWhere((row) => row['name'] == 'מטבח')['owner_email'],
      'new-owner@shop.test',
    );
    expect(
      rows.firstWhere((row) => row['name'] == 'בית מרקחת')['owner_email'],
      'new-owner@shop.test',
    );
  });

  test('every environment report goes to the one shop address', () async {
    final mailer = _RecordingMailer();
    final store = SyncStore.memory(
      mailer: mailer,
      ownerEmail: 'owner@shop.test',
    );
    addTearDown(store.close);
    store.setOwnerEmail('מטבח', 'kitchen@shop.test');
    store.setOwnerEmail('בית מרקחת', 'pharmacy@shop.test');

    final statuses = await store.sendClosedDay(DateTime(2026, 10, 12, 0, 1));

    expect(statuses, ['sent', 'sent']);
    expect(mailer.sent, 2);
    expect(mailer.tos, ['owner@shop.test', 'owner@shop.test']);
  });

  test('the test button sends today to the shop address', () async {
    final mailer = _RecordingMailer();
    final store = SyncStore.memory(
      mailer: mailer,
      ownerEmail: 'owner@shop.test',
    );
    addTearDown(store.close);
    final now = DateTime.now();
    store.exchange(
      deviceId: 'tablet-a',
      environment: 'מטבח',
      cursor: 0,
      push: [
        _push('refrigeration_log', {
          ..._log(id: 'today', movementId: 'move-today', eventType: 'check_in'),
          'product_name_snapshot': 'חלב',
          'occurred_at': now.toUtc().toIso8601String(),
        }),
      ],
    );
    final server = await shelf_io.serve(
      buildHandler(
        store: store,
        token: 'secret',
        adminUser: 'owner',
        adminPassword: 'panel-secret',
        mail: MailSettings(
          ownerEmail: 'owner@shop.test',
          smtpHost: 'smtp.shop.test',
          smtpFrom: 'from@shop.test',
        ),
      ),
      InternetAddress.loopbackIPv4,
      0,
    );
    addTearDown(server.close);
    final client = HttpClient();
    addTearDown(client.close);
    final allowed = await _form(client, server.port, '/admin/login', {
      'user': 'owner',
      'password': 'panel-secret',
    });

    final sent = await _form(
      client,
      server.port,
      '/admin/test-report',
      {},
      cookie: allowed.cookie,
    );
    expect(sent.status, 302);
    final page = await _get(
      client,
      server.port,
      '/admin?notice=test-ok',
      cookie: allowed.cookie,
    );
    expect(page.body, contains('נשלח דוח הבדיקה של היום.'));
    expect(mailer.sent, 1);
    expect(mailer.lastTo, 'owner@shop.test');
    expect(mailer.lastBody, contains('חלב'));

    final again = await _form(
      client,
      server.port,
      '/admin/test-report',
      {},
      cookie: allowed.cookie,
    );
    expect(again.status, 302);
    expect(mailer.sent, 2);
  });

  test('the report waits until the chosen hour', () async {
    final mailer = _RecordingMailer();
    final store = SyncStore.memory(
      mailer: mailer,
      ownerEmail: 'owner@shop.test',
    );
    addTearDown(store.close);
    store.exchange(
      deviceId: 'tablet-a',
      environment: 'מטבח',
      cursor: 0,
      push: [
        _push('refrigeration_log', {
          ..._log(
            id: 'log-hour',
            movementId: 'move-hour',
            eventType: 'check_in',
          ),
          'occurred_at': DateTime(2026, 10, 11, 15).toUtc().toIso8601String(),
        }),
      ],
    );

    final early = await store.sendClosedDay(
      DateTime(2026, 10, 12, 18, 29),
      reportTime: const ReportTime(18, 30),
    );
    final due = await store.sendClosedDay(
      DateTime(2026, 10, 12, 18, 30),
      reportTime: const ReportTime(18, 30),
    );
    final again = await store.sendClosedDay(
      DateTime(2026, 10, 12, 19),
      reportTime: const ReportTime(18, 30),
    );

    expect(early, isEmpty);
    expect(due, ['sent']);
    expect(again, isEmpty);
    expect(mailer.sent, 1);
  });

  test(
    'the panel writes the admin login and the clock back to the file',
    () async {
      final store = SyncStore.memory(ownerEmail: 'owner@shop.test');
      addTearDown(store.close);
      final dir = Directory.systemTemp.createTempSync('cooling-admin-panel-');
      addTearDown(() => dir.deleteSync(recursive: true));
      final envFile = File('${dir.path}/.env')
        ..writeAsStringSync(
          'SYNC_TOKEN=secret\nADMIN_USER=owner\nADMIN_PASSWORD=panel-secret\n',
        );
      final shopFile = File('${dir.path}/shop.json')
        ..writeAsStringSync(
          '{"_readme":"kept","SYNC_TOKEN":"secret","ADMIN_USER":"owner","ADMIN_PASSWORD":"panel-secret"}\n',
        );
      final schedule = ShopSchedule();
      final mail = MailSettings(ownerEmail: 'owner@shop.test');
      final reportFile = File('${dir.path}/report.txt');
      final server = await shelf_io.serve(
        buildHandler(
          store: store,
          token: 'secret',
          adminUser: 'owner',
          adminPassword: 'panel-secret',
          mail: mail,
          envFile: envFile,
          shopFile: shopFile,
          reportFile: reportFile,
          schedule: schedule,
        ),
        InternetAddress.loopbackIPv4,
        0,
      );
      addTearDown(server.close);
      final client = HttpClient();
      addTearDown(client.close);

      final allowed = await _form(client, server.port, '/admin/login', {
        'user': 'owner',
        'password': 'panel-secret',
      });
      final page = await _get(
        client,
        server.port,
        '/admin',
        cookie: allowed.cookie,
      );
      expect(page.body, contains('שמירה'));
      expect(page.body, contains('שעת הדוח'));
      expect(page.body, contains('שליחת דוח לבדיקה'));
      expect(page.body, isNot(contains('name="sync_token"')));

      final renamed = await _form(client, server.port, '/admin/save', {
        'admin_user': 'shop',
        'admin_password': 'new pass',
        'time_zone': 'UTC',
        'report_time': '18:30',
        'report_format': 'builtin',
        'owner_email': 'owner@shop.test',
      }, cookie: allowed.cookie);
      expect(renamed.status, 302);
      final stillIn = await _get(
        client,
        server.port,
        '/admin',
        cookie: allowed.cookie,
      );
      expect(stillIn.status, 200);
      expect(stillIn.body, contains('value="shop"'));
      final oldPassword = await _form(client, server.port, '/admin/login', {
        'user': 'owner',
        'password': 'panel-secret',
      });
      expect(oldPassword.cookie, isNull);
      final newPassword = await _form(client, server.port, '/admin/login', {
        'user': 'shop',
        'password': 'new pass',
      });
      expect(newPassword.cookie, isNotNull);

      expect(schedule.timeZone, 'UTC');
      expect(schedule.reportTime.text, '18:30');
      expect(loadEnvFile(envFile)['TZ'], 'UTC');
      expect(loadEnvFile(envFile)['REPORT_TIME'], '18:30');
      expect(loadEnvFile(envFile)['ADMIN_PASSWORD'], 'new pass');
      expect(loadEnvFile(envFile)['SYNC_TOKEN'], 'secret');

      final badTime = await _form(client, server.port, '/admin/save', {
        'admin_user': 'shop',
        'admin_password': 'nope',
        'time_zone': 'UTC',
        'report_time': '18:99',
        'report_format': 'builtin',
        'owner_email': 'owner@shop.test',
      }, cookie: allowed.cookie);
      expect(badTime.status, 302);
      final badTimePage = await _get(
        client,
        server.port,
        '/admin?notice=time',
        cookie: allowed.cookie,
      );
      expect(
        badTimePage.body,
        contains('שעת הדוח צריכה להיות בשעה כמו 18:30.'),
      );
      expect(schedule.reportTime.text, '18:30');
      final keptPassword = await _form(client, server.port, '/admin/login', {
        'user': 'shop',
        'password': 'new pass',
      });
      expect(keptPassword.cookie, isNotNull);

      final rejected = await _form(client, server.port, '/admin/save', {
        'admin_user': 'shop',
        'admin_password': 'new pass',
        'time_zone': 'Not a zone',
        'report_time': '18:30',
        'report_format': 'builtin',
        'owner_email': 'owner@shop.test',
      }, cookie: allowed.cookie);
      expect(rejected.status, 302);
      expect(schedule.timeZone, 'UTC');

      final saved = jsonDecode(shopFile.readAsStringSync()) as Map;
      expect(saved['SYNC_TOKEN'], 'secret');
      expect(saved['_readme'], 'kept');
      expect(saved['ADMIN_USER'], 'shop');
      expect(saved['ADMIN_PASSWORD'], 'new pass');
      expect(saved['TZ'], 'UTC');
      expect(saved['REPORT_TIME'], '18:30');

      reportFile.writeAsStringSync('סביבה: {{environment}}\n');
      final chosen = await _form(client, server.port, '/admin/save', {
        'admin_user': 'shop',
        'admin_password': 'new pass',
        'time_zone': 'UTC',
        'report_time': '18:30',
        'report_format': 'custom',
        'owner_email': 'owner@shop.test',
      }, cookie: allowed.cookie);
      expect(chosen.status, 302);
      expect(schedule.reportFormat, 'custom');
      expect(loadEnvFile(envFile)['REPORT_FORMAT'], 'custom');
      final shown = await _get(
        client,
        server.port,
        '/admin?tab=report',
        cookie: allowed.cookie,
      );
      expect(shown.body, contains('הדוח הקבוע'));
      expect(shown.body, contains('איך נקלט'));
      expect(shown.body, contains('value="custom" checked'));
      expect(shown.body, isNot(contains('name="smtp_password"')));
    },
  );
}

Map<String, dynamic> _log({
  required String id,
  required String movementId,
  required String eventType,
}) {
  return {
    'id': id,
    'movement_id': movementId,
    'product_id': 'milk',
    'product_name_snapshot': 'Whole milk',
    'fridge_id': 'kitchen',
    'event_type': eventType,
    'temperature_celsius': 3,
    'occurred_at': '2026-10-11T08:00:00.000Z',
    'created_at': '2026-10-11T08:00:00.000Z',
    'origin_device_id': 'tablet-a',
  };
}

Map<String, dynamic> _push(String type, Map<String, dynamic> payload) {
  return {'entity_type': type, 'entity_id': payload['id'], 'payload': payload};
}

class _RecordingMailer implements ReportMailer {
  int sent = 0;
  final tos = <String>[];
  String? lastTo;
  String? lastSubject;
  String? lastBody;
  String? lastHtml;

  @override
  Future<bool> send({
    required String to,
    required String subject,
    required String body,
    String? html,
  }) async {
    sent += 1;
    tos.add(to);
    lastTo = to;
    lastSubject = subject;
    lastBody = body;
    lastHtml = html;
    return true;
  }
}

Future<({int status, String? cookie})> _form(
  HttpClient client,
  int port,
  String path,
  Map<String, String> fields, {
  String? cookie,
}) async {
  final request = await client.postUrl(
    Uri.parse('http://127.0.0.1:$port$path'),
  );
  request.followRedirects = false;
  if (cookie != null) {
    request.headers.set(HttpHeaders.cookieHeader, cookie);
  }
  request.headers.contentType = ContentType(
    'application',
    'x-www-form-urlencoded',
    charset: 'utf-8',
  );
  request.write(Uri(queryParameters: fields).query);
  final response = await request.close();
  await response.drain<void>();
  final setCookie = response.headers.value(HttpHeaders.setCookieHeader);
  final session = setCookie == null || !setCookie.contains('admin_session=')
      ? null
      : setCookie.split(';').first;
  return (status: response.statusCode, cookie: session);
}

Future<({int status, String body})> _get(
  HttpClient client,
  int port,
  String path, {
  String? cookie,
}) async {
  final request = await client.getUrl(Uri.parse('http://127.0.0.1:$port$path'));
  request.followRedirects = false;
  if (cookie != null) {
    request.headers.set(HttpHeaders.cookieHeader, cookie);
  }
  final response = await request.close();
  final body = await response.transform(utf8.decoder).join();
  return (status: response.statusCode, body: body);
}

Future<({int status, Map<String, dynamic> json})> _post(
  HttpClient client,
  int port, {
  required String token,
  required Map<String, Object?> body,
}) async {
  final request = await client.postUrl(
    Uri.parse('http://127.0.0.1:$port/v1/sync'),
  );
  request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $token');
  request.headers.contentType = ContentType.json;
  request.write(jsonEncode(body));
  final response = await request.close();
  final raw = await response.transform(utf8.decoder).join();
  final decoded = jsonDecode(raw);
  return (
    status: response.statusCode,
    json: decoded is Map<String, dynamic> ? decoded : <String, dynamic>{},
  );
}
