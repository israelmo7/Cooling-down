import 'package:cooling_down/data/db/app_database.dart';
import 'package:cooling_down/data/db/seed_ids.dart';
import 'package:cooling_down/data/repositories/drift_log_repository.dart';
import 'package:cooling_down/data/repositories/drift_worker_repository.dart';
import 'package:cooling_down/domain/settings/device_settings.dart';
import 'package:cooling_down/domain/workers/worker_refresh.dart';
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

  test('periodic refresh asks from 08:00 every 8 hours until 20:00', () {
    const refresh = WorkerRefresh(
      mode: WorkerRefreshMode.periodic,
      style: WorkerPromptStyle.popup,
      startMinute: 8 * 60,
      intervalHours: 8,
      endMinute: 20 * 60,
    );
    final day = DateTime(2026, 10, 12);
    final before = day.add(const Duration(hours: 7, minutes: 59));
    final atEight = day.add(const Duration(hours: 8));
    final afternoon = day.add(const Duration(hours: 15));
    final atFour = day.add(const Duration(hours: 16));
    final atEightPm = day.add(const Duration(hours: 20));
    final after = day.add(const Duration(hours: 20, minutes: 1));
    final pickedAtEight = WorkerSession(
      workerId: 'worker-1',
      workerName: 'דנה',
      activeAt: atEight,
    );

    expect(refresh.latestSlot(before), isNull);
    expect(refresh.isDue(atEight, pickedAtEight), isFalse);
    expect(refresh.latestSlot(afternoon), atEight);
    expect(refresh.isDue(afternoon, pickedAtEight), isFalse);
    expect(refresh.latestSlot(atFour), atFour);
    expect(refresh.isDue(atFour, pickedAtEight), isTrue);
    expect(refresh.isDue(atEightPm, pickedAtEight), isTrue);
    expect(refresh.latestSlot(after), isNull);
    expect(refresh.allowsAction(pickedAtEight, after), isTrue);

    const off = WorkerRefresh(mode: WorkerRefreshMode.off);
    final stale = WorkerSession(
      workerId: 'worker-1',
      workerName: 'דנה',
      activeAt: atEight.subtract(const Duration(days: 1)),
    );
    expect(off.isDue(afternoon, stale), isFalse);
    expect(off.allowsAction(stale, afternoon), isTrue);
    expect(off.allowsAction(const WorkerSession(), afternoon), isFalse);
    expect(parseClockMinutes('0800'), 8 * 60);
    expect(parseClockMinutes('20:00'), 20 * 60);
  });

  test('08:00 until 08:00 stays open through the evening', () {
    const refresh = WorkerRefresh(
      mode: WorkerRefreshMode.periodic,
      startMinute: 8 * 60,
      intervalHours: 24,
      endMinute: 8 * 60,
    );
    final day = DateTime(2026, 10, 12);
    final atEight = day.add(const Duration(hours: 8));
    final evening = day.add(const Duration(hours: 19));
    final signedInBefore = WorkerSession(
      workerId: 'worker-1',
      workerName: 'דנה',
      activeAt: day.add(const Duration(hours: 7)),
    );
    final signedInAfter = WorkerSession(
      workerId: 'worker-1',
      workerName: 'דנה',
      activeAt: day.add(const Duration(hours: 10)),
    );

    expect(refresh.latestSlot(evening), atEight);
    expect(refresh.isDue(evening, signedInBefore), isTrue);
    expect(refresh.isDue(evening, signedInAfter), isFalse);
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
