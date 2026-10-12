import 'package:cooling_down/data/db/app_database.dart';
import 'package:cooling_down/data/db/seed_ids.dart';
import 'package:cooling_down/data/repositories/drift_log_repository.dart';
import 'package:cooling_down/data/repositories/drift_product_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase database;
  late DriftProductRepository products;
  late DriftLogRepository logs;

  setUp(() {
    database = AppDatabase.memory();
    products = DriftProductRepository(database);
    logs = DriftLogRepository(database);
  });

  tearDown(() => database.close());

  test(
    'check-in shows frequent products and search keeps the full list',
    () async {
      final before = await products.watchSearch('').first;
      expect(
        before.map((product) => product.name),
        containsAll(['חלב', 'חזה עוף', 'אינסולין', 'חיסון']),
      );

      await logs.insertCheckIn(
        productId: SeedIds.wholeMilk,
        fridgeId: SeedIds.kitchenFridge,
        temperatureCelsius: 3,
        workerName: 'דנה',
      );
      await logs.insertCheckIn(
        productId: SeedIds.wholeMilk,
        fridgeId: SeedIds.kitchenFridge,
        temperatureCelsius: 3,
        workerName: 'דנה',
      );
      await logs.insertCheckIn(
        productId: SeedIds.chickenBreast,
        fridgeId: SeedIds.kitchenFridge,
        temperatureCelsius: 3,
        workerName: 'דנה',
      );
      final oneOff = await products.addOneOffProduct('גבינה צהובה');
      await logs.insertCheckIn(
        productId: oneOff!.id,
        fridgeId: SeedIds.kitchenFridge,
        temperatureCelsius: 3,
        workerName: 'דנה',
      );

      final frequent = await products.watchSearch('').first;
      expect(frequent.map((product) => product.name).toList(), [
        'חלב',
        'חזה עוף',
      ]);

      final searched = await products.watchSearch('חיסון').first;
      expect(searched.single.name, 'חיסון');
    },
  );
}
