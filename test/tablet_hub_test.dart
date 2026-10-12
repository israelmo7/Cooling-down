import 'package:cooling_down/data/db/app_database.dart';
import 'package:cooling_down/data/db/seed_ids.dart';
import 'package:cooling_down/data/repositories/drift_log_repository.dart';
import 'package:cooling_down/data/repositories/drift_settings_repository.dart';
import 'package:cooling_down/data/sync/http_sync_gateway.dart';
import 'package:cooling_down/data/sync/sync_gateway.dart';
import 'package:cooling_down/data/sync/tablet_hub.dart';
import 'package:cooling_down/domain/entities/alert.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

void main() {
  test('another tablet pulls this tablet and pushes a check-out', () async {
    final database = AppDatabase.memory();
    addTearDown(database.close);
    final settings = DriftSettingsRepository(database);
    final current = await settings.ensure();
    await settings.save(
      current.copyWith(
        hubEnabled: true,
        serverToken: 'secret',
        environmentName: 'Kitchen',
      ),
    );
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
    final hub = TabletHub(database, settings);
    addTearDown(hub.dispose);
    await hub.apply(await settings.ensure(), port: 0);
    final client = http.Client();
    addTearDown(client.close);
    final gateway = HttpSyncGateway(
      baseUrl: 'http://127.0.0.1:${hub.port}',
      token: 'secret',
      client: client,
    );

    final pulled = await gateway.exchange(
      const SyncRequest(
        deviceId: 'other-tablet',
        environment: 'Kitchen',
        cursor: 0,
        push: [],
      ),
    );
    final remoteOut = await gateway.exchange(
      SyncRequest(
        deviceId: 'other-tablet',
        environment: 'Kitchen',
        cursor: pulled.cursor,
        push: [
          SyncPushItem(
            entityType: 'refrigeration_log',
            entityId: 'remote-out',
            payloadJson:
                '{"id":"remote-out","movement_id":"${checkIn.movementId}","product_id":"${SeedIds.wholeMilk}","product_name_snapshot":"Whole milk","fridge_id":"${SeedIds.kitchenFridge}","event_type":"check_out","temperature_celsius":4,"occurred_at":"2026-10-11T12:00:00.000Z","created_at":"2026-10-11T12:00:00.000Z","origin_device_id":"other-tablet"}',
          ),
        ],
      ),
    );

    expect(hub.current.listening, isTrue);
    expect(pulled.reachable, isTrue);
    expect(
      pulled.changes.map((change) => change.entityId),
      contains(checkIn.id),
    );
    expect(remoteOut.reachable, isTrue);
    expect(remoteOut.conflicts, isNotEmpty);
    final stored = await database.select(database.refrigerationLogs).get();
    expect(stored.map((row) => row.id), contains('remote-out'));
    expect(await logs.watchOpenHoldings().first, isEmpty);
    final alerts = await database.select(database.alerts).get();
    expect(
      alerts.where((row) => row.kind == AlertKind.syncConflict),
      isNotEmpty,
    );

    final denied = await client.post(
      Uri.parse('http://127.0.0.1:${hub.port}/v1/sync'),
      headers: {'authorization': 'Bearer nope'},
      body: '{}',
    );
    expect(denied.statusCode, 401);
  });
}
