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
import 'package:colonizethis_app/widgets/ct_nine_patch_button.dart';
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

      await tester.binding.setSurfaceSize(const Size(1280, 720));
      final bootstrapSw = Stopwatch()..start();
      await bootstrapForIntegrationTest();
      await tester.pump();
      await e2eWaitForNewGameEntry(tester, perf: perf);
      perf.timing('bootstrap_for_integration_test', bootstrapSw.elapsed);
      final preloadSw = Stopwatch()..start();
      await ensureAllRelocated64pxPngsLoadSuiteOnce();
      perf.timing('asset_preload', preloadSw.elapsed);

      final newGameSw = Stopwatch()..start();
      await bootstrapNewGameToMap(tester, perf: perf);
      perf.timing('new_game_to_map', newGameSw.elapsed);

      final l10n = lookupAppLocalizations(const Locale('en'));

      Future<void> expectCivilianPanelTexts() async {
        await waitUntilFound(
          tester,
          find.byKey(kCtE2ECivilianPanelRootKey),
          timeout: const Duration(seconds: 20),
          perf: perf,
          phaseName: 'wait_until_found_civilian_panel',
        );
        final snap = ctE2eCivilianPanelSnapshot;
        expect(snap, isNotNull);
        final expected = civilianUnitsPanelExpectedTexts(snap!, l10n);
        final actual = <String>[];
        collectTextPreorder(
          tester.element(find.byKey(kCtE2ECivilianPanelRootKey)),
          actual,
        );
        expect(actual, orderedEquals(expected));
      }

      Future<void> expectNavalPanelTexts({required bool expanded}) async {
        await waitUntilFound(
          tester,
          find.byKey(kCtE2ENavalPanelRootKey),
          timeout: const Duration(seconds: 20),
          perf: perf,
          phaseName: 'wait_until_found_naval_panel',
        );
        final snap = ctE2eNavalPanelSnapshot;
        expect(snap, isNotNull);
        final expected = navalUnitsPanelExpectedTexts(
          snap!,
          l10n,
          fleetTilesExpanded: expanded,
        );
        final actual = <String>[];
        collectTextPreorder(
          tester.element(find.byKey(kCtE2ENavalPanelRootKey)),
          actual,
        );
        if (!expanded) {
          expect(actual, orderedEquals(expected));
          return;
        }
        final collapsedExpected = navalUnitsPanelExpectedTexts(
          snap,
          l10n,
          fleetTilesExpanded: false,
        );
        expect(
          actual,
          anyOf(orderedEquals(expected), orderedEquals(collapsedExpected)),
        );
      }

      Future<void> expectProductionPanelTexts() async {
        await waitUntilFound(
          tester,
          find.byKey(kCtE2EProductionPanelRootKey),
          timeout: const Duration(seconds: 20),
          perf: perf,
          phaseName: 'wait_until_found_production_panel',
        );
        final snap = ctE2eProductionPanelSnapshot;
        expect(snap, isNotNull);
        final expected = productionPanelWideExpectedTexts(snap!, l10n);
        final actual = <String>[];
        collectTextPreorder(
          tester.element(find.byKey(kCtE2EProductionPanelRootKey)),
          actual,
        );
        expect(actual, orderedEquals(expected));
      }

      // --- Civilian (empire rail): baseline ---
      await openCivilianPanel(tester, perf: perf);
      await expectCivilianPanelTexts();
      await closeBottomSheet(tester, perf: perf);

      // --- Builder: build improvement + first legal tile (e2e tap target) ---
      await openCivilianPanel(tester, perf: perf);
      await tapFirstAssignInCivilianPanel(tester);
      await tester.tap(find.text('Build improvement'));
      await waitUntilFound(
        tester,
        find.byKey(kCtE2ESelectFirstValidWorkTileKey).hitTestable(),
        timeout: const Duration(seconds: 5),
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

      // --- Explorer: prospect + first legal tile ---
      await openCivilianPanel(tester, perf: perf);
      await tapAssignOnCivilianRowWithTitle(tester, kUnitTypeExplorer);
      await tester.tap(find.text('Prospect'));
      await waitUntilFound(
        tester,
        find.byKey(kCtE2ESelectFirstValidWorkTileKey).hitTestable(),
        timeout: const Duration(seconds: 5),
        perf: perf,
        phaseName: 'wait_until_first_valid_work_tile_after_prospect',
      );
      await tester.tap(find.byKey(kCtE2ESelectFirstValidWorkTileKey));
      await e2ePumpUntil(
        tester,
        () => find.byKey(kCtE2ESelectFirstValidWorkTileKey).evaluate().isEmpty,
        timeout: const Duration(seconds: 5),
        perf: perf,
        phaseName: 'pump_until_work_tile_overlay_cleared_prospect',
      );
      await closeBottomSheet(tester, perf: perf);

      // --- Civilian rail: after draft orders ---
      await openCivilianPanel(tester, perf: perf);
      await expectCivilianPanelTexts();
      await closeBottomSheet(tester, perf: perf);

      // --- Naval rail: collapsed ---
      await openNavalPanel(tester, perf: perf);
      await expectNavalPanelTexts(expanded: false);
      await expandEachExpansionTileOnce(tester);
      final navalPanelRoot = find.byKey(kCtE2ENavalPanelRootKey);
      final split = find.descendant(
        of: navalPanelRoot,
        matching: find.text('Split'),
      );
      expect(split, findsWidgets);
      final moveOneRight = find.descendant(
        of: find.byType(CtDialogShell),
        matching: find.widgetWithText(CtNinePatchButton, '>'),
      );
      await tester.tap(split.first);
      await waitUntilFound(
        tester,
        moveOneRight.hitTestable(),
        timeout: const Duration(seconds: 5),
        perf: perf,
        phaseName: 'wait_until_split_stepper_visible',
      );
      await tester.tap(moveOneRight.first);
      await waitUntilFound(
        tester,
        find.text('Confirm Split').hitTestable(),
        timeout: const Duration(seconds: 5),
        perf: perf,
        phaseName: 'wait_until_confirm_split_visible',
      );
      await tester.tap(find.text('Confirm Split'));
      await e2ePumpUntil(
        tester,
        () => find.byType(CtDialogShell).evaluate().isEmpty,
        timeout: const Duration(seconds: 5),
        perf: perf,
        phaseName: 'pump_until_split_dialog_closed',
      );

      // Split triggers a panel refresh; ensure fleet tiles are expanded again.
      await expandEachExpansionTileOnce(tester);
      final moveButtons = find.descendant(
        of: navalPanelRoot,
        matching: find.text('Move'),
      );
      if (moveButtons.evaluate().isNotEmpty) {
        await tester.tap(moveButtons.first);
        await e2ePumpUntil(
          tester,
          () =>
              find.byType(RadioListTile<dynamic>).evaluate().isNotEmpty ||
              find.text('Confirm').hitTestable().evaluate().isNotEmpty ||
              find.byType(AlertDialog).evaluate().isNotEmpty,
          timeout: const Duration(seconds: 5),
          perf: perf,
          phaseName: 'pump_until_move_dialog_ready',
        );

        final seaRadio = find.byType(RadioListTile<dynamic>);
        if (seaRadio.evaluate().isNotEmpty) {
          await tester.tap(seaRadio.first);
          await waitUntilFound(
            tester,
            find.text('Confirm').hitTestable(),
            timeout: const Duration(seconds: 5),
            perf: perf,
            phaseName: 'wait_until_move_confirm_after_sea_radio',
          );
        }
        final confirm = find.text('Confirm');
        if (confirm.evaluate().isNotEmpty) {
          await tester.tap(confirm.first);
          await e2ePumpUntil(
            tester,
            () => find.byType(AlertDialog).evaluate().isEmpty,
            timeout: const Duration(seconds: 5),
            perf: perf,
            phaseName: 'pump_until_move_dialog_closed',
          );
        }
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

      // --- Civilian + naval from first map markers (tile scope) ---
      await openPanelFromMarker(
        tester,
        markerButton: find.byKey(kCtE2EOpenFirstCivilianMarkerPanelKey),
        panelRoot: find.byKey(kCtE2ECivilianPanelRootKey),
        perf: perf,
      );
      await expectCivilianPanelTexts();
      await closeBottomSheet(tester, perf: perf);

      await openPanelFromMarker(
        tester,
        markerButton: find.byKey(kCtE2EOpenFirstFleetMarkerPanelKey),
        panelRoot: find.byKey(kCtE2ENavalPanelRootKey),
        perf: perf,
      );
      await expectNavalPanelTexts(expanded: false);
      await closeBottomSheet(tester, perf: perf);

      // --- Next turn ---
      final turnBefore =
          find
                  .descendant(
                    of: find.byKey(kGameMapNextTurnButtonKey),
                    matching: find.byType(Text),
                  )
                  .evaluate()
                  .single
                  .widget
              as Text;
      final turnLabelBefore = turnBefore.data!;

      await tester.tap(find.byKey(kGameMapNextTurnButtonKey));
      perf.bumpCounter('next_turn_taps');
      await e2ePumpUntil(
        tester,
        () {
          if (find.text(l10n.common_yes).hitTestable().evaluate().isNotEmpty) {
            return true;
          }
          final turnAfterFinder = find.descendant(
            of: find.byKey(kGameMapNextTurnButtonKey),
            matching: find.byType(Text),
          );
          if (turnAfterFinder.evaluate().isEmpty) {
            return false;
          }
          final turnAfter = turnAfterFinder.evaluate().single.widget as Text;
          return turnAfter.data != turnLabelBefore;
        },
        timeout: const Duration(seconds: 2),
        perf: perf,
        phaseName: 'pump_until_next_turn_confirm_or_label_advanced',
      );
      final confirmNextTurn = find.text(l10n.common_yes).hitTestable();
      if (confirmNextTurn.evaluate().isNotEmpty) {
        await tester.tap(confirmNextTurn.first, warnIfMissed: false);
      }
      final nextTurnElapsed = await e2eWaitForNextTurnLabelAdvance(
        tester,
        turnLabelBefore: turnLabelBefore,
        timeout: const Duration(seconds: 10),
        perf: perf,
      );
      // Refs #2237 AC1 benchmark budget on CI baseline.
      expect(
        nextTurnElapsed,
        lessThan(const Duration(seconds: 10)),
        reason:
            'Next turn should resolve under 10s for new-game benchmark path.',
      );

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
      perf.timing('test_total', testSw.elapsed);
    },
  );
}
