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

/// How many stored actions the admin page and a quiet-day mail will list.
const recentActionLimit = 30;

/// The built-in table heading, shown read-only on the admin page.
String get builtInReportHeading => _columns.join(' | ');

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
  final conclusion = _conclusion(rows, day, dayNotices);
  final stored = rows.isEmpty ? logs : const <StoredLogLine>[];
  return ClosedDayReport(
    subject: 'דוח קירור · $environmentName · $date',
    body: _plain(
      environmentName: environmentName,
      date: date,
      day: day,
      rows: rows,
      notices: dayNotices,
      conclusion: conclusion,
      stored: stored,
    ),
    html: _html(
      environmentName: environmentName,
      date: date,
      day: day,
      rows: rows,
      notices: dayNotices,
      conclusion: conclusion,
      stored: stored,
    ),
  );
}

/// Fills [template] from the same rows as the built-in table.
/// `{{rows}}` ... `{{/rows}}` repeats once per movement.
ClosedDayReport buildCustomReport({
  required String template,
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
  final conclusion = _conclusion(rows, day, dayNotices);
  final notes = dayNotices.isEmpty
      ? 'אין אזהרות.'
      : dayNotices.map((notice) => notice.message).join('\n');
  final stored = rows.isEmpty ? logs : const <StoredLogLine>[];
  final body = _fillTemplate(
    template: template,
    environmentName: environmentName,
    date: date,
    day: day,
    rows: rows,
    notes: notes,
    conclusion: conclusion,
  );
  final storedText = _storedText(stored);
  final fullBody = storedText.isEmpty ? body : '$body\n\n$storedText';
  final columns = _columnsIn(template);
  return ClosedDayReport(
    subject: 'דוח קירור · $environmentName · $date',
    body: fullBody,
    html: columns.isEmpty
        ? '<pre dir="rtl" style="font-family:Arial,Helvetica,sans-serif;white-space:pre-wrap;">${_escape(fullBody)}</pre>'
        : _html(
            environmentName: environmentName,
            date: date,
            day: day,
            rows: rows,
            notices: dayNotices,
            conclusion: conclusion,
            stored: stored,
            columns: columns,
            showNotes: template.contains('{{notes}}'),
            showConclusion: template.contains('{{conclusion}}'),
          ),
  );
}

String _fillTemplate({
  required String template,
  required String environmentName,
  required String date,
  required DateTime day,
  required List<_ReportRow> rows,
  required String notes,
  required String conclusion,
}) {
  final block = RegExp(r'\{\{rows\}\}([\s\S]*?)\{\{/rows\}\}');
  final match = block.firstMatch(template);
  var text = template;
  if (match != null) {
    final pattern = match.group(1)!;
    final rendered = rows.map((row) {
      return pattern
          .replaceAll('{{product}}', row.productName)
          .replaceAll('{{check_in}}', _how(row.checkIn))
          .replaceAll('{{check_in_time}}', _when(row.checkIn, day))
          .replaceAll('{{check_out}}', _how(row.checkOut))
          .replaceAll('{{check_out_time}}', _when(row.checkOut, day));
    }).join();
    text = template.replaceRange(match.start, match.end, rendered);
  }
  text = text
      .replaceAll('{{environment}}', environmentName)
      .replaceAll('{{date}}', date)
      .replaceAll('{{notes}}', notes)
      .replaceAll('{{conclusion}}', conclusion);
  for (final token in [
    'product',
    'check_in',
    'check_in_time',
    'check_out',
    'check_out_time',
    'rows',
    '/rows',
  ]) {
    text = text.replaceAll('{{$token}}', '');
  }
  return text;
}

String _conclusion(
  List<_ReportRow> rows,
  DateTime day,
  List<StoredNotice> dayNotices,
) {
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
  if (dayNotices.isEmpty) {
    return 'מסקנה: היום נסגר לפי מה שכבר הגיע למחשב $counts.';
  }
  if (dayNotices.length == 1) {
    return 'מסקנה: יש הערה אחת שדורשת בדיקה $counts.';
  }
  return 'מסקנה: יש ${dayNotices.length} הערות שדורשות בדיקה $counts.';
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
  required List<StoredLogLine> stored,
}) {
  final buffer = StringBuffer()
    ..writeln('סביבה: $environmentName')
    ..writeln('תאריך: $date')
    ..writeln()
    ..writeln(_columns.join(' | '));
  if (rows.isEmpty) {
    buffer.writeln('אין תנועות.');
    final remembered = _storedText(stored);
    if (remembered.isNotEmpty) {
      buffer
        ..writeln()
        ..writeln(remembered);
    }
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

enum _ReportColumn { product, checkIn, checkInTime, checkOut, checkOutTime }

const _allColumns = [
  _ReportColumn.product,
  _ReportColumn.checkIn,
  _ReportColumn.checkInTime,
  _ReportColumn.checkOut,
  _ReportColumn.checkOutTime,
];

List<_ReportColumn> _columnsIn(String template) {
  final match = RegExp(r'\{\{rows\}\}([\s\S]*?)\{\{/rows\}\}')
      .firstMatch(template);
  if (match == null) {
    return const [];
  }
  final found = <_ReportColumn>[];
  for (final token in RegExp(
    r'\{\{([a-z_]+)\}\}',
  ).allMatches(match.group(1)!)) {
    final column = switch (token.group(1)) {
      'product' => _ReportColumn.product,
      'check_in' => _ReportColumn.checkIn,
      'check_in_time' => _ReportColumn.checkInTime,
      'check_out' => _ReportColumn.checkOut,
      'check_out_time' => _ReportColumn.checkOutTime,
      _ => null,
    };
    if (column != null && !found.contains(column)) {
      found.add(column);
    }
  }
  return found;
}

String _columnTitle(_ReportColumn column) {
  return switch (column) {
    _ReportColumn.product => 'מוצר',
    _ReportColumn.checkIn => 'איך נקלט',
    _ReportColumn.checkInTime => 'מתי נקלט',
    _ReportColumn.checkOut => 'איך הוצא',
    _ReportColumn.checkOutTime => 'מתי הוצא',
  };
}

String _columnValue(_ReportColumn column, _ReportRow row, DateTime day) {
  return switch (column) {
    _ReportColumn.product => row.productName,
    _ReportColumn.checkIn => _how(row.checkIn),
    _ReportColumn.checkInTime => _when(row.checkIn, day),
    _ReportColumn.checkOut => _how(row.checkOut),
    _ReportColumn.checkOutTime => _when(row.checkOut, day),
  };
}

bool _columnLtr(_ReportColumn column) {
  return column == _ReportColumn.checkInTime ||
      column == _ReportColumn.checkOutTime;
}

String _html({
  required String environmentName,
  required String date,
  required DateTime day,
  required List<_ReportRow> rows,
  required List<StoredNotice> notices,
  required String conclusion,
  required List<StoredLogLine> stored,
  List<_ReportColumn> columns = _allColumns,
  bool showNotes = true,
  bool showConclusion = true,
}) {
  final head = columns
      .map(
        (column) =>
            '<th style="text-align:right;padding:10px 12px;border:1px solid #d7e0e4;background:#eef3f5;">${_escape(_columnTitle(column))}</th>',
      )
      .join();
  final body = rows.isEmpty
      ? '<tr><td colspan="${columns.length}" style="padding:12px;border:1px solid #d7e0e4;">אין תנועות.</td></tr>'
      : rows.map((row) {
          final cells = [
            for (final column in columns)
              _cell(_columnValue(column, row, day), ltr: _columnLtr(column)),
          ];
          return '<tr>${cells.join()}</tr>';
        }).join();
  final notes = notices.isEmpty
      ? '<p style="margin:0;">אין אזהרות.</p>'
      : '<ul style="margin:0;padding-right:20px;">${notices.map((notice) => '<li>${_escape(notice.message)}</li>').join()}</ul>';
  final notesBlock = showNotes
      ? '''
  <h2 style="font-size:16px;margin:20px 0 8px;">הערות</h2>
  $notes'''
      : '';
  final conclusionBlock = showConclusion
      ? '<p style="margin:16px 0 0;">${_escape(conclusion)}</p>'
      : '';
  return '''
<div dir="rtl" style="font-family:Arial,Helvetica,sans-serif;color:#122428;background:#f4f7f8;padding:24px;">
  <h1 style="font-size:22px;margin:0 0 12px;">דוח קירור</h1>
  <p style="margin:0 0 4px;">סביבה: ${_escape(environmentName)}</p>
  <p style="margin:0 0 16px;">תאריך: ${_escape(date)}</p>
  <table dir="rtl" style="width:100%;border-collapse:collapse;background:#ffffff;">
    <thead><tr>$head</tr></thead>
    <tbody>$body</tbody>
  </table>
  $notesBlock
  ${_storedHtml(stored)}
  $conclusionBlock
</div>
''';
}

List<StoredLogLine> _recent(List<StoredLogLine> logs) {
  final recent = [...logs]
    ..sort((a, b) => b.occurredAt.compareTo(a.occurredAt));
  if (recent.length <= recentActionLimit) {
    return recent;
  }
  return recent.sublist(0, recentActionLimit);
}

String _storedText(List<StoredLogLine> logs) {
  if (logs.isEmpty) {
    return '';
  }
  final recent = _recent(logs);
  final buffer = StringBuffer('תנועות אחרונות שנשמרו');
  for (final line in recent) {
    buffer.writeln();
    buffer.write(
      '${_stamp(line.occurredAt)} ${line.productName} ${_eventWord(line.eventType)}',
    );
  }
  if (logs.length > recent.length) {
    buffer.writeln();
    buffer.write(
      'מוצגות ${recent.length} התנועות האחרונות מתוך ${logs.length}.',
    );
  }
  return buffer.toString();
}

String _storedHtml(List<StoredLogLine> logs) {
  if (logs.isEmpty) {
    return '';
  }
  final recent = _recent(logs);
  final items = recent
      .map(
        (line) =>
            '<li>${_escape(_stamp(line.occurredAt))} ${_escape(line.productName)} ${_escape(_eventWord(line.eventType))}</li>',
      )
      .join();
  final more = logs.length > recent.length
      ? '<p style="margin:8px 0 0;">מוצגות ${recent.length} התנועות האחרונות מתוך ${logs.length}.</p>'
      : '';
  return '''
  <h2 style="font-size:16px;margin:20px 0 8px;">תנועות אחרונות שנשמרו</h2>
  <ul style="margin:0;padding-right:20px;">$items</ul>
  $more''';
}

String _eventWord(String eventType) {
  if (eventType == 'check_in') {
    return 'קליטה';
  }
  if (eventType == 'check_out') {
    return 'הוצאה';
  }
  return eventType;
}

String _stamp(DateTime instant) {
  final local = instant.toLocal();
  final day = local.day.toString().padLeft(2, '0');
  final month = local.month.toString().padLeft(2, '0');
  return '$day/$month ${_clock(instant)}';
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
