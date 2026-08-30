import 'package:colonizethis_app/features/game/widgets/diplomacy/diplomacy_dialogs_grant_subsidy_body.dart';
import 'package:colonizethis_app/widgets/ct_nine_patch_button.dart';
import 'package:colonizethis_diplomacy/colonizethis_diplomacy.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'app_shell_harness.dart';
import 'diplomacy_dialogs_test_support.dart';

void main() {
  suppressLogsForTests();

  testWidgets('GrantOrSubsidyDialog submits default valid grant amount', (
    WidgetTester tester,
  ) async {
    final bus = AppEventBus.create();
    GrantOrSubsidySubmittedEvent? submitted;
    final sub = bus.on<GrantOrSubsidySubmittedEvent>().listen((e) {
      submitted = e;
    });
    addTearDown(sub.cancel);

    await pumpGrantOrSubsidyDialog(tester, humanTreasury: 5000, bus: bus);

    expect(find.text('Grant aid'), findsOneWidget);
    expect(find.textContaining('£'), findsWidgets);

    await tester.tap(find.widgetWithText(CtNinePatchButton, 'Submit'));
    await tester.pumpAndSettle();

    expect(submitted, isNotNull);
    expect(submitted!.amount, 1000);
    expect(submitted!.isSubsidy, isFalse);
    expect(find.text('Grant aid'), findsNothing);
  });

  testWidgets(
    'GrantOrSubsidyDialog submit disabled when treasury below minimum',
    (WidgetTester tester) async {
      final bus = AppEventBus.create();
      var submittedCalled = false;
      final sub = bus.on<GrantOrSubsidySubmittedEvent>().listen((_) {
        submittedCalled = true;
      });
      addTearDown(sub.cancel);

      await pumpGrantOrSubsidyDialog(tester, humanTreasury: 500, bus: bus);

      expect(find.text('Grant aid'), findsOneWidget);
      final submit = find.widgetWithText(CtNinePatchButton, 'Submit');
      final button = tester.widget<CtNinePatchButton>(submit);
      expect(button.enabled, isFalse);

      await tester.tap(submit);
      await tester.pumpAndSettle();

      expect(submittedCalled, isFalse);
      expect(find.text('Grant aid'), findsOneWidget);
    },
  );

  testWidgets('GrantOrSubsidyDialog Cancel closes dialog', (
    WidgetTester tester,
  ) async {
    final bus = AppEventBus.create();
    var submittedCalled = false;
    final sub = bus.on<GrantOrSubsidySubmittedEvent>().listen((_) {
      submittedCalled = true;
    });
    addTearDown(sub.cancel);

    await pumpGrantOrSubsidyDialog(tester, humanTreasury: 5000, bus: bus);

    await tester.tap(find.widgetWithText(CtNinePatchButton, 'Cancel'));
    await tester.pumpAndSettle();

    expect(submittedCalled, isFalse);
    expect(find.text('Grant aid'), findsNothing);
  });

  testWidgets(
    'GrantOrSubsidyDialog shows live Cost/Effect for grant and updates on step',
    (WidgetTester tester) async {
      final game = await pumpGrantOrSubsidyDialog(tester, humanTreasury: 5000);
      final targetName = game.players[1].displayName;

      expect(
        find.byKey(const Key('grantOrSubsidyDialogPreview')),
        findsOneWidget,
      );
      expect(
        find.text('Cost: £1000 from your treasury when the grant resolves.'),
        findsOneWidget,
      );
      expect(
        find.text(
          'Effect: Standing with $targetName improves when the grant resolves.',
        ),
        findsOneWidget,
      );
      expect(
        find.text(
          'Effect: A larger gift this turn does not improve standing further.',
        ),
        findsOneWidget,
      );
      final standingWord = find.textContaining('Effect: Standing word ');
      expect(standingWord, findsOneWidget);
      final standingWordText = tester.widget<Text>(standingWord).data;

      await tester.tap(find.byKey(const Key('diplo_amount_plus')));
      await tester.pump();

      expect(
        find.text('Cost: £2000 from your treasury when the grant resolves.'),
        findsOneWidget,
      );
      expect(
        find.text('Cost: £1000 from your treasury when the grant resolves.'),
        findsNothing,
      );
      expect(
        find.text(
          'Effect: A larger gift this turn does not improve standing further.',
        ),
        findsOneWidget,
      );
      expect(find.text(standingWordText!), findsOneWidget);
    },
  );

  testWidgets(
    'GrantOrSubsidyDialog shows subsidy Cost/Effect without a second confirm path',
    (WidgetTester tester) async {
      final game = await pumpGrantOrSubsidyDialog(
        tester,
        humanTreasury: 5000,
        isSubsidy: true,
      );
      final targetName = game.players[1].displayName;

      expect(find.text('Cost: No per-turn gold charge.'), findsOneWidget);
      expect(
        find.text(
          'Effect: ${subsidyFillPriceConsequence(targetDisplayName: targetName, percent: 5)}',
        ),
        findsOneWidget,
      );
      expect(find.textContaining('Standing word'), findsNothing);
      expect(find.textContaining('larger gift'), findsNothing);
      expect(find.textContaining('market terms are affected'), findsNothing);

      await tester.tap(find.byKey(const Key('diplo_amount_plus')));
      await tester.pump();

      expect(
        find.text(
          'Effect: ${subsidyFillPriceConsequence(targetDisplayName: targetName, percent: 10)}',
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'GrantOrSubsidyDialog omits Cost/Effect when grant treasury is below minimum',
    (WidgetTester tester) async {
      await pumpGrantOrSubsidyDialog(tester, humanTreasury: 500);

      expect(
        find.byKey(const Key('grantOrSubsidyDialogPreview')),
        findsNothing,
      );
      expect(find.textContaining('Cost:'), findsNothing);
      expect(
        find.byKey(const Key('grantOrSubsidyDialogWarning')),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'GrantSubsidyAmountBody does not call preview builder when grant amount is 0',
    (WidgetTester tester) async {
      final invokedAmounts = <int>[];
      await tester.pumpWidget(
        buildAppShell(
          child: GrantSubsidyAmountBody(
            title: 'Grant aid',
            treasury: 0,
            isSubsidy: false,
            onCancel: () {},
            onSubmit: (_) {},
            previewLinesForAmount: (amount) {
              invokedAmounts.add(amount);
              return const <String>['Cost: £0'];
            },
          ),
        ),
      );
      await tester.pump();

      expect(invokedAmounts, isEmpty);
      expect(find.text('Cost: £0'), findsNothing);
    },
  );
}
