import 'package:drift/drift.dart';

import '../../domain/entities/alert.dart';
import '../../domain/repositories/alert_repository.dart';
import '../db/app_database.dart';
import '../mappers.dart';

class DriftAlertRepository implements AlertRepository {
  DriftAlertRepository(this._db);

  final AppDatabase _db;

  @override
  Stream<List<Alert>> watchUnacknowledged() {
    final statement = _db.select(_db.alerts)
      ..where((table) => table.acknowledgedAt.isNull())
      ..orderBy([
        (table) =>
            OrderingTerm(expression: table.createdAt, mode: OrderingMode.desc),
      ]);
    return statement.watch().map((rows) => rows.map(mapAlert).toList());
  }

  @override
  Future<void> acknowledge(String id) {
    return (_db.update(_db.alerts)..where((table) => table.id.equals(id)))
        .write(AlertsCompanion(acknowledgedAt: Value(DateTime.now().toUtc())));
  }
}
