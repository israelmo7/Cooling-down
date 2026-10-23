class CatalogEntryNotFound implements Exception {
  const CatalogEntryNotFound(this.message);

  final String message;

  @override
  String toString() => message;
}

/// A quantity that cannot be recorded: below 1, above the maximum, or
/// more than what is still inside for this movement.
class InvalidQuantityException implements Exception {
  const InvalidQuantityException(this.message);

  final String message;

  @override
  String toString() => message;
}

class NoOpenHoldingException implements Exception {
  const NoOpenHoldingException(this.movementId);

  final String movementId;

  @override
  String toString() => 'No open holding for movement $movementId.';
}
