import 'package:drift/drift.dart';

import '../../core/clock.dart';
import '../../domain/repositories/settings_repository.dart';
import '../../domain/repositories/sync_repository.dart';
import '../../domain/settings/device_settings.dart';
import '../db/app_database.dart';
import '../db/converters.dart';
import '../sync/gateway_factory.dart';
import '../sync/sync_gateway.dart';

class DriftSyncRepository implements SyncRepository {
  DriftSyncRepository(
    this._db, {
    required this.settings,
    Clock? clock,
    SyncGateway Function(DeviceSettings settings)? gatewayFor,
  }) : _clock = clock ?? const Clock(),
       _gatewayFor = gatewayFor ?? gatewayForSettings;

  final AppDatabase _db;
  final SettingsRepository settings;
  final Clock _clock;
  final SyncGateway Function(DeviceSettings settings) _gatewayFor;

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
    final current = await settings.ensure();
    final pending =
        await (_db.select(_db.syncOutbox)
              ..where(
                (table) =>
                    table.status.equalsValue(SyncStatus.pending) |
                    table.status.equalsValue(SyncStatus.inFlight),
              )
              ..orderBy([(table) => OrderingTerm(expression: table.createdAt)]))
            .get();

    if (!current.hasServer) {
      if (pending.isEmpty) {
        return const SyncAttempt(synced: 0, remaining: 0);
      }
      await _restore(pending, 'offline');
      return SyncAttempt(
        synced: 0,
        remaining: pending.length,
        stoppedBecause: 'אין חיבור למחשב',
      );
    }

    for (final row in pending) {
      await (_db.update(_db.syncOutbox)
            ..where((table) => table.id.equals(row.id)))
          .write(const SyncOutboxCompanion(status: Value(SyncStatus.inFlight)));
    }

    final SyncExchange result;
    try {
      result = await _gatewayFor(current).exchange(
        SyncRequest(
          deviceId: current.deviceId,
          environment: current.environmentName,
          cursor: current.syncCursor,
          ownerEmail: '',
          push: [
            for (final row in pending)
              SyncPushItem(
                entityType: row.entityType,
                entityId: row.entityId,
                payloadJson: row.payloadJson,
              ),
          ],
        ),
      );
    } on Object catch (error) {
      await _restore(pending, error.toString());
      await settings.recordSync(error: error.toString());
      return SyncAttempt(
        synced: 0,
        remaining: pending.length,
        stoppedBecause: error.toString(),
      );
    }

    if (!result.reachable) {
      final reason = result.error ?? 'אין חיבור למחשב';
      await _restore(pending, reason);
      await settings.recordSync(error: reason);
      return SyncAttempt(
        synced: 0,
        remaining: pending.length,
        stoppedBecause: reason,
      );
    }

    try {
      // Each tablet keeps its own rows. The computer stores the upload
      // under this environment and does not copy another environment back.
      final accepted = result.acceptedIds.toSet();
      for (final row in pending) {
        final ok = accepted.contains(row.entityId);
        await (_db.update(
          _db.syncOutbox,
        )..where((table) => table.id.equals(row.id))).write(
          SyncOutboxCompanion(
            status: Value(ok ? SyncStatus.synced : SyncStatus.pending),
            lastError: ok
                ? const Value(null)
                : const Value('המחשב לא קיבל את הרשומה.'),
            attemptCount: ok
                ? const Value.absent()
                : Value(row.attemptCount + 1),
          ),
        );
      }
      await settings.recordSync(
        cursor: result.cursor,
        at: _clock.now(),
        clearError: true,
      );
    } on Object catch (error) {
      await _restore(pending, error.toString());
      await settings.recordSync(error: error.toString());
      return SyncAttempt(
        synced: 0,
        remaining: pending.length,
        stoppedBecause: error.toString(),
      );
    }

    final synced = pending
        .where((row) => result.acceptedIds.contains(row.entityId))
        .length;
    return SyncAttempt(
      synced: synced,
      remaining: pending.length - synced,
    );
  }

  Future<void> _restore(List<SyncOutboxRow> rows, String error) async {
    for (final row in rows) {
      await (_db.update(
        _db.syncOutbox,
      )..where((table) => table.id.equals(row.id))).write(
        SyncOutboxCompanion(
          status: const Value(SyncStatus.pending),
          attemptCount: Value(row.attemptCount + 1),
          lastError: Value(error),
        ),
      );
    }
  }
}
