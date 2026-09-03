// Interactive round-phase + wide regression pins for `QuickBattleScreen`
// (CMPT20001). Non-interactive result view lives in
// `quick_battle_screen_320dp_min_viewport_test.dart`.
//
// SPEC: `SPEC/ui/mobile-adaptation.md` § 7; `SPEC/ui/quick-battle-screen.md`.
// Refs #2870 S10.

import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';

import 'quick_battle_screen_320dp_min_viewport_support.dart';

void main() {
  suppressLogsForTests();

  group('SPEC/ui/mobile-adaptation.md § 7 — QuickBattleScreen interactive '
      '(round phase) @ 320 dp (Refs #2870 S10)', () {
    testWidgets(
      'AC (positive) QuickBattleScreen interactive: true @ 320×640: no '
      'RenderFlex overflow exception, round-counter title + '
      'QuickBattleActionSelector Command Points header + every action '
      'Wrap child render, and the Resolve (Auto) fallback is absent',
      (WidgetTester tester) async {
        await pumpQuickBattleScreen320(
          tester,
          size: kQuickBattle320MinViewport,
          interactive: true,
        );

        expect(
          tester.takeException(),
          isNull,
          reason:
              'SPEC/ui/mobile-adaptation.md § 7: QuickBattleScreen '
              '(interactive: true, round phase) MUST NOT emit a '
              'RenderFlex overflow exception at kMinViewportWidth '
              '(320 dp). The round-counter Text, the '
              'QuickBattleDeploymentView CtPanel + Wrap of lane/line '
              'rows, and the QuickBattleActionSelector Wrap of five '
              'CtNinePatchButton chips (Volley Fire / Defend / '
              'Maneuver / Fall Back / Assault) MUST lay out within '
              'the ~288 dp CtDialogShell content column without '
              'horizontal overflow — the action chips MUST flow onto '
              'extra runs rather than overflowing the row.',
        );

        // Round-counter title resolves to `Quick Battle — Round 1 / 3`
        // per `l10n.quickBattle_round(1, 3)` and the fixture's
        // `maxRounds = 3`.
        expect(
          find.textContaining('Quick Battle — Round 1 / 3'),
          findsOneWidget,
        );

        // QuickBattleActionSelector header from
        // `l10n.quickBattle_commandPoints(3)` MUST render so the
        // Wrap of action chips is actually exercised at narrow
        // widths.
        expect(find.textContaining('Command Points: 3'), findsOneWidget);

        // Every action chip from SPEC/ui/quick-battle-screen.md
        // § Layout / wireframe — Round phase MUST mount at 320 dp
        // (label rendered via `l10n.quickBattle_actionWithCost(...)`
        // so `find.textContaining` matches the label fragment
        // before the CP suffix).
        expect(find.textContaining('Volley Fire'), findsOneWidget);
        expect(find.textContaining('Defend'), findsOneWidget);
        expect(find.textContaining('Maneuver'), findsOneWidget);
        expect(find.textContaining('Fall Back'), findsOneWidget);
        expect(find.textContaining('Assault'), findsOneWidget);

        // Non-interactive fallback button MUST be absent so the
        // interactive branch from SPEC § States and variants is
        // actually exercised (negative AC).
        expect(find.text('Resolve (Auto)'), findsNothing);
      },
    );
  });

  group('SPEC/ui/mobile-adaptation.md § 7 — QuickBattleScreen wide '
      'regression sentinel (Refs #2870 S10)', () {
    testWidgets('Negative control: QuickBattleScreen interactive: false @ '
        '1024×768 also pumps without exception (regression sentinel '
        'for the overflow contract — keeps the 320 dp positive pins '
        'meaningful)', (WidgetTester tester) async {
      await pumpQuickBattleScreen320(
        tester,
        size: kQuickBattle320WideViewport,
        interactive: false,
      );

      expect(tester.takeException(), isNull);
      expect(find.textContaining('Battle Result:'), findsOneWidget);
      expect(find.text('Continue'), findsOneWidget);
    });
  });
}
