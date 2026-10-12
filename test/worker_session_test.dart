import 'package:cooling_down/data/db/app_database.dart';
import 'package:cooling_down/data/db/seed_ids.dart';
import 'package:cooling_down/data/repositories/drift_log_repository.dart';
import 'package:cooling_down/data/repositories/drift_worker_repository.dart';
import 'package:cooling_down/domain/settings/device_settings.dart';
import 'package:cooling_down/domain/workers/worker_session.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('a worker stays active for ten minutes', () {
    final at = DateTime.utc(2026, 10, 12, 8);
    final session = WorkerSession(
      workerId: 'worker-1',
      workerName: 'דנה',
      activeAt: at,
    );
    expect(session.isActive(at.add(const Duration(minutes: 9))), isTrue);
    expect(session.isActive(at.add(defaultWorkerIdleLimit)), isFalse);
    expect(const WorkerSession().isActive(at), isFalse);
    const idle = Duration(seconds: 30);
    expect(
      session.isActive(at.add(const Duration(seconds: 29)), idle: idle),
      isTrue,
    );
    expect(session.isActive(at.add(idle), idle: idle), isFalse);
    expect(normalizeWorkerIdleSeconds(''), defaultWorkerIdleSeconds);
    expect(normalizeWorkerIdleSeconds('45'), 45);
    expect(normalizeWorkerIdleSeconds('999999'), 86400);
  });

  test('check-in stores the worker name that was active', () async {
    final database = AppDatabase.memory();
    addTearDown(database.close);
    final workers = DriftWorkerRepository(database);
    final logs = DriftLogRepository(database);
    final worker = await workers.addWorker('דנה');
    await workers.selectWorker(worker!.id, at: DateTime.utc(2026, 10, 12, 8));

    final checkIn = await logs.insertCheckIn(
      productId: SeedIds.wholeMilk,
      fridgeId: SeedIds.kitchenFridge,
      temperatureCelsius: 3,
      workerName: 'דנה',
    );
    final checkOut = await logs.insertCheckOut(
      movementId: checkIn.movementId,
      temperatureCelsius: 4,
      workerName: 'יוסי',
    );

    expect(checkIn.workerNameSnapshot, 'דנה');
    expect(checkOut.workerNameSnapshot, 'יוסי');
    final outbox = await database.select(database.syncOutbox).get();
    expect(outbox.first.payloadJson, contains('דנה'));

    await workers.deleteWorker(worker.id);
    final session = await workers.readSession();
    expect(session.workerId, isNull);
    final stored = await database.select(database.refrigerationLogs).get();
    expect(stored.first.workerNameSnapshot, 'דנה');
  });
}
