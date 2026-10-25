/// Append-only temperature event. Check-out is a second row, not an edit.
enum LogEventType {
  checkIn('check_in'),
  checkOut('check_out');

  const LogEventType(this.storageValue);

  final String storageValue;
}

class RefrigerationLog {
  const RefrigerationLog({
    required this.id,
    required this.movementId,
    required this.productId,
    required this.productNameSnapshot,
    required this.fridgeId,
    required this.eventType,
    required this.temperatureCelsius,
    required this.occurredAt,
    required this.createdAt,
    this.originDeviceId = '',
    this.workerNameSnapshot = '',
    this.dueAt,
    this.quantity = 1,
    this.packageId,
  });

  final String id;
  final String movementId;
  final String productId;
  final String productNameSnapshot;
  final String fridgeId;
  final LogEventType eventType;
  final double temperatureCelsius;
  final DateTime occurredAt;
  final DateTime createdAt;
  final String originDeviceId;
  final String workerNameSnapshot;

  /// When this check-in should leave the fridge. Empty when no time was set.
  final DateTime? dueAt;

  /// How many units this event moved. Always at least 1.
  final int quantity;

  /// Supplier receiving package, when this check-in was part of one.
  final String? packageId;
}
