/// A local clock time such as 18:30. Midnight is 00:00.
class ReportTime {
  const ReportTime(this.hour, this.minute);

  static const midnight = ReportTime(0, 0);

  final int hour;
  final int minute;

  String get text {
    final hours = hour.toString().padLeft(2, '0');
    final minutes = minute.toString().padLeft(2, '0');
    return '$hours:$minutes';
  }

  /// True once [now] is at this minute or later on the same day.
  bool reached(DateTime now) {
    if (now.hour != hour) {
      return now.hour > hour;
    }
    return now.minute >= minute;
  }

  /// The next time this clock time occurs strictly after [now].
  DateTime nextAfter(DateTime now) {
    final today = DateTime(now.year, now.month, now.day, hour, minute);
    if (now.isBefore(today)) {
      return today;
    }
    return DateTime(now.year, now.month, now.day + 1, hour, minute);
  }
}

/// `18:30` stays. An older hour such as `6` becomes `06:00`.
/// Anything else, including an empty value, is midnight.
ReportTime normalizeReportTime(String raw) {
  return tryParseReportTime(raw) ?? ReportTime.midnight;
}

/// Null when [raw] is not a clock time or a whole hour.
ReportTime? tryParseReportTime(String raw) {
  final trimmed = raw.trim();
  final clock = RegExp(r'^(\d{1,2}):(\d{2})(?::\d{2})?$').firstMatch(trimmed);
  if (clock != null) {
    return _time(int.parse(clock.group(1)!), int.parse(clock.group(2)!));
  }
  final hourOnly = RegExp(r'^(\d{1,2})$').firstMatch(trimmed);
  if (hourOnly != null) {
    return _time(int.parse(hourOnly.group(1)!), 0);
  }
  return null;
}

ReportTime? _time(int hour, int minute) {
  if (hour < 0 || hour > 23 || minute < 0 || minute > 59) {
    return null;
  }
  return ReportTime(hour, minute);
}

/// `custom` uses report.txt. Every other value uses the built-in table.
String normalizeReportFormat(String raw) {
  return raw.trim() == 'custom' ? 'custom' : 'builtin';
}
