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

  test('check-in keeps the catalog and a product added on the spot', () async {
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

    final shown = await products.watchSearch('').first;
    expect(shown.map((product) => product.name).toList(), [
      'חלב',
      'גבינה צהובה',
      'חזה עוף',
      'אינסולין',
      'חיסון',
    ]);

    final searched = await products.watchSearch('חיסון').first;
    expect(searched.single.name, 'חיסון');
  });

  test('a used product leaves the list and the log keeps its name', () async {
    await logs.insertCheckIn(
      productId: SeedIds.wholeMilk,
      fridgeId: SeedIds.kitchenFridge,
      temperatureCelsius: 3,
      workerName: 'דנה',
    );

    await products.deleteProduct(SeedIds.wholeMilk);
    await products.deleteProduct(SeedIds.vaccine);

    final listed = await products.watchAll().first;
    expect(listed.map((product) => product.name), isNot(contains('חלב')));
    expect(listed.map((product) => product.name), isNot(contains('חיסון')));
    final onCheckIn = await products.watchSearch('').first;
    expect(onCheckIn.map((product) => product.name), isNot(contains('חלב')));
    expect(onCheckIn.map((product) => product.name), isNot(contains('חיסון')));
    expect(await products.findById(SeedIds.wholeMilk), isNotNull);
    expect(await products.findById(SeedIds.vaccine), isNull);

    final again = await products.addProduct('חלב');
    expect(again?.id, SeedIds.wholeMilk);
    expect(
      (await products.watchAll().first).map((product) => product.name),
      contains('חלב'),
    );
  });
}
