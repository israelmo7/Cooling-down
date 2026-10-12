import '../entities/fridge.dart';
import '../entities/product.dart';

/// Local catalog reads. Fridges are reference data used when logging products.
abstract class ProductRepository {
  Stream<List<Product>> watchSearch(String query);

  Stream<List<Product>> watchAll();

  Future<void> addProduct(String name);

  Future<void> renameProduct(String id, String name);

  /// Returns false when a log already points at this product.
  Future<bool> deleteProduct(String id);

  Future<Product?> findById(String id);

  Stream<List<Fridge>> watchFridges();

  Future<Fridge?> findFridgeById(String id);
}
