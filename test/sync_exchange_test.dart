import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cooling_down/data/db/app_database.dart';
import 'package:cooling_down/data/db/seed_ids.dart';
import 'package:cooling_down/data/repositories/drift_log_repository.dart';
import 'package:cooling_down/data/repositories/drift_settings_repository.dart';
import 'package:cooling_down/data/repositories/drift_sync_repository.dart';
import 'package:cooling_down/data/sync/http_sync_gateway.dart';
import 'package:cooling_down/data/sync/remote_apply.dart';
import 'package:cooling_down/data/sync/sync_gateway.dart';
import 'package:cooling_down/domain/entities/alert.dart';
import 'package:cooling_down/domain/entities/refrigeration_log.dart';
import 'package:cooling_down/domain/settings/device_settings.dart';
import 'package:cooling_down/domain/sync/checkout_conflict.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

void main() {
  test('applying the same remote log twice does not duplicate it', () async {
    final database = AppDatabase.memory();
    addTearDown(database.close);
    final applier = RemoteApplier(database);
    final change = _logChange(
      seq: 1,
      id: 'remote-in',
      movementId: 'move-1',
      eventType: 'check_in',
    );

    await applier.apply([change]);
    await applier.apply([change]);

    final logs = await database.select(database.refrigerationLogs).get();
    expect(logs, hasLength(1));
    final outbox = await database.select(database.syncOutbox).get();
    expect(outbox, isEmpty);
  });

  test(
    'a second remote check-out is kept and closes the holding once',
    () async {
      final database = AppDatabase.memory();
      addTearDown(database.close);
      final logs = DriftLogRepository(database);
      final checkIn = await logs.insertCheckIn(
        productId: SeedIds.wholeMilk,
        fridgeId: SeedIds.kitchenFridge,
        temperatureCelsius: 3,
        occurredAt: DateTime.utc(2026, 10, 11, 8),
      );
      await logs.insertCheckOut(
        movementId: checkIn.movementId,
        temperatureCelsius: 4,
        occurredAt: DateTime.utc(2026, 10, 11, 12),
      );

      final applier = RemoteApplier(database);
      final remoteOut = _logChange(
        seq: 4,
        id: 'remote-out',
        movementId: checkIn.movementId,
        eventType: 'check_out',
        occurredAt: '2026-10-11T12:05:00.000Z',
      );
      await applier.apply([remoteOut]);
      await applier.apply([remoteOut]);

      final stored = await database.select(database.refrigerationLogs).get();
      expect(
        stored.where((row) => row.eventType == LogEventType.checkOut),
        hasLength(2),
      );
      expect(await logs.watchOpenHoldings().first, isEmpty);
      final alerts = await database.select(database.alerts).get();
      final conflict = alerts.where(
        (row) => row.kind == AlertKind.syncConflict,
      );
      expect(conflict, hasLength(1));
      expect(conflict.single.id, checkoutConflictAlertId(checkIn.movementId));
      expect(conflict.single.message, contains('Whole milk'));
    },
  );

  test('sync pulls another tablet and marks the local outbox synced', () async {
    final database = AppDatabase.memory();
    addTearDown(database.close);
    final settings = DriftSettingsRepository(database);
    final current = await settings.ensure();
    await settings.save(
      current.copyWith(
        serverUrl: 'http://192.168.1.20:8080',
        serverToken: 'secret',
      ),
    );
    final logs = DriftLogRepository(database);
    final checkIn = await logs.insertCheckIn(
      productId: SeedIds.chickenBreast,
      fridgeId: SeedIds.kitchenFridge,
      temperatureCelsius: 2,
    );
    final remote = _logChange(
      seq: 8,
      id: 'other-in',
      movementId: 'other-move',
      eventType: 'check_in',
      productId: SeedIds.insulin,
      productName: 'Insulin',
      fridgeId: SeedIds.pharmacyFridge,
    );
    final gateway = _FakeGateway(
      SyncExchange(
        reachable: true,
        cursor: 8,
        acceptedIds: [checkIn.id],
        changes: [remote],
      ),
    );
    final sync = DriftSyncRepository(
      database,
      settings: settings,
      gatewayFor: (DeviceSettings _) => gateway,
    );

    final attempt = await sync.trySync();
    final holdings = await logs.watchOpenHoldings().first;
    final outbox = await database.select(database.syncOutbox).get();
    final saved = await settings.ensure();

    expect(attempt.synced, 1);
    expect(attempt.pulled, 1);
    expect(attempt.remaining, 0);
    expect(holdings.map((row) => row.productName), contains('Insulin'));
    expect(outbox.single.status.name, 'synced');
    expect(saved.syncCursor, 8);
    expect(saved.lastSyncError, isNull);
    expect(gateway.request!.environment, 'מטבח');
  });

  test('the http gateway posts the batch and reads the reply', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(server.close);
    final client = http.Client();
    addTearDown(client.close);
    final responded = _serve(server);
    final gateway = HttpSyncGateway(
      baseUrl: 'http://127.0.0.1:${server.port}',
      token: 'secret',
      client: client,
    );

    final exchange = await gateway.exchange(
      const SyncRequest(
        deviceId: 'tablet-a',
        environment: 'Kitchen',
        cursor: 3,
        push: [
          SyncPushItem(
            entityType: 'refrigeration_log',
            entityId: 'log-1',
            payloadJson: '{"id":"log-1"}',
          ),
        ],
      ),
    );
    final report = await gateway.postReport(
      const ReportPost(
        id: 'report-1',
        environment: 'Kitchen',
        reportDate: '2026-10-11',
        ownerEmail: 'owner@example.com',
        subject: 'Day',
        body: 'Quiet.',
      ),
    );
    final seen = await responded;

    expect(seen.authorization, 'Bearer secret');
    expect(seen.syncBody['cursor'], 3);
    expect(seen.syncBody['push'], hasLength(1));
    expect(exchange.reachable, isTrue);
    expect(exchange.cursor, 9);
    expect(exchange.changes.single.entityId, 'other-in');
    expect(report.status, 'stored');
  });
}

