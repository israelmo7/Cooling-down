/// True when the typed come-out time is usable: empty (no reminder), or a
/// number of hours in (0, 72]. Anything else is a typo, not "no reminder".
bool isValidHoldHoursInput(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) {
    return true;
  }
  final value = double.tryParse(trimmed.replaceAll(',', '.'));
  return value != null && value > 0 && value <= 72;
}

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
