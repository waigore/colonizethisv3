// Branch waterfall pins for `e2eWaitForMapHudAfterNewGameStart` (Slice D / #4195).
library;

import 'package:colonizethis_app/features/game/widgets/dialogue/game_start_intro_overlay.dart';
import 'package:colonizethis_app/features/game/screens/game/game_screen_shared.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app_e2e_support/e2e_test_shared_bootstrap.dart';

import 'wait_map_hud_harness.dart';

void registerWaitMapHudBranchGroup() {
  testWidgets(
    'returns immediately when home-to-capital button is already mounted',
    (WidgetTester tester) async {
      await pumpWaitMapHudHost(tester, initial: WaitMapHudSetupPhase.mapHud);
      final sw = Stopwatch()..start();
      await e2eWaitForMapHudAfterNewGameStart(
        tester,
        overallCap: const Duration(seconds: 5),
      );
      expect(
        sw.elapsed,
        lessThan(const Duration(milliseconds: 500)),
        reason:
            'Helper must short-circuit on the entry home-to-capital check '
            'when the map HUD is already mounted; reaching the overall cap '
            'would imply the pre-pump branch order regressed (#2336 AC5).',
      );
      expect(
        find.byKey(kHomeToCapitalButtonKey),
        findsOneWidget,
        reason:
            'Sanity check: the host kept the home-to-capital button mounted '
            'across the helper return so callers can chain on the same key.',
      );
    },
  );

  testWidgets(
    'fails with TestFailure when the "Could not create game" dialog is mounted',
    (WidgetTester tester) async {
      await pumpWaitMapHudHost(tester, initial: WaitMapHudSetupPhase.errorDialog);
      Object? caught;
      try {
        await e2eWaitForMapHudAfterNewGameStart(
          tester,
          overallCap: const Duration(seconds: 5),
        );
      } catch (e) {
        caught = e;
      }
      expect(
        caught,
        isA<TestFailure>(),
        reason:
            '"Could not create game" must drive the fail-fast branch so a '
            'broken setup is not silently masked by the home-capital wait '
            '(#2336 AC10).',
      );
      expect(
        caught.toString(),
        allOf(
          contains('New game setup failed'),
          contains('error dialog'),
        ),
        reason:
            'Failure message must attribute the failure to the new-game '
            'setup branch ("New game setup failed") and the originating '
            'control ("error dialog") so the call site is unambiguous in '
            'CI logs (#2336 bootstrap contract).',
      );
    },
  );

  testWidgets(
    'fails on "Could not create game" even when home-to-capital is also mounted',
    (WidgetTester tester) async {
      // Build a host that mounts BOTH the error text and the home-to-capital
      // button in the same frame. The helper inspects them in declaration
      // order — error precedes home-capital — so the fail-fast branch must
      // win deterministically. Regressions that reorder the checks (or
      // demote the error to a soft warning) would let a broken setup leak
      // through as a green E2E run (#2336 AC10).
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                const Center(child: Text('Could not create game')),
                Positioned(
                  top: 0,
                  child: TextButton(
                    key: kHomeToCapitalButtonKey,
                    onPressed: () {},
                    child: const Text('Capital'),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      Object? caught;
      try {
        await e2eWaitForMapHudAfterNewGameStart(
          tester,
          overallCap: const Duration(seconds: 5),
        );
      } catch (e) {
        caught = e;
      }
      expect(
        caught,
        isA<TestFailure>(),
        reason:
            'Error-dialog check must precede the home-capital short-circuit; '
            'a race that lets the success branch run before the error branch '
            'would silently hide setup failures.',
      );
    },
  );

  testWidgets(
    'returns once a scheduled home-to-capital mount lands during pump',
    (WidgetTester tester) async {
      // Schedule the host to flip into the mapHud phase after 80 ms of
      // fake-async time so the helper's adaptive pump loop advances the
      // clock past the Timer deadline and observes the change on a later
      // iteration (no guarded `tester.pump` from the test itself; #2336
      // AC5 adaptive polling).
      final controller = await pumpWaitMapHudHost(
        tester,
        initial: WaitMapHudSetupPhase.idle,
        transitionAfter: const Duration(milliseconds: 80),
        transitionTo: WaitMapHudSetupPhase.mapHud,
      );
      expect(find.byKey(kHomeToCapitalButtonKey), findsNothing);

      await e2eWaitForMapHudAfterNewGameStart(
        tester,
        overallCap: const Duration(seconds: 5),
      );

      expect(
        controller.phase,
        WaitMapHudSetupPhase.mapHud,
        reason:
            'Sanity check: the scheduled mount must have applied before the '
            'helper returned, otherwise the helper short-circuited on a '
            'stale state.',
      );
      expect(
        find.byKey(kHomeToCapitalButtonKey),
        findsOneWidget,
        reason:
            'Helper must return with the map HUD already mounted so callers '
            'can issue follow-up taps without an extra wait.',
      );
    },
  );

  testWidgets(
    'continues polling while "Creating game" text is mounted and returns once HUD lands',
    (WidgetTester tester) async {
      // Initial phase is `creatingGame` so the helper exercises the
      // dedicated "Creating game" branch on early iterations (idle pump
      // with adaptive backoff, no intro-dismiss handoff). After 120 ms of
      // fake-async time the host swaps to the map HUD, which the helper
      // must observe on a later iteration and return cleanly. A regression
      // that promoted "Creating game" to a fail-fast (or rerouted it
      // through the intro-dismiss path) would either throw here or burn
      // wall clock through unnecessary dismiss calls.
      await pumpWaitMapHudHost(
        tester,
        initial: WaitMapHudSetupPhase.creatingGame,
        transitionAfter: const Duration(milliseconds: 120),
        transitionTo: WaitMapHudSetupPhase.mapHud,
      );

      await e2eWaitForMapHudAfterNewGameStart(
        tester,
        overallCap: const Duration(seconds: 5),
      );

      expect(
        find.text('Creating game'),
        findsNothing,
        reason:
            'Sanity check: the host must have left the "Creating game" '
            'screen before the helper returned.',
      );
      expect(find.byKey(kHomeToCapitalButtonKey), findsOneWidget);
    },
  );

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
