import 'package:cooling_down/app.dart';
import 'package:cooling_down/data/db/app_database.dart';
import 'package:cooling_down/data/maintenance/tablet_maintenance.dart';
import 'package:cooling_down/presentation/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('tablet shell shows check-in, check-out, and the live feed', (
    tester,
  ) async {
    final database = AppDatabase.memory();
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
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.byKey(const Key('open-settings')), findsOneWidget);
    expect(find.text('קליטה'), findsOneWidget);
    expect(find.text('הוצאה'), findsOneWidget);
    expect(find.text('במקרר'), findsOneWidget);
    expect(find.text('חזה עוף'), findsOneWidget);
    expect(find.text('מקרר מטבח'), findsOneWidget);
    expect(find.byKey(const Key('confirm-check-in')), findsOneWidget);
    expect(find.byKey(const Key('confirm-check-out')), findsNothing);

    final checkIn = tester.widget<FilledButton>(
      find.byKey(const Key('confirm-check-in')),
    );
    expect(checkIn.onPressed, isNull);

    await tester.tap(find.text('הוצאה'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.byKey(const Key('confirm-check-out')), findsOneWidget);
    final checkOut = tester.widget<FilledButton>(
      find.byKey(const Key('confirm-check-out')),
    );
    expect(checkOut.onPressed, isNull);

    await tester.tap(find.text('במקרר'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text('אין כרגע פריטים במקרר.'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    final closing = database.close();
    await tester.pump();
    await tester.pump(Duration.zero);
    await closing;
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  }, timeout: const Timeout(Duration(seconds: 30)));

  testWidgets('settings opens from the top bar', (tester) async {
    final database = AppDatabase.memory();
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
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('שם הסביבה'), findsOneWidget);
    expect(find.text('אימייל הבעלים'), findsOneWidget);
    expect(find.text('שליחת דוח בחצות'), findsOneWidget);
    expect(find.text('שליחת הדוח היומי'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    final closing = database.close();
    await tester.pump();
    await tester.pump(Duration.zero);
    await closing;
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  }, timeout: const Timeout(Duration(seconds: 30)));
}
