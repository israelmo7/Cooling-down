import '../entities/alert.dart';

abstract class AlertRepository {
  Stream<List<Alert>> watchUnacknowledged();

  Future<void> acknowledge(String id);
}
