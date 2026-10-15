import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'platform/kiosk.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  unawaited(Kiosk.pin());
  runApp(const ProviderScope(child: CoolingDownApp()));
}
