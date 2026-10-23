import 'package:cooling_down/domain/hold_for.dart';
import 'package:cooling_down/domain/quantity.dart';
import 'package:cooling_down/data/db/app_database.dart';
import 'package:cooling_down/data/db/seed_ids.dart';
import 'package:cooling_down/data/repositories/drift_log_repository.dart';
import 'package:cooling_down/domain/entities/refrigeration_log.dart';
import 'package:cooling_down/domain/failures.dart';
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
      workerName: 'דנה',
    );
    final checkOut = await repository.insertCheckOut(
      movementId: checkIn.movementId,
      temperatureCelsius: 4,
      occurredAt: DateTime.utc(2026, 10, 11, 12),
      workerName: 'דנה',
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
      fridgeId: SeedIds.kitchenFridge,
      temperatureCelsius: 5,
      workerName: 'דנה',
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

  test('an out-of-range temperature is stored without a warning', () async {
    await repository.insertCheckIn(
      productId: SeedIds.wholeMilk,
      fridgeId: SeedIds.kitchenFridge,
      temperatureCelsius: 12,
      workerName: 'דנה',
    );

    final logs = await database.select(database.refrigerationLogs).get();
    final alerts = await database.select(database.alerts).get();
    final outbox = await database.select(database.syncOutbox).get();

    expect(logs, hasLength(1));
    expect(logs.single.temperatureCelsius, 12);
    expect(alerts, isEmpty);
    expect(outbox, hasLength(1));
    expect(outbox.single.entityType, 'refrigeration_log');
  });

  test('a product starts from the average of its check-ins', () async {
    await repository.insertCheckIn(
      productId: SeedIds.wholeMilk,
      fridgeId: SeedIds.kitchenFridge,
      temperatureCelsius: 2,
      workerName: 'דנה',
    );
    await repository.insertCheckIn(
      productId: SeedIds.wholeMilk,
      fridgeId: SeedIds.kitchenFridge,
      temperatureCelsius: 4,
      workerName: 'דנה',
    );

    expect(await repository.averageCheckInCelsius(SeedIds.wholeMilk), 3);
    expect(
      await repository.averageCheckInCelsius(SeedIds.chickenBreast),
      isNull,
    );
  });

  test('a come-out time stays on the open item', () async {
    final due = DateTime.utc(2026, 10, 20, 16);
    final checkIn = await repository.insertCheckIn(
      productId: SeedIds.wholeMilk,
      fridgeId: SeedIds.kitchenFridge,
      temperatureCelsius: 3,
      workerName: 'דנה',
      dueAt: due,
    );

    final open = await repository.watchOpenHoldings().first;
    expect(open.single.dueAt?.isAtSameMomentAs(due), isTrue);
    expect(checkIn.dueAt?.isAtSameMomentAs(due), isTrue);
  });

  test('a check-in without a worker is rejected', () async {
    Object? error;
    try {
      await repository.insertCheckIn(
        productId: SeedIds.wholeMilk,
        fridgeId: SeedIds.kitchenFridge,
        temperatureCelsius: 3,
        workerName: '   ',
      );
    } on Object catch (caught) {
      error = caught;
    }
    expect(error, isA<CatalogEntryNotFound>());
    expect(await database.select(database.refrigerationLogs).get(), isEmpty);
  });

  test('an in-range check-in enqueues one outbox row', () async {
    await repository.insertCheckIn(
      productId: SeedIds.vaccine,
      fridgeId: SeedIds.kitchenFridge,
      temperatureCelsius: 4,
      workerName: 'דנה',
    );

    final outbox = await database.select(database.syncOutbox).get();
    expect(outbox, hasLength(1));
    expect(outbox.single.status.name, 'pending');
    expect(outbox.single.attemptCount, 0);
  });

  test('quantity is stored on both events and on the open item', () async {
    final checkIn = await repository.insertCheckIn(
      productId: SeedIds.wholeMilk,
      fridgeId: SeedIds.kitchenFridge,
      temperatureCelsius: 3,
      workerName: 'דנה',
      quantity: 5,
    );
    expect(checkIn.quantity, 5);

    var open = await repository.watchOpenHoldings().first;
    expect(open.single.quantity, 5);
    expect(open.single.checkedInQuantity, 5);

    // A partial check-out leaves the rest inside.
    final checkOut = await repository.insertCheckOut(
      movementId: checkIn.movementId,
      temperatureCelsius: 4,
      workerName: 'דנה',
      quantity: 3,
    );
    expect(checkOut.quantity, 3);
    open = await repository.watchOpenHoldings().first;
    expect(open.single.quantity, 2);
    expect(open.single.checkedInQuantity, 5);

    await repository.insertCheckOut(
      movementId: checkIn.movementId,
      temperatureCelsius: 4,
      workerName: 'דנה',
      quantity: 2,
    );
    expect(await repository.watchOpenHoldings().first, isEmpty);

    final outbox = await database.select(database.syncOutbox).get();
    expect(outbox.length, 3);
    expect(outbox.first.payloadJson, contains('"quantity":5'));
    expect(outbox[1].payloadJson, contains('"quantity":3'));
    expect(outbox.last.payloadJson, contains('"quantity":2'));

    expect(tryParseQuantity(''), isNull);
    expect(tryParseQuantity('0'), isNull);
    expect(tryParseQuantity('-1'), isNull);
    expect(tryParseQuantity('7'), 7);
    expect(tryParseQuantity('abc'), isNull);
    expect(tryParseQuantity('10000'), isNull);
    expect(tryParseQuantity('9999'), 9999);
  });

  test(
    'an invalid quantity or temperature is rejected, not corrected',
    () async {
      Future<Object?> errorOf(Future<dynamic> Function() action) async {
        try {
          await action();
        } on Object catch (error) {
          return error;
        }
        return null;
      }

      expect(
        await errorOf(
          () => repository.insertCheckIn(
            productId: SeedIds.wholeMilk,
            fridgeId: SeedIds.kitchenFridge,
            temperatureCelsius: 3,
            workerName: 'דנה',
            quantity: 0,
          ),
        ),
        isA<InvalidQuantityException>(),
      );
      expect(
        await errorOf(
          () => repository.insertCheckIn(
            productId: SeedIds.wholeMilk,
            fridgeId: SeedIds.kitchenFridge,
            temperatureCelsius: 3,
            workerName: 'דנה',
            quantity: 10000,
          ),
        ),
        isA<InvalidQuantityException>(),
      );
      expect(
        await errorOf(
          () => repository.insertCheckIn(
            productId: SeedIds.wholeMilk,
            fridgeId: SeedIds.kitchenFridge,
            temperatureCelsius: 999,
            workerName: 'דנה',
          ),
        ),
        isA<CatalogEntryNotFound>(),
      );
      expect(await database.select(database.refrigerationLogs).get(), isEmpty);

      final checkIn = await repository.insertCheckIn(
        productId: SeedIds.wholeMilk,
        fridgeId: SeedIds.kitchenFridge,
        temperatureCelsius: 3,
        workerName: 'דנה',
        quantity: 3,
      );
      // More than what is inside, and zero, are both refused. Nothing extra
      // is written for either attempt.
      expect(
        await errorOf(
          () => repository.insertCheckOut(
            movementId: checkIn.movementId,
            temperatureCelsius: 4,
            workerName: 'דנה',
            quantity: 1000,
          ),
        ),
        isA<InvalidQuantityException>(),
      );
      expect(
        await errorOf(
          () => repository.insertCheckOut(
            movementId: checkIn.movementId,
            temperatureCelsius: 4,
            workerName: 'דנה',
            quantity: 0,
          ),
        ),
        isA<InvalidQuantityException>(),
      );
      final logs = await database.select(database.refrigerationLogs).get();
      expect(logs, hasLength(1));
      final open = await repository.watchOpenHoldings().first;
      expect(open.single.quantity, 3);
    },
  );

  test('come-out hours accept a half hour and ignore empty text', () {
    expect(isValidHoldHoursInput(''), isTrue);
    expect(isValidHoldHoursInput('0.5'), isTrue);
    expect(isValidHoldHoursInput('72'), isTrue);
    expect(isValidHoldHoursInput('0'), isFalse);
    expect(isValidHoldHoursInput('-1'), isFalse);
    expect(isValidHoldHoursInput('73'), isFalse);
    expect(isValidHoldHoursInput('abc'), isFalse);
    expect(parseHoldHours(''), isNull);
    expect(parseHoldHours('0'), isNull);
    expect(parseHoldHours('0.5'), 0.5);
    expect(parseHoldHours('2,5'), 2.5);
    final due = dueAfter(DateTime.utc(2026, 10, 20, 12), 0.5);
    expect(due, DateTime.utc(2026, 10, 20, 12, 30));
  });
}
