import 'package:uuid/uuid.dart';

const _uuid = Uuid();

/// Matches the tablet function in lib/domain/sync/checkout_conflict.dart.
String checkoutConflictAlertId(String movementId) {
  return _uuid.v5(
    Namespace.url.value,
    'cooling-down/checkout-conflict/$movementId',
  );
}

String checkoutConflictMessage(String productName) {
  return '$productName was checked out more than once for the same stay. Both temperatures were kept. The earliest check-out closed it.';
}
