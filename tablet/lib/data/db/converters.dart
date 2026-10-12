import 'package:drift/drift.dart';

import '../../domain/entities/alert.dart';
import '../../domain/entities/refrigeration_log.dart';

class LogEventTypeConverter extends TypeConverter<LogEventType, String> {
  const LogEventTypeConverter();

  @override
  LogEventType fromSql(String fromDb) {
    return LogEventType.values.firstWhere(
      (value) => value.storageValue == fromDb,
    );
  }

  @override
  String toSql(LogEventType value) => value.storageValue;
}

class AlertSeverityConverter extends TypeConverter<AlertSeverity, String> {
  const AlertSeverityConverter();

  @override
  AlertSeverity fromSql(String fromDb) {
    return AlertSeverity.values.firstWhere(
      (value) => value.storageValue == fromDb,
    );
  }

  @override
  String toSql(AlertSeverity value) => value.storageValue;
}

class AlertKindConverter extends TypeConverter<AlertKind, String> {
  const AlertKindConverter();

  @override
  AlertKind fromSql(String fromDb) {
    return AlertKind.values.firstWhere((value) => value.storageValue == fromDb);
  }

  @override
  String toSql(AlertKind value) => value.storageValue;
}

enum SyncStatus {
  pending('pending'),
  inFlight('in_flight'),
  synced('synced'),
  failed('failed');

  const SyncStatus(this.storageValue);

  final String storageValue;
}

class SyncStatusConverter extends TypeConverter<SyncStatus, String> {
  const SyncStatusConverter();

  @override
  SyncStatus fromSql(String fromDb) {
    return SyncStatus.values.firstWhere(
      (value) => value.storageValue == fromDb,
    );
  }

  @override
  String toSql(SyncStatus value) => value.storageValue;
}
