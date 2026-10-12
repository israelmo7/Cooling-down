import '../entities/worker.dart';

/// How long a chosen worker stays signed in without a tap.
const workerIdleLimit = Duration(minutes: 10);

/// The worker currently responsible for actions on this tablet.
class WorkerSession {
  const WorkerSession({this.workerId, this.workerName = '', this.activeAt});

  final String? workerId;
  final String workerName;
  final DateTime? activeAt;

  bool isActive(DateTime now) {
    final id = workerId;
    final at = activeAt;
    if (id == null || id.isEmpty || workerName.trim().isEmpty || at == null) {
      return false;
    }
    return now.toUtc().difference(at.toUtc()) < workerIdleLimit;
  }
}

/// Check-in and check-out stay open until a worker list exists.
bool workerAllowsAction({
  required List<Worker>? workers,
  required WorkerSession? session,
  required DateTime now,
}) {
  if (workers == null || workers.isEmpty) {
    return true;
  }
  return session?.isActive(now) ?? false;
}
