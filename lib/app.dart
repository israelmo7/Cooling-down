import 'package:flutter/material.dart';

import 'presentation/shell/tablet_shell.dart';

class CoolingDownApp extends StatelessWidget {
  const CoolingDownApp({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF0A6E8A),
    );
    return MaterialApp(
      title: 'Cooling down',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: colorScheme,
        scaffoldBackgroundColor: colorScheme.surfaceContainerLow,
        materialTapTargetSize: MaterialTapTargetSize.padded,
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            minimumSize: const Size(64, 72),
            textStyle: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        navigationBarTheme: NavigationBarThemeData(
          height: 88,
          labelTextStyle: WidgetStateProperty.all(
            const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
      ),
      home: const TabletShell(),
    );
  }
}
