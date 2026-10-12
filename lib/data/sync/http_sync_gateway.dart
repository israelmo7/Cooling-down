import 'dart:convert';

import 'package:http/http.dart' as http;

import 'sync_gateway.dart';

/// Talks to the optional Cooling down server.
class HttpSyncGateway implements SyncGateway {
  HttpSyncGateway({
    required this.baseUrl,
    required this.token,
    http.Client? client,
  }) : _client = client ?? http.Client();

  final String baseUrl;
  final String token;
  final http.Client _client;

  Map<String, String> get _headers => {
    'authorization': 'Bearer $token',
    'content-type': 'application/json',
  };

  @override
  Future<SyncExchange> exchange(SyncRequest request) async {
    try {
      final response = await _client
          .post(
            Uri.parse('$baseUrl/v1/sync'),
            headers: _headers,
            body: jsonEncode({
              'device_id': request.deviceId,
              'environment': request.environment,
              'cursor': request.cursor,
              if (request.ownerEmail.trim().isNotEmpty)
                'owner_email': request.ownerEmail.trim(),
              'push': [
                for (final item in request.push)
                  {
                    'entity_type': item.entityType,
                    'entity_id': item.entityId,
                    'payload': jsonDecode(item.payloadJson),
                  },
              ],
            }),
          )
          .timeout(const Duration(seconds: 20));
      if (response.statusCode == 401) {
        return const SyncExchange.offline('המחשב דחה את האסימון.');
      }
      if (response.statusCode != 200) {
        return SyncExchange.offline('המחשב החזיר ${response.statusCode}.');
      }
      final decoded = jsonDecode(response.body);
      if (decoded is! Map) {
        return const SyncExchange.offline(
          'התשובה מהמחשב לא קריאה.',
        );
      }
      return SyncExchange(
        reachable: true,
        cursor: (decoded['cursor'] as num?)?.toInt() ?? request.cursor,
        acceptedIds: [
          for (final id in (decoded['accepted'] as List? ?? const []))
            id.toString(),
        ],
        conflicts: [
          for (final row in (decoded['conflicts'] as List? ?? const []))
            if (row is Map)
              SyncConflict(
                entityId: row['entity_id']?.toString() ?? '',
                reason: row['reason']?.toString() ?? '',
              ),
        ],
        changes: [
          for (final row in (decoded['changes'] as List? ?? const []))
            if (row is Map)
              SyncChange(
                seq: (row['seq'] as num?)?.toInt() ?? 0,
                entityType: row['entity_type']?.toString() ?? '',
                entityId: row['entity_id']?.toString() ?? '',
                deviceId: row['device_id']?.toString() ?? '',
                payload: _payloadMap(row['payload']),
              ),
        ],
      );
    } on Object catch (error) {
      return SyncExchange.offline(error.toString());
    }
  }

  @override
  Future<ReportPostResult> postReport(ReportPost report) async {
    try {
      final response = await _client
          .post(
            Uri.parse('$baseUrl/v1/reports'),
            headers: _headers,
            body: jsonEncode({
              'id': report.id,
              'environment': report.environment,
              'report_date': report.reportDate,
              'owner_email': report.ownerEmail,
              'subject': report.subject,
              'body': report.body,
            }),
          )
          .timeout(const Duration(seconds: 20));
      if (response.statusCode == 401) {
        return const ReportPostResult(
          status: 'failed',
          error: 'המחשב דחה את האסימון.',
        );
      }
      if (response.statusCode != 200) {
        return ReportPostResult(
          status: 'failed',
          error: 'המחשב החזיר ${response.statusCode}.',
        );
      }
      final decoded = jsonDecode(response.body);
      if (decoded is! Map) {
        return const ReportPostResult(
          status: 'failed',
          error: 'התשובה מהמחשב לא קריאה.',
        );
      }
      return ReportPostResult(
        status: decoded['status']?.toString() ?? 'failed',
        error: decoded['error']?.toString(),
      );
    } on Object catch (error) {
      return ReportPostResult(status: 'failed', error: error.toString());
    }
  }
}

Map<String, Object?> _payloadMap(Object? value) {
  if (value is! Map) {
    return const {};
  }
  return value.map((key, item) => MapEntry(key.toString(), item as Object?));
}
