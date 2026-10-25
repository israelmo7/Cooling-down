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
    this.quantity = 1,
  });

  final String movementId;
  final String eventType;
  final DateTime occurredAt;
  final String productName;
  final double? temperature;
  final String fridgeName;
  final String workerName;

  /// How many units this event moved.
  final int quantity;
}

class StoredNotice {
  const StoredNotice({required this.message, required this.createdAt});

  final String message;
  final DateTime createdAt;
}

/// One environment that was on during the report day but not fully synced
/// by the end of that day.
class SyncGapNote {
  const SyncGapNote({
    required this.environmentName,
    required this.unsynced,
  });

  final String environmentName;
  final Duration unsynced;
}

class _Pair {
  StoredLogLine? checkIn;
  StoredLogLine? checkOut;

  /// Every (possibly partial) check-out of this movement.
  final checkOuts = <StoredLogLine>[];

  void take(StoredLogLine line) {
    if (line.eventType == 'check_in') {
      if (checkIn == null || line.occurredAt.isBefore(checkIn!.occurredAt)) {
        checkIn = line;
      }
      return;
    }
    if (line.eventType == 'check_out') {
      checkOuts.add(line);
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
    this.checkOutQuantity = 0,
  });

  final String productName;
  final StoredLogLine? checkIn;
  final StoredLogLine? checkOut;
  final DateTime order;

  /// Total units taken out, summed over partial check-outs.
  final int checkOutQuantity;
}

const _columns = [
  'מוצר',
  'כמות',
  'איך נקלט',
  'מתי נקלט',
  'איך הוצא',
  'מתי הוצא',
];

/// How many stored actions the admin places page will list.
const recentActionLimit = 30;

/// The built-in table heading, shown read-only on the admin page.
String get builtInReportHeading => _columns.join(' | ');

/// Hebrew line for an incomplete sync, e.g. `מטבח: לא סונכרן במלואו · כ־3 שעות`.
String formatSyncGapLine(SyncGapNote note) {
  return '${note.environmentName}: לא סונכרן במלואו · ${_formatUnsynced(note.unsynced)}';
}

const _supplierColumns = [
  'סביבה',
  'מוצר',
  'כמות',
  'טמפ׳',
  'מתי',
  'מי',
];

/// One check-in row in a shared supplier delivery (may span environments).
class SupplierEntry {
  const SupplierEntry({
    required this.environmentName,
    required this.line,
  });

  final String environmentName;
  final StoredLogLine line;
}

