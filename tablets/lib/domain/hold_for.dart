/// Hours until a product should leave. Empty text means no reminder.
double? parseHoldHours(String raw) {
  final trimmed = raw.trim().replaceAll(',', '.');
  if (trimmed.isEmpty) {
    return null;
  }
  final value = double.tryParse(trimmed);
  if (value == null || value <= 0) {
    return null;
  }
  if (value > 72) {
    return 72;
  }
  return value;
}

DateTime dueAfter(DateTime from, double hours) {
  final minutes = (hours * 60).round();
  return from.toUtc().add(Duration(minutes: minutes));
}
