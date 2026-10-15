import 'package:cooling_down/core/temperature.dart';
import 'package:cooling_down/data/db/app_database.dart';
import 'package:cooling_down/data/db/seed_ids.dart';
import 'package:cooling_down/data/repositories/drift_product_repository.dart';
import 'package:cooling_down/data/repositories/drift_settings_repository.dart';
import 'package:cooling_down/presentation/format.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('a temperature stays left to right', () {
    expect(formatCelsius(4.0), '\u20664.0 °C\u2069');
    expect(ltrCelsius(4.5), '\u20664.5°C\u2069');
  });

  test('the one fridge takes the environment name', () async {
    final database = AppDatabase.memory();
    addTearDown(database.close);
    final products = DriftProductRepository(database);
    final settings = DriftSettingsRepository(database);

    final seeded = await products.watchFridges().first;
    expect(seeded.map((fridge) => fridge.id), [SeedIds.kitchenFridge]);
    expect(seeded.single.name, 'מטבח');

    final current = await settings.ensure();
    await settings.save(current.copyWith(environmentName: 'מחסן'));

    final renamed = await products.watchFridges().first;
    expect(renamed, hasLength(1));
    expect(renamed.single.name, 'מחסן');
  });
}
