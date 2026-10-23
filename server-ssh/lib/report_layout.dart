/// The columns a shop can turn on. The product name is always in the table.
class ReportColumns {
  const ReportColumns({
    this.quantity = true,
    this.checkIn = true,
    this.checkInTime = true,
    this.checkOut = true,
    this.checkOutTime = true,
    this.notes = true,
    this.conclusion = true,
  });

  final bool quantity;
  final bool checkIn;
  final bool checkInTime;
  final bool checkOut;
  final bool checkOutTime;
  final bool notes;
  final bool conclusion;

  static const fixed = ReportColumns();

  /// Reads the tokens already in [template]. An empty file means every column.
  factory ReportColumns.fromTemplate(String template) {
    if (template.trim().isEmpty) {
      return fixed;
    }
    return ReportColumns(
      quantity: _has(template, 'quantity'),
      checkIn: _has(template, 'check_in'),
      checkInTime: _has(template, 'check_in_time'),
      checkOut: _has(template, 'check_out'),
      checkOutTime: _has(template, 'check_out_time'),
      notes: _has(template, 'notes'),
      conclusion: _has(template, 'conclusion'),
    );
  }

  /// The report.txt body for these columns.
  String toTemplate() {
    final headers = <String>['מוצר'];
    final tokens = <String>['{{product}}'];
    if (quantity) {
      headers.add('כמות');
      tokens.add('{{quantity}}');
    }
    if (checkIn) {
      headers.add('איך נקלט');
      tokens.add('{{check_in}}');
    }
    if (checkInTime) {
      headers.add('מתי נקלט');
      tokens.add('{{check_in_time}}');
    }
    if (checkOut) {
      headers.add('איך הוצא');
      tokens.add('{{check_out}}');
    }
    if (checkOutTime) {
      headers.add('מתי הוצא');
      tokens.add('{{check_out_time}}');
    }
    final buffer = StringBuffer()
      ..writeln('סביבה: {{environment}}')
      ..writeln('תאריך: {{date}}')
      ..writeln()
      ..writeln(headers.join(' | '))
      ..writeln('{{rows}}')
      ..writeln(tokens.join(' | '))
      ..writeln('{{/rows}}');
    if (notes) {
      buffer
        ..writeln()
        ..writeln('{{notes}}');
    }
    if (conclusion) {
      buffer
        ..writeln()
        ..writeln('{{conclusion}}');
    }
    return buffer.toString();
  }
}

bool _has(String template, String token) {
  return RegExp('\\{\\{$token\\}\\}').hasMatch(template);
}
