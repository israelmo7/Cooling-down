import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../domain/entities/fridge.dart';
import '../../domain/entities/product.dart';
import '../../domain/repositories/product_repository.dart';
import '../db/app_database.dart';
import '../mappers.dart';

/// A used product that was removed from the catalog. The row stays because a
/// log points at it. Check-in hides this mark. A one-off keeps a null sku, so
/// it stays on the check-in list without joining the settings list.
const removedFromCheckIn = 'hidden';

class DriftProductRepository implements ProductRepository {
  DriftProductRepository(this._db, {Uuid? uuid}) : _uuid = uuid ?? const Uuid();

  final AppDatabase _db;
  final Uuid _uuid;

  @override
  Stream<List<Product>> watchSearch(String query) {
    final trimmed = query.trim().replaceAll('%', '').replaceAll('_', '');
    final statement = _db.select(_db.products)
      ..where((product) {
        // The settings list, plus a name added on this screen. A removed
        // product is listed=false and marked [removedFromCheckIn].
        final onCheckIn = product.listed.equals(true) | product.sku.isNull();
        if (trimmed.isEmpty) {
          return onCheckIn;
        }
        return onCheckIn & product.name.like('%$trimmed%');
      })
      ..orderBy([(product) => OrderingTerm(expression: product.name)])
      ..limit(300);
    return statement.watch().map((rows) => rows.map(mapProduct).toList());
  }

  @override
  Stream<List<Product>> watchAll() {
    final statement = _db.select(_db.products)
      ..where((table) => table.listed.equals(true))
      ..orderBy([(table) => OrderingTerm(expression: table.name)]);
    return statement.watch().map((rows) => rows.map(mapProduct).toList());
  }

  @override
  Future<Product?> addProduct(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      return null;
    }
    final existing = await _productNamed(trimmed);
    if (existing != null) {
      final clearRemoved = existing.sku == removedFromCheckIn;
      if (!existing.listed || clearRemoved) {
        await (_db.update(
          _db.products,
        )..where((table) => table.id.equals(existing.id))).write(
          ProductsCompanion(
            listed: const Value(true),
            sku: clearRemoved ? const Value(null) : const Value.absent(),
          ),
        );
      }
      return mapProduct(existing);
    }
    return _insertProduct(trimmed, listed: true);
  }

  @override
  Future<Product?> addOneOffProduct(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      return null;
    }
    final existing = await _productNamed(trimmed);
    if (existing != null) {
      if (existing.sku == removedFromCheckIn) {
        await (_db.update(_db.products)
              ..where((table) => table.id.equals(existing.id)))
            .write(const ProductsCompanion(sku: Value(null)));
      }
      return mapProduct(existing);
    }
    return _insertProduct(trimmed, listed: false);
  }

  Future<ProductRow?> _productNamed(String name) {
    return (_db.select(
      _db.products,
    )..where((table) => table.name.equals(name))).getSingleOrNull();
  }

  Future<Product> _insertProduct(String name, {required bool listed}) async {
    final createdAt = DateTime.now().toUtc();
    final id = _uuid.v4();
    await _db
        .into(_db.products)
        .insert(
          ProductsCompanion.insert(
            id: id,
            name: name,
            listed: Value(listed),
            createdAt: createdAt,
          ),
        );
    return Product(id: id, name: name, createdAt: createdAt);
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
  Future<void> deleteProduct(String id) async {
    try {
      await (_db.delete(
        _db.products,
      )..where((table) => table.id.equals(id))).go();
    } on Object catch (error) {
      if (!error.toString().contains('FOREIGN KEY')) {
        rethrow;
      }
      await (_db.update(
        _db.products,
      )..where((table) => table.id.equals(id))).write(
        const ProductsCompanion(
          listed: Value(false),
          sku: Value(removedFromCheckIn),
        ),
      );
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
