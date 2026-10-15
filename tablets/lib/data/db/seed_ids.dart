/// Stable catalog ids. They are UUID strings so the same values fit PostgreSQL.
abstract final class SeedIds {
  /// The one fridge on this tablet. Its name follows the environment setting.
  static const kitchenFridge = '11111111-1111-4111-8111-111111111111';

  /// Older tablets seeded these. A past log may still point at them.
  static const pharmacyFridge = '22222222-2222-4222-8222-222222222222';
  static const freezer = '33333333-3333-4333-8333-333333333333';

  static const wholeMilk = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaa1';
  static const chickenBreast = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaa2';
  static const insulin = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaa3';
  static const vaccine = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaa4';
}
