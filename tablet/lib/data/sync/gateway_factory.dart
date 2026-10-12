import 'package:http/http.dart' as http;

import '../../domain/settings/device_settings.dart';
import 'http_sync_gateway.dart';
import 'offline_sync_gateway.dart';
import 'sync_gateway.dart';

SyncGateway gatewayForSettings(DeviceSettings settings, {http.Client? client}) {
  if (!settings.hasServer) {
    return const OfflineSyncGateway();
  }
  return HttpSyncGateway(
    baseUrl: settings.serverUrl,
    token: settings.serverToken,
    client: client,
  );
}
