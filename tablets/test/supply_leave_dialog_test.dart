import 'package:cooling_down/presentation/widgets/confirm_action_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('enter supply asks are you sure', (tester) async {
    late Future<bool> answer;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            return TextButton(
              onPressed: () {
                answer = confirmEnterSupplyMode(context);
              },
              child: const Text('open'),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pump();
    expect(find.text('האם אתה בטוח?'), findsOneWidget);
    expect(find.textContaining('להפעיל מצב אספקה'), findsOneWidget);

    await tester.tap(find.byKey(const Key('confirm-recorded-action')));
    await tester.pumpAndSettle();
    expect(await answer, isTrue);
  });

  testWidgets('leave supply waits then allows אישור', (tester) async {
    late Future<bool> answer;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            return TextButton(
              onPressed: () {
                answer = confirmLeaveSupplyMode(context, countdownSeconds: 2);
              },
              child: const Text('open'),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pump();
    expect(find.byKey(const Key('supply-leave-dialog')), findsOneWidget);
    expect(find.text('האם אתה בטוח?'), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(find.byKey(const Key('supply-leave-yes')))
          .onPressed,
      isNull,
    );

    await tester.pump(const Duration(seconds: 2));
    expect(
      tester
          .widget<FilledButton>(find.byKey(const Key('supply-leave-yes')))
          .onPressed,
      isNotNull,
    );

    await tester.tap(find.byKey(const Key('supply-leave-yes')));
    await tester.pumpAndSettle();
    expect(await answer, isTrue);
  });
}
