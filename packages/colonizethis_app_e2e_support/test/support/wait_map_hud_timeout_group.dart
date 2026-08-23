// Timeout / intro-handoff pins extracted from wait_map_hud_branch_group.dart
// (#4598 headroom).
library;

import 'package:colonizethis_app/features/game/widgets/dialogue/game_start_intro_overlay.dart';
import 'package:colonizethis_app/features/game/screens/game/game_screen_shared.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app_e2e_support/e2e_test_shared_bootstrap.dart';

import 'wait_map_hud_harness.dart';

void registerWaitMapHudTimeoutGroup() {
  testWidgets(
    'hands off to intro-dismiss while loading indicator blocks, then returns once HUD lands',
    (WidgetTester tester) async {
      // `GameStartIntroLoadingIndicator` makes `e2eGameStartIntroBlocksUi`
      // return true, so the helper must enter the intro-dismiss branch
      // (resets the poll cadence and awaits the dismissal helper). The
      // host swaps to the map HUD after 100 ms of fake-async time —
      // crucially, removing the loading indicator first so the dismiss
      // helper returns and the outer loop can advance through the
      // home-to-capital short-circuit. A regression that demoted the
      // intro-blocks branch to the generic idle pump would either spin on
      // the loading indicator forever (it never clears on its own) or
      // race the home-capital check while the intro shell is still up.
      await pumpWaitMapHudHost(
        tester,
        initial: WaitMapHudSetupPhase.introLoading,
        transitionAfter: const Duration(milliseconds: 100),
        transitionTo: WaitMapHudSetupPhase.mapHud,
      );

      await e2eWaitForMapHudAfterNewGameStart(
        tester,
        overallCap: const Duration(seconds: 5),
      );

      expect(
        find.byType(GameStartIntroLoadingIndicator),
        findsNothing,
        reason:
            'Sanity check: the loading indicator must have left the tree '
            'before the helper returned, otherwise the intro-dismiss handoff '
            'was bypassed.',
      );
      expect(find.byKey(kHomeToCapitalButtonKey), findsOneWidget);
    },
  );

  testWidgets(
    'fails with TestFailure when overall cap elapses with no settle',
    (WidgetTester tester) async {
      await pumpWaitMapHudHost(tester, initial: WaitMapHudSetupPhase.idle);
      Object? caught;
      try {
        await e2eWaitForMapHudAfterNewGameStart(
          tester,
          overallCap: const Duration(milliseconds: 150),
        );
      } catch (e) {
        caught = e;
      }
      expect(
        caught,
        isA<TestFailure>(),
        reason:
            'Persistent empty setup state must hit the timeout fail path so '
            'real bootstrap regressions are not silently swallowed (#2336 '
            'AC10).',
      );
      final message = caught.toString();
      expect(
        message,
        contains('Timed out'),
        reason:
            'Failure message must call out the timeout so the helper failure '
            'is attributable in CI logs.',
      );
      expect(
        message,
        contains('map (home→capital)'),
        reason:
            'Failure message must reference the map (home→capital) wait so '
            'the failure is unambiguously attributed to '
            '`e2eWaitForMapHudAfterNewGameStart` (and not a sibling poll '
            'helper).',
      );
    },
  );
}

