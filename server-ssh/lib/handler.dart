import 'dart:convert';
import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import 'admin.dart';
import 'mailer.dart';
import 'server_config.dart';
import 'sync_store.dart';

Handler buildHandler({
  required SyncStore store,
  required String token,
  String adminUser = '',
  String adminPassword = '',
  MailSettings? mail,
  File? envFile,
  File? shopFile,
  File? reportFile,
  ShopSchedule? schedule,
  void Function()? onScheduleChanged,
}) {
  final gate = AdminGate(user: adminUser, password: adminPassword);
  final router = Router()
    ..post('/v1/sync', (Request request) => _sync(request, store))
    ..post('/v1/reports', (Request request) => _report(request, store));
  mountAdmin(
    router,
    store: store,
    gate: gate,
    mail: mail ?? MailSettings(),
    envFile: envFile,
    shopFile: shopFile,
    reportFile: reportFile,
    schedule: schedule ?? ShopSchedule(),
    onScheduleChanged: onScheduleChanged,
  );

  return (Request request) {
    final path = request.url.path;
    if (path == 'admin' || path.startsWith('admin/')) {
      return router(request);
    }
    if (request.headers['authorization'] != 'Bearer $token') {
      return _json(401, {'error': 'unauthorized'});
    }
    return router(request);
  };
}

Future<Response> _sync(Request request, SyncStore store) async {
  final body = await _object(request);
  if (body == null) {
    return _json(400, {'error': 'Expected a JSON object.'});
  }
  final deviceId = body['device_id'];
  final environment = body['environment'];
  final cursor = body['cursor'];
  final push = body['push'];
  if (deviceId is! String || deviceId.isEmpty) {
    return _json(400, {'error': 'device_id is required.'});
  }
  if (environment is! String || environment.isEmpty) {
    return _json(400, {'error': 'environment is required.'});
  }
  if (cursor is! num) {
    return _json(400, {'error': 'cursor is required.'});
  }
  if (push is! List) {
    return _json(400, {'error': 'push must be a list.'});
  }
  try {
    final ownerEmail = body['owner_email'];
    final pendingRaw = body['pending_count'];
    final pendingCount = pendingRaw is num ? pendingRaw.toInt() : null;
    final result = await store.exchange(
      deviceId: deviceId,
      environment: environment,
      cursor: cursor.toInt(),
      ownerEmail: ownerEmail is String ? ownerEmail : null,
      pendingCount: pendingCount,
      push: [
        for (final item in push)
          if (item is Map)
            Map<String, dynamic>.from(item)
          else
            throw const FormatException('Each push item must be an object.'),
      ],
    );
    return _json(200, result);
  } on FormatException catch (error) {
    return _json(400, {'error': error.message});
  }
}

Future<Response> _report(Request request, SyncStore store) async {
  final body = await _object(request);
  if (body == null) {
    return _json(400, {'error': 'Expected a JSON object.'});
  }
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
    return _json(400, {'error': 'The report is missing a required field.'});
  }
  final result = await store.submitReport(
    id: id,
    environment: environment,
    reportDate: reportDate,
    ownerEmail: ownerEmail,
    subject: subject,
    body: text,
  );
  return _json(200, result);
}

Future<Map<String, Object?>?> _object(Request request) async {
  final raw = await request.readAsString();
  if (raw.isEmpty) {
    return null;
  }
  final decoded = jsonDecode(raw);
  if (decoded is! Map) {
    return null;
  }
  return decoded.map((key, value) => MapEntry(key.toString(), value));
}

Response _json(int status, Map<String, Object?> body) {
  return Response(
    status,
    body: jsonEncode(body),
    headers: {'content-type': 'application/json'},
  );
}
