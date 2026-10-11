import 'package:cooling_down/app.dart';
import 'package:cooling_down/data/db/app_database.dart';
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
        overrides: [appDatabaseProvider.overrideWithValue(database)],
        child: const CoolingDownApp(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('Check in'), findsOneWidget);
    expect(find.text('Check out'), findsOneWidget);
    expect(find.text('In the fridge'), findsOneWidget);
    expect(find.text('Chicken breast'), findsOneWidget);
    expect(find.text('Kitchen fridge'), findsOneWidget);
    expect(find.byKey(const Key('confirm-check-in')), findsOneWidget);
    expect(find.byKey(const Key('confirm-check-out')), findsNothing);

    final checkIn = tester.widget<FilledButton>(
      find.byKey(const Key('confirm-check-in')),
    );
    expect(checkIn.onPressed, isNull);

    await tester.tap(find.text('Check out'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.byKey(const Key('confirm-check-out')), findsOneWidget);
    final checkOut = tester.widget<FilledButton>(
      find.byKey(const Key('confirm-check-out')),
    );
    expect(checkOut.onPressed, isNull);

    await tester.tap(find.text('In the fridge'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text('Nothing is in a fridge right now.'), findsOneWidget);

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
