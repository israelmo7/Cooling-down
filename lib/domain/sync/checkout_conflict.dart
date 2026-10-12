import 'package:uuid/uuid.dart';

const _uuid = Uuid();

/// Same id on every tablet and on the server, so the alert is inserted once.
String checkoutConflictAlertId(String movementId) {
  return _uuid.v5(
    Namespace.url.value,
    'cooling-down/checkout-conflict/$movementId',
  );
}

String checkoutConflictMessage(String productName) {
  return '$productName הוצא יותר מפעם אחת לאותה שהייה. שתי הטמפרטורות נשמרו. ההוצאה המוקדמת ביותר סגרה את הפריט.';
}
