import '../entities/open_holding.dart';
import '../entities/refrigeration_log.dart';

/// Insert-only log of check-in and check-out events.
///
/// [occurredAt] is omitted by the tablet UI so the clock captures confirm time.
abstract class LogRepository {
  Future<RefrigerationLog> insertCheckIn({
    required String productId,
    required String fridgeId,
    required double temperatureCelsius,
    DateTime? occurredAt,
    required String workerName,
    DateTime? dueAt,
  });

  /// Mean check-in temperature for [productId], or null when it has none.
  Future<double?> averageCheckInCelsius(String productId);

  Future<RefrigerationLog> insertCheckOut({
    required String movementId,
    required double temperatureCelsius,
    DateTime? occurredAt,
    required String workerName,
  });

  Stream<List<OpenHolding>> watchOpenHoldings();
}
