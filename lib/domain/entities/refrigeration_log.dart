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
}
