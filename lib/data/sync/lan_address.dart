import 'dart:io';

/// IPv4 address other tablets on this Wi-Fi can reach.
Future<String?> lanIpv4() async {
  final interfaces = await NetworkInterface.list(
    type: InternetAddressType.IPv4,
    includeLinkLocal: false,
  );
  String? fallback;
  for (final interface in interfaces) {
    for (final address in interface.addresses) {
      if (address.isLoopback) {
        continue;
      }
      final ip = address.address;
      if (ip.startsWith('192.168.') ||
          ip.startsWith('10.') ||
          _isPrivate172(ip)) {
        return ip;
      }
      fallback ??= ip;
    }
  }
  return fallback;
}

bool _isPrivate172(String ip) {
  final parts = ip.split('.');
  if (parts.length != 4 || parts.first != '172') {
    return false;
  }
  final second = int.tryParse(parts[1]);
  return second != null && second >= 16 && second <= 31;
}
