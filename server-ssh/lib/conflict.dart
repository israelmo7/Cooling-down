import 'package:uuid/uuid.dart';

const _uuid = Uuid();

/// Stable id so the same double check-out is stored once.
String checkoutConflictAlertId(String movementId) {
  return _uuid.v5(
    Namespace.url.value,
    'cooling-down/checkout-conflict/$movementId',
  );
}

String checkoutConflictMessage(String productName) {
  return '$productName הוצא יותר מפעם אחת לאותה שהייה. שתי הטמפרטורות נשמרו. ההוצאה המוקדמת ביותר סגרה את הפריט.';
}

String checkoutQuantityConflictMessage(String productName) {
  return '$productName הוצא בכמות גדולה ממה שנקלט לאותה שהייה. יש לבדוק את הכמויות בדוח.';
}