SyncChange _logChange({
  required int seq,
  required String id,
  required String movementId,
  required String eventType,
  String productId = SeedIds.wholeMilk,
  String productName = 'Whole milk',
  String fridgeId = SeedIds.kitchenFridge,
  String occurredAt = '2026-10-11T08:00:00.000Z',
}) {
  return SyncChange(
    seq: seq,
    entityType: 'refrigeration_log',
    entityId: id,
    deviceId: 'other-tablet',
    payload: {
      'id': id,
      'movement_id': movementId,
      'product_id': productId,
      'product_name_snapshot': productName,
      'fridge_id': fridgeId,
      'event_type': eventType,
      'temperature_celsius': 3,
      'occurred_at': occurredAt,
      'created_at': occurredAt,
      'origin_device_id': 'other-tablet',
    },
  );
}

class _FakeGateway implements SyncGateway {
  _FakeGateway(this.result);

  final SyncExchange result;
  SyncRequest? request;

  @override
  Future<SyncExchange> exchange(SyncRequest request) async {
    this.request = request;
    return result;
  }

  @override
  Future<ReportPostResult> postReport(ReportPost report) async {
    return const ReportPostResult(status: 'stored');
  }
}

class _Seen {
  _Seen({required this.authorization, required this.syncBody});

  final String? authorization;
  final Map<String, dynamic> syncBody;
}

Future<_Seen> _serve(HttpServer server) {
  final done = Completer<_Seen>();
  var count = 0;
  String? authorization;
  Map<String, dynamic>? syncBody;
  server.listen((request) async {
    count += 1;
    if (count == 1) {
      authorization = request.headers.value(HttpHeaders.authorizationHeader);
      final raw = await utf8.decoder.bind(request).join();
      syncBody = jsonDecode(raw) as Map<String, dynamic>;
      request.response.headers.contentType = ContentType.json;
      request.response.write(
        jsonEncode({
          'cursor': 9,
          'accepted': ['log-1'],
          'conflicts': <Object?>[],
          'changes': [
            {
              'seq': 9,
              'entity_type': 'refrigeration_log',
              'entity_id': 'other-in',
              'device_id': 'tablet-b',
              'payload': {'id': 'other-in'},
            },
          ],
        }),
      );
      await request.response.close();
      return;
    }
    await utf8.decoder.bind(request).join();
    request.response.headers.contentType = ContentType.json;
    request.response.write(jsonEncode({'status': 'stored'}));
    await request.response.close();
    done.complete(
      _Seen(authorization: authorization, syncBody: syncBody ?? const {}),
    );
  });
  return done.future;
}
