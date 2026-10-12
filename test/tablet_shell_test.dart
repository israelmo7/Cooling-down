import 'package:cooling_down/app.dart';
import 'package:cooling_down/data/db/app_database.dart';
import 'package:cooling_down/data/maintenance/tablet_maintenance.dart';
import 'package:cooling_down/domain/settings/device_settings.dart';
import 'package:cooling_down/presentation/check_out/check_out_panel.dart';
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
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.byKey(const Key('open-settings')), findsOneWidget);
    expect(find.text('קליטה'), findsOneWidget);
    expect(find.text('הוצאה'), findsOneWidget);
    expect(find.text('במקרר'), findsOneWidget);
    expect(find.text('חזה עוף'), findsOneWidget);
    expect(find.text('מקרר'), findsNothing);
    expect(find.text('מקרר מטבח'), findsNothing);
    expect(find.text('מטבח'), findsOneWidget);
    expect(find.byKey(const Key('confirm-check-in')), findsOneWidget);
    expect(find.byKey(const Key('confirm-check-out')), findsNothing);

    final checkIn = tester.widget<FilledButton>(
      find.byKey(const Key('confirm-check-in')),
    );
    expect(checkIn.onPressed, isNull);

    await tester.tap(find.text('חזה עוף'));
    await tester.pump();
    expect(
      tester
          .widget<FilledButton>(find.byKey(const Key('confirm-check-in')))
          .onPressed,
      isNotNull,
    );

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

    expect(find.text('מטבח'), findsWidgets);
    expect(find.text('אימות פעולה'), findsOneWidget);
    expect(
      tester.widget<Switch>(find.byKey(const Key('confirm-action'))).value,
      isFalse,
    );
    expect(find.text('שם הסביבה'), findsOneWidget);
    expect(find.text('שם המכשיר'), findsNothing);
    expect(find.text('מזהה: מטבח'), findsOneWidget);
    expect(find.text('אימייל הבעלים'), findsNothing);
    expect(find.text('מוצרים'), findsOneWidget);
    expect(find.text('חלב'), findsWidgets);
    expect(find.text('שליחת דוח בחצות'), findsNothing);
    expect(find.text('הטאבלט הזה הוא העותק המשותף'), findsNothing);
    expect(find.text('שרת דואר'), findsNothing);
    expect(find.text('שליחת הדוח היומי'), findsNothing);
    expect(find.byKey(const Key('settings-field-אסימון גישה')), findsNothing);
    expect(find.byKey(const Key('settings-field-כתובת המחשב')), findsNothing);
    expect(find.text('לוח ניהול'), findsOneWidget);
    expect(find.text('שינוי הגדרות'), findsOneWidget);

    final locked = tester.widget<TextField>(
      find.byKey(const Key('settings-field-שם הסביבה')),
    );
    expect(locked.readOnly, isTrue);

    await tester.tap(find.byKey(const Key('unlock-settings')));
    await tester.pump();
    await tester.enterText(find.byKey(const Key('settings-password')), 'nope');
    await tester.tap(find.byKey(const Key('confirm-settings-password')));
    await tester.pump();
    expect(find.text('הסיסמה שגויה.'), findsOneWidget);
    expect(
      tester
          .widget<TextField>(find.byKey(const Key('settings-field-שם הסביבה')))
          .readOnly,
      isTrue,
    );

    await tester.enterText(
      find.byKey(const Key('settings-password')),
      '123459876',
    );
    await tester.tap(find.byKey(const Key('confirm-settings-password')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(
      tester
          .widget<TextField>(find.byKey(const Key('settings-field-שם הסביבה')))
          .readOnly,
      isFalse,
    );
    expect(find.text('שמירה'), findsOneWidget);
    expect(find.byKey(const Key('settings-field-אסימון גישה')), findsOneWidget);
    expect(find.byKey(const Key('settings-field-כתובת המחשב')), findsOneWidget);

    await tester.ensureVisible(find.byKey(const Key('add-product')));
    await tester.pump();
    await tester.enterText(find.byKey(const Key('new-product-name')), 'גבינה');
    await tester.tap(find.byKey(const Key('add-product')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text('גבינה'), findsWidgets);

    Navigator.of(tester.element(find.text('הגדרות'))).pop();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('גבינה'), findsOneWidget);
    expect(find.text('מטבח'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    final closing = database.close();
    await tester.pump();
    await tester.pump(Duration.zero);
    await closing;
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  }, timeout: const Timeout(Duration(seconds: 30)));

  testWidgets('action confirmation asks before check-in and check-out', (
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
    await tester.tap(find.byKey(const Key('open-settings')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    await tester.ensureVisible(find.byKey(const Key('confirm-action')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('confirm-action')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text('האם אתה בטוח?'), findsOneWidget);
    expect(find.text('הפעלת אימות פעולה'), findsOneWidget);
    await tester.tap(find.byKey(const Key('confirm-recorded-action')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(
      tester.widget<Switch>(find.byKey(const Key('confirm-action'))).value,
      isTrue,
    );

    Navigator.of(tester.element(find.text('הגדרות'))).pop();
    await tester.pumpAndSettle();

    await tester.tap(find.text('חזה עוף'));
    await tester.pump();
    await tester.tap(find.byKey(const Key('confirm-check-in')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('האם אתה בטוח?'), findsOneWidget);
    expect(find.text('קליטה: חזה עוף ב-4.0 °C'), findsOneWidget);
    await tester.tap(find.text('ביטול'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('נשמר בטאבלט'), findsOneWidget);
    expect(find.text('4.0 °C'), findsOneWidget);

    await tester.tap(find.byKey(const Key('confirm-check-in')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tap(find.byKey(const Key('confirm-recorded-action')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump();
    expect(find.text('נשמר בטאבלט · 1 ממתינים לסנכרון'), findsOneWidget);
    expect(find.textContaining('נקלט'), findsOneWidget);
    await tester.pump(const Duration(seconds: 3));
    await tester.pump();
    expect(find.textContaining('נקלט'), findsNothing);

    await tester.tap(find.text('הוצאה'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tap(
      find.descendant(
        of: find.byType(CheckOutPanel),
        matching: find.text('חזה עוף'),
      ),
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('confirm-check-out')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text('האם אתה בטוח?'), findsOneWidget);
    expect(find.text('הוצאה: חזה עוף ב-4.0 °C'), findsOneWidget);
    await tester.tap(find.byKey(const Key('confirm-recorded-action')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump();
    expect(find.text('נשמר בטאבלט · 2 ממתינים לסנכרון'), findsOneWidget);
    expect(find.text('אין כרגע פריטים במקרר.'), findsWidgets);
    await tester.pump(const Duration(seconds: 3));
    await tester.pump();

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    final closing = database.close();
    await tester.pump();
    await tester.pump(Duration.zero);
    await closing;
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  }, timeout: const Timeout(Duration(seconds: 30)));

  testWidgets('check-in can record a product that is not on the list', (
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
    await tester.pump();

    await tester.tap(find.byKey(const Key('check-in-new-product')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    await tester.enterText(
      find.byKey(const Key('check-in-new-product-name')),
      'גבינה צהובה',
    );
    await tester.tap(find.byKey(const Key('confirm-new-check-in-product')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('גבינה צהובה'), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(find.byKey(const Key('confirm-check-in')))
          .onPressed,
      isNotNull,
    );

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    final closing = database.close();
    await tester.pump();
    await tester.pump(Duration.zero);
    await closing;
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  }, timeout: const Timeout(Duration(seconds: 30)));

  test('environment title is limited to 20 characters', () {
    expect(clipEnvironmentName('מטבח'), 'מטבח');
    expect(clipEnvironmentName('  '), 'מטבח');
    expect(clipEnvironmentName('א' * 25), 'א' * 20);
  });

  testWidgets('a temperature warning disappears on its own', (tester) async {
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

    await tester.tap(find.text('חזה עוף'));
    await tester.pump();
    for (var step = 0; step < 4; step++) {
      await tester.tap(find.byTooltip('העלאת טמפרטורה'));
      await tester.pump();
    }
    await tester.tap(find.byKey(const Key('confirm-check-in')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.textContaining('מחוץ לטווח'), findsOneWidget);

    await tester.pump(const Duration(seconds: 4));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.textContaining('מחוץ לטווח'), findsNothing);

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
