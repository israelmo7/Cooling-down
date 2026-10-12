class SyncAttempt {
  const SyncAttempt({
    required this.synced,
    required this.remaining,
    this.stoppedBecause,
  });

  final int synced;
  final int remaining;
  final String? stoppedBecause;
}

/// Pushes queued local inserts when a gateway accepts them.
abstract class SyncRepository {
  Stream<int> watchPendingCount();

  Future<SyncAttempt> trySync();
}
