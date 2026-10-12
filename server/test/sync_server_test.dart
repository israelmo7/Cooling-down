import 'dart:convert';
import 'dart:io';

import 'package:cooling_down_server/handler.dart';
import 'package:cooling_down_server/mailer.dart';
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

  test('admin login edits one environment email only', () async {
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

    final denied = await _form(
      client,
      server.port,
      '/admin/login',
      {'user': 'owner', 'password': 'wrong'},
    );
    expect(denied.status, 302);
    expect(denied.cookie, isNull);

    final allowed = await _form(
      client,
      server.port,
      '/admin/login',
      {'user': 'owner', 'password': 'panel-secret'},
    );
    expect(allowed.status, 302);
    expect(allowed.cookie, isNotNull);

    final saved = await _form(
      client,
      server.port,
      '/admin/email',
      {'environment': 'מטבח', 'owner_email': 'new-kitchen@shop.test'},
      cookie: allowed.cookie,
    );
    expect(saved.status, 302);
    final rows = store.environmentSummaries();
    expect(
      rows.firstWhere((row) => row['name'] == 'מטבח')['owner_email'],
      'new-kitchen@shop.test',
    );
    expect(
      rows.firstWhere((row) => row['name'] == 'בית מרקחת')['owner_email'],
      'pharmacy@shop.test',
    );
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
  });
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
  String? lastTo;
  String? lastSubject;
  String? lastBody;

  @override
  Future<bool> send({
    required String to,
    required String subject,
    required String body,
  }) async {
    sent += 1;
    lastTo = to;
    lastSubject = subject;
    lastBody = body;
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
  final request = await client.postUrl(Uri.parse('http://127.0.0.1:$port$path'));
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
