/// Largest quantity accepted for one check-in or check-out event.
const maxQuantity = 9999;

/// True when [value] can be recorded as a quantity.
bool isValidQuantity(int value) => value >= 1 && value <= maxQuantity;

/// Keeps [value] inside [min]…[max], both inclusive.
int clampQuantity(int value, {int min = 1, int max = maxQuantity}) {
  final low = min < 1 ? 1 : min;
  final high = max < low ? low : (max > maxQuantity ? maxQuantity : max);
  if (value < low) {
    return low;
  }
  if (value > high) {
    return high;
  }
  return value;
}

/// Parses a typed quantity, or returns null when it is not a whole number
/// in [1, maxQuantity]. Empty text is invalid: callers pre-fill the field,
/// so there is nothing to guess. Nothing is silently turned into 1.
int? tryParseQuantity(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) {
    return null;
  }
  final value = int.tryParse(trimmed);
  if (value == null || !isValidQuantity(value)) {
    return null;
  }
  return value;
}
