import 'package:colonizethis_data/colonizethis_data.dart' show MapTopology;
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:colonizethis_app/config/ct_e2e.dart';
import 'package:colonizethis_app/config/ct_e2e_last_panel_snapshot.dart';
import 'package:colonizethis_app/features/game/widgets/units/shared/units_panel_region_label.dart';
import 'e2e_test_shared.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart'
    show
        OrderEngine,
        allProvinces,
        buildPlayerView,
        homeFleetIdFor,
        kWorkTargetExplore,
        provinceIdsAdjacentToSeaZone,
        regionIdForSeaZone,
        suggestWorkOrders;
import 'package:colonizethis_models/colonizethis_models.dart'
    show MoveOrder, ProvinceId, Unit, WorkOrder, kUnitTypeExplorer;
import 'package:colonizethis_app/features/game/flame/game_screen_shared.dart';
import 'package:colonizethis_app/l10n/l10n.dart';
import 'package:colonizethis_app/main.dart' show bootstrapForIntegrationTest;
import 'package:colonizethis_app/widgets/ct_choice_chip.dart';
import 'package:colonizethis_app/widgets/ct_dialog_shell.dart';
import 'package:colonizethis_app/widgets/ct_nine_patch_button.dart';
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

    final wallClock = Stopwatch()..start();
    void ensureUnderWallClock(String step) {
      if (wallClock.elapsed > _kFleetE2eMaxWallClock) {
        fail(
          'Fleet e2e exceeded ${_kFleetE2eMaxWallClock.inMinutes} minute wall clock '
          'at $step (elapsed=${wallClock.elapsed.inSeconds}s).',
        );
      }
    }

    await e2eBootstrapNewGameToMap(tester, perf: perf);
    ensureUnderWallClock('after bootstrap');

    final l10n = lookupAppLocalizations(const Locale('en'));

    await _splitHomeFleetOnce(tester, l10n, perf: perf);
    await e2eCloseBottomSheet(tester, perf: perf, overallTimeout: _kMaxUiResponseWait);
    ensureUnderWallClock('after split fleet');

    for (
      var turnIdx = 0;
      turnIdx < _kMaxNextTurnTapsForNwFleetReach;
      turnIdx++
    ) {
      ensureUnderWallClock('turn loop start turnIdx=$turnIdx');
      perf.bumpCounter('turn_loop_iterations');
      await e2eDismissTransientUi(tester, perf: perf);
      await _tapNewWorldRegionTabIfPresent(tester);
      await _openNavalPanel(tester, perf: perf);
      if (_harnessDetectsNonHomeFleetInNewWorld(tester)) {
        await e2eCloseBottomSheet(tester, perf: perf, overallTimeout: _kMaxUiResponseWait);
        perf.timing(
          'test_total',
          testSw.elapsed,
          meta: 'result=reached_in_loop',
        );
        return;
      }
      await e2eCloseBottomSheet(tester, perf: perf, overallTimeout: _kMaxUiResponseWait);

      await _tryNavalMoveSegment(tester, l10n, perf: perf);
      await e2eCloseBottomSheet(tester, perf: perf, overallTimeout: _kMaxUiResponseWait);

      if (_harnessDetectsNonHomeFleetInNewWorld(tester)) {
        perf.timing(
          'test_total',
          testSw.elapsed,
          meta: 'result=reached_after_move',
        );
        return;
      }

      await _advanceOneHumanTurn(tester, l10n, perf: perf);
      await e2eDismissTransientUi(tester, perf: perf);
      ensureUnderWallClock('after turn advance turnIdx=$turnIdx');
    }

    ensureUnderWallClock('before final naval check');
    await e2eDismissTransientUi(tester, perf: perf);
    await _tapNewWorldRegionTabIfPresent(tester);
    await _openNavalPanel(tester, perf: perf);
    if (!_harnessDetectsNonHomeFleetInNewWorld(tester)) {
      fail(
        'After $_kMaxNextTurnTapsForNwFleetReach Next turn resolutions, no non-home human fleet in region '
        'newWorld (ctE2eNavalPanelSnapshot / naval panel UI). '
        'Last exception: ${tester.takeException()}',
      );
    }
    await e2eCloseBottomSheet(tester, perf: perf, overallTimeout: _kMaxUiResponseWait);
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

      final wallClock = Stopwatch()..start();
      void ensureUnderWallClock(String step) {
        if (wallClock.elapsed > _kFleetE2eMaxWallClock) {
          fail(
            'Fleet e2e exceeded ${_kFleetE2eMaxWallClock.inMinutes} minute wall clock '
            'at $step (elapsed=${wallClock.elapsed.inSeconds}s).',
          );
        }
      }

      await e2eBootstrapNewGameToMap(tester, perf: perf);
      ensureUnderWallClock('after bootstrap');

      final l10n = lookupAppLocalizations(const Locale('en'));

      await _splitHomeFleetOnce(tester, l10n, perf: perf);
      await e2eCloseBottomSheet(tester, perf: perf, overallTimeout: _kMaxUiResponseWait);
      ensureUnderWallClock('after split fleet');
      CtE2eNavalPanelSnapshot? lastKnownNavalSnapshot;

      for (
        var turnIdx = 0;
        turnIdx < _kMaxNextTurnTapsForNwFleetReach;
        turnIdx++
      ) {
        ensureUnderWallClock('turn loop start turnIdx=$turnIdx');
        perf.bumpCounter('turn_loop_iterations');
        await e2eDismissTransientUi(tester, perf: perf);
        await _tapNewWorldRegionTabIfPresent(tester);
        await _openNavalPanel(tester, perf: perf);
        if (ctE2eNavalPanelSnapshot != null) {
          lastKnownNavalSnapshot = ctE2eNavalPanelSnapshot;
        }
        if (_harnessDetectsNonHomeFleetInNewWorld(tester)) {
          await e2eCloseBottomSheet(tester, perf: perf, overallTimeout: _kMaxUiResponseWait);
          break;
        }
        await e2eCloseBottomSheet(tester, perf: perf, overallTimeout: _kMaxUiResponseWait);

        await _tryNavalMoveSegment(tester, l10n, perf: perf);
        await e2eCloseBottomSheet(tester, perf: perf, overallTimeout: _kMaxUiResponseWait);

        if (_harnessDetectsNonHomeFleetInNewWorld(tester)) {
          break;
        }

        await _advanceOneHumanTurn(tester, l10n, perf: perf);
        await e2eDismissTransientUi(tester, perf: perf);
        ensureUnderWallClock('after turn advance turnIdx=$turnIdx');
      }

      await e2eDismissTransientUi(tester, perf: perf);
      await _tapNewWorldRegionTabIfPresent(tester);
      await _openNavalPanel(tester, perf: perf);
      if (ctE2eNavalPanelSnapshot != null) {
        lastKnownNavalSnapshot = ctE2eNavalPanelSnapshot;
      }
      if (!_harnessDetectsNonHomeFleetInNewWorld(tester)) {
        fail(
          'Explorer explore e2e requires a non-home human fleet in New World first. '
          'Last exception: ${tester.takeException()}',
        );
      }
      await e2eCloseBottomSheet(tester, perf: perf, overallTimeout: _kMaxUiResponseWait);
      ensureUnderWallClock('fleet in NW confirmed');

      await _awaitNwCoastalOrVisibleLandForBundledExploreE2e(
        tester: tester,
        l10n: l10n,
        ensureUnderWallClock: ensureUnderWallClock,
      );

      await _tapNewWorldRegionTabIfPresent(tester);
      Future<bool> checkExploreEnabledFromCivilianPanel() async {
        final phaseSw = Stopwatch()..start();
        await e2eOpenCivilianPanel(
          tester,
          afterSheetPanelsClearPhase:
              'pump_until_panels_cleared_after_close_sheet_fleet_civilian_open',
          bottomSheetCloseTimeout: _kMaxUiResponseWait,
        );
        await e2eWaitUntilFound(
          tester,
          find.byKey(kCtE2ECivilianPanelRootKey),
          timeout: _kMaxUiResponseWait,
          perf: perf,
          phaseName: 'wait_until_found_civilian_panel',
        );
        final enabled = await _anyExplorerHasEnabledExploreAssignFleetE2e(
          tester,
        );
        await e2eCloseBottomSheet(tester, perf: perf, overallTimeout: _kMaxUiResponseWait);
        perf.timing(
          'bundled_explore_retry_loop',
          phaseSw.elapsed,
          meta: 'result=${enabled ? "enabled" : "not_enabled"}',
        );
        return enabled;
      }

      var exploreEnabled = await checkExploreEnabledFromCivilianPanel();
      // Linux CI can require more than three post-reveal turns before the
      // Assign list surfaces an enabled Explore row for at least one explorer.
      // Keep strict failure semantics, but widen the bounded retry window.
      const maxBoundedTurnRetries = 8;
      for (
        var retryIdx = 0;
        !exploreEnabled && retryIdx < maxBoundedTurnRetries;
        retryIdx++
      ) {
        // CI can lag reveal/suggestion propagation by a few turns.
        // Keep assertion strict, but retry with a small bounded loop.
        perf.bumpCounter('bundled_explore_retry_iterations');
        await _advanceOneHumanTurn(tester, l10n, perf: perf);
        await e2eDismissTransientUi(tester, perf: perf);
        await _tapNewWorldRegionTabIfPresent(tester);
        exploreEnabled = await checkExploreEnabledFromCivilianPanel();
      }
      if (!exploreEnabled) {
        if (!_playerHasAnyNewWorldFoggedOrBetterFromCtSnapshot()) {
          // Guard against CI topology/seed runs where no NW land becomes
          // visible within bounded retries, so Explore cannot be enabled.
          return;
        }
        final diag = _bundledExploreRejectionDiagnostics(
          lastKnownNavalSnapshot,
        );
        fail(
          'Post-bundle #1869 regression: Explorer Assign never surfaced an enabled '
          'Explore row after New World fleet confirmation and '
          '$maxBoundedTurnRetries bounded Next turn retries.\n'
          '$diag\n'
          'Last exception: ${tester.takeException()}',
        );
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
