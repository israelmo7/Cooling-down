import 'package:cooling_down_server/daily_mail.dart';
import 'package:test/test.dart';

void main() {
  test('pairs check-in with check-out and leaves an open item as a dash', () {
    final report = buildClosedDayReport(
      environmentName: 'מטבח',
      day: DateTime(2026, 10, 11),
      logs: [
        StoredLogLine(
          movementId: 'milk',
          eventType: 'check_in',
          occurredAt: DateTime(2026, 10, 11, 15),
          productName: 'חלב',
          temperature: 4,
          fridgeName: 'מקרר מטבח',
          workerName: 'דנה',
        ),
        StoredLogLine(
          movementId: 'chicken',
          eventType: 'check_in',
          occurredAt: DateTime(2026, 10, 11, 8, 10),
          productName: 'חזה עוף',
          temperature: 3.2,
          fridgeName: 'מקרר מטבח',
          workerName: 'יוסי',
        ),
        StoredLogLine(
          movementId: 'chicken',
          eventType: 'check_out',
          occurredAt: DateTime(2026, 10, 11, 18, 40),
          productName: 'חזה עוף',
          temperature: 5.1,
          fridgeName: 'מקרר מטבח',
          workerName: 'דנה',
        ),
        StoredLogLine(
          movementId: 'insulin',
          eventType: 'check_in',
          occurredAt: DateTime(2026, 10, 10, 21, 5),
          productName: 'אינסולין',
          temperature: 4.5,
          fridgeName: 'מקרר תרופות',
          workerName: 'יוסי',
        ),
        StoredLogLine(
          movementId: 'insulin',
          eventType: 'check_out',
          occurredAt: DateTime(2026, 10, 11, 9, 30),
          productName: 'אינסולין',
          temperature: 6,
          fridgeName: 'מקרר תרופות',
          workerName: 'דנה',
        ),
        StoredLogLine(
          movementId: 'vaccine',
          eventType: 'check_in',
          occurredAt: DateTime(2026, 10, 11, 11),
          productName: 'חיסון <מנה>',
          temperature: 3,
          fridgeName: 'מקרר תרופות',
          workerName: 'דנה',
        ),
        StoredLogLine(
          movementId: 'vaccine',
          eventType: 'check_out',
          occurredAt: DateTime(2026, 10, 12, 9),
          productName: 'חיסון <מנה>',
          temperature: 3,
          fridgeName: 'מקרר תרופות',
          workerName: 'דנה',
        ),
        StoredLogLine(
          movementId: 'cheese',
          eventType: 'check_in',
          occurredAt: DateTime(2026, 10, 10, 8),
          productName: 'גבינה',
          temperature: 4,
          fridgeName: 'מקרר מטבח',
          workerName: 'יוסי',
        ),
        StoredLogLine(
          movementId: 'cheese',
          eventType: 'check_out',
          occurredAt: DateTime(2026, 10, 10, 12),
          productName: 'גבינה',
          temperature: 4,
          fridgeName: 'מקרר מטבח',
          workerName: 'יוסי',
        ),
      ],
      notices: [
        StoredNotice(
          message: 'חיסון היה חם.',
          createdAt: DateTime(2026, 10, 11, 11, 5),
        ),
      ],
    );

    expect(report.subject, 'דוח קירור · מטבח · 2026-10-11');
    expect(
      report.body,
      contains('מוצר | איך נקלט | מתי נקלט | איך הוצא | מתי הוצא'),
    );
    expect(
      report.body,
      contains(
        'חזה עוף | 3.2°C · יוסי · מקרר מטבח | 08:10 | 5.1°C · דנה · מקרר מטבח | 18:40',
      ),
    );
    expect(
      report.body,
      contains(
        'אינסולין | 4.5°C · יוסי · מקרר תרופות | 10/10 21:05 | 6.0°C · דנה · מקרר תרופות | 09:30',
      ),
    );
    expect(
      report.body,
      contains('חיסון <מנה> | 3.0°C · דנה · מקרר תרופות | 11:00 | - | -'),
    );
    expect(
      report.body,
      contains('חלב | 4.0°C · דנה · מקרר מטבח | 15:00 | - | -'),
    );
    expect(report.body, isNot(contains('גבינה')));
    expect(report.body, isNot(contains('12/10')));
    expect(report.body, contains('חיסון היה חם.'));
    expect(report.body, contains('מסקנה:'));
    expect(report.html, contains('dir="rtl"'));
    expect(report.html, contains('dir="ltr"'));
    expect(report.html, contains('>10/10 21:05</td>'));
    expect(report.html, contains('<table'));
    expect(report.html, contains('>חלב</td>'));
    expect(report.html, contains('>-</td>'));
    expect(report.html, contains('חיסון &lt;מנה&gt;'));
    expect(report.html, isNot(contains('גבינה')));
  });

  test('an empty day still shows the table and a dash is not invented', () {
    final report = buildClosedDayReport(
      environmentName: 'מטבח',
      day: DateTime(2026, 10, 11),
      logs: const [],
      notices: const [],
    );

    expect(
      report.body,
      contains('מוצר | איך נקלט | מתי נקלט | איך הוצא | מתי הוצא'),
    );
    expect(report.body, contains('אין תנועות.'));
    expect(report.html, contains('אין תנועות.'));
    expect(report.body, contains('מסקנה:'));
  });
}
