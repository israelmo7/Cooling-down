/// One queued insert the tablet wants the server to keep.
class SyncPushItem {
  const SyncPushItem({
    required this.entityType,
    required this.entityId,
    required this.payloadJson,
  });

  final String entityType;
  final String entityId;
  final String payloadJson;
}

class SyncRequest {
  const SyncRequest({
    required this.deviceId,
    required this.environment,
    required this.cursor,
    required this.push,
  });

  final String deviceId;
  final String environment;
  final int cursor;
  final List<SyncPushItem> push;
}

class SyncChange {
  const SyncChange({
    required this.seq,
    required this.entityType,
    required this.entityId,
    required this.deviceId,
    required this.payload,
  });

  final int seq;
  final String entityType;
  final String entityId;
  final String deviceId;
  final Map<String, Object?> payload;
}

class SyncConflict {
  const SyncConflict({required this.entityId, required this.reason});

  final String entityId;
  final String reason;
}

class SyncExchange {
  const SyncExchange({
    required this.reachable,
    this.cursor = 0,
    this.acceptedIds = const [],
    this.conflicts = const [],
    this.changes = const [],
    this.error,
  });

  const SyncExchange.offline([String? error])
    : this(reachable: false, error: error ?? 'offline');

  final bool reachable;
  final int cursor;
  final List<String> acceptedIds;
  final List<SyncConflict> conflicts;
  final List<SyncChange> changes;
  final String? error;
}

class ReportPost {
  const ReportPost({
    required this.id,
    required this.environment,
    required this.reportDate,
    required this.ownerEmail,
    required this.subject,
    required this.body,
  });

  final String id;
  final String environment;
  final String reportDate;
  final String ownerEmail;
  final String subject;
  final String body;
}

class ReportPostResult {
  const ReportPostResult({required this.status, this.error});

  const ReportPostResult.waiting() : this(status: 'waiting');

  final String status;
  final String? error;
}

/// Remote side of sync. A tablet with no server uses an offline gateway.
abstract class SyncGateway {
  const SyncGateway();

  Future<SyncExchange> exchange(SyncRequest request);

  Future<ReportPostResult> postReport(ReportPost report);
}
