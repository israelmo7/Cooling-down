/// Hebrew end-of-day mail built from the logs the shop computer already stored.
class ClosedDayReport {
  const ClosedDayReport({
    required this.subject,
    required this.body,
    required this.html,
  });

  final String subject;
  final String body;

  /// The same report as a right-to-left table, sent with the plain text.
  final String html;
}

class StoredLogLine {
  const StoredLogLine({
    required this.movementId,
    required this.eventType,
    required this.occurredAt,
    required this.productName,
    required this.temperature,
    required this.fridgeName,
    this.workerName = '',
  });

  final String movementId;
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

class _Pair {
  StoredLogLine? checkIn;
  StoredLogLine? checkOut;

  void take(StoredLogLine line) {
    if (line.eventType == 'check_in') {
      if (checkIn == null || line.occurredAt.isBefore(checkIn!.occurredAt)) {
        checkIn = line;
      }
      return;
    }
    if (line.eventType == 'check_out') {
      if (checkOut == null || line.occurredAt.isBefore(checkOut!.occurredAt)) {
        checkOut = line;
      }
    }
  }
}

class _ReportRow {
  const _ReportRow({
    required this.productName,
    required this.checkIn,
    required this.checkOut,
    required this.order,
  });

  final String productName;
  final StoredLogLine? checkIn;
  final StoredLogLine? checkOut;
  final DateTime order;
}

const _columns = ['מוצר', 'איך נקלט', 'מתי נקלט', 'איך הוצא', 'מתי הוצא'];

ClosedDayReport buildClosedDayReport({
  required String environmentName,
  required DateTime day,
  required List<StoredLogLine> logs,
  required List<StoredNotice> notices,
}) {
  final date = _dateKey(day);
  final rows = _rowsForDay(logs, day);
  final dayNotices = notices
      .where((row) => _sameDay(row.createdAt, day))
      .toList();
  final checkIns = rows
      .where(
        (row) => row.checkIn != null && _sameDay(row.checkIn!.occurredAt, day),
      )
      .length;
  final checkOuts = rows
      .where(
        (row) =>
            row.checkOut != null && _sameDay(row.checkOut!.occurredAt, day),
      )
      .length;
  final counts = '($checkIns קליטות, $checkOuts הוצאות)';
  final conclusion = dayNotices.isEmpty
      ? 'מסקנה: היום נסגר לפי מה שכבר הגיע למחשב $counts.'
      : dayNotices.length == 1
      ? 'מסקנה: יש הערה אחת שדורשת בדיקה $counts.'
      : 'מסקנה: יש ${dayNotices.length} הערות שדורשות בדיקה $counts.';
  return ClosedDayReport(
    subject: 'דוח קירור · $environmentName · $date',
    body: _plain(
      environmentName: environmentName,
      date: date,
      day: day,
      rows: rows,
      notices: dayNotices,
      conclusion: conclusion,
    ),
    html: _html(
      environmentName: environmentName,
      date: date,
      day: day,
      rows: rows,
      notices: dayNotices,
      conclusion: conclusion,
    ),
  );
}

/// One row per movement that was checked in or checked out on [day].
/// A checkout after [day] is still unknown, so those cells stay empty.
List<_ReportRow> _rowsForDay(List<StoredLogLine> logs, DateTime day) {
  final pairs = <String, _Pair>{};
  for (var index = 0; index < logs.length; index++) {
    final line = logs[index];
    final id = line.movementId.trim();
    final key = id.isEmpty ? 'row-$index' : id;
    pairs.putIfAbsent(key, _Pair.new).take(line);
  }
  final rows = <_ReportRow>[];
  for (final pair in pairs.values) {
    final happenedToday =
        (pair.checkIn != null && _sameDay(pair.checkIn!.occurredAt, day)) ||
        (pair.checkOut != null && _sameDay(pair.checkOut!.occurredAt, day));
    if (!happenedToday) {
      continue;
    }
    final checkIn = _knownBy(pair.checkIn, day);
    final checkOut = _knownBy(pair.checkOut, day);
    final named = checkIn ?? checkOut;
    if (named == null) {
      continue;
    }
    rows.add(
      _ReportRow(
        productName: named.productName,
        checkIn: checkIn,
        checkOut: checkOut,
        order: _orderTime(checkIn, checkOut, day),
      ),
    );
  }
  rows.sort((a, b) {
    final byTime = a.order.compareTo(b.order);
    if (byTime != 0) {
      return byTime;
    }
    return a.productName.compareTo(b.productName);
  });
  return rows;
}

StoredLogLine? _knownBy(StoredLogLine? line, DateTime day) {
  if (line == null || _afterDay(line.occurredAt, day)) {
    return null;
  }
  return line;
}

DateTime _orderTime(
  StoredLogLine? checkIn,
  StoredLogLine? checkOut,
  DateTime day,
) {
  final onDay = <DateTime>[
    if (checkIn != null && _sameDay(checkIn.occurredAt, day))
      checkIn.occurredAt,
    if (checkOut != null && _sameDay(checkOut.occurredAt, day))
      checkOut.occurredAt,
  ]..sort();
  if (onDay.isNotEmpty) {
    return onDay.first;
  }
  return checkIn?.occurredAt ?? checkOut!.occurredAt;
}

String _plain({
  required String environmentName,
  required String date,
  required DateTime day,
  required List<_ReportRow> rows,
  required List<StoredNotice> notices,
  required String conclusion,
}) {
  final buffer = StringBuffer()
    ..writeln('סביבה: $environmentName')
    ..writeln('תאריך: $date')
    ..writeln()
    ..writeln(_columns.join(' | '));
  if (rows.isEmpty) {
    buffer.writeln('אין תנועות.');
  } else {
    for (final row in rows) {
      buffer.writeln(
        [
          row.productName,
          _how(row.checkIn),
          _when(row.checkIn, day),
          _how(row.checkOut),
          _when(row.checkOut, day),
        ].join(' | '),
      );
    }
  }
  buffer
    ..writeln()
    ..writeln('הערות');
  if (notices.isEmpty) {
    buffer.writeln('אין אזהרות.');
  } else {
    for (final notice in notices) {
      buffer.writeln('- ${notice.message}');
    }
  }
  buffer
    ..writeln()
    ..write(conclusion);
  return buffer.toString();
}

String _html({
  required String environmentName,
  required String date,
  required DateTime day,
  required List<_ReportRow> rows,
  required List<StoredNotice> notices,
  required String conclusion,
}) {
  final head = _columns
      .map(
        (column) =>
            '<th style="text-align:right;padding:10px 12px;border:1px solid #d7e0e4;background:#eef3f5;">${_escape(column)}</th>',
      )
      .join();
  final body = rows.isEmpty
      ? '<tr><td colspan="5" style="padding:12px;border:1px solid #d7e0e4;">אין תנועות.</td></tr>'
      : rows.map((row) {
          final cells = [
            _cell(row.productName),
            _cell(_how(row.checkIn)),
            _cell(_when(row.checkIn, day), ltr: true),
            _cell(_how(row.checkOut)),
            _cell(_when(row.checkOut, day), ltr: true),
          ];
          return '<tr>${cells.join()}</tr>';
        }).join();
  final notes = notices.isEmpty
      ? '<p style="margin:0;">אין אזהרות.</p>'
      : '<ul style="margin:0;padding-right:20px;">${notices.map((notice) => '<li>${_escape(notice.message)}</li>').join()}</ul>';
  return '''
<div dir="rtl" style="font-family:Arial,Helvetica,sans-serif;color:#122428;background:#f4f7f8;padding:24px;">
  <h1 style="font-size:22px;margin:0 0 12px;">דוח קירור</h1>
  <p style="margin:0 0 4px;">סביבה: ${_escape(environmentName)}</p>
  <p style="margin:0 0 16px;">תאריך: ${_escape(date)}</p>
  <table dir="rtl" style="width:100%;border-collapse:collapse;background:#ffffff;">
    <thead><tr>$head</tr></thead>
    <tbody>$body</tbody>
  </table>
  <h2 style="font-size:16px;margin:20px 0 8px;">הערות</h2>
  $notes
  <p style="margin:16px 0 0;">${_escape(conclusion)}</p>
</div>
''';
}

String _cell(String value, {bool ltr = false}) {
  final missing = value == '-';
  final color = missing ? 'color:#6b7280;' : '';
  final direction = ltr ? ' dir="ltr"' : '';
  return '<td$direction style="text-align:right;padding:10px 12px;border:1px solid #d7e0e4;$color">${_escape(value)}</td>';
}

String _how(StoredLogLine? line) {
  if (line == null) {
    return '-';
  }
  final parts = <String>[
    if (line.temperature != null)
      _ltr('${line.temperature!.toStringAsFixed(1)}°C'),
    if (line.workerName.trim().isNotEmpty) line.workerName.trim(),
    if (line.fridgeName.trim().isNotEmpty) line.fridgeName.trim(),
  ];
  return parts.isEmpty ? '-' : parts.join(' · ');
}

String _ltr(String value) => '\u2066$value\u2069';

String _when(StoredLogLine? line, DateTime day) {
  if (line == null) {
    return '-';
  }
  final clock = _clock(line.occurredAt);
  if (_sameDay(line.occurredAt, day)) {
    return clock;
  }
  final local = line.occurredAt.toLocal();
  final date = local.day.toString().padLeft(2, '0');
  final month = local.month.toString().padLeft(2, '0');
  return '$date/$month $clock';
}

String _escape(String value) {
  return value
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;');
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

bool _afterDay(DateTime instant, DateTime day) {
  final local = instant.toLocal();
  final event = DateTime(local.year, local.month, local.day);
  final report = DateTime(day.year, day.month, day.day);
  return event.isAfter(report);
}
