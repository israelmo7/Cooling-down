import 'package:cooling_down/app.dart';
import 'package:cooling_down/data/db/app_database.dart';
import 'package:cooling_down/data/maintenance/tablet_maintenance.dart';
import 'package:cooling_down/data/repositories/drift_settings_repository.dart';
import 'package:cooling_down/data/repositories/drift_worker_repository.dart';
import 'package:cooling_down/domain/settings/device_settings.dart';
import 'package:cooling_down/domain/workers/worker_refresh.dart';
import 'package:cooling_down/presentation/check_out/check_out_panel.dart';
import 'package:cooling_down/presentation/format.dart';
import 'package:cooling_down/presentation/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> signInWorker(AppDatabase database) async {
  final workers = DriftWorkerRepository(database);
  final worker = await workers.addWorker('דנה');
  await workers.selectWorker(worker!.id);
}

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
    final titleBar = tester.widget<AppBar>(find.byType(AppBar));
    expect(titleBar.centerTitle, isTrue);
    expect(titleBar.titleTextStyle?.fontSize, 32);
    expect(find.text('קליטה'), findsOneWidget);
    expect(find.text('הוצאה'), findsOneWidget);
    expect(find.text('במקרר'), findsOneWidget);
    expect(find.text('חזה עוף'), findsOneWidget);
    expect(find.text('מקרר'), findsNothing);
    expect(find.text('מקרר מטבח'), findsNothing);
    expect(find.text('מטבח'), findsOneWidget);
    expect(find.byKey(const Key('settings-section-catalog')), findsNothing);
    expect(find.byKey(const Key('confirm-check-in')), findsOneWidget);
    expect(find.byKey(const Key('confirm-check-out')), findsNothing);
    expect(find.text('מי עובד עכשיו?'), findsNothing);
    expect(
      find.descendant(
        of: find.byKey(const Key('current-worker')),
        matching: find.text('לא עובד'),
      ),
      findsOneWidget,
    );

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
      isNull,
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
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('מטבח'), findsWidgets);
    expect(find.text('אימות פעולה'), findsOneWidget);
    expect(
      tester.widget<Switch>(find.byKey(const Key('confirm-action'))).value,
      isFalse,
    );
    expect(find.text('שם הסביבה'), findsOneWidget);
    expect(
      tester.getTopLeft(find.byKey(const Key('settings-section-catalog'))).dy,
      greaterThan(
        tester.getTopLeft(find.byKey(const Key('settings-field-שם הסביבה'))).dy,
      ),
    );
    expect(
      tester.getTopLeft(find.byKey(const Key('settings-product-list'))).dy,
      greaterThan(
        tester.getTopLeft(find.byKey(const Key('settings-section-catalog'))).dy,
      ),
    );
    expect(find.byKey(const Key('settings-section-admin')), findsOneWidget);
    expect(find.text('שם המכשיר'), findsNothing);
    expect(find.text('מזהה: מטבח'), findsOneWidget);
    expect(find.text('אימייל הבעלים'), findsNothing);
    expect(find.text('מוצרים'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const Key('settings-product-list')),
        matching: find.text('חלב'),
      ),
      findsNothing,
    );
    expect(
      tester.getTopLeft(find.byKey(const Key('confirm-action'))).dy,
      greaterThan(
        tester.getTopLeft(find.byKey(const Key('settings-product-list'))).dy,
      ),
    );
    expect(
      tester.getTopLeft(find.byKey(const Key('confirm-action'))).dy,
      greaterThan(
        tester.getTopLeft(find.byKey(const Key('settings-worker-list'))).dy,
      ),
    );
    await tester.tap(find.byKey(const Key('settings-product-list')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(
      find.descendant(
        of: find.byKey(const Key('settings-product-list')),
        matching: find.text('חלב'),
      ),
      findsOneWidget,
    );
    expect(find.text('שליחת דוח בחצות'), findsNothing);
    expect(find.text('הטאבלט הזה הוא העותק המשותף'), findsNothing);
    expect(find.text('שרת דואר'), findsNothing);
    expect(find.text('שליחת הדוח היומי'), findsNothing);
    expect(find.byKey(const Key('settings-field-אסימון גישה')), findsNothing);
    expect(find.byKey(const Key('settings-field-כתובת המחשב')), findsNothing);
    expect(find.byKey(const Key('worker-refresh')), findsNothing);
    expect(find.byKey(const Key('settings-field-סיסמה')), findsNothing);
    expect(find.byKey(const Key('settings-field-שניות')), findsNothing);
    expect(find.text('הקפצה'), findsNothing);
    expect(find.text('לוח ניהול'), findsOneWidget);
    expect(find.text('שינוי הגדרות'), findsOneWidget);

    final locked = tester.widget<TextField>(
      find.byKey(const Key('settings-field-שם הסביבה')),
    );
    expect(locked.readOnly, isTrue);

    await tester.tap(find.byKey(const Key('unlock-settings')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.byKey(const Key('settings-password')), findsNothing);
    expect(
      tester
          .widget<TextField>(find.byKey(const Key('settings-field-שם הסביבה')))
          .readOnly,
      isFalse,
    );
    expect(find.text('שמירה'), findsOneWidget);
    expect(find.byKey(const Key('confirm-action')), findsNothing);
    expect(find.text('אימות פעולה'), findsNothing);
    final settingsList = find.byWidgetPredicate(
      (widget) =>
          widget is Scrollable && widget.axisDirection == AxisDirection.down,
    );
    await tester.scrollUntilVisible(
      find.byKey(const Key('settings-field-סיסמה')),
      300,
      scrollable: settingsList.first,
    );
    await Scrollable.ensureVisible(
      tester.element(find.byKey(const Key('settings-field-סיסמה'))),
      alignment: 1,
    );
    await tester.pump();
    expect(find.byKey(const Key('settings-field-אסימון גישה')), findsOneWidget);
    expect(find.byKey(const Key('settings-field-כתובת המחשב')), findsOneWidget);
    expect(
      tester.getTopLeft(find.byKey(const Key('settings-field-כתובת המחשב'))).dy,
      greaterThan(
        tester.getTopLeft(find.byKey(const Key('worker-refresh'))).dy,
      ),
    );
    expect(
      tester.getTopLeft(find.byKey(const Key('settings-field-אסימון גישה'))).dy,
      greaterThan(
        tester
            .getTopLeft(find.byKey(const Key('settings-field-כתובת המחשב')))
            .dy,
      ),
    );
    expect(
      tester
          .widget<TextField>(find.byKey(const Key('settings-field-סיסמה')))
          .controller
          ?.text,
      isEmpty,
    );
    expect(
      tester.getTopLeft(find.byKey(const Key('settings-field-סיסמה'))).dy,
      greaterThan(
        tester
            .getTopLeft(find.byKey(const Key('settings-field-אסימון גישה')))
            .dy,
      ),
    );
    expect(find.byKey(const Key('worker-refresh')), findsOneWidget);
    expect(
      tester
          .widget<TextField>(find.byKey(const Key('settings-field-שניות')))
          .controller
          ?.text,
      '600',
    );
    expect(find.text('המתנה'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.byKey(const Key('settings-product-list')),
      200,
      scrollable: find
          .byWidgetPredicate(
            (widget) =>
                widget is Scrollable &&
                widget.axisDirection == AxisDirection.down,
          )
          .first,
    );
    if (find.byKey(const Key('add-product')).evaluate().isEmpty) {
      await tester.tap(find.byKey(const Key('settings-product-list')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
    }
    await Scrollable.ensureVisible(
      tester.element(find.byKey(const Key('new-product-name'))),
      alignment: 0.5,
    );
    await tester.pump();
    await tester.enterText(find.byKey(const Key('new-product-name')), 'גבינה');
    await Scrollable.ensureVisible(
      tester.element(find.byKey(const Key('add-product'))),
      alignment: 0.5,
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('add-product')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text('גבינה'), findsWidgets);

    Navigator.of(tester.element(find.text('הגדרות'))).pop();
    await tester.pumpAndSettle();
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
    await signInWorker(database);
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
    expect(
      find.text('קליטה: חזה עוף ב-${formatCelsius(4.0)} · דנה'),
      findsOneWidget,
    );
    await tester.tap(find.text('ביטול'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('לא מסונכרן'), findsOneWidget);
    expect(
      tester.widget<Text>(find.byKey(const Key('sync-status'))).style?.color,
      const Color(0xFFB91C1C),
    );
    expect(find.text(formatCelsius(4.0)), findsOneWidget);

    await tester.tap(find.byKey(const Key('confirm-check-in')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tap(find.byKey(const Key('confirm-recorded-action')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump();
    expect(find.text('לא מסונכרן'), findsOneWidget);
    expect(find.textContaining('נקלט'), findsOneWidget);
    await tester.pump(const Duration(seconds: 11));
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
    expect(
      find.text('הוצאה: חזה עוף ב-${formatCelsius(4.0)} · דנה'),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const Key('confirm-recorded-action')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump();
    expect(find.text('לא מסונכרן'), findsOneWidget);
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
    await signInWorker(database);
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

    final stored = await database.select(database.products).get();
    expect(
      stored.singleWhere((row) => row.name == 'גבינה צהובה').listed,
      isFalse,
    );
    expect(stored.where((row) => row.name == 'חלב').single.listed, isTrue);

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
    await signInWorker(database);
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

    await tester.pump(const Duration(seconds: 11));
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

  testWidgets('check-in asks who is working and stores that name', (
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
    await tester.tap(find.byKey(const Key('unlock-settings')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    await tester.scrollUntilVisible(
      find.byKey(const Key('settings-worker-list')),
      200,
      scrollable: find
          .byWidgetPredicate(
            (widget) =>
                widget is Scrollable &&
                widget.axisDirection == AxisDirection.down,
          )
          .first,
    );
    await tester.tap(find.byKey(const Key('settings-worker-list')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await Scrollable.ensureVisible(
      tester.element(find.byKey(const Key('new-worker-name'))),
      alignment: 0.5,
    );
    await tester.pump();
    await tester.enterText(find.byKey(const Key('new-worker-name')), 'דנה');
    await Scrollable.ensureVisible(
      tester.element(find.byKey(const Key('add-worker'))),
      alignment: 0.5,
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('add-worker')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    Navigator.of(tester.element(find.text('הגדרות'))).pop();
    await tester.pumpAndSettle();
    expect(find.text('מי עובד עכשיו?'), findsNothing);
    await tester.tap(find.byKey(const Key('worker-idle-gate')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text('מי עובד עכשיו?'), findsOneWidget);
    await tester.tap(
      find.descendant(
        of: find.byKey(const Key('worker-picker')),
        matching: find.text('דנה'),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    await tester.tap(find.text('חלב'));
    await tester.pump();
    await tester.tap(find.byKey(const Key('confirm-check-in')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    final stored = await database.select(database.refrigerationLogs).get();
    expect(stored.single.workerNameSnapshot, 'דנה');

    tester.widget<SnackBarAction>(find.byType(SnackBarAction)).onPressed();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    final cancelled = await database.select(database.refrigerationLogs).get();
    expect(cancelled, hasLength(2));
    expect(cancelled.last.workerNameSnapshot, 'דנה · ביטול');
    expect(find.textContaining('הקליטה בוטלה'), findsOneWidget);

    await tester.pump(const Duration(seconds: 7));
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

  testWidgets('the name on top changes the worker without asking on confirm', (
    tester,
  ) async {
    final database = AppDatabase.memory();
    await signInWorker(database);
    await DriftWorkerRepository(database).addWorker('יוסי');
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

    expect(find.text('מי עובד עכשיו?'), findsNothing);
    expect(
      find.descendant(
        of: find.byKey(const Key('current-worker')),
        matching: find.text('דנה'),
      ),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('current-worker')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text('מי עובד עכשיו?'), findsOneWidget);
    await tester.tap(
      find.descendant(
        of: find.byKey(const Key('worker-picker')),
        matching: find.text('יוסי'),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(
      find.descendant(
        of: find.byKey(const Key('current-worker')),
        matching: find.text('יוסי'),
      ),
      findsOneWidget,
    );

    await tester.tap(find.text('חלב'));
    await tester.pump();
    expect(find.text('מי עובד עכשיו?'), findsNothing);
    await tester.tap(find.byKey(const Key('confirm-check-in')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text('מי עובד עכשיו?'), findsNothing);
    final stored = await database.select(database.refrigerationLogs).get();
    expect(stored.single.workerNameSnapshot, 'יוסי');

    await tester.pump(const Duration(seconds: 11));
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

  testWidgets('after the no-use timeout the next tap asks with name squares', (
    tester,
  ) async {
    final database = AppDatabase.memory();
    final workers = DriftWorkerRepository(database);
    final dana = await workers.addWorker('דנה');
    await workers.addWorker('יוסי');
    await workers.selectWorker(
      dana!.id,
      at: DateTime.now().toUtc().subtract(const Duration(minutes: 1)),
    );
    final settings = DriftSettingsRepository(database);
    final current = await settings.ensure();
    await settings.save(current.copyWith(workerIdleSeconds: 30));
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

    expect(find.text('מי עובד עכשיו?'), findsNothing);
    expect(find.byKey(const Key('worker-idle-gate')), findsOneWidget);

    await tester.tap(find.byKey(const Key('worker-idle-gate')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text('מי עובד עכשיו?'), findsOneWidget);
    final squares = find.descendant(
      of: find.byKey(const Key('worker-picker')),
      matching: find.byWidgetPredicate(
        (widget) =>
            widget is SizedBox && widget.width == 156 && widget.height == 156,
      ),
    );
    expect(squares, findsNWidgets(2));
    expect(tester.getSize(squares.first), const Size(156, 156));
    expect(
      find.descendant(
        of: find.byKey(const Key('worker-picker')),
        matching: find.byType(ListTile),
      ),
      findsNothing,
    );

    await tester.tap(
      find.descendant(
        of: find.byKey(const Key('worker-picker')),
        matching: find.text('יוסי'),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byKey(const Key('worker-idle-gate')), findsNothing);
    expect(find.text('מי עובד עכשיו?'), findsNothing);

    await tester.tap(find.text('חלב'));
    await tester.pump();
    expect(
      tester
          .widget<FilledButton>(find.byKey(const Key('confirm-check-in')))
          .onPressed,
      isNotNull,
    );

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

  testWidgets('worker refresh opens a short list of three choices', (
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
    await tester.tap(find.byKey(const Key('unlock-settings')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.byKey(const Key('settings-password')), findsNothing);

    expect(
      tester
          .widget<Text>(
            find.descendant(
              of: find.byKey(const Key('worker-refresh')),
              matching: find.text('רענון עובד'),
            ),
          )
          .style
          ?.fontWeight,
      FontWeight.w700,
    );
    await tester.tap(find.byKey(const Key('worker-refresh')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text('ללא'), findsOneWidget);
    expect(find.text('לא בשימוש'), findsOneWidget);
    expect(find.text('מחזוריות'), findsOneWidget);

    await tester.tap(find.text('ללא'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.byKey(const Key('settings-field-שניות')), findsNothing);
    expect(find.text('הקפצה'), findsNothing);

    await tester.tap(find.byKey(const Key('worker-refresh')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tap(find.text('מחזוריות'));
    await tester.pump();
    expect(find.byKey(const Key('settings-field-משעה')), findsOneWidget);
    expect(find.byKey(const Key('settings-field-שעות')), findsOneWidget);
    expect(find.byKey(const Key('settings-field-עד')), findsOneWidget);
    expect(
      tester
          .widget<SegmentedButton<WorkerPromptStyle>>(
            find.byKey(const Key('worker-prompt-style')),
          )
          .selected,
      {WorkerPromptStyle.wait},
    );
    await tester.ensureVisible(find.text('הקפצה'));
    await tester.pump();
    await tester.tap(find.text('הקפצה'));
    await tester.pump();
    expect(
      tester
          .widget<SegmentedButton<WorkerPromptStyle>>(
            find.byKey(const Key('worker-prompt-style')),
          )
          .selected,
      {WorkerPromptStyle.popup},
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

  testWidgets('הקפצה opens who is working without a tap', (tester) async {
    final database = AppDatabase.memory();
    final workers = DriftWorkerRepository(database);
    final dana = await workers.addWorker('דנה');
    await workers.selectWorker(
      dana!.id,
      at: DateTime.now().toUtc().subtract(const Duration(minutes: 1)),
    );
    final settings = DriftSettingsRepository(database);
    final current = await settings.ensure();
    await settings.save(
      current.copyWith(
        workerIdleSeconds: 30,
        workerPromptStyle: WorkerPromptStyle.popup,
      ),
    );
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

    expect(find.text('מי עובד עכשיו?'), findsOneWidget);
    expect(find.byKey(const Key('worker-idle-gate')), findsNothing);

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

  testWidgets('ללא keeps a manually chosen worker signed in', (tester) async {
    final database = AppDatabase.memory();
    final workers = DriftWorkerRepository(database);
    final dana = await workers.addWorker('דנה');
    await workers.selectWorker(
      dana!.id,
      at: DateTime.now().toUtc().subtract(const Duration(hours: 2)),
    );
    final settings = DriftSettingsRepository(database);
    final current = await settings.ensure();
    await settings.save(
      current.copyWith(workerRefreshMode: WorkerRefreshMode.off),
    );
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

    expect(find.text('מי עובד עכשיו?'), findsNothing);
    expect(find.byKey(const Key('worker-idle-gate')), findsNothing);
    await tester.tap(find.text('חלב'));
    await tester.pump();
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

  testWidgets('a blank settings password is none and any saved one works', (
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
    await tester.tap(find.byKey(const Key('unlock-settings')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.byKey(const Key('settings-password')), findsNothing);

    final fieldsScroll = Scrollable.of(
      tester.element(find.byKey(const Key('settings-field-שם הסביבה'))),
    );
    fieldsScroll.position.jumpTo(fieldsScroll.position.maxScrollExtent);
    await tester.pump();
    await Scrollable.ensureVisible(
      tester.element(find.byKey(const Key('settings-field-סיסמה'))),
      alignment: 0.5,
    );
    await tester.pump();
    expect(
      tester
          .widget<TextField>(find.byKey(const Key('settings-field-סיסמה')))
          .controller
          ?.text,
      isEmpty,
    );
    await tester.enterText(
      find.byKey(const Key('settings-field-סיסמה')),
      '123459876',
    );
    await tester.tap(find.text('שמירה'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.byKey(const Key('settings-field-סיסמה')), findsNothing);

    await tester.tap(find.byKey(const Key('unlock-settings')));
    await tester.pump();
    await tester.enterText(find.byKey(const Key('settings-password')), '1111');
    await tester.tap(find.byKey(const Key('confirm-settings-password')));
    await tester.pump();
    expect(find.text('הסיסמה שגויה.'), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('settings-password')),
      '123459876',
    );
    await tester.tap(find.byKey(const Key('confirm-settings-password')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text('הסיסמה שגויה.'), findsNothing);
    final unlockedScroll = Scrollable.of(
      tester.element(find.byKey(const Key('settings-field-שם הסביבה'))),
    );
    unlockedScroll.position.jumpTo(unlockedScroll.position.maxScrollExtent);
    await tester.pump();
    expect(
      tester
          .widget<TextField>(find.byKey(const Key('settings-field-סיסמה')))
          .controller
          ?.text,
      '123459876',
    );
    await tester.enterText(find.byKey(const Key('settings-field-סיסמה')), '');
    await tester.tap(find.text('שמירה'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tap(find.byKey(const Key('unlock-settings')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.byKey(const Key('settings-password')), findsNothing);
    final clearedScroll = Scrollable.of(
      tester.element(find.byKey(const Key('settings-field-שם הסביבה'))),
    );
    clearedScroll.position.jumpTo(clearedScroll.position.maxScrollExtent);
    await tester.pump();
    expect(
      tester
          .widget<TextField>(find.byKey(const Key('settings-field-סיסמה')))
          .controller
          ?.text,
      isEmpty,
    );

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
}
