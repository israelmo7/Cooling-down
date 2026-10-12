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
  return '$productName הוצא יותר מפעם אחת לאותה שהייה. שתי הטמפרטורות נשמרו. ההוצאה המוקדמת ביותר סגרה את הפריט.';
}
