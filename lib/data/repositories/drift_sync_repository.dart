import 'package:drift/drift.dart';

import '../../domain/repositories/sync_repository.dart';
import '../db/app_database.dart';
import '../db/converters.dart';
import '../sync/sync_gateway.dart';

class DriftSyncRepository implements SyncRepository {
  DriftSyncRepository(this._db, {required this.gateway});

  final AppDatabase _db;
  final SyncGateway gateway;

  @override
  Stream<int> watchPendingCount() {
    final count = _db.syncOutbox.id.count();
    final query = _db.selectOnly(_db.syncOutbox)
      ..addColumns([count])
      ..where(_db.syncOutbox.status.equalsValue(SyncStatus.pending));
    return query.watch().map((rows) => rows.single.read(count) ?? 0);
  }

  @override
  Future<SyncAttempt> trySync() async {
    final pending =
        await (_db.select(_db.syncOutbox)
              ..where((table) => table.status.equalsValue(SyncStatus.pending))
              ..orderBy([(table) => OrderingTerm(expression: table.createdAt)]))
            .get();
    var synced = 0;
    for (final row in pending) {
      await (_db.update(_db.syncOutbox)
            ..where((table) => table.id.equals(row.id)))
          .write(SyncOutboxCompanion(status: const Value(SyncStatus.inFlight)));
      final accepted = await gateway.pushInsert(
        entityType: row.entityType,
        entityId: row.entityId,
        payloadJson: row.payloadJson,
      );
      if (!accepted) {
        await (_db.update(
          _db.syncOutbox,
        )..where((table) => table.id.equals(row.id))).write(
          SyncOutboxCompanion(
            status: const Value(SyncStatus.pending),
            attemptCount: Value(row.attemptCount + 1),
            lastError: const Value('offline'),
          ),
        );
        return SyncAttempt(
          synced: synced,
          remaining: pending.length - synced,
          stoppedBecause: 'offline',
        );
      }
      await (_db.update(
        _db.syncOutbox,
      )..where((table) => table.id.equals(row.id))).write(
        const SyncOutboxCompanion(
          status: Value(SyncStatus.synced),
          lastError: Value(null),
        ),
      );
      synced += 1;
    }
    return SyncAttempt(synced: synced, remaining: 0);
  }
}
