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

  /// One upload at a time so a manual tap and the minute timer cannot
  /// mark the same rows in-flight and restore each other’s work.
  Future<SyncAttempt>? _running;

  @override
  Stream<int> watchPendingCount() {
    final count = _db.syncOutbox.id.count();
    final query = _db.selectOnly(_db.syncOutbox)
      ..addColumns([count])
      ..where(_db.syncOutbox.status.equalsValue(SyncStatus.pending));
    return query.watch().map((rows) => rows.single.read(count) ?? 0);
  }

  @override
  Future<SyncAttempt> trySync() {
    final existing = _running;
    if (existing != null) {
      return existing;
    }
    final started = _trySyncOnce();
    _running = started;
    return started.whenComplete(() {
      if (identical(_running, started)) {
        _running = null;
      }
    });
  }

  Future<SyncAttempt> _trySyncOnce() async {
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
          pendingCount: pending.length,
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
      final reason = syncFailureMessage(error);
      await _restore(pending, reason);
      await settings.recordSync(error: reason);
      return SyncAttempt(
        synced: 0,
        remaining: pending.length,
        stoppedBecause: reason,
      );
    }

    if (!result.reachable) {
      final reason = syncFailureMessage(result.error);
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
      final reason = syncFailureMessage(error);
      await _restore(pending, reason);
      await settings.recordSync(error: reason);
      return SyncAttempt(
        synced: 0,
        remaining: pending.length,
        stoppedBecause: reason,
      );
    }

    final synced = pending
        .where((row) => result.acceptedIds.contains(row.entityId))
        .length;
    return SyncAttempt(synced: synced, remaining: pending.length - synced);
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

/// Short Hebrew line for offline / timeout / socket noise.
String syncFailureMessage(Object? error) {
  if (error == null) {
    return 'אין חיבור למחשב';
  }
  final text = error.toString().trim();
  if (text.isEmpty) {
    return 'אין חיבור למחשב';
  }
  final lower = text.toLowerCase();
  if (lower.contains('timeout') ||
      lower.contains('timed out') ||
      lower.contains('socket') ||
      lower.contains('clientexception') ||
      lower.contains('connection') ||
      lower.contains('network') ||
      lower.contains('failed host') ||
      lower.contains('errno') ||
      text.contains('אין חיבור')) {
    return 'אין חיבור למחשב';
  }
  if (text.length > 80) {
    return 'אין חיבור למחשב';
  }
  return text;
}
