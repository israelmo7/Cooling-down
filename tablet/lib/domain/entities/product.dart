/// Catalog item that can be checked in and out of a fridge.
class Product {
  const Product({
    required this.id,
    required this.name,
    this.sku,
    required this.createdAt,
  });

  final String id;
  final String name;
  final String? sku;
  final DateTime createdAt;
}
