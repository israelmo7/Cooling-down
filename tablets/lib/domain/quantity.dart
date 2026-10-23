/// Largest quantity accepted for one check-in or check-out event.
const maxQuantity = 9999;

/// True when [value] can be recorded as a quantity.
bool isValidQuantity(int value) => value >= 1 && value <= maxQuantity;

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
