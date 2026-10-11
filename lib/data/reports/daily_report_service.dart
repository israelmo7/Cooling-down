import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../core/clock.dart';
import '../../domain/entities/alert.dart';
import '../../domain/entities/refrigeration_log.dart';
import '../../domain/reports/daily_report.dart';
import '../../domain/repositories/settings_repository.dart';
import '../../domain/settings/device_settings.dart';
import '../db/app_database.dart';
import '../sync/gateway_factory.dart';
import '../sync/sync_gateway.dart';

class DailyReportService {
  DailyReportService(
    this._db, {
    required this.settings,
    Clock? clock,
    Uuid? uuid,
    SyncGateway Function(DeviceSettings settings)? gatewayFor,
  }) : _clock = clock ?? const Clock(),
       _uuid = uuid ?? const Uuid(),
       _gatewayFor = gatewayFor ?? gatewayForSettings;

  final AppDatabase _db;
  final SettingsRepository settings;
  final Clock _clock;
  final Uuid _uuid;
  final SyncGateway Function(DeviceSettings settings) _gatewayFor;

  Stream<StoredDailyReport?> watchLatest() {
    final query = _db.select(_db.dailyReports)
      ..orderBy([
        (table) =>
            OrderingTerm(expression: table.createdAt, mode: OrderingMode.desc),
      ])
      ..limit(1);
    return query.watch().map((rows) {
      if (rows.isEmpty) {
        return null;
      }
      return _stored(rows.first);
    });
  }

  Future<String> deliverToday({required bool manual}) async {
    final current = await settings.ensure();
    final nowLocal = _clock.now().toLocal();
    final date = reportDateKey(nowLocal);
    final existing = await _find(current.environmentName, date);

    if (!manual &&
        !isDailyReportDue(
          enabled: current.dailyReportEnabled,
          nowLocal: nowLocal,
          hour: current.reportHour,
          minute: current.reportMinute,
          recordedStatus: existing?.status,
        )) {
      return '';
    }

    if (existing != null &&
        (existing.status == ReportStatus.sent ||
            existing.status == ReportStatus.alreadySent)) {
      return 'Already emailed for today.';
    }
    if (current.ownerEmail.trim().isEmpty) {
      return 'Add the owner email in Settings first.';
    }

    final content = await _compose(current, nowLocal);
    final id = existing?.id ?? _uuid.v4();
    if (existing == null) {
      await _db
          .into(_db.dailyReports)
          .insert(
            DailyReportsCompanion.insert(
              id: id,
              environmentName: current.environmentName,
              reportDate: date,
              ownerEmail: current.ownerEmail.trim(),
              subject: content.subject,
              body: content.body,
              status: ReportStatus.waiting,
              createdAt: _clock.now(),
            ),
          );
    } else {
      await (_db.update(
        _db.dailyReports,
      )..where((table) => table.id.equals(id))).write(
        DailyReportsCompanion(
          ownerEmail: Value(current.ownerEmail.trim()),
          subject: Value(content.subject),
          body: Value(content.body),
          status: const Value(ReportStatus.waiting),
          lastError: const Value(null),
        ),
      );
    }

    if (!current.hasServer) {
      return 'Saved on this tablet. Add a server to email it.';
    }

    final result = await _gatewayFor(current).postReport(
      ReportPost(
        id: id,
        environment: current.environmentName,
        reportDate: date,
        ownerEmail: current.ownerEmail.trim(),
        subject: content.subject,
        body: content.body,
      ),
    );
    final emailed =
        result.status == ReportStatus.sent ||
        result.status == ReportStatus.alreadySent;
    await (_db.update(
      _db.dailyReports,
    )..where((table) => table.id.equals(id))).write(
      DailyReportsCompanion(
        status: Value(result.status),
        sentAt: emailed ? Value(_clock.now()) : const Value.absent(),
        lastError: Value(result.error),
      ),
    );
    return _message(result);
  }

  Future<DailyReportContent> _compose(
    DeviceSettings settings,
    DateTime nowLocal,
  ) async {
    final day = DateTime(nowLocal.year, nowLocal.month, nowLocal.day);
    final fridges = await _db.select(_db.fridges).get();
    final fridgeNames = {for (final fridge in fridges) fridge.id: fridge.name};
    final logs = await _db.select(_db.refrigerationLogs).get();
    final todays = logs.where((row) => _sameDay(row.occurredAt, day)).toList()
      ..sort((a, b) => a.occurredAt.compareTo(b.occurredAt));
    final alerts = await _db.select(_db.alerts).get();
    final holdings = await _openHoldings(fridgeNames);

    return buildDailyReport(
      environmentName: settings.environmentName,
      day: day,
      movements: [
        for (final row in todays)
          ReportMovement(
            productName: row.productNameSnapshot,
            eventLabel: row.eventType == LogEventType.checkIn ? 'in' : 'out',
            temperatureCelsius: row.temperatureCelsius,
            occurredAt: row.occurredAt,
            fridgeName: fridgeNames[row.fridgeId] ?? row.fridgeId,
          ),
      ],
      stillInside: holdings,
      temperatureAlerts: [
        for (final row in alerts)
          if (row.kind == AlertKind.temperatureOutOfRange &&
              _sameDay(row.createdAt, day))
            ReportNotice(message: row.message),
      ],
      conflicts: [
        for (final row in alerts)
          if (row.kind == AlertKind.syncConflict &&
              _sameDay(row.createdAt, day))
            ReportNotice(message: row.message),
      ],
    );
  }

  Future<List<ReportHolding>> _openHoldings(
    Map<String, String> fridgeNames,
  ) async {
    final logs = await _db.select(_db.refrigerationLogs).get();
    final closed = logs
        .where((row) => row.eventType == LogEventType.checkOut)
        .map((row) => row.movementId)
        .toSet();
    final open =
        logs
            .where(
              (row) =>
                  row.eventType == LogEventType.checkIn &&
                  !closed.contains(row.movementId),
            )
            .toList()
          ..sort((a, b) => b.occurredAt.compareTo(a.occurredAt));
    return [
      for (final row in open)
        ReportHolding(
          productName: row.productNameSnapshot,
          fridgeName: fridgeNames[row.fridgeId] ?? row.fridgeId,
          checkedInAt: row.occurredAt,
        ),
    ];
  }

  Future<DailyReportRow?> _find(String environment, String date) {
    return (_db.select(_db.dailyReports)..where(
          (table) =>
              table.environmentName.equals(environment) &
              table.reportDate.equals(date),
        ))
        .getSingleOrNull();
  }

  bool _sameDay(DateTime instant, DateTime day) {
    final local = instant.toLocal();
    return local.year == day.year &&
        local.month == day.month &&
        local.day == day.day;
  }

  StoredDailyReport _stored(DailyReportRow row) {
    return StoredDailyReport(
      id: row.id,
      environmentName: row.environmentName,
      reportDate: row.reportDate,
      ownerEmail: row.ownerEmail,
      subject: row.subject,
      body: row.body,
      status: row.status,
      createdAt: row.createdAt,
      sentAt: row.sentAt,
      lastError: row.lastError,
    );
  }

  String _message(ReportPostResult result) {
    switch (result.status) {
      case ReportStatus.sent:
        return 'Emailed the owner.';
      case ReportStatus.alreadySent:
        return 'Already emailed for today.';
      case ReportStatus.stored:
        return 'Saved on the server. Email is not set up there yet.';
      case ReportStatus.waiting:
        return 'Saved on this tablet. Add a server to email it.';
      default:
        return result.error ?? 'The report could not be emailed.';
    }
  }
}
