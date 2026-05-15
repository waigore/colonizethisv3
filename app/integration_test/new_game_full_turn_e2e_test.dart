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

Future<void> _openPanelFromMarker(
  WidgetTester tester, {
  required Finder markerButton,
  required Finder panelRoot,
  Duration timeout = const Duration(seconds: 20),
  E2ePerfLog? perf,
}) async {
  final sw = Stopwatch()..start();
  var panelPollMs = 25;
  while (sw.elapsed < timeout) {
    if (panelRoot.evaluate().isNotEmpty) {
      perf?.timing('open_panel_from_marker', sw.elapsed);
      return;
    }
    final tappable = markerButton.hitTestable();
    if (tappable.evaluate().isEmpty) {
      // Clear transient overlays/dialogs that can block marker taps.
      await dismissTransientUi(tester, perf: perf);
      if (panelRoot.evaluate().isNotEmpty) {
        perf?.timing('open_panel_from_marker', sw.elapsed);
        return;
      }
      if (await e2ePumpUntilConditionOrIdle(
        tester,
        () => markerButton.hitTestable().evaluate().isNotEmpty,
        timeout: Duration(milliseconds: panelPollMs),
        perf: perf,
        phaseName: 'pump_until_marker_hit_testable_after_dismiss',
      )) {
        panelPollMs = 25;
      } else {
        panelPollMs = e2eAdaptivePollRampAfterIdle(panelPollMs);
      }
      continue;
    }
    await tester.tap(tappable.first, warnIfMissed: false);
    if (panelRoot.evaluate().isNotEmpty) {
      perf?.timing('open_panel_from_marker', sw.elapsed);
      return;
    }
    await tester.pump();
    if (panelRoot.evaluate().isNotEmpty) {
      perf?.timing('open_panel_from_marker', sw.elapsed);
      return;
    }
    if (await e2ePumpUntilConditionOrIdle(
      tester,
      () => panelRoot.evaluate().isNotEmpty,
      timeout: const Duration(seconds: 3),
      perf: perf,
      phaseName: 'pump_until_marker_panel_root_after_tap',
    )) {
      perf?.timing('open_panel_from_marker', sw.elapsed);
      return;
    }
    panelPollMs = 25;
    await tester.pump(Duration(milliseconds: panelPollMs));
    panelPollMs = e2eAdaptivePollRampAfterIdle(panelPollMs);
  }
  fail(
    'Timed out after ${timeout.inSeconds}s opening marker panel. '
    'marker=$markerButton panel=$panelRoot Last exception: ${tester.takeException()}',
  );
}

Future<void> _openProductionPanel(WidgetTester tester) async {
  final productionPanel = find.byKey(kCtE2EProductionPanelRootKey);
  final productionButton = find.byKey(kEmpireProductionButtonKey);
  final sw = Stopwatch()..start();
  var idlePollMs = 25;
  while (sw.elapsed < const Duration(seconds: 20)) {
    if (productionPanel.evaluate().isNotEmpty) {
      return;
    }

    if (find.byType(BottomSheet).evaluate().isNotEmpty) {
      await closeBottomSheet(tester);
      // Exit the spin loop as soon as the sheet is gone (Refs #2336 H7).
      await e2ePumpUntilConditionOrIdle(
        tester,
        () => find.byType(BottomSheet).evaluate().isEmpty,
        timeout: const Duration(milliseconds: 600),
        phaseName: 'pump_until_sheet_cleared_production_open',
      );
      idlePollMs = 25;
      continue;
    }

    if (find.byType(CtDialogShell).evaluate().isNotEmpty) {
      await tester.binding.handlePopRoute();
      await e2ePumpUntil(
        tester,
        () => find.byType(CtDialogShell).evaluate().isEmpty,
        timeout: const Duration(seconds: 2),
        phaseName: 'pump_until_production_path_shell_cleared',
      );
      idlePollMs = 25;
      continue;
    }

    if (productionButton.evaluate().isNotEmpty) {
      final productionButtonHit = productionButton.hitTestable();
      final target = productionButtonHit.evaluate().isNotEmpty
          ? productionButtonHit
          : productionButton;
      await tester.tap(target.first, warnIfMissed: false);
      // Match civilian/naval open: skip the first poll wait when the panel
      // subtree mounts synchronously (Refs #2336 adaptive polling / H7).
      if (productionPanel.evaluate().isNotEmpty) {
        return;
      }
      idlePollMs = 25;
      await tester.pump();
      if (productionPanel.evaluate().isNotEmpty) {
        return;
      }
      await waitUntilFound(
        tester,
        productionPanel,
        timeout: const Duration(seconds: 5),
        phaseName: 'wait_until_production_panel_after_rail_tap',
      );
      if (productionPanel.evaluate().isNotEmpty) {
        return;
      }
      if (await e2ePumpUntilConditionOrIdle(
        tester,
        () => productionPanel.evaluate().isNotEmpty,
        timeout: const Duration(milliseconds: 600),
        phaseName: 'pump_until_production_panel_after_rail_tap_miss',
      )) {
        return;
      }
      idlePollMs = 25;
      continue;
    }
    // Dismiss transient overlays/dialogs and retry opening from the rail.
    await dismissTransientUi(tester);
    if (await e2ePumpUntilConditionOrIdle(
      tester,
      () =>
          productionPanel.evaluate().isNotEmpty ||
          productionButton.hitTestable().evaluate().isNotEmpty,
      timeout: Duration(milliseconds: idlePollMs),
      phaseName: 'pump_until_production_entry_after_dismiss_transient',
    )) {
      idlePollMs = 25;
    } else {
      idlePollMs = e2eAdaptivePollRampAfterIdle(idlePollMs);
    }
  }

  fail(
    'Timed out opening production panel; '
    'button=$productionButton panel=$productionPanel',
  );
}

