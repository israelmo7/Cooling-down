/// How long a chosen worker stays signed in when settings have no timeout.
const defaultWorkerIdleLimit = Duration(seconds: 600);

/// The worker currently responsible for actions on this tablet.
class WorkerSession {
  const WorkerSession({this.workerId, this.workerName = '', this.activeAt});

  final String? workerId;
  final String workerName;
  final DateTime? activeAt;

  bool isActive(DateTime now, {Duration idle = defaultWorkerIdleLimit}) {
    final id = workerId;
    final at = activeAt;
    if (id == null || id.isEmpty || workerName.trim().isEmpty || at == null) {
      return false;
    }
    return now.toUtc().difference(at.toUtc()) < idle;
  }
}

/// A check-in or check-out needs someone signed in.
bool workerAllowsAction({
  required WorkerSession? session,
  required DateTime now,
  Duration idle = defaultWorkerIdleLimit,
}) {
  return session?.isActive(now, idle: idle) ?? false;
}
