import 'package:cooling_down/app.dart';
import 'package:cooling_down/data/db/app_database.dart';
import 'package:cooling_down/data/maintenance/tablet_maintenance.dart';
import 'package:cooling_down/data/repositories/drift_settings_repository.dart';
import 'package:cooling_down/presentation/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('settings mentions a missing computer, then a failed link', (
    tester,
  ) async {
    final database = AppDatabase.memory();
    final settings = DriftSettingsRepository(database);
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(database),
          tabletMaintenanceProvider.overrideWithValue(TabletMaintenance.idle()),
        ],
        child: const CoolingDownApp(),
      ),
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('open-settings')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byKey(const Key('computer-details-missing')), findsOneWidget);
    expect(find.text('חסרים פרטי המחשב.'), findsOneWidget);
    expect(find.byKey(const Key('computer-unreachable')), findsNothing);
    expect(find.byKey(const Key('release-kiosk')), findsNothing);
    expect(
      tester
          .widget<Text>(find.byKey(const Key('computer-details-missing')))
          .style
          ?.color,
      isNot(const Color(0xFFB91C1C)),
    );

    final current = await settings.ensure();
    await settings.save(
      current.copyWith(
        serverUrl: 'http://192.168.1.20:8080',
        serverToken: 'secret',
      ),
    );
    await settings.recordSync(error: 'failed');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.byKey(const Key('computer-details-missing')), findsNothing);
    expect(find.text('אין חיבור למחשב'), findsOneWidget);
    expect(
      tester
          .widget<Text>(find.byKey(const Key('computer-unreachable')))
          .style
          ?.color,
      const Color(0xFFB91C1C),
    );
    expect(find.text('failed'), findsNothing);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    final closing = database.close();
    await tester.pump();
    await tester.pump(Duration.zero);
    await closing;
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}
