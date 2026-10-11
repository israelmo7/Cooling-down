import 'sync_gateway.dart';

/// Keeps queued rows local. Used until a PostgreSQL gateway is configured.
class OfflineSyncGateway implements SyncGateway {
  const OfflineSyncGateway();

  @override
  Future<bool> pushInsert({
    required String entityType,
    required String entityId,
    required String payloadJson,
  }) async {
    return false;
  }
}
