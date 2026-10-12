/// Hebrew end-of-day mail built from the logs the shop computer already stored.
class ClosedDayReport {
  const ClosedDayReport({required this.subject, required this.body});

  final String subject;
  final String body;
}

class StoredLogLine {
  const StoredLogLine({
    required this.eventType,
    required this.occurredAt,
    required this.productName,
    required this.temperature,
    required this.fridgeName,
    this.workerName = '',
  });

  final String eventType;
  final DateTime occurredAt;
  final String productName;
  final double? temperature;
  final String fridgeName;
  final String workerName;
}

class StoredNotice {
  const StoredNotice({required this.message, required this.createdAt});

  final String message;
  final DateTime createdAt;
}

ClosedDayReport buildClosedDayReport({
  required String environmentName,
  required DateTime day,
  required List<StoredLogLine> logs,
  required List<StoredNotice> notices,
}) {
  final date = _dateKey(day);
  final dayLogs = logs.where((row) => _sameDay(row.occurredAt, day)).toList()
    ..sort((a, b) => a.occurredAt.compareTo(b.occurredAt));
  final dayNotices = notices
      .where((row) => _sameDay(row.createdAt, day))
      .toList();
  final checkIns = dayLogs.where((row) => row.eventType == 'check_in').length;
  final checkOuts = dayLogs.where((row) => row.eventType == 'check_out').length;
  final buffer = StringBuffer()
    ..writeln('סביבה: $environmentName')
    ..writeln('תאריך: $date')
    ..writeln()
    ..writeln('מה קרה')
    ..writeln('- $checkIns קליטות')
    ..writeln('- $checkOuts הוצאות')
    ..writeln()
    ..writeln('תנועות');
  if (dayLogs.isEmpty) {
    buffer.writeln('אין תנועות.');
  } else {
    for (final row in dayLogs.take(20)) {
      final word = row.eventType == 'check_in' ? 'נכנס' : 'יצא';
      final temperature = row.temperature == null
          ? ''
          : ' ב-${row.temperature!.toStringAsFixed(1)}°C';
      final fridge = row.fridgeName.isEmpty ? '' : ' (${row.fridgeName})';
      final worker = row.workerName.trim().isEmpty
          ? ''
          : ' · ${row.workerName.trim()}';
      buffer.writeln(
        '- ${_clock(row.occurredAt)} ${row.productName} $word$temperature$fridge$worker',
      );
    }
    if (dayLogs.length > 20) {
      buffer.writeln('- ועוד ${dayLogs.length - 20}');
    }
  }
  buffer
    ..writeln()
    ..writeln('הערות');
  if (dayNotices.isEmpty) {
    buffer.writeln('אין אזהרות.');
  } else {
    for (final row in dayNotices.take(20)) {
      buffer.writeln('- ${row.message}');
    }
  }
  buffer
    ..writeln()
    ..write(
      dayNotices.isEmpty
          ? 'מסקנה: היום נסגר לפי מה שכבר הגיע למחשב ($checkIns קליטות, $checkOuts הוצאות).'
          : 'מסקנה: יש ${dayNotices.length} הערות שדורשות בדיקה ($checkIns קליטות, $checkOuts הוצאות).',
    );
  return ClosedDayReport(
    subject: 'דוח קירור · $environmentName · $date',
    body: buffer.toString(),
  );
}

String _dateKey(DateTime day) {
  final year = day.year.toString().padLeft(4, '0');
  final month = day.month.toString().padLeft(2, '0');
  final date = day.day.toString().padLeft(2, '0');
  return '$year-$month-$date';
}

String _clock(DateTime instant) {
  final local = instant.toLocal();
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}

bool _sameDay(DateTime instant, DateTime day) {
  final local = instant.toLocal();
  return local.year == day.year &&
      local.month == day.month &&
      local.day == day.day;
}
