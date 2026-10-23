/// A check-in that still has units inside: no check-out yet, or only part
/// of the checked-in quantity has been taken out.
class OpenHolding {
  const OpenHolding({
    required this.movementId,
    required this.productId,
    required this.productName,
    required this.fridgeId,
    required this.fridgeName,
    required this.checkInTemperatureCelsius,
    required this.checkedInAt,
    this.dueAt,
    this.quantity = 1,
    int? checkedInQuantity,
  }) : checkedInQuantity = checkedInQuantity ?? quantity;

  final String movementId;
  final String productId;
  final String productName;
  final String fridgeId;
  final String fridgeName;
  final double checkInTemperatureCelsius;
  final DateTime checkedInAt;
  final DateTime? dueAt;

  /// How many units are still inside (checked in minus already taken out).
  final int quantity;

  /// How many units entered with the original check-in.
  final int checkedInQuantity;
}
