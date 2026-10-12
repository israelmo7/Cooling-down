import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../domain/entities/fridge.dart';
import '../../domain/entities/product.dart';
import '../../domain/repositories/product_repository.dart';
import '../db/app_database.dart';
import '../mappers.dart';

class DriftProductRepository implements ProductRepository {
  DriftProductRepository(this._db, {Uuid? uuid}) : _uuid = uuid ?? const Uuid();

  final AppDatabase _db;
  final Uuid _uuid;

  @override
  Stream<List<Product>> watchSearch(String query) {
    final trimmed = query.trim().replaceAll('%', '').replaceAll('_', '');
    final statement = _db.select(_db.products)
      ..orderBy([(table) => OrderingTerm(expression: table.name)])
      ..limit(200);
    if (trimmed.isNotEmpty) {
      statement.where((table) => table.name.like('%$trimmed%'));
    }
    return statement.watch().map((rows) => rows.map(mapProduct).toList());
  }

  @override
  Stream<List<Product>> watchAll() {
    final statement = _db.select(_db.products)
      ..orderBy([(table) => OrderingTerm(expression: table.name)]);
    return statement.watch().map((rows) => rows.map(mapProduct).toList());
  }

  @override
  Future<void> addProduct(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      return;
    }
    await _db
        .into(_db.products)
        .insert(
          ProductsCompanion.insert(
            id: _uuid.v4(),
            name: trimmed,
            createdAt: DateTime.now().toUtc(),
          ),
        );
  }

  @override
  Future<void> renameProduct(String id, String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      return;
    }
    await (_db.update(_db.products)..where((table) => table.id.equals(id)))
        .write(ProductsCompanion(name: Value(trimmed)));
  }

  @override
  Future<bool> deleteProduct(String id) async {
    try {
      await (_db.delete(
        _db.products,
      )..where((table) => table.id.equals(id))).go();
      return true;
    } on Object catch (error) {
      if (error.toString().contains('FOREIGN KEY')) {
        return false;
      }
      rethrow;
    }
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
