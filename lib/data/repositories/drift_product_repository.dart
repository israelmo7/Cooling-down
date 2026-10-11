import 'package:drift/drift.dart';

import '../../domain/entities/fridge.dart';
import '../../domain/entities/product.dart';
import '../../domain/repositories/product_repository.dart';
import '../db/app_database.dart';
import '../mappers.dart';

class DriftProductRepository implements ProductRepository {
  DriftProductRepository(this._db);

  final AppDatabase _db;

  @override
  Stream<List<Product>> watchSearch(String query) {
    final trimmed = query.trim().replaceAll('%', '').replaceAll('_', '');
    final statement = _db.select(_db.products)
      ..orderBy([(table) => OrderingTerm(expression: table.name)])
      ..limit(20);
    if (trimmed.isNotEmpty) {
      statement.where((table) => table.name.like('%$trimmed%'));
    }
    return statement.watch().map((rows) => rows.map(mapProduct).toList());
  }

  @override
  Future<Product?> findById(String id) async {
    final row = await (_db.select(
      _db.products,
    )..where((table) => table.id.equals(id))).getSingleOrNull();
    return row == null ? null : mapProduct(row);
  }

  @override
  Stream<List<Fridge>> watchFridges() {
    final statement = _db.select(_db.fridges)
      ..orderBy([(table) => OrderingTerm(expression: table.name)]);
    return statement.watch().map((rows) => rows.map(mapFridge).toList());
  }

  @override
  Future<Fridge?> findFridgeById(String id) async {
    final row = await (_db.select(
      _db.fridges,
    )..where((table) => table.id.equals(id))).getSingleOrNull();
    return row == null ? null : mapFridge(row);
  }
}
