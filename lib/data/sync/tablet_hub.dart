import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';

import '../../domain/entities/refrigeration_log.dart';
import '../../domain/repositories/settings_repository.dart';
import '../../domain/settings/device_settings.dart';
import '../db/app_database.dart';
import '../reports/hub_report.dart';
import 'feed.dart';
import 'lan_address.dart';
import 'remote_apply.dart';
import 'sync_gateway.dart';

const hubPort = 8080;

class HubStatus {
  const HubStatus({this.listening = false, this.address, this.error});

  final bool listening;
  final String? address;
  final String? error;
}

/// Serves this tablet's database to other tablets on the same Wi-Fi.
class TabletHub {
  TabletHub(this._db, this._settings);

  final AppDatabase _db;
  final SettingsRepository _settings;
  RemoteApplier get _applier => RemoteApplier(_db);
  final _statuses = StreamController<HubStatus>.broadcast();

  HttpServer? _server;
  HubStatus current = const HubStatus();

  int? get port => _server?.port;
  var _generation = 0;

  Stream<HubStatus> watch() async* {
    yield current;
    yield* _statuses.stream;
  }

  Future<void> apply(
    DeviceSettings? settings, {
    int port = hubPort,
    bool restart = false,
  }) async {
    final generation = ++_generation;
    if (settings == null || !settings.hubEnabled) {
      await _stop();
      return;
    }
    if (restart) {
      await _stop();
    }
    if (_server != null) {
      return;
    }
    try {
      await backfillSyncFeed(_db);
      if (generation != _generation) {
        return;
      }
      final server = await HttpServer.bind(InternetAddress.anyIPv4, port);
      if (generation != _generation) {
        await server.close(force: true);
        return;
      }
      _server = server;
      server.listen(_onRequest);
      final ip = await lanIpv4();
      _publish(
        HubStatus(
          listening: true,
          address: 'http://${ip ?? 'this-tablet'}:${server.port}',
        ),
      );
    } on Object catch (error) {
      if (generation != _generation) {
        return;
      }
      _publish(HubStatus(error: error.toString()));
    }
  }

  Future<void> dispose() async {
    _generation += 1;
    await _stop();
    await _statuses.close();
  }

  Future<void> _stop() async {
    final server = _server;
    _server = null;
    if (server != null) {
      await server.close(force: true);
    }
    _publish(const HubStatus());
  }

  Future<void> _onRequest(HttpRequest request) async {
    try {
      final settings = await _settings.ensure();
      final auth = request.headers.value(HttpHeaders.authorizationHeader);
      if (settings.serverToken.isEmpty ||
          auth != 'Bearer ${settings.serverToken}') {
        await _write(request, 401, {'error': 'unauthorized'});
        return;
      }
      final raw = await utf8.decoder.bind(request).join();
      final body = _object(raw);
      if (request.method != 'POST' || body == null) {
        await _write(request, 400, {'error': 'Expected a JSON object.'});
        return;
      }
      if (request.uri.path == '/v1/sync') {
        final result = await _exchange(settings, body);
        await _write(request, 200, result);
        return;
      }
      if (request.uri.path == '/v1/reports') {
        final result = await _report(settings, body);
        await _write(request, result.statusCode, result.body);
        return;
      }
      await _write(request, 404, {'error': 'not found'});
    } on FormatException catch (error) {
      await _write(request, 400, {'error': error.message});
    } on Object catch (error) {
      await _write(request, 500, {'error': error.toString()});
    }
  }

