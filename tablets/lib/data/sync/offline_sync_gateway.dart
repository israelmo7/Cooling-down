import 'sync_gateway.dart';

/// Keeps queued rows on the tablet until a server address is saved.
class OfflineSyncGateway implements SyncGateway {
  const OfflineSyncGateway();

  @override
  Future<SyncExchange> exchange(SyncRequest request) async {
    return const SyncExchange.offline();
  }

  @override
  Future<ReportPostResult> postReport(ReportPost report) async {
    return const ReportPostResult.waiting();
  }
}
