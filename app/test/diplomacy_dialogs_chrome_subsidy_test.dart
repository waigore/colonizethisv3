// Subsidy percent mode chrome for GrantOrSubsidyDialog (Refs #3753 R3 / #4734 Slice F).
// Dark editorial chrome pins: diplomacy_dialogs_chrome_test.dart.

import 'package:colonizethis_app/features/game/widgets/diplomacy/diplomacy_dialogs.dart';
import 'package:colonizethis_app/widgets/ct_nine_patch_button.dart';
import 'package:colonizethis_diplomacy/colonizethis_diplomacy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'app_shell_harness.dart';
import 'diplomacy_dialogs_test_support.dart';
import 'panel_test_fixtures.dart';

void main() {
  suppressLogsForTests();

  group('Subsidy percent mode (Refs #3753 R3)', () {
    testWidgets(
      'renders percent amount and a percent step line with no £ currency copy',
      (tester) async {
        await pumpGrantOrSubsidyDialog(
          tester,
          humanTreasury: 0,
          isSubsidy: true,
        );

        expect(find.text('Set subsidy'), findsOneWidget);

        final amount = tester.widget<Text>(
          find.byKey(const Key('grantOrSubsidyDialogAmount')),
        );
        expect(amount.data, '$kSubsidyPercentDefault%');

        final treasury = tester.widget<Text>(
          find.byKey(const Key('grantOrSubsidyDialogTreasury')),
        );
        expect(treasury.data, contains('%'));
        expect(treasury.data, isNot(contains('£')));

        expect(find.textContaining('£'), findsNothing);
      },
    );

    testWidgets('Submit is enabled even when treasury is zero', (tester) async {
      await pumpGrantOrSubsidyDialog(tester, humanTreasury: 0, isSubsidy: true);

      final submit = find.widgetWithText(CtNinePatchButton, 'Submit');
      expect(tester.widget<CtNinePatchButton>(submit).enabled, isTrue);
      expect(
        find.byKey(const Key('grantOrSubsidyDialogWarning')),
        findsNothing,
      );
    });

    testWidgets('plus steps by 5% and clamps at the 20% maximum', (
      tester,
    ) async {
      await pumpGrantOrSubsidyDialog(tester, humanTreasury: 0, isSubsidy: true);

      await tester.tap(find.byKey(const Key('diplo_amount_plus')));
      await tester.pump();
      expect(find.text('10%'), findsOneWidget);

      for (var i = 0; i < 6; i++) {
        await tester.tap(find.byKey(const Key('diplo_amount_plus')));
        await tester.pump();
      }
      expect(find.text('$kSubsidyPercentMax%'), findsOneWidget);
    });

    testWidgets('minus clamps at the 5% minimum', (tester) async {
      await pumpGrantOrSubsidyDialog(tester, humanTreasury: 0, isSubsidy: true);

      for (var i = 0; i < 4; i++) {
        await tester.tap(find.byKey(const Key('diplo_amount_minus')));
        await tester.pump();
      }
      expect(find.text('$kSubsidyPercentMin%'), findsOneWidget);
    });

    testWidgets('Submit emits a valid subsidy percent', (tester) async {
      final base = buildDiplomacyScreenTestGame();
      final humanPlayerId = base.players.first.id;
      final targetFactionId = base.players.length >= 2
          ? base.players[1].id
          : (base.minorNations.isNotEmpty ? base.minorNations.first.id : 'm1');

      final bus = AppEventBus.create();
      GrantOrSubsidySubmittedEvent? submitted;
      final sub = bus.on<GrantOrSubsidySubmittedEvent>().listen((e) {
        submitted = e;
      });
      addTearDown(sub.cancel);

      await tester.pumpWidget(
        buildAppShell(
          child: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                child: const Text('Open'),
                onPressed: () {
                  showDialog<void>(
                    context: context,
                    builder: (ctx) => GrantOrSubsidyDialog(
                      game: base,
                      humanPlayerId: humanPlayerId,
                      targetFactionId: targetFactionId,
                      isSubsidy: true,
                      bus: bus,
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('diplo_amount_plus')));
      await tester.pump();

      await tester.tap(find.widgetWithText(CtNinePatchButton, 'Submit'));
      await tester.pumpAndSettle();

      expect(submitted, isNotNull);
      expect(submitted!.isSubsidy, isTrue);
      expect(submitted!.amount, 10);
      expect(isValidSubsidyPercent(submitted!.amount), isTrue);
    });
  });
}
