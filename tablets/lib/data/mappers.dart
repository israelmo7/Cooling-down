import '../domain/entities/alert.dart';
import '../domain/entities/fridge.dart';
import '../domain/entities/product.dart';
import '../domain/entities/refrigeration_log.dart';
import 'db/app_database.dart';

Product mapProduct(ProductRow row) {
  return Product(
    id: row.id,
    name: row.name,
    sku: row.sku,
    createdAt: row.createdAt,
  );
}

Fridge mapFridge(FridgeRow row) {
  return Fridge(
    id: row.id,
    name: row.name,
    minCelsius: row.minCelsius,
    maxCelsius: row.maxCelsius,
  );
}

RefrigerationLog mapLog(RefrigerationLogRow row) {
  return RefrigerationLog(
    id: row.id,
    movementId: row.movementId,
    productId: row.productId,
    productNameSnapshot: row.productNameSnapshot,
    fridgeId: row.fridgeId,
    eventType: row.eventType,
    temperatureCelsius: row.temperatureCelsius,
    occurredAt: row.occurredAt,
    createdAt: row.createdAt,
    originDeviceId: row.originDeviceId,
    workerNameSnapshot: row.workerNameSnapshot,
    dueAt: row.dueAt,
    quantity: row.quantity,
  );
}

Alert mapAlert(AlertRow row) {
  return Alert(
    id: row.id,
    severity: row.severity,
    kind: row.kind,
    productId: row.productId,
    logId: row.logId,
    message: row.message,
    createdAt: row.createdAt,
    acknowledgedAt: row.acknowledgedAt,
    originDeviceId: row.originDeviceId,
  );
}