  Future<Map<String, Object?>> _exchange(
    DeviceSettings settings,
    Map<String, Object?> body,
  ) async {
    final deviceId = body['device_id'];
    final environment = body['environment'];
    final cursor = body['cursor'];
    final push = body['push'];
    if (deviceId is! String || deviceId.isEmpty) {
      throw const FormatException('device_id is required.');
    }
    if (environment is! String || environment.isEmpty) {
      throw const FormatException('environment is required.');
    }
    if (environment != settings.environmentName) {
      throw FormatException(
        'This tablet is sharing ${settings.environmentName}.',
      );
    }
    if (cursor is! num) {
      throw const FormatException('cursor is required.');
    }
    if (push is! List) {
      throw const FormatException('push must be a list.');
    }

    final accepted = <String>[];
    final conflicts = <Map<String, String>>[];
    for (final item in push) {
      if (item is! Map) {
        throw const FormatException('Each push item must be an object.');
      }
      final entityType = item['entity_type'];
      final entityId = item['entity_id'];
      final payload = item['payload'];
      if (entityType is! String || entityId is! String || payload is! Map) {
        throw const FormatException('A push item is incomplete.');
      }
      final bodyPayload = Map<String, Object?>.from(payload);
      if (bodyPayload['id'] != entityId) {
        throw const FormatException('The payload id must match the entity id.');
      }
      final already = await _feedHas(entityType, entityId);
      await _applier.apply([
        SyncChange(
          seq: 0,
          entityType: entityType,
          entityId: entityId,
          deviceId: deviceId,
          payload: bodyPayload,
        ),
      ]);
      if (!already &&
          entityType == 'refrigeration_log' &&
          bodyPayload['event_type'] == LogEventType.checkOut.storageValue) {
        final movementId = bodyPayload['movement_id'];
        if (movementId is String && await _checkoutCount(movementId) > 1) {
          conflicts.add({
            'entity_id': entityId,
            'reason': 'movement already checked out',
          });
        }
      }
      accepted.add(entityId);
    }

    final changes =
        await (_db.select(_db.syncFeed)
              ..where((table) => table.seq.isBiggerThanValue(cursor.toInt()))
              ..orderBy([(table) => OrderingTerm(expression: table.seq)])
              ..limit(500))
            .get();
    final maxRow =
        await (_db.select(_db.syncFeed)
              ..orderBy([
                (table) => OrderingTerm(
                  expression: table.seq,
                  mode: OrderingMode.desc,
                ),
              ])
              ..limit(1))
            .getSingleOrNull();
    final maxSeq = maxRow?.seq ?? 0;
    final lastSeq = changes.isEmpty ? maxSeq : changes.last.seq;
    return {
      'cursor': lastSeq,
      'accepted': accepted,
      'conflicts': conflicts,
      'changes': [
        for (final row in changes)
          {
            'seq': row.seq,
            'entity_type': row.entityType,
            'entity_id': row.entityId,
            'device_id': row.originDeviceId,
            'payload': jsonDecode(row.payloadJson),
          },
      ],
    };
  }

  Future<({int statusCode, Map<String, Object?> body})> _report(
    DeviceSettings settings,
    Map<String, Object?> body,
  ) async {
    final id = body['id'];
    final environment = body['environment'];
    final reportDate = body['report_date'];
    final ownerEmail = body['owner_email'];
    final subject = body['subject'];
    final text = body['body'];
    if (id is! String ||
        environment is! String ||
        reportDate is! String ||
        ownerEmail is! String ||
        subject is! String ||
        text is! String ||
        id.isEmpty ||
        environment.isEmpty ||
        reportDate.isEmpty ||
        ownerEmail.isEmpty) {
      return (
        statusCode: 400,
        body: {'error': 'The report is missing a required field.'},
      );
    }
    if (environment != settings.environmentName) {
      return (
        statusCode: 400,
        body: {'error': 'This tablet is sharing ${settings.environmentName}.'},
      );
    }
    final result = await acceptOwnerReport(
      db: _db,
      settings: settings,
      report: ReportPost(
        id: id,
        environment: environment,
        reportDate: reportDate,
        ownerEmail: ownerEmail,
        subject: subject,
        body: text,
      ),
    );
    return (
      statusCode: 200,
      body: {
        'status': result.status,
        if (result.error != null) 'error': result.error!,
      },
    );
  }

  Future<bool> _feedHas(String entityType, String entityId) async {
    final row =
        await (_db.select(_db.syncFeed)..where(
              (table) =>
                  table.entityType.equals(entityType) &
                  table.entityId.equals(entityId),
            ))
            .getSingleOrNull();
    return row != null;
  }

  Future<int> _checkoutCount(String movementId) async {
    final count = _db.refrigerationLogs.id.count();
    final query = _db.selectOnly(_db.refrigerationLogs)
      ..addColumns([count])
      ..where(
        _db.refrigerationLogs.movementId.equals(movementId) &
            _db.refrigerationLogs.eventType.equalsValue(LogEventType.checkOut),
      );
    return (await query.getSingle()).read(count) ?? 0;
  }

  void _publish(HubStatus status) {
    current = status;
    if (!_statuses.isClosed) {
      _statuses.add(status);
    }
  }

  Future<void> _write(
    HttpRequest request,
    int status,
    Map<String, Object?> body,
  ) async {
    request.response.statusCode = status;
    request.response.headers.contentType = ContentType.json;
    request.response.write(jsonEncode(body));
    await request.response.close();
  }
}

Map<String, Object?>? _object(String raw) {
  if (raw.isEmpty) {
    return null;
  }
  final decoded = jsonDecode(raw);
  if (decoded is! Map) {
    return null;
  }
  return decoded.map((key, value) => MapEntry(key.toString(), value));
}
