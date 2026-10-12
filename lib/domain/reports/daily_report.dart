/// Status stored for one environment on one local calendar day.
abstract final class ReportStatus {
  static const waiting = 'waiting';
  static const sent = 'sent';
  static const alreadySent = 'already_sent';
  static const stored = 'stored';
  static const failed = 'failed';
}

class ReportMovement {
  const ReportMovement({
    required this.productName,
    required this.eventLabel,
    required this.temperatureCelsius,
    required this.occurredAt,
    required this.fridgeName,
  });

  final String productName;
  final String eventLabel;
  final double temperatureCelsius;
  final DateTime occurredAt;
  final String fridgeName;
}

class ReportHolding {
  const ReportHolding({
    required this.productName,
    required this.fridgeName,
    required this.checkedInAt,
  });

  final String productName;
  final String fridgeName;
  final DateTime checkedInAt;
}

class ReportNotice {
  const ReportNotice({required this.message});

  final String message;
}

class DailyReportContent {
  const DailyReportContent({required this.subject, required this.body});

  final String subject;
  final String body;
}

class StoredDailyReport {
  const StoredDailyReport({
    required this.id,
    required this.environmentName,
    required this.reportDate,
    required this.ownerEmail,
    required this.subject,
    required this.body,
    required this.status,
    required this.createdAt,
    this.sentAt,
    this.lastError,
  });

  final String id;
  final String environmentName;
  final String reportDate;
  final String ownerEmail;
  final String subject;
  final String body;
  final String status;
  final DateTime createdAt;
  final DateTime? sentAt;
  final String? lastError;
}

/// Calendar day key from a date whose year, month, and day are already local.
String reportDateKey(DateTime localDay) {
  final year = localDay.year.toString().padLeft(4, '0');
  final month = localDay.month.toString().padLeft(2, '0');
  final day = localDay.day.toString().padLeft(2, '0');
  return '$year-$month-$day';
}

String formatReportClock(DateTime instant) {
  final local = instant.toLocal();
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}

/// The calendar day that closed at the most recent local midnight.
DateTime closedReportDay(DateTime nowLocal) {
  final startOfToday = DateTime(nowLocal.year, nowLocal.month, nowLocal.day);
  return startOfToday.subtract(const Duration(days: 1));
}

/// Due after the configured local time, until the report is emailed or stored.
/// At 00:00 the report covers [closedReportDay] and stays due until it is sent.
bool isDailyReportDue({
  required bool enabled,
  required DateTime nowLocal,
  required int hour,
  required int minute,
  required String? recordedStatus,
}) {
  if (!enabled) {
    return false;
  }
  final dueAt = DateTime(
    nowLocal.year,
    nowLocal.month,
    nowLocal.day,
    hour,
    minute,
  );
  if (nowLocal.isBefore(dueAt)) {
    return false;
  }
  return recordedStatus == null ||
      recordedStatus == ReportStatus.waiting ||
      recordedStatus == ReportStatus.failed;
}

DailyReportContent buildDailyReport({
  required String environmentName,
  required DateTime day,
  required List<ReportMovement> movements,
  required List<ReportHolding> stillInside,
  required List<ReportNotice> temperatureAlerts,
  required List<ReportNotice> conflicts,
}) {
  final date = reportDateKey(day);
  final checkIns = movements.where((row) => row.eventLabel == 'in').length;
  final checkOuts = movements.where((row) => row.eventLabel == 'out').length;
  final buffer = StringBuffer()
    ..writeln('סביבה: $environmentName')
    ..writeln('תאריך: $date')
    ..writeln()
    ..writeln('מה קרה')
    ..writeln('- $checkIns קליטות')
    ..writeln('- $checkOuts הוצאות');

  _writeList(
    buffer,
    title: 'תנועות',
    lines: [
      for (final row in movements)
        '${formatReportClock(row.occurredAt)} ${row.productName} ${_eventWord(row.eventLabel)} ב-${row.temperatureCelsius.toStringAsFixed(1)}°C (${row.fridgeName})',
    ],
  );
  _writeList(
    buffer,
    title: 'עדיין במקרר',
    lines: [
      for (final row in stillInside)
        '${row.productName} ב${row.fridgeName} מאז ${formatReportClock(row.checkedInAt)}',
    ],
    empty: 'אין פריטים שנשארו במקרר.',
  );
  _writeList(
    buffer,
    title: 'אזהרות טמפרטורה',
    lines: [for (final row in temperatureAlerts) row.message],
    empty: 'אין אזהרות טמפרטורה.',
  );
  _writeList(
    buffer,
    title: 'קונפליקטים',
    lines: [for (final row in conflicts) row.message],
    empty: 'אין קונפליקטים.',
  );
  buffer
    ..writeln()
    ..write(
      _conclusion(
        checkIns: checkIns,
        checkOuts: checkOuts,
        stillInside: stillInside.length,
        temperatureAlerts: temperatureAlerts.length,
        conflicts: conflicts.length,
      ),
    );

  return DailyReportContent(
    subject: 'דוח קירור · $environmentName · $date',
    body: buffer.toString(),
  );
}

void _writeList(
  StringBuffer buffer, {
  required String title,
  required List<String> lines,
  String? empty,
}) {
  buffer
    ..writeln()
    ..writeln(title);
  if (lines.isEmpty && empty != null) {
    buffer.writeln(empty);
    return;
  }
  final shown = lines.take(20);
  for (final line in shown) {
    buffer.writeln('- $line');
  }
  if (lines.length > 20) {
    buffer.writeln('- ועוד ${lines.length - 20}');
  }
}

String _conclusion({
  required int checkIns,
  required int checkOuts,
  required int stillInside,
  required int temperatureAlerts,
  required int conflicts,
}) {
  if (temperatureAlerts == 0 && conflicts == 0 && stillInside == 0) {
    return 'מסקנה: היום נסגר בצורה תקינה. הטמפרטורות היו בטווח, כל ההוצאות תאמו, ואין פריטים שנשארו במקרר ($checkIns קליטות, $checkOuts הוצאות).';
  }
  final parts = <String>[
    if (temperatureAlerts > 0)
      temperatureAlerts == 1
          ? 'אזהרת טמפרטורה אחת דורשת בדיקה'
          : '$temperatureAlerts אזהרות טמפרטורה דורשות בדיקה',
    if (conflicts > 0)
      conflicts == 1
          ? 'קונפליקט אחד שמר את שתי הטמפרטורות; ההוצאה המוקדמת סגרה את הפריט'
          : '$conflicts קונפליקטים שמרו את שתי הטמפרטורות; ההוצאה המוקדמת סגרה את הפריט',
    if (stillInside > 0)
      stillInside == 1
          ? 'פריט אחד עדיין במקרר'
          : '$stillInside פריטים עדיין במקרר',
  ];
  return 'מסקנה: ${parts.join('; ')}.';
}

String _eventWord(String eventLabel) {
  return eventLabel == 'in' ? 'נכנס' : 'יצא';
}
