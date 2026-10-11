/// A check-in that does not yet have a matching check-out.
class OpenHolding {
  const OpenHolding({
    required this.movementId,
    required this.productId,
    required this.productName,
    required this.fridgeId,
    required this.fridgeName,
    required this.checkInTemperatureCelsius,
    required this.checkedInAt,
  });

  final String movementId;
  final String productId;
  final String productName;
  final String fridgeId;
  final String fridgeName;
  final double checkInTemperatureCelsius;
  final DateTime checkedInAt;
}
