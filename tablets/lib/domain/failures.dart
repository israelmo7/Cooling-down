class CatalogEntryNotFound implements Exception {
  const CatalogEntryNotFound(this.message);

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
