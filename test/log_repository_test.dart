import 'package:cooling_down/data/db/app_database.dart';
import 'package:cooling_down/data/db/seed_ids.dart';
import 'package:cooling_down/data/repositories/drift_log_repository.dart';
import 'package:cooling_down/domain/entities/refrigeration_log.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase database;
  late DriftLogRepository repository;

  setUp(() {
    database = AppDatabase.memory();
    repository = DriftLogRepository(database);
  });

  tearDown(() => database.close());

  test('check-in then check-out appends two rows for one movement', () async {
    final checkIn = await repository.insertCheckIn(
      productId: SeedIds.wholeMilk,
      fridgeId: SeedIds.kitchenFridge,
      temperatureCelsius: 3,
      occurredAt: DateTime.utc(2026, 10, 11, 8),
    );
    final checkOut = await repository.insertCheckOut(
      movementId: checkIn.movementId,
      temperatureCelsius: 4,
      occurredAt: DateTime.utc(2026, 10, 11, 12),
    );

    final logs = await database.select(database.refrigerationLogs).get();
    expect(logs, hasLength(2));
    expect(checkOut.movementId, checkIn.movementId);
    expect(checkIn.eventType, LogEventType.checkIn);
    expect(checkOut.eventType, LogEventType.checkOut);
    expect(checkIn.id, isNot(checkOut.id));
    expect(await repository.watchOpenHoldings().first, isEmpty);

    final outbox = await database.select(database.syncOutbox).get();
    expect(outbox, hasLength(2));
    expect(outbox.every((row) => row.operation == 'insert'), isTrue);
    expect(
      outbox.every((row) => row.entityType == 'refrigeration_log'),
      isTrue,
    );
  });

  test('updating a refrigeration log is rejected', () async {
    final checkIn = await repository.insertCheckIn(
      productId: SeedIds.insulin,
      fridgeId: SeedIds.pharmacyFridge,
      temperatureCelsius: 5,
    );

    Object? error;
    try {
      await database.customStatement(
        'UPDATE refrigeration_logs SET temperature_celsius = 99 WHERE id = ?',
        [checkIn.id],
      );
    } on Object catch (caught) {
      error = caught;
    }

    expect(error, isNotNull);
    expect(error.toString(), contains('immutable'));
    final stored = await (database.select(
      database.refrigerationLogs,
    )..where((table) => table.id.equals(checkIn.id))).getSingle();
    expect(stored.temperatureCelsius, 5);
  });

  test('an out-of-range temperature stores the log and an alert', () async {
    final checkIn = await repository.insertCheckIn(
      productId: SeedIds.wholeMilk,
      fridgeId: SeedIds.kitchenFridge,
      temperatureCelsius: 12,
    );

    final logs = await database.select(database.refrigerationLogs).get();
    final alerts = await database.select(database.alerts).get();
    final outbox = await database.select(database.syncOutbox).get();

    expect(logs, hasLength(1));
    expect(logs.single.temperatureCelsius, 12);
    expect(alerts, hasLength(1));
    expect(alerts.single.logId, checkIn.id);
    expect(alerts.single.message, contains('Whole milk'));
    expect(outbox, hasLength(2));
    expect(outbox.map((row) => row.entityType).toSet(), {
      'refrigeration_log',
      'alert',
    });
  });

  test('an in-range check-in enqueues one outbox row', () async {
    await repository.insertCheckIn(
      productId: SeedIds.vaccine,
      fridgeId: SeedIds.pharmacyFridge,
      temperatureCelsius: 4,
    );

    final outbox = await database.select(database.syncOutbox).get();
    expect(outbox, hasLength(1));
    expect(outbox.single.status.name, 'pending');
    expect(outbox.single.attemptCount, 0);
  });
}
