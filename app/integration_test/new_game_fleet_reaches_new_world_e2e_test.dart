import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:colonizethis_app/config/ct_e2e.dart';
import 'package:colonizethis_app/config/ct_e2e_last_panel_snapshot.dart';
import 'e2e_helpers.dart';
import 'package:colonizethis_app/l10n/l10n.dart';
import 'package:colonizethis_app/main.dart' show bootstrapForIntegrationTest;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

part 'new_game_fleet_reaches_new_world_e2e_helpers.dart';
part 'new_game_fleet_reaches_new_world_e2e_helpers_part2.dart';

void main() {
  suppressLogsForTests();
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('new game → non-home fleet at sea in New World '
      '(≤$_kMaxNextTurnTapsForNwFleetReach Next turn taps)', (
    WidgetTester tester,
  ) async {
    const testName = 'new_game_fleet_reaches_new_world';
    final perf = E2ePerfLog(testName);
    final testSw = Stopwatch()..start();
    expect(
      kCtE2EEnabled,
      isTrue,
      reason:
          'Run with: flutter test integration_test/... --dart-define=CT_E2E=true',
    );

    await tester.binding.setSurfaceSize(const Size(1280, 720));
    final bootstrapSw = Stopwatch()..start();
    await bootstrapForIntegrationTest();
    await tester.pump();
    await e2eWaitForNewGameEntry(tester, perf: perf);
    perf.timing('bootstrap_for_integration_test', bootstrapSw.elapsed);
    await ensureAllRelocated64pxPngsLoadSuiteOnce();

    final wallClock = Stopwatch()..start();
    final ensureUnderWallClock = e2eMakeWallClockGuard(
      testName: testName,
      stopwatch: wallClock,
      cap: _kFleetE2eMaxWallClock,
    );

    await bootstrapNewGameToMap(tester, perf: perf);
    ensureUnderWallClock('after bootstrap');

    final l10n = lookupAppLocalizations(const Locale('en'));

    await splitHomeFleetOnce(
      tester,
      l10n,
      perf: perf,
      openNavalTimeout: _kMaxUiResponseWait,
      bottomSheetCloseTimeout: _kMaxUiResponseWait,
    );
    await closeBottomSheet(
      tester,
      perf: perf,
      overallTimeout: _kMaxUiResponseWait,
    );
    ensureUnderWallClock('after split fleet');

    final loopResult = await fleetReachTurnLoop(
      tester,
      l10n,
      perf: perf,
      ensureUnderWallClock: ensureUnderWallClock,
      maxUiResponseWait: _kMaxUiResponseWait,
      maxTurns: _kMaxNextTurnTapsForNwFleetReach,
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
      maxUiResponseWait: _kMaxUiResponseWait,
      failureMessageBuilder: (lastException) =>
          'After $_kMaxNextTurnTapsForNwFleetReach Next turn resolutions, no non-home human fleet in region '
          'newWorld (ctE2eNavalPanelSnapshot / naval panel UI). '
          'Last exception: $lastException',
    );
    ensureUnderWallClock('test complete');
    perf.timing('test_total', testSw.elapsed, meta: 'result=final_check');
  });

  testWidgets(
    'post-bundle GitHub #1869: after NW fleet, Explorer Assign → Explore enabled',
    (WidgetTester tester) async {
      const testName = 'new_game_fleet_explore_enabled_post_bundle';
      final perf = E2ePerfLog(testName);
      final testSw = Stopwatch()..start();
      expect(
        kCtE2EEnabled,
        isTrue,
        reason:
            'Run with: flutter test integration_test/... --dart-define=CT_E2E=true',
      );

      await tester.binding.setSurfaceSize(const Size(1280, 720));
      final bootstrapSw = Stopwatch()..start();
      await bootstrapForIntegrationTest();
      await tester.pump();
      await e2eWaitForNewGameEntry(tester, perf: perf);
      perf.timing('bootstrap_for_integration_test', bootstrapSw.elapsed);
      await ensureAllRelocated64pxPngsLoadSuiteOnce();

      final wallClock = Stopwatch()..start();
      final ensureUnderWallClock = e2eMakeWallClockGuard(
        testName: testName,
        stopwatch: wallClock,
        cap: _kFleetE2eMaxWallClock,
      );

      await bootstrapNewGameToMap(tester, perf: perf);
      ensureUnderWallClock('after bootstrap');

      final l10n = lookupAppLocalizations(const Locale('en'));

      await splitHomeFleetOnce(
        tester,
        l10n,
        perf: perf,
        openNavalTimeout: _kMaxUiResponseWait,
        bottomSheetCloseTimeout: _kMaxUiResponseWait,
      );
      await closeBottomSheet(
        tester,
        perf: perf,
        overallTimeout: _kMaxUiResponseWait,
      );
      ensureUnderWallClock('after split fleet');

      final loopResult = await fleetReachTurnLoop(
        tester,
        l10n,
        perf: perf,
        ensureUnderWallClock: ensureUnderWallClock,
        maxUiResponseWait: _kMaxUiResponseWait,
        maxTurns: _kMaxNextTurnTapsForNwFleetReach,
      );
      CtE2eNavalPanelSnapshot? lastKnownNavalSnapshot =
          loopResult.lastKnownNavalSnapshot;

      final finalCheck = await ensureNonHomeFleetInNwAfterLoop(
        tester,
        perf: perf,
        maxUiResponseWait: _kMaxUiResponseWait,
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
        maxUiResponseWait: _kMaxUiResponseWait,
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
        maxUiResponseWait: _kMaxUiResponseWait,
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
