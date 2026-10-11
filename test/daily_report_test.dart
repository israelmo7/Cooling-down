import 'package:cooling_down/core/clock.dart';
import 'package:cooling_down/data/db/app_database.dart';
import 'package:cooling_down/data/db/seed_ids.dart';
import 'package:cooling_down/data/reports/daily_report_service.dart';
import 'package:cooling_down/data/repositories/drift_log_repository.dart';
import 'package:cooling_down/data/repositories/drift_settings_repository.dart';
import 'package:cooling_down/domain/reports/daily_report.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('a report is due after the chosen local time until it is sent', () {
    final morning = DateTime(2026, 10, 11, 8);
    final evening = DateTime(2026, 10, 11, 21, 5);

    expect(
      isDailyReportDue(
        enabled: true,
        nowLocal: morning,
        hour: 21,
        minute: 0,
        recordedStatus: null,
      ),
      isFalse,
    );
    expect(
      isDailyReportDue(
        enabled: true,
        nowLocal: evening,
        hour: 21,
        minute: 0,
        recordedStatus: null,
      ),
      isTrue,
    );
    expect(
      isDailyReportDue(
        enabled: false,
        nowLocal: evening,
        hour: 21,
        minute: 0,
        recordedStatus: null,
      ),
      isFalse,
    );
    expect(
      isDailyReportDue(
        enabled: true,
        nowLocal: evening,
        hour: 21,
        minute: 0,
        recordedStatus: ReportStatus.sent,
      ),
      isFalse,
    );
    expect(
      isDailyReportDue(
        enabled: true,
        nowLocal: evening,
        hour: 21,
        minute: 0,
        recordedStatus: ReportStatus.waiting,
      ),
      isTrue,
    );
  });

  test('the report counts the day and writes a conclusion', () {
    final clean = buildDailyReport(
      environmentName: 'Kitchen',
      day: DateTime(2026, 10, 11),
      movements: [
        ReportMovement(
          productName: 'Whole milk',
          eventLabel: 'in',
          temperatureCelsius: 3,
          occurredAt: DateTime.utc(2026, 10, 11, 8),
          fridgeName: 'Kitchen fridge',
        ),
        ReportMovement(
          productName: 'Whole milk',
          eventLabel: 'out',
          temperatureCelsius: 4,
          occurredAt: DateTime.utc(2026, 10, 11, 12),
          fridgeName: 'Kitchen fridge',
        ),
      ],
      stillInside: const [],
      temperatureAlerts: const [],
      conflicts: const [],
    );
    expect(clean.subject, contains('Kitchen'));
    expect(clean.body, contains('1 check-ins'));
    expect(clean.body, contains('1 check-outs'));
    expect(clean.body, contains('closed cleanly'));

    final messy = buildDailyReport(
      environmentName: 'Pharmacy',
      day: DateTime(2026, 10, 11),
      movements: const [],
      stillInside: [
        ReportHolding(
          productName: 'Insulin',
          fridgeName: 'Pharmacy fridge',
          checkedInAt: DateTime.utc(2026, 10, 11, 9),
        ),
      ],
      temperatureAlerts: const [ReportNotice(message: 'Insulin was warm.')],
      conflicts: const [
        ReportNotice(message: 'Insulin was checked out twice.'),
      ],
    );
    expect(messy.body, contains('Conclusion:'));
    expect(messy.body, contains('temperature warning'));
    expect(messy.body, contains('conflict'));
    expect(messy.body, contains('still inside'));
  });

  test('the end-of-day service saves a report from today\'s logs', () async {
    final database = AppDatabase.memory();
    addTearDown(database.close);
    final clock = FixedClock(DateTime(2026, 10, 11, 21, 30));
    final logs = DriftLogRepository(database, clock: clock);
    final settings = DriftSettingsRepository(database);
    await logs.insertCheckIn(
      productId: SeedIds.wholeMilk,
      fridgeId: SeedIds.kitchenFridge,
      temperatureCelsius: 12,
      occurredAt: clock.now().toLocal().subtract(const Duration(hours: 4)),
    );
    final current = await settings.ensure();
    await settings.save(
      current.copyWith(
        ownerEmail: 'owner@example.com',
        dailyReportEnabled: true,
        reportHour: 21,
      ),
    );
    final service = DailyReportService(
      database,
      settings: settings,
      clock: clock,
    );

    final message = await service.deliverToday(manual: false);
    final stored = await service.watchLatest().first;

    expect(message, contains('Saved on this tablet'));
    expect(stored, isNotNull);
    expect(stored!.status, ReportStatus.waiting);
    expect(stored.body, contains('Whole milk'));
    expect(stored.body, contains('Temperature warnings'));
    expect(stored.body, contains('Conclusion:'));
  });
}