Future<void> _tapFirstAssignInCivilianPanel(WidgetTester tester) async {
  final root = find.byKey(kCtE2ECivilianPanelRootKey);
  final listView = find.descendant(of: root, matching: find.byType(ListView));
  expect(listView, findsOneWidget);
  final panelScrollable = find.descendant(
    of: listView,
    matching: find.byType(Scrollable),
  );
  expect(panelScrollable, findsOneWidget);
  final assign = find.descendant(of: root, matching: find.text('Assign'));
  expect(assign, findsWidgets);
  final firstAssign = assign.first;
  await tester.scrollUntilVisible(
    firstAssign,
    120,
    scrollable: panelScrollable,
  );
  await tester.ensureVisible(firstAssign);
  await tester.pump();
  await tester.tap(firstAssign);
  await e2eWaitUntilAnyFinderHitTestable(
    tester,
    <Finder>[
      find.text('Build improvement'),
      find.text('Prospect'),
      find.text('Explore'),
    ],
    timeout: const Duration(seconds: 5),
    phaseName: 'wait_until_civilian_work_menu',
  );
}

/// Taps Assign on a [ListTile] whose title is exactly [unitTypeTitle]
/// (e.g. [Unit.type] like `Explorer`). Scrolls the panel [Scrollable] until the
/// row is visible, then taps Assign.
Future<void> _tapAssignOnCivilianRowWithTitle(
  WidgetTester tester,
  String unitTypeTitle,
) async {
  final root = find.byKey(kCtE2ECivilianPanelRootKey);
  final listView = find.descendant(of: root, matching: find.byType(ListView));
  expect(listView, findsOneWidget);
  final panelScrollable = find.descendant(
    of: listView,
    matching: find.byType(Scrollable),
  );
  expect(panelScrollable, findsOneWidget);
  // Scope titles to the list: several units share the same display title
  // (e.g. multiple `Explorer` rows); `find.text` under the root can match
  // unrelated widgets and break `scrollUntilVisible`.
  final titlesInList = find.descendant(
    of: listView,
    matching: find.text(unitTypeTitle),
  );
  // ListView lazy-builds off-screen rows; taller rows (shared action row) can
  // push unit types below the first viewport without any Text in the element tree.
  final sw = Stopwatch()..start();
  while (titlesInList.evaluate().isEmpty &&
      sw.elapsed < const Duration(seconds: 20)) {
    await tester.drag(panelScrollable, const Offset(0, -120));
    await e2ePumpUntilConditionOrIdle(
      tester,
      () => titlesInList.evaluate().isNotEmpty,
      timeout: const Duration(milliseconds: 200),
      phaseName: 'pump_until_civilian_title_visible_after_scroll_drag',
    );
  }
  expect(
    titlesInList,
    findsWidgets,
    reason:
        'Timed out scrolling civilian panel for a visible "$unitTypeTitle" row',
  );
  final n = titlesInList.evaluate().length;
  for (var i = 0; i < n; i++) {
    final titleAt = titlesInList.at(i);
    await tester.scrollUntilVisible(titleAt, 120, scrollable: panelScrollable);
    await tester.ensureVisible(titleAt);
    final listTile = find.ancestor(
      of: titleAt,
      matching: find.byType(ListTile),
    );
    final assign = find.descendant(of: listTile, matching: find.text('Assign'));
    if (assign.evaluate().isEmpty) {
      continue;
    }
    final assignHit = assign.first;
    await tester.ensureVisible(assignHit);
    await tester.pump();
    await tester.tap(assignHit);
    await e2eWaitUntilAnyFinderHitTestable(
      tester,
      <Finder>[
        find.text('Build improvement'),
        find.text('Prospect'),
        find.text('Explore'),
      ],
      timeout: const Duration(seconds: 5),
      phaseName: 'wait_until_civilian_work_menu_row',
    );
    return;
  }
  fail('No idle Assign row for unit type "$unitTypeTitle" in civilian panel');
}

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
      await _tapFirstAssignInCivilianPanel(tester);
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
      await _tapAssignOnCivilianRowWithTitle(tester, kUnitTypeExplorer);
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
      await tester.tap(find.byKey(kEmpireCivilianUnitsButtonKey));
      await expectCivilianPanelTexts();
      await closeBottomSheet(tester, perf: perf);

      // --- Naval rail: collapsed ---
      await tester.tap(find.byKey(kEmpireNavalUnitsButtonKey));
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
      await _openPanelFromMarker(
        tester,
        markerButton: find.byKey(kCtE2EOpenFirstCivilianMarkerPanelKey),
        panelRoot: find.byKey(kCtE2ECivilianPanelRootKey),
        perf: perf,
      );
      await expectCivilianPanelTexts();
      await closeBottomSheet(tester, perf: perf);

      await _openPanelFromMarker(
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
      await _openProductionPanel(tester);
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
