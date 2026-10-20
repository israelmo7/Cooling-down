import 'package:cooling_down_server/daily_mail.dart';
import 'package:test/test.dart';

String _celsius(num degrees) => '\u2066${degrees.toStringAsFixed(1)}°C\u2069';

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
        'חזה עוף | ${_celsius(3.2)} · יוסי · מקרר מטבח | 08:10 | ${_celsius(5.1)} · דנה · מקרר מטבח | 18:40',
      ),
    );
    expect(
      report.body,
      contains(
        'אינסולין | ${_celsius(4.5)} · יוסי · מקרר תרופות | 10/10 21:05 | ${_celsius(6)} · דנה · מקרר תרופות | 09:30',
      ),
    );
    expect(
      report.body,
      contains(
        'חיסון <מנה> | ${_celsius(3)} · דנה · מקרר תרופות | 11:00 | - | -',
      ),
    );
    expect(
      report.body,
      contains('חלב | ${_celsius(4)} · דנה · מקרר מטבח | 15:00 | - | -'),
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

  test('a custom file repeats one line per movement', () {
    final report = buildCustomReport(
      template: '''
סביבה: {{environment}}
תאריך: {{date}}
{{rows}}
{{product}} | {{check_in}} | {{check_in_time}} | {{check_out}} | {{check_out_time}}
{{/rows}}
{{notes}}
{{conclusion}}
''',
      environmentName: 'מטבח',
      day: DateTime(2026, 10, 11),
      logs: [
        StoredLogLine(
          movementId: 'milk',
          eventType: 'check_in',
          occurredAt: DateTime(2026, 10, 11, 15),
          productName: 'חלב',
          temperature: 4,
          fridgeName: 'מטבח',
          workerName: 'דנה',
        ),
        StoredLogLine(
          movementId: 'open',
          eventType: 'check_in',
          occurredAt: DateTime(2026, 10, 11, 9),
          productName: 'גבינה',
          temperature: 3,
          fridgeName: 'מטבח',
          workerName: 'יוסי',
        ),
      ],
      notices: const [],
    );

    expect(report.body, contains('סביבה: מטבח'));
    expect(report.body, contains('תאריך: 2026-10-11'));
    expect(report.body, contains('חלב |'));
    expect(report.body, contains('גבינה |'));
    expect(report.body, contains('| - | -'));
    expect(report.body, contains('מסקנה:'));
    expect(report.html, contains('<table'));
    expect(report.html, contains('>חלב</td>'));
    expect(report.html, contains('>גבינה</td>'));
    expect(report.html, contains('>איך נקלט</th>'));
    expect(report.html, isNot(contains('<pre')));
  });

  test('a quiet day still names the actions already stored', () {
    final report = buildClosedDayReport(
      environmentName: 'מטבח',
      day: DateTime(2026, 10, 11),
      logs: [
        StoredLogLine(
          movementId: 'milk',
          eventType: 'check_in',
          occurredAt: DateTime(2026, 10, 10, 8, 5),
          productName: 'חלב',
          temperature: 4,
          fridgeName: 'מקרר מטבח',
          workerName: 'דנה',
        ),
      ],
      notices: const [],
    );

    expect(report.body, contains('אין תנועות.'));
    expect(report.body, contains('תנועות אחרונות שנשמרו'));
    expect(report.body, contains('10/10 08:05 חלב קליטה'));
    expect(report.html, contains('חלב'));
    expect(report.html, contains('קליטה'));
  });

  test('the stored-action list stops after thirty lines', () {
    final report = buildClosedDayReport(
      environmentName: 'מטבח',
      day: DateTime(2026, 10, 11),
      logs: [
        for (var index = 0; index < 31; index++)
          StoredLogLine(
            movementId: 'move-$index',
            eventType: 'check_in',
            occurredAt: DateTime(2026, 10, 1, 8, index),
            productName: 'מוצר $index',
            temperature: 4,
            fridgeName: 'מטבח',
          ),
      ],
      notices: const [],
    );

    expect(report.body, contains('מוצר 30'));
    expect(report.body, isNot(contains('מוצר 0')));
    expect(report.body, contains('מוצגות 30 התנועות האחרונות מתוך 31.'));
  });
}
