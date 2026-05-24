import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:colonizethis_app/config/ct_e2e.dart';
import 'package:colonizethis_app/config/ct_e2e_last_panel_snapshot.dart';
import 'e2e_helpers.dart';
import 'package:colonizethis_app/main.dart' show bootstrapForIntegrationTest;
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

part 'new_game_fleet_reaches_new_world_e2e_helpers.dart';
part 'new_game_fleet_reaches_new_world_e2e_helpers_part2.dart';

void main() {
  suppressLogsForTests();
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('new game → non-home fleet at sea in New World '
      '(≤$kE2eDefaultFleetReachLoopMaxTurns Next turn taps)', (
    WidgetTester tester,
  ) async {
    final preamble = await enterFleetReachScenarioReady(
      tester,
      testName: 'new_game_fleet_reaches_new_world',
      bootstrapForIntegrationTest: bootstrapForIntegrationTest,
      maxUiResponseWait: kE2eDefaultNavalMoveSegmentUiWait,
      wallClockCap: kE2eMaxWallClock,
    );
    final perf = preamble.perf;
    final testSw = preamble.testSw;
    final l10n = preamble.l10n;
    final ensureUnderWallClock = preamble.ensureUnderWallClock;

    final loopResult = await fleetReachTurnLoop(
      tester,
      l10n,
      perf: perf,
      ensureUnderWallClock: ensureUnderWallClock,
      maxUiResponseWait: kE2eDefaultNavalMoveSegmentUiWait,
      maxTurns: kE2eDefaultFleetReachLoopMaxTurns,
    );
    final earlyReturnMeta = fleetReachLoopExitTestTotalMetaLabel(
      loopResult.exit,
    );
    if (earlyReturnMeta != null) {
      // Non-null meta label means the loop took an early-return exit
      // (snapshot detection during the loop, either before/after the move
      // or before/after the region-tab settle, or any inner-loop reach
      // detection). The lifted mapping preserves the legacy
      // `reachedSnapshotAfterRegionTab → 'result=reached_snapshot_precheck'`
      // quirk byte-for-byte; see
      // [e2eFleetReachLoopExitTestTotalMetaLabel] for the historical
      // context (Refs GitHub #2336 AC1 / AC2 / Bottleneck 4).
      perf.timing('test_total', testSw.elapsed, meta: earlyReturnMeta);
      return;
    }

    ensureUnderWallClock('before final naval check');
    await ensureNonHomeFleetInNwAfterLoop(
      tester,
      perf: perf,
      maxUiResponseWait: kE2eDefaultNavalMoveSegmentUiWait,
      failureMessageBuilder: (lastException) =>
          'After $kE2eDefaultFleetReachLoopMaxTurns Next turn resolutions, no non-home human fleet in region '
          'newWorld (ctE2eNavalPanelSnapshot / naval panel UI). '
          'Last exception: $lastException',
    );
    ensureUnderWallClock('test complete');
    perf.timing('test_total', testSw.elapsed, meta: 'result=final_check');
  });

  testWidgets(
    'post-bundle GitHub #1869: after NW fleet, Explorer Assign → Explore enabled',
    (WidgetTester tester) async {
      final preamble = await enterFleetReachScenarioReady(
        tester,
        testName: 'new_game_fleet_explore_enabled_post_bundle',
        bootstrapForIntegrationTest: bootstrapForIntegrationTest,
        maxUiResponseWait: kE2eDefaultNavalMoveSegmentUiWait,
        wallClockCap: kE2eMaxWallClock,
      );
      final perf = preamble.perf;
      final testSw = preamble.testSw;
      final l10n = preamble.l10n;
      final ensureUnderWallClock = preamble.ensureUnderWallClock;

      final loopResult = await fleetReachTurnLoop(
        tester,
        l10n,
        perf: perf,
        ensureUnderWallClock: ensureUnderWallClock,
        maxUiResponseWait: kE2eDefaultNavalMoveSegmentUiWait,
        maxTurns: kE2eDefaultFleetReachLoopMaxTurns,
      );
      CtE2eNavalPanelSnapshot? lastKnownNavalSnapshot =
          loopResult.lastKnownNavalSnapshot;

      final finalCheck = await ensureNonHomeFleetInNwAfterLoop(
        tester,
        perf: perf,
        maxUiResponseWait: kE2eDefaultNavalMoveSegmentUiWait,
        failureMessageBuilder: (lastException) =>
            'Explorer explore e2e requires a non-home human fleet in New World first. '
            'Last exception: $lastException',
      );
      if (finalCheck.lastKnownNavalSnapshot != null) {
        lastKnownNavalSnapshot = finalCheck.lastKnownNavalSnapshot;
      }
      ensureUnderWallClock('fleet in NW confirmed');

      await awaitNwCoastalOrVisibleLandForBundledExplore(
        tester,
        l10n,
        ensureUnderWallClock: ensureUnderWallClock,
        maxUiResponseWait: kE2eDefaultNavalMoveSegmentUiWait,
      );

      await e2eTapNewWorldRegionTabIfPresent(tester);

      // Linux CI can require more than three post-reveal turns before the
      // Assign list surfaces an enabled Explore row for at least one explorer.
      // Keep strict failure semantics, but widen the bounded retry window via
      // the lifted [awaitExploreEnabledFromCivilianPanel] helper which carries
      // the bounded retry-loop contract (Refs GitHub #2336 AC1 / AC2 / AC5 /
      // Bottleneck 5).
      final exploreEnabled = await awaitExploreEnabledFromCivilianPanel(
        tester,
        l10n,
        perf: perf,
        maxUiResponseWait: kE2eDefaultNavalMoveSegmentUiWait,
      );
      if (!exploreEnabled) {
        await handleBundledExploreFailure(
          tester,
          navalSnapshot: ctE2eNavalPanelSnapshot,
          civilianSnapshot: ctE2eCivilianPanelSnapshot,
          lastKnownNavalSnapshot: lastKnownNavalSnapshot,
          maxBoundedTurnRetries: kE2eDefaultBundledExploreMaxTurnRetries,
        );
        return;
      }

      ensureUnderWallClock('test complete');
      perf.timing('test_total', testSw.elapsed);
    },
  );

  // Refs #1869 slice 6b: interim Move-then-Explore AC is documented here as an
  // explicit skip so 6a and 6b are never combined in one ambiguous conditional.
  // Post-bundle behavior is covered by the sibling test above.
  testWidgets(
    'SKIP interim #1869 6b: Move-then-Explore staging (pre-bundle builds)',
    (WidgetTester tester) async {
      expect(kCtE2EEnabled, isTrue);
    },
    skip: true,
  );
}
