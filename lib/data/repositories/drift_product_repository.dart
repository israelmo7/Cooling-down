import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../domain/entities/fridge.dart';
import '../../domain/entities/product.dart';
import '../../domain/entities/refrigeration_log.dart';
import '../../domain/repositories/product_repository.dart';
import '../db/app_database.dart';
import '../mappers.dart';

/// How many products check-in shows before a search narrows the catalog.
const frequentProductLimit = 12;

class DriftProductRepository implements ProductRepository {
  DriftProductRepository(this._db, {Uuid? uuid}) : _uuid = uuid ?? const Uuid();

  final AppDatabase _db;
  final Uuid _uuid;

  @override
  Stream<List<Product>> watchSearch(String query) {
    final trimmed = query.trim().replaceAll('%', '').replaceAll('_', '');
    if (trimmed.isEmpty) {
      return _watchCheckInChoices();
    }
    return _watchListed(like: '%$trimmed%');
  }

  /// Products checked in most often. Before any check-in, the listed catalog
  /// is shown so a new tablet still has something to tap.
  Stream<List<Product>> _watchCheckInChoices() {
    final uses = _db.refrigerationLogs.id.count();
    final frequent =
        _db.select(_db.products).join([
            innerJoin(
              _db.refrigerationLogs,
              _db.refrigerationLogs.productId.equalsExp(_db.products.id) &
                  _db.refrigerationLogs.eventType.equalsValue(
                    LogEventType.checkIn,
                  ),
            ),
          ])
          ..where(_db.products.listed.equals(true))
          ..addColumns([uses])
          ..groupBy([_db.products.id])
          ..orderBy([
            OrderingTerm(expression: uses, mode: OrderingMode.desc),
            OrderingTerm(expression: _db.products.name),
          ])
          ..limit(frequentProductLimit);

    return frequent.watch().asyncMap((rows) async {
      if (rows.isNotEmpty) {
        return rows
            .map((row) => mapProduct(row.readTable(_db.products)))
            .toList();
      }
      return _listedProducts();
    });
  }

  Stream<List<Product>> _watchListed({required String like}) {
    final statement = _db.select(_db.products)
      ..where((table) => table.listed.equals(true) & table.name.like(like))
      ..orderBy([(table) => OrderingTerm(expression: table.name)])
      ..limit(200);
    return statement.watch().map((rows) => rows.map(mapProduct).toList());
  }

  Future<List<Product>> _listedProducts() async {
    final rows =
        await (_db.select(_db.products)
              ..where((table) => table.listed.equals(true))
              ..orderBy([(table) => OrderingTerm(expression: table.name)])
              ..limit(200))
            .get();
    return rows.map(mapProduct).toList();
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
      if (!existing.listed) {
        await (_db.update(_db.products)
              ..where((table) => table.id.equals(existing.id)))
            .write(const ProductsCompanion(listed: Value(true)));
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
