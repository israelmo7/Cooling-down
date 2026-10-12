/// Clock used when a check-in or check-out is confirmed.
class Clock {
  const Clock();

  DateTime now() => DateTime.now().toUtc();
}

/// Fixed clock for tests that need a known confirm time.
class FixedClock extends Clock {
  const FixedClock(this.instant);

  final DateTime instant;

  @override
  DateTime now() => instant.toUtc();
}