/// Entry-only table for a closed supplier delivery across tablets.
ClosedDayReport buildSupplierPackageReport({
  required List<SupplierEntry> entries,
  DateTime? closedAt,
  @Deprecated('Use entries[].environmentName') String? environmentName,
}) {
  final when = closedAt ?? DateTime.now();
  final date = _dateKey(when.toLocal());
  final sorted = [...entries]
    ..sort((a, b) {
      final byEnv = a.environmentName.compareTo(b.environmentName);
      if (byEnv != 0) {
        return byEnv;
      }
      return a.line.occurredAt.compareTo(b.line.occurredAt);
    });
  final buffer = StringBuffer()
    ..writeln('מצב אספקה · $date')
    ..writeln()
    ..writeln(_supplierColumns.join(' | '));
  if (sorted.isEmpty) {
    buffer.writeln('אין תנועות.');
  } else {
    for (final entry in sorted) {
      final line = entry.line;
      buffer.writeln(
        [
          entry.environmentName,
          line.productName,
          '${line.quantity}',
          line.temperature == null
              ? '-'
              : _ltr('${line.temperature!.toStringAsFixed(1)}°C'),
          _clock(line.occurredAt),
          line.workerName.trim().isEmpty ? '-' : line.workerName.trim(),
        ].join(' | '),
      );
    }
  }
  final body = buffer.toString();
  final head = _supplierColumns
      .map(
        (title) =>
            '<th style="text-align:right;padding:10px 12px;border:1px solid #d7e0e4;background:#eef3f5;">${_escape(title)}</th>',
      )
      .join();
  final rows = sorted.isEmpty
      ? '<tr><td colspan="6" style="padding:12px;border:1px solid #d7e0e4;">אין תנועות.</td></tr>'
      : sorted.map((entry) {
          final line = entry.line;
          final cells = [
            _cell(entry.environmentName),
            _cell(line.productName),
            _cell('${line.quantity}'),
            _cell(
              line.temperature == null
                  ? '-'
                  : '${line.temperature!.toStringAsFixed(1)}°C',
              ltr: true,
            ),
            _cell(_clock(line.occurredAt), ltr: true),
            _cell(
              line.workerName.trim().isEmpty ? '-' : line.workerName.trim(),
            ),
          ];
          return '<tr>${cells.join()}</tr>';
        }).join();
  final html =
      '''
<div dir="rtl" style="font-family:Arial,Helvetica,sans-serif;color:#122428;background:#f4f7f8;padding:24px;">
  <h1 style="font-size:22px;margin:0 0 12px;">מצב אספקה</h1>
  <p style="margin:0 0 16px;">תאריך: ${_escape(date)}</p>
  <table dir="rtl" style="width:100%;border-collapse:collapse;background:#ffffff;">
    <thead><tr>$head</tr></thead>
    <tbody>$rows</tbody>
  </table>
</div>
''';
  return ClosedDayReport(
    subject: 'מצב אספקה · $date',
    body: body,
    html: html,
  );
}

ClosedDayReport buildClosedDayReport({
  required String environmentName,
  required DateTime day,
  required List<StoredLogLine> logs,
  List<SyncGapNote> syncGaps = const [],
}) {
  final date = _dateKey(day);
  final rows = _rowsForDay(logs, day);
  return ClosedDayReport(
    subject: 'דוח קירור · $environmentName · $date',
    body: _plain(
      environmentName: environmentName,
      date: date,
      day: day,
      rows: rows,
      syncGaps: syncGaps,
    ),
    html: _html(
      environmentName: environmentName,
      date: date,
      day: day,
      rows: rows,
      syncGaps: syncGaps,
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
  List<StoredNotice> notices = const [],
  List<SyncGapNote> syncGaps = const [],
}) {
  final date = _dateKey(day);
  final rows = _rowsForDay(logs, day);
  final notes = notices.isEmpty
      ? ''
      : notices.map((notice) => notice.message).join('\n');
  final body = _fillTemplate(
    template: template,
    environmentName: environmentName,
    date: date,
    day: day,
    rows: rows,
    notes: notes,
  );
  final gapText = _syncGapPlain(syncGaps);
  final fullBody = gapText.isEmpty ? body : '$body\n\n$gapText';
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
            syncGaps: syncGaps,
            columns: columns,
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
}) {
  final block = RegExp(r'\{\{rows\}\}([\s\S]*?)\{\{/rows\}\}');
  final match = block.firstMatch(template);
  var text = template;
  if (match != null) {
    final pattern = match.group(1)!;
    final rendered = rows.map((row) {
      return pattern
          .replaceAll('{{product}}', row.productName)
          .replaceAll('{{quantity}}', _quantityText(row))
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
      .replaceAll('{{conclusion}}', '');
  for (final token in [
    'product',
    'quantity',
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
        checkOutQuantity: pair.checkOuts
            .where((line) => !_afterDay(line.occurredAt, day))
            .fold(0, (sum, line) => sum + line.quantity),
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
  required List<SyncGapNote> syncGaps,
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
          _quantityText(row),
          _how(row.checkIn),
          _when(row.checkIn, day),
          _how(row.checkOut),
          _when(row.checkOut, day),
        ].join(' | '),
      );
    }
  }
  final gaps = _syncGapPlain(syncGaps);
  if (gaps.isNotEmpty) {
    buffer
      ..writeln()
      ..write(gaps);
  }
  return buffer.toString();
}

enum _ReportColumn {
  product,
  quantity,
  checkIn,
  checkInTime,
  checkOut,
  checkOutTime,
}

const _allColumns = [
  _ReportColumn.product,
  _ReportColumn.quantity,
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
      'quantity' => _ReportColumn.quantity,
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
    _ReportColumn.quantity => 'כמות',
    _ReportColumn.checkIn => 'איך נקלט',
    _ReportColumn.checkInTime => 'מתי נקלט',
    _ReportColumn.checkOut => 'איך הוצא',
    _ReportColumn.checkOutTime => 'מתי הוצא',
  };
}

