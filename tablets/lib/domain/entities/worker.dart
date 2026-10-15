/// A person who checks products in and out on this tablet.
class Worker {
  const Worker({required this.id, required this.name, required this.createdAt});

  final String id;
  final String name;
  final DateTime createdAt;
}
