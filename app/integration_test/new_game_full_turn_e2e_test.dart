import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:colonizethis_app/config/ct_e2e.dart';
import 'package:colonizethis_app/config/ct_e2e_last_panel_snapshot.dart';
import 'package:colonizethis_app/features/game/flame/game_screen_shared.dart';
import 'e2e_helpers.dart';
import 'package:colonizethis_app/main.dart' show bootstrapForIntegrationTest;
import 'package:colonizethis_app/test_support/civilian_units_panel_e2e_expected_lines.dart';
import 'package:colonizethis_app/test_support/naval_units_panel_e2e_expected_lines.dart';
import 'package:colonizethis_app/test_support/production_panel_e2e_expected_lines.dart';
import 'package:colonizethis_models/colonizethis_models.dart'
    show kUnitTypeExplorer;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  suppressLogsForTests();
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'new game → full human turn: civilians, naval split/move, production',
    (WidgetTester tester) async {
      // Standard E2E scenario opener (kCtE2EEnabled gate, surface size,
      // bootstrap, asset preload, new-game-to-map, l10n) lifted into
      // [enterStandardE2eScenario] so the full-turn and capital-panel
      // scenarios share one canonical entry sequence and the widget-test
      // pin at `app/test/e2e_enter_standard_e2e_scenario_test.dart`
      // guards the constants / signature contract. The lifted helper
      // emits the `asset_preload` timing slice (full-turn parity) by
      // default; passing `assetPreloadTimingPhase: null` would suppress
      // it. Refs GitHub #2336 AC1 / AC2 / Bottleneck 6.
      final opener = await enterStandardE2eScenario(
        tester,
        testName: 'new_game_full_turn',
        bootstrapForIntegrationTest: bootstrapForIntegrationTest,
      );
      final perf = opener.perf;
      final testSw = opener.testSw;
      final l10n = opener.l10n;
      final ensureUnderWallClock = opener.ensureUnderWallClock;

      Future<void> expectCivilianPanelTexts() async {
        await expectPanelTextsMatchSnapshot(
          tester,
          panelRootKey: kCtE2ECivilianPanelRootKey,
          snapshot: ctE2eCivilianPanelSnapshot,
          buildExpected: () => civilianUnitsPanelExpectedTexts(
            ctE2eCivilianPanelSnapshot!,
            l10n,
          ),
          phaseName: 'wait_until_found_civilian_panel',
          perf: perf,
        );
      }

      Future<void> expectNavalPanelTexts({required bool expanded}) async {
        await expectPanelTextsMatchSnapshot(
          tester,
          panelRootKey: kCtE2ENavalPanelRootKey,
          snapshot: ctE2eNavalPanelSnapshot,
          buildExpected: () => navalUnitsPanelExpectedTexts(
            ctE2eNavalPanelSnapshot!,
            l10n,
            fleetTilesExpanded: expanded,
          ),
          phaseName: 'wait_until_found_naval_panel',
          perf: perf,
          buildAlternativeExpected: expanded
              ? () => navalUnitsPanelExpectedTexts(
                  ctE2eNavalPanelSnapshot!,
                  l10n,
                  fleetTilesExpanded: false,
                )
              : null,
        );
      }

      Future<void> expectProductionPanelTexts() async {
        await expectPanelTextsMatchSnapshot(
          tester,
          panelRootKey: kCtE2EProductionPanelRootKey,
          snapshot: ctE2eProductionPanelSnapshot,
          buildExpected: () => productionPanelWideExpectedTexts(
            ctE2eProductionPanelSnapshot!,
            l10n,
          ),
          phaseName: 'wait_until_found_production_panel',
          perf: perf,
        );
      }

      // --- Civilian (empire rail): baseline ---
      await openCivilianPanel(tester, perf: perf);
      await expectCivilianPanelTexts();
      await closeBottomSheet(tester, perf: perf);
      ensureUnderWallClock('after civilian baseline panel');

      // --- Builder: build improvement + first legal tile (e2e tap target) ---
      await openCivilianPanel(tester, perf: perf);
      await tapFirstAssignInCivilianPanel(tester);
      await tester.tap(find.text('Build improvement'));
      await pickFirstValidWorkTileAndAwaitOverlayClear(
        tester,
        appearPhase: 'wait_until_first_valid_work_tile_after_build_improvement',
        clearPhase: 'pump_until_work_tile_overlay_cleared_build',
        perf: perf,
      );
      await closeBottomSheet(tester, perf: perf);
      ensureUnderWallClock('after builder build_improvement');

      // --- Explorer: prospect + first legal tile ---
      await openCivilianPanel(tester, perf: perf);
      await tapAssignOnCivilianRowWithTitle(tester, kUnitTypeExplorer);
      await tester.tap(find.text('Prospect'));
      await maybePickFirstValidWorkTileAndAwaitOverlayClear(
        tester,
        appearPhase: 'pump_until_prospect_work_tile_optional',
        clearPhase: 'pump_until_work_tile_overlay_cleared_prospect',
        skippedTimingLabel: 'prospect_work_tile',
        skippedMeta: 'skipped_no_valid_tile_on_e2e_map',
        perf: perf,
      );
      await closeBottomSheet(tester, perf: perf);
      ensureUnderWallClock('after explorer prospect');

      // --- Civilian rail: after draft orders ---
      await openCivilianPanel(tester, perf: perf);
      await expectCivilianPanelTexts();
      await closeBottomSheet(tester, perf: perf);
      ensureUnderWallClock('after civilian post-draft panel');

      // --- Naval rail: collapsed ---
      await openNavalPanel(tester, perf: perf);
      await expectNavalPanelTexts(expanded: false);
      await expandEachExpansionTileOnce(tester);
      await splitHomeFleetOnce(
        tester,
        l10n,
        perf: perf,
        navalPanelAlreadyOpen: true,
      );
      await attemptFirstFleetMoveOrCancel(tester, l10n, perf: perf);
      await dismissCtDialogShellIfPresent(tester, l10n, perf: perf);

      await expandEachExpansionTileOnce(tester);
      await expectNavalPanelTexts(expanded: true);
      await closeBottomSheet(tester, perf: perf);
      ensureUnderWallClock('after naval split + move');

      // --- Civilian + naval from first map markers (tile scope) ---
      await openPanelFromMarker(
        tester,
        markerButton: find.byKey(kCtE2EOpenFirstCivilianMarkerPanelKey),
        panelRoot: find.byKey(kCtE2ECivilianPanelRootKey),
        perf: perf,
      );
      await expectCivilianPanelTexts();
      await closeBottomSheet(tester, perf: perf);
      ensureUnderWallClock('after civilian marker panel');

      await openPanelFromMarker(
        tester,
        markerButton: find.byKey(kCtE2EOpenFirstFleetMarkerPanelKey),
        panelRoot: find.byKey(kCtE2ENavalPanelRootKey),
        perf: perf,
      );
      await expectNavalPanelTexts(expanded: false);
      await closeBottomSheet(tester, perf: perf);
      ensureUnderWallClock('after fleet marker panel');

      // --- Next turn ---
      await dismissTransientUi(tester, perf: perf);
      await closeBottomSheet(tester, perf: perf);
      final nextTurnElapsed = await advanceOneHumanTurn(
        tester,
        l10n: l10n,
        perf: perf,
      );
      expect(
        nextTurnElapsed,
        lessThan(kE2eNextTurnResolutionTimeout),
        reason:
            'Next turn should resolve within the turn-resolution usability budget.',
      );
      ensureUnderWallClock('after next turn');

      // --- Production (post-resolution stockpiles) ---
      await openProductionPanel(tester, perf: perf);
      await expectProductionPanelTexts();

      await tester.tap(find.byIcon(Icons.arrow_back));
      await waitUntilFound(
        tester,
        find.byKey(kHomeToCapitalButtonKey),
        timeout: const Duration(seconds: 10),
        perf: perf,
        phaseName: 'wait_until_home_to_capital_after_production_back',
      );
      expect(find.byKey(kHomeToCapitalButtonKey), findsOneWidget);
      ensureUnderWallClock('test complete');
      perf.timing('test_total', testSw.elapsed);
    },
  );
}
