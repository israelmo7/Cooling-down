/// Remote side of the outbox. A true result means the insert was accepted.
abstract class SyncGateway {
  const SyncGateway();

  Future<bool> pushInsert({
    required String entityType,
    required String entityId,
    required String payloadJson,
  });
}
