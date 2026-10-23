import 'package:cooling_down/core/clock.dart';
import 'package:cooling_down/data/db/app_database.dart';
import 'package:cooling_down/data/db/seed_ids.dart';
import 'package:cooling_down/data/reports/daily_report_service.dart';
import 'package:cooling_down/data/repositories/drift_log_repository.dart';
import 'package:cooling_down/data/repositories/drift_settings_repository.dart';
import 'package:cooling_down/domain/reports/daily_report.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('a midnight report is due for the day that just closed', () {
    final justAfterMidnight = DateTime(2026, 10, 12, 0, 1);
    expect(closedReportDay(justAfterMidnight), DateTime(2026, 10, 11));
    expect(
      isDailyReportDue(
        enabled: true,
        nowLocal: justAfterMidnight,
        hour: 0,
        minute: 0,
        recordedStatus: null,
      ),
      isTrue,
    );
    expect(
      isDailyReportDue(
        enabled: false,
        nowLocal: justAfterMidnight,
        hour: 0,
        minute: 0,
        recordedStatus: null,
      ),
      isFalse,
    );
    expect(
      isDailyReportDue(
        enabled: true,
        nowLocal: justAfterMidnight,
        hour: 0,
        minute: 0,
        recordedStatus: ReportStatus.sent,
      ),
      isFalse,
    );
    expect(
      isDailyReportDue(
        enabled: true,
        nowLocal: DateTime(2026, 10, 12, 8),
        hour: 21,
        minute: 0,
        recordedStatus: null,
      ),
      isFalse,
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
          quantity: 4,
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
    expect(clean.body, contains('1 קליטות'));
    expect(clean.body, contains('1 הוצאות'));
    expect(clean.body, contains('כמות 4'));
    expect(clean.body, contains('כמות 1'));
    expect(clean.body, contains('נסגר בצורה תקינה'));

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
    expect(messy.body, contains('מסקנה:'));
    expect(messy.body, contains('אזהרת טמפרטורה'));
    expect(messy.body, contains('קונפליקט'));
    expect(messy.body, contains('עדיין במקרר'));
  });

  test('midnight saves a report for the day that just closed', () async {
    final database = AppDatabase.memory();
    addTearDown(database.close);
    final clock = FixedClock(DateTime(2026, 10, 12, 0, 5));
    final logs = DriftLogRepository(database, clock: clock);
    final settings = DriftSettingsRepository(database);
    await logs.insertCheckIn(
      productId: SeedIds.wholeMilk,
      fridgeId: SeedIds.kitchenFridge,
      temperatureCelsius: 12,
      occurredAt: DateTime(2026, 10, 11, 18),
      workerName: 'דנה',
    );
    final current = await settings.ensure();
    await settings.save(
      current.copyWith(
        ownerEmail: 'owner@example.com',
        dailyReportEnabled: true,
        reportHour: 0,
        reportMinute: 0,
      ),
    );
    final service = DailyReportService(
      database,
      settings: settings,
      clock: clock,
    );

    final message = await service.deliverToday(manual: false);
    final stored = await service.watchLatest().first;

    expect(message, contains('נשמר בטאבלט'));
    expect(stored, isNotNull);
    expect(stored!.reportDate, '2026-10-11');
    expect(stored.status, ReportStatus.waiting);
    expect(stored.body, contains('חלב'));
    expect(stored.body, contains('דנה'));
    expect(stored.body, contains('אזהרות טמפרטורה'));
    expect(stored.body, contains('מסקנה:'));
  });
}