String _columnValue(_ReportColumn column, _ReportRow row, DateTime day) {
  return switch (column) {
    _ReportColumn.product => row.productName,
    _ReportColumn.quantity => _quantityText(row),
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
  required List<SyncGapNote> syncGaps,
  List<_ReportColumn> columns = _allColumns,
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
  final gapBlock = _syncGapHtml(syncGaps);
  return '''
<div dir="rtl" style="font-family:Arial,Helvetica,sans-serif;color:#122428;background:#f4f7f8;padding:24px;">
  <h1 style="font-size:22px;margin:0 0 12px;">דוח קירור</h1>
  <p style="margin:0 0 4px;">סביבה: ${_escape(environmentName)}</p>
  <p style="margin:0 0 16px;">תאריך: ${_escape(date)}</p>
  <table dir="rtl" style="width:100%;border-collapse:collapse;background:#ffffff;">
    <thead><tr>$head</tr></thead>
    <tbody>$body</tbody>
  </table>
  $gapBlock
</div>
''';
}

String _syncGapPlain(List<SyncGapNote> gaps) {
  if (gaps.isEmpty) {
    return '';
  }
  return gaps.map(formatSyncGapLine).join('\n');
}

String _syncGapHtml(List<SyncGapNote> gaps) {
  if (gaps.isEmpty) {
    return '';
  }
  final lines = gaps
      .map(
        (note) =>
            '<p style="margin:8px 0 0;">${_escape(formatSyncGapLine(note))}</p>',
      )
      .join();
  return '<div style="margin-top:16px;">$lines</div>';
}

String _formatUnsynced(Duration gap) {
  final minutes = gap.inMinutes;
  if (minutes < 1) {
    return 'פחות מדקה';
  }
  if (minutes < 60) {
    return 'כ־$minutes דקות';
  }
  final hours = gap.inHours;
  if (hours < 48) {
    return 'כ־$hours שעות';
  }
  final days = gap.inDays;
  return 'כ־$days ימים';
}

String _cell(String value, {bool ltr = false}) {
  final missing = value == '-';
  final color = missing ? 'color:#6b7280;' : '';
  final direction = ltr ? ' dir="ltr"' : '';
  return '<td$direction style="text-align:right;padding:10px 12px;border:1px solid #d7e0e4;$color">${_escape(value)}</td>';
}

/// One row pairs a check-in with its check-out, so the single כמות cell
/// shows the checked-in amount and, when the checked-out amount differs,
/// both amounts: `נכנס 5 · הוצא 3`. Equal amounts show once.
String _quantityText(_ReportRow row) {
  final checkedIn = row.checkIn?.quantity;
  // Partial check-outs add up; the single check-out line only carries the
  // first one's own quantity.
  final checkedOut = row.checkOut == null
      ? null
      : (row.checkOutQuantity > 0
            ? row.checkOutQuantity
            : row.checkOut!.quantity);
  if (checkedIn != null && checkedOut != null) {
    if (checkedIn == checkedOut) {
      return '$checkedIn';
    }
    return 'נכנס $checkedIn · הוצא $checkedOut';
  }
  final only = checkedIn ?? checkedOut;
  return only == null ? '-' : '$only';
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
