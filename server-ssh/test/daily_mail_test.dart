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
    );

    expect(report.subject, 'דוח קירור · מטבח · 2026-10-11');
    expect(
      report.body,
      contains('מוצר | כמות | איך נקלט | מתי נקלט | איך הוצא | מתי הוצא'),
    );
    expect(
      report.body,
      contains(
        'חזה עוף | 1 | ${_celsius(3.2)} · יוסי · מקרר מטבח | 08:10 | ${_celsius(5.1)} · דנה · מקרר מטבח | 18:40',
      ),
    );
    expect(
      report.body,
      contains(
        'אינסולין | 1 | ${_celsius(4.5)} · יוסי · מקרר תרופות | 10/10 21:05 | ${_celsius(6)} · דנה · מקרר תרופות | 09:30',
      ),
    );
    expect(
      report.body,
      contains(
        'חיסון <מנה> | 1 | ${_celsius(3)} · דנה · מקרר תרופות | 11:00 | - | -',
      ),
    );
    expect(
      report.body,
      contains('חלב | 1 | ${_celsius(4)} · דנה · מקרר מטבח | 15:00 | - | -'),
    );
    expect(report.body, isNot(contains('גבינה')));
    expect(report.body, isNot(contains('12/10')));
    expect(report.body, isNot(contains('הערות')));
    expect(report.body, isNot(contains('מסקנה:')));
    expect(report.body, isNot(contains('חיסון היה חם.')));
    expect(report.body, isNot(contains('תנועות אחרונות שנשמרו')));
    expect(report.html, contains('dir="rtl"'));
    expect(report.html, contains('dir="ltr"'));
    expect(report.html, contains('>10/10 21:05</td>'));
    expect(report.html, contains('<table'));
    expect(report.html, contains('>חלב</td>'));
    expect(report.html, contains('>-</td>'));
    expect(report.html, contains('חיסון &lt;מנה&gt;'));
    expect(report.html, isNot(contains('גבינה')));
    expect(report.html, isNot(contains('הערות')));
  });

  test('the quantity cell shows both amounts when in and out differ', () {
    final report = buildClosedDayReport(
      environmentName: 'מטבח',
      day: DateTime(2026, 10, 11),
      logs: [
        StoredLogLine(
          movementId: 'milk',
          eventType: 'check_in',
          occurredAt: DateTime(2026, 10, 11, 8),
          productName: 'חלב',
          temperature: 4,
          fridgeName: 'מטבח',
          quantity: 5,
        ),
        StoredLogLine(
          movementId: 'milk',
          eventType: 'check_out',
          occurredAt: DateTime(2026, 10, 11, 12),
          productName: 'חלב',
          temperature: 4,
          fridgeName: 'מטבח',
          quantity: 3,
        ),
        StoredLogLine(
          movementId: 'cheese',
          eventType: 'check_in',
          occurredAt: DateTime(2026, 10, 11, 9),
          productName: 'גבינה',
          temperature: 4,
          fridgeName: 'מטבח',
          quantity: 2,
        ),
      ],
    );

    expect(report.body, contains('חלב | נכנס 5 · הוצא 3 |'));
    expect(report.body, contains('גבינה | 2 |'));
    expect(report.html, contains('>נכנס 5 · הוצא 3</td>'));
    expect(report.html, contains('>כמות</th>'));
  });

  test('partial check-outs add up in the quantity cell', () {
    final report = buildClosedDayReport(
      environmentName: 'מטבח',
      day: DateTime(2026, 10, 11),
      logs: [
        StoredLogLine(
          movementId: 'milk',
          eventType: 'check_in',
          occurredAt: DateTime(2026, 10, 11, 8),
          productName: 'חלב',
          temperature: 4,
          fridgeName: 'מטבח',
          quantity: 5,
        ),
        StoredLogLine(
          movementId: 'milk',
          eventType: 'check_out',
          occurredAt: DateTime(2026, 10, 11, 10),
          productName: 'חלב',
          temperature: 4,
          fridgeName: 'מטבח',
          quantity: 2,
        ),
        StoredLogLine(
          movementId: 'milk',
          eventType: 'check_out',
          occurredAt: DateTime(2026, 10, 11, 12),
          productName: 'חלב',
          temperature: 5,
          fridgeName: 'מטבח',
          quantity: 3,
        ),
      ],
    );

    expect(report.body, contains('חלב | 5 |'));
    expect(report.body, isNot(contains('נכנס 5 · הוצא 2')));
  });

  test('an empty day is only the table', () {
    final report = buildClosedDayReport(
      environmentName: 'מטבח',
      day: DateTime(2026, 10, 11),
      logs: const [],
    );

    expect(
      report.body,
      contains('מוצר | כמות | איך נקלט | מתי נקלט | איך הוצא | מתי הוצא'),
    );
    expect(report.body, contains('אין תנועות.'));
    expect(report.html, contains('אין תנועות.'));
    expect(report.body, isNot(contains('מסקנה:')));
    expect(report.body, isNot(contains('הערות')));
  });

  test('a custom file repeats one line per movement', () {
    final report = buildCustomReport(
      template: '''
סביבה: {{environment}}
תאריך: {{date}}
{{rows}}
{{product}} | {{check_in}} | {{check_in_time}} | {{check_out}} | {{check_out_time}}
{{/rows}}
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
    );

    expect(report.body, contains('סביבה: מטבח'));
    expect(report.body, contains('תאריך: 2026-10-11'));
    expect(report.body, contains('חלב |'));
    expect(report.body, contains('גבינה |'));
    expect(report.body, contains('| - | -'));
    expect(report.body, isNot(contains('מסקנה:')));
    expect(report.html, contains('<table'));
    expect(report.html, contains('>חלב</td>'));
    expect(report.html, contains('>גבינה</td>'));
    expect(report.html, contains('>איך נקלט</th>'));
    expect(report.html, isNot(contains('<pre')));
  });

  test('a quiet day does not list older stored actions', () {
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
    );

    expect(report.body, contains('אין תנועות.'));
    expect(report.body, isNot(contains('תנועות אחרונות שנשמרו')));
    expect(report.body, isNot(contains('10/10 08:05 חלב קליטה')));
  });

  test('a supplier delivery report is entry-only with environment first', () {
    final report = buildSupplierPackageReport(
      closedAt: DateTime(2026, 10, 11, 16),
      entries: [
        SupplierEntry(
          environmentName: 'מטבח',
          line: StoredLogLine(
            movementId: 'm1',
            eventType: 'check_in',
            occurredAt: DateTime(2026, 10, 11, 15, 10),
            productName: 'חלב',
            temperature: 4,
            fridgeName: 'מטבח',
            workerName: 'דנה',
            quantity: 2,
          ),
        ),
        SupplierEntry(
          environmentName: 'בר',
          line: StoredLogLine(
            movementId: 'm2',
            eventType: 'check_in',
            occurredAt: DateTime(2026, 10, 11, 15, 20),
            productName: 'גבינה',
            temperature: 5,
            fridgeName: 'בר',
            workerName: 'יוסי',
            quantity: 1,
          ),
        ),
      ],
    );

    expect(report.subject, contains('מצב אספקה'));
    expect(report.body, contains('סביבה | מוצר | כמות | טמפ׳ | מתי | מי'));
    expect(report.body, contains('מטבח | חלב | 2 |'));
    expect(report.body, contains('בר | גבינה | 1 |'));
    expect(report.body, isNot(contains('איך הוצא')));
    expect(report.html, contains('מצב אספקה'));
  });

  test('a sync gap line sits under the table', () {
    final report = buildClosedDayReport(
      environmentName: 'מטבח',
      day: DateTime(2026, 10, 11),
      logs: const [],
      syncGaps: [
        SyncGapNote(
          environmentName: 'מטבח',
          unsynced: const Duration(hours: 3),
        ),
      ],
    );

    expect(report.body, contains('מטבח: לא סונכרן במלואו · כ־3 שעות'));
    expect(report.html, contains('מטבח: לא סונכרן במלואו · כ־3 שעות'));
    expect(formatSyncGapLine(
      const SyncGapNote(
        environmentName: 'בר',
        unsynced: Duration(minutes: 20),
      ),
    ), 'בר: לא סונכרן במלואו · כ־20 דקות');
  });
}
