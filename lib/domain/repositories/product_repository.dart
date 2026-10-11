import '../entities/fridge.dart';
import '../entities/product.dart';

/// Local catalog reads. Fridges are reference data used when logging products.
abstract class ProductRepository {
  Stream<List<Product>> watchSearch(String query);

  Future<Product?> findById(String id);

  Stream<List<Fridge>> watchFridges();

  Future<Fridge?> findFridgeById(String id);
}
