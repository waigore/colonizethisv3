// Pin the 320 dp minimum-viewport contract for `QuickBattleScreen`
// (CMPT20001) — non-interactive result view.
// Interactive round-phase + wide sentinel live in
// `quick_battle_screen_320dp_min_viewport_interactive_test.dart`.
//
// SPEC: `SPEC/ui/mobile-adaptation.md` § 7; `SPEC/ui/quick-battle-screen.md`.
// Refs #2870 S10.

import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';

import 'quick_battle_screen_320dp_min_viewport_support.dart';

void main() {
  suppressLogsForTests();

  group('SPEC/ui/mobile-adaptation.md § 7 — QuickBattleScreen non-interactive '
      '(result view) @ 320 dp (Refs #2870 S10)', () {
    testWidgets(
      'AC (positive) QuickBattleScreen interactive: false @ 320×640: no '
      'RenderFlex overflow exception, Battle Result winner sentence + '
      'both casualty rows + Continue render',
      (WidgetTester tester) async {
        await pumpQuickBattleScreen320(
          tester,
          size: kQuickBattle320MinViewport,
          interactive: false,
        );

        expect(
          tester.takeException(),
          isNull,
          reason:
              'SPEC/ui/mobile-adaptation.md § 7: QuickBattleScreen '
              '(interactive: false, result view after auto-resolve) '
              'MUST NOT emit a RenderFlex overflow exception at '
              'kMinViewportWidth (320 dp). The result view from '
              'SPEC/ui/quick-battle-screen.md § Result phase auto-runs '
              'through resolveQuickBattle in initState and MUST lay '
              'out the Battle Result winner title + optional captured '
              'banner + two casualty bodySmall rows + trailing '
              'right-aligned Continue action within the ~288 dp '
              'CtDialogShell content column.',
        );

        // The "Battle Result: <winner>" title resolves through
        // `l10n.quickBattle_battleResult(...)` and renders regardless
        // of which side wins under the 2 vs 1 fixture above.
        expect(find.textContaining('Battle Result:'), findsOneWidget);

        // Both per-side casualty rows render via
        // `l10n.quickBattle_casualties(name, count)` so the
        // bodySmall casualty lines actually lay out at narrow widths.
        expect(find.textContaining('Attacker casualties:'), findsOneWidget);
        expect(find.textContaining('Defender casualties:'), findsOneWidget);

        // Trailing right-aligned Continue action MUST remain
        // reachable at 320 dp so the orchestrator can drive
        // `onComplete` once the user dismisses the result view.
        expect(find.text('Continue'), findsOneWidget);

        // The round-counter title and Resolve (Auto) fallback MUST
        // both be absent in the result view: the screen replaces
        // the round-phase column with the `_ResultView` widget once
        // `_result != null`. The absence here is the negative AC
        // that proves the non-interactive auto-resolve path
        // transitioned out of the round phase.
        expect(find.textContaining('Quick Battle — Round'), findsNothing);
        expect(find.text('Resolve (Auto)'), findsNothing);
      },
    );

    testWidgets('AC (positive) QuickBattleScreen interactive: false @ 320×640: '
        'tapping Continue invokes onComplete exactly once with the '
        'resolver result (the trailing right-aligned CtNinePatchButton '
        'is still reachable at the minimum viewport)', (
      WidgetTester tester,
    ) async {
      int completeCount = 0;
      QuickBattleResult? lastResult;
      await pumpQuickBattleScreen320(
        tester,
        size: kQuickBattle320MinViewport,
        interactive: false,
        onComplete: (r) {
          completeCount += 1;
          lastResult = r;
        },
      );

      // The Continue button MUST be hit-testable inside the ~288 dp
      // CtDialogShell content column at 320 dp.
      await tester.tap(find.text('Continue'));
      await tester.pump();

      expect(
        completeCount,
        1,
        reason:
            'SPEC/ui/quick-battle-screen.md § Acceptance Criteria: '
            'tapping Continue MUST invoke onComplete exactly once '
            'and the Continue button MUST remain reachable at '
            'kMinViewportWidth (320 dp) so the narrow viewport '
            'does not break the result-view dismissal contract.',
      );
      expect(lastResult, isNotNull);
    });
  });
}
