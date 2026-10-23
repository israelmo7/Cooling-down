import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Keeps an Android tablet awake and pinned. Other platforms do nothing.
class Kiosk {
  static const _channel = MethodChannel('cooling_down/kiosk');

  static bool get supported => !kIsWeb && Platform.isAndroid;

  static Future<void> pin() => _call('pin');

  static Future<void> unpin() => _call('unpin');

  /// Leaves the pinned app so the browser can open, and pins again on return.
  static Future<void> openOutside() => _call('openOutside');

  static Future<void> _call(String method) async {
    if (!supported) {
      return;
    }
    try {
      await _channel.invokeMethod<bool>(method);
    } on PlatformException {
      // The screen stays on even when pinning is unavailable.
    }
  }
}
