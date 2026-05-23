import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:colonizethis_app/config/ct_e2e.dart';
import 'package:colonizethis_app/config/ct_e2e_last_panel_snapshot.dart';
import 'package:colonizethis_app/features/game/flame/game_screen_shared.dart';
import 'e2e_helpers.dart';
import 'package:colonizethis_app/l10n/l10n.dart';
import 'package:colonizethis_app/main.dart' show bootstrapForIntegrationTest;
import 'package:colonizethis_app/test_support/civilian_units_panel_e2e_expected_lines.dart';
import 'package:colonizethis_app/test_support/naval_units_panel_e2e_expected_lines.dart';
import 'package:colonizethis_app/test_support/production_panel_e2e_expected_lines.dart';
import 'package:colonizethis_models/colonizethis_models.dart'
    show kUnitTypeExplorer;
import 'package:colonizethis_app/widgets/ct_dialog_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  suppressLogsForTests();
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'new game → full human turn: civilians, naval split/move, production',
    (WidgetTester tester) async {
      const testName = 'new_game_full_turn';
      final perf = E2ePerfLog(testName);
      final testSw = Stopwatch()..start();
      expect(
        kCtE2EEnabled,
        isTrue,
        reason:
            'Run with: flutter test integration_test/... --dart-define=CT_E2E=true',
      );

      // 5-minute PR wall-clock cap per scenario path per
      // `SPEC/program/e2e-integration-tests.md` § Determinism PR runtime rule
      // (`colonizethis-e2e-ui-stability.mdc`). Mirrors the fleet E2E pattern;
      // Refs GitHub #2336.
      final ensureUnderWallClock = e2eMakeWallClockGuard(
        testName: testName,
        stopwatch: testSw,
      );

      await tester.binding.setSurfaceSize(const Size(1280, 720));
      final bootstrapSw = Stopwatch()..start();
      await bootstrapForIntegrationTest();
      await tester.pump();
      await e2eWaitForNewGameEntry(tester, perf: perf);
      perf.timing('bootstrap_for_integration_test', bootstrapSw.elapsed);
      ensureUnderWallClock('after bootstrap_for_integration_test');
      final preloadSw = Stopwatch()..start();
      await ensureAllRelocated64pxPngsLoadSuiteOnce();
      perf.timing('asset_preload', preloadSw.elapsed);
      ensureUnderWallClock('after asset_preload');

      final newGameSw = Stopwatch()..start();
      await bootstrapNewGameToMap(tester, perf: perf);
      perf.timing('new_game_to_map', newGameSw.elapsed);
      ensureUnderWallClock('after new_game_to_map');

      final l10n = lookupAppLocalizations(const Locale('en'));

      Future<void> expectCivilianPanelTexts() async {
        await expectPanelTextsMatchSnapshot(
          tester,
          panelRootKey: kCtE2ECivilianPanelRootKey,
          snapshot: ctE2eCivilianPanelSnapshot,
          buildExpected: () =>
              civilianUnitsPanelExpectedTexts(ctE2eCivilianPanelSnapshot!, l10n),
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
      await waitUntilFound(
        tester,
        find.byKey(kCtE2ESelectFirstValidWorkTileKey).hitTestable(),
        timeout: const Duration(seconds: 15),
        perf: perf,
        phaseName: 'wait_until_first_valid_work_tile_after_build_improvement',
      );
      await tester.tap(find.byKey(kCtE2ESelectFirstValidWorkTileKey));
      await e2ePumpUntil(
        tester,
        () => find.byKey(kCtE2ESelectFirstValidWorkTileKey).evaluate().isEmpty,
        timeout: const Duration(seconds: 5),
        perf: perf,
        phaseName: 'pump_until_work_tile_overlay_cleared_build',
      );
      await closeBottomSheet(tester, perf: perf);
      ensureUnderWallClock('after builder build_improvement');

      // --- Explorer: prospect + first legal tile ---
      await openCivilianPanel(tester, perf: perf);
      await tapAssignOnCivilianRowWithTitle(tester, kUnitTypeExplorer);
      await tester.tap(find.text('Prospect'));
      final prospectWorkTile = find.byKey(kCtE2ESelectFirstValidWorkTileKey);
      final prospectTileReady = await e2ePumpUntilConditionOrIdle(
        tester,
        () => prospectWorkTile.hitTestable().evaluate().isNotEmpty,
        timeout: const Duration(seconds: 15),
        perf: perf,
        phaseName: 'pump_until_prospect_work_tile_optional',
      );
      if (prospectTileReady) {
        await tester.tap(prospectWorkTile.hitTestable().first, warnIfMissed: false);
        await e2ePumpUntil(
          tester,
          () => prospectWorkTile.evaluate().isEmpty,
          timeout: const Duration(seconds: 5),
          perf: perf,
          phaseName: 'pump_until_work_tile_overlay_cleared_prospect',
        );
      } else {
        perf.timing(
          'prospect_work_tile',
          Duration.zero,
          meta: 'skipped_no_valid_tile_on_e2e_map',
        );
      }
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
      final navalPanelRoot = find.byKey(kCtE2ENavalPanelRootKey);
      final moveButtons = find.descendant(
        of: navalPanelRoot,
        matching: find.text('Move'),
      );
      if (moveButtons.evaluate().isNotEmpty) {
        await tester.tap(moveButtons.first, warnIfMissed: false);
        await waitUntilFound(
          tester,
          find.byType(AlertDialog),
          timeout: const Duration(seconds: 5),
          perf: perf,
          phaseName: 'wait_until_move_dialog_after_tap',
        );
        final moveDialog = find.byType(AlertDialog);
        final destinationRadios = find.descendant(
          of: moveDialog,
          matching: find.byType(RadioListTile<dynamic>),
        );
        if (destinationRadios.evaluate().isEmpty) {
          final cancel = find.descendant(
            of: moveDialog,
            matching: find.text(l10n.common_cancel),
          ).hitTestable();
          expect(cancel, findsOneWidget);
          await tester.tap(cancel.first, warnIfMissed: false);
        } else {
          await tester.tap(destinationRadios.first, warnIfMissed: false);
          await e2ePumpUntilConditionOrIdle(
            tester,
            () => find
                .descendant(
                  of: moveDialog,
                  matching: find.text(l10n.common_confirm),
                )
                .hitTestable()
                .evaluate()
                .isNotEmpty,
            timeout: const Duration(seconds: 2),
            perf: perf,
            phaseName: 'pump_until_move_confirm_tappable',
          );
          final confirm = find
              .descendant(
                of: moveDialog,
                matching: find.text(l10n.common_confirm),
              )
              .hitTestable();
          await tester.tap(confirm.first, warnIfMissed: false);
        }
        await e2ePumpUntil(
          tester,
          () => find.byType(AlertDialog).evaluate().isEmpty,
          timeout: const Duration(seconds: 10),
          perf: perf,
          phaseName: 'pump_until_move_dialog_closed',
        );
      }
      if (find.byType(CtDialogShell).evaluate().isNotEmpty) {
        final closeCandidates = <Finder>[
          find.text(l10n.common_cancel),
          find.text(l10n.common_close),
          find.byIcon(Icons.close),
        ];
        for (final candidate in closeCandidates) {
          final tappable = candidate.hitTestable();
          if (tappable.evaluate().isNotEmpty) {
            await tester.tap(tappable.first, warnIfMissed: false);
            await e2ePumpUntil(
              tester,
              () => find.byType(CtDialogShell).evaluate().isEmpty,
              timeout: const Duration(seconds: 3),
              perf: perf,
              phaseName: 'pump_until_shell_closed_after_close_candidate',
            );
            break;
          }
        }
      }

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
