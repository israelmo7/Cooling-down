enum AlertSeverity {
  info('info'),
  warning('warning'),
  critical('critical');

  const AlertSeverity(this.storageValue);

  final String storageValue;
}

enum AlertKind {
  temperatureOutOfRange('temperature_out_of_range');

  const AlertKind(this.storageValue);

  final String storageValue;
}

/// Recorded when a saved temperature falls outside the fridge band.
class Alert {
  const Alert({
    required this.id,
    required this.severity,
    required this.kind,
    this.productId,
    this.logId,
    required this.message,
    required this.createdAt,
    this.acknowledgedAt,
  });

  final String id;
  final AlertSeverity severity;
  final AlertKind kind;
  final String? productId;
  final String? logId;
  final String message;
  final DateTime createdAt;
  final DateTime? acknowledgedAt;
}
