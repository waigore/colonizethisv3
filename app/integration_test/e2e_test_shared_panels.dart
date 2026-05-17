import 'package:colonizethis_app/config/ct_e2e.dart';
import 'package:colonizethis_app/features/game/dialogue/game_start_intro_overlay.dart';
import 'package:colonizethis_app/features/game/flame/game_screen_shared.dart';
import 'package:colonizethis_app/l10n/app_localizations_contract.dart';
import 'package:colonizethis_app/widgets/ct_dialog_shell.dart';
import 'package:colonizethis_app/widgets/ct_nine_patch_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'e2e_test_shared.dart';

Future<void> _e2eDismissGameStartIntroOverlayIfPresent(WidgetTester tester) async {
  if (find.byType(GameStartIntroOverlay).evaluate().isEmpty) {
    return;
  }
  for (final label in ['Continue', 'I shall.']) {
    final control = find.text(label);
    if (control.evaluate().isNotEmpty) {
      await tester.tap(control.first, warnIfMissed: false);
      break;
    }
  }
  await e2ePumpUntilConditionOrIdle(
    tester,
    () => find.byType(GameStartIntroOverlay).evaluate().isEmpty,
    timeout: const Duration(seconds: 2),
    phaseName: 'pump_until_game_start_intro_dismissed',
  );
}

/// Opens the civilian units panel from the empire rail or the first civilian
/// marker, closing a conflicting naval/civilian sheet first when needed.
///
/// Single canonical implementation for full-turn and fleet E2E (GitHub #2336
/// / AC2). Uses adaptive waits for rail/marker readiness instead of blind
/// idle pumps.
Future<void> e2eOpenCivilianPanel(
  WidgetTester tester, {
  Duration timeout = const Duration(seconds: 20),
  E2ePerfLog? perf,
  Duration bottomSheetCloseTimeout = kE2eDefaultBottomSheetCloseTimeout,
  String afterSheetPanelsClearPhase =
      'pump_until_panels_cleared_after_close_sheet_civilian_open',
}) async {
  final sw = Stopwatch()..start();
  final empireRailButton = find.byKey(kEmpireCivilianUnitsButtonKey);
  final markerButton = find.byKey(kCtE2EOpenFirstCivilianMarkerPanelKey);
  final civilianPanel = find.byKey(kCtE2ECivilianPanelRootKey);
  Future<bool> tryOpen(Finder trigger) async {
    if (civilianPanel.hitTestable().evaluate().isNotEmpty) {
      return true;
    }
    if (trigger.evaluate().isEmpty) {
      return false;
    }
    await tester.tap(trigger.first, warnIfMissed: false);
    if (civilianPanel.evaluate().isNotEmpty) {
      return true;
    }
    await tester.pump();
    if (civilianPanel.evaluate().isNotEmpty) {
      return true;
    }
    return e2ePumpUntilConditionOrIdle(
      tester,
      () => civilianPanel.evaluate().isNotEmpty,
      timeout: const Duration(seconds: 3),
      perf: perf,
      phaseName: 'pump_until_civilian_panel_after_trigger_tap',
    );
  }

  if (civilianPanel.hitTestable().evaluate().isNotEmpty) {
    perf?.timing('open_panel_civilian', sw.elapsed);
    return;
  }
  await _e2eDismissGameStartIntroOverlayIfPresent(tester);

  var panelPollMs = 25;
  while (sw.elapsed < timeout) {
    await tester.pump(Duration(milliseconds: panelPollMs));
    panelPollMs = e2eAdaptivePollRampAfterIdle(panelPollMs);

    if (find.byType(BottomSheet).evaluate().isNotEmpty) {
      await e2eCloseBottomSheet(
        tester,
        perf: perf,
        overallTimeout: bottomSheetCloseTimeout,
      );
      await e2ePumpUntilConditionOrIdle(
        tester,
        () => find.byType(BottomSheet).evaluate().isEmpty,
        timeout: const Duration(seconds: 2),
        perf: perf,
        phaseName: afterSheetPanelsClearPhase,
      );
      await e2ePumpUntilConditionOrIdle(
        tester,
        () =>
            empireRailButton.hitTestable().evaluate().isNotEmpty ||
            markerButton.hitTestable().evaluate().isNotEmpty,
        timeout: const Duration(seconds: 3),
        perf: perf,
        phaseName: 'pump_until_civilian_opener_after_sheet_close',
      );
      panelPollMs = 25;
      continue;
    }
    if (find.byType(AlertDialog).evaluate().isNotEmpty ||
        find.byType(CtDialogShell).evaluate().isNotEmpty) {
      await e2eDismissTransientUi(tester, perf: perf);
      panelPollMs = 25;
      continue;
    }
    if (empireRailButton.evaluate().isNotEmpty) {
      if (await tryOpen(empireRailButton)) {
        perf?.timing('open_panel_civilian', sw.elapsed);
        return;
      }
      panelPollMs = 25;
      continue;
    }
    if (markerButton.evaluate().isNotEmpty) {
      if (await tryOpen(markerButton)) {
        perf?.timing('open_panel_civilian', sw.elapsed);
        return;
      }
      panelPollMs = 25;
      continue;
    }
    if (await e2ePumpUntilConditionOrIdle(
      tester,
      () =>
          empireRailButton.hitTestable().evaluate().isNotEmpty ||
          markerButton.hitTestable().evaluate().isNotEmpty,
      timeout: Duration(milliseconds: panelPollMs),
      perf: perf,
      phaseName: 'pump_until_civilian_rail_or_marker_hit_testable',
    )) {
      panelPollMs = 25;
      continue;
    }
    panelPollMs = e2eAdaptivePollRampAfterIdle(panelPollMs);
  }
  fail(
    'Timed out after ${timeout.inSeconds}s waiting for a civilian panel opener '
    '(empire rail or first-civilian marker). '
    'Last exception: ${tester.takeException()}',
  );
}

/// Default cap for naval-panel open polling (parity with civilian panel opener).
const Duration kE2eDefaultNavalOpenTimeout = Duration(seconds: 20);

/// Opens the naval units panel from the empire rail or the first fleet marker,
/// dismissing transient UI and closing conflicting sheets when needed.
///
/// Single canonical implementation for fleet E2E (GitHub #2336); mirrors
/// [e2eOpenCivilianPanel] structure with naval keys and adaptive polling.
Future<void> e2eOpenNavalPanel(
  WidgetTester tester, {
  E2ePerfLog? perf,
  Duration timeout = kE2eDefaultNavalOpenTimeout,
  Duration bottomSheetCloseTimeout = kE2eDefaultBottomSheetCloseTimeout,
  String afterSheetPanelsClearPhase =
      'pump_until_panels_cleared_after_close_sheet_naval_open',
}) async {
  final sw = Stopwatch()..start();
  final empireRailButton = find.byKey(kEmpireNavalUnitsButtonKey);
  final markerButton = find.byKey(kCtE2EOpenFirstFleetMarkerPanelKey);
  final navalPanel = find.byKey(kCtE2ENavalPanelRootKey);

  Future<bool> tryOpen(Finder trigger) async {
    if (navalPanel.hitTestable().evaluate().isNotEmpty) {
      return true;
    }
    if (trigger.evaluate().isEmpty) {
      return false;
    }
    try {
      await tester.ensureVisible(trigger);
    } catch (_) {}
    await tester.tap(trigger.first, warnIfMissed: false);
    if (navalPanel.evaluate().isNotEmpty) {
      return true;
    }
    await tester.pump();
    if (navalPanel.evaluate().isNotEmpty) {
      return true;
    }
    return e2ePumpUntilConditionOrIdle(
      tester,
      () => navalPanel.evaluate().isNotEmpty,
      timeout: const Duration(seconds: 3),
      perf: perf,
      phaseName: 'pump_until_naval_panel_after_trigger_tap',
    );
  }

  if (navalPanel.hitTestable().evaluate().isNotEmpty) {
    perf?.timing('open_panel_naval', sw.elapsed);
    return;
  }
  await _e2eDismissGameStartIntroOverlayIfPresent(tester);

  var panelPollMs = 25;
  while (sw.elapsed < timeout) {
    await tester.pump(Duration(milliseconds: panelPollMs));
    panelPollMs = e2eAdaptivePollRampAfterIdle(panelPollMs);

    if (find.byType(BottomSheet).evaluate().isNotEmpty) {
      await e2eCloseBottomSheet(
        tester,
        perf: perf,
        overallTimeout: bottomSheetCloseTimeout,
      );
      await e2ePumpUntilConditionOrIdle(
        tester,
        () => find.byType(BottomSheet).evaluate().isEmpty,
        timeout: const Duration(seconds: 2),
        perf: perf,
        phaseName: afterSheetPanelsClearPhase,
      );
      await e2ePumpUntilConditionOrIdle(
        tester,
        () =>
            empireRailButton.hitTestable().evaluate().isNotEmpty ||
            markerButton.hitTestable().evaluate().isNotEmpty,
        timeout: const Duration(seconds: 3),
        perf: perf,
        phaseName: 'pump_until_naval_opener_after_sheet_close',
      );
      panelPollMs = 25;
      continue;
    }
    if (find.byType(AlertDialog).evaluate().isNotEmpty ||
        find.byType(CtDialogShell).evaluate().isNotEmpty) {
      await e2eDismissTransientUi(tester, perf: perf);
      panelPollMs = 25;
      continue;
    }
    if (empireRailButton.evaluate().isNotEmpty) {
      if (await tryOpen(empireRailButton)) {
        perf?.timing('open_panel_naval', sw.elapsed);
        return;
      }
      panelPollMs = 25;
      continue;
    }
    if (markerButton.evaluate().isNotEmpty) {
      if (await tryOpen(markerButton)) {
        perf?.timing('open_panel_naval', sw.elapsed);
        return;
      }
      panelPollMs = 25;
      continue;
    }
    if (await e2ePumpUntilConditionOrIdle(
      tester,
      () =>
          empireRailButton.hitTestable().evaluate().isNotEmpty ||
          markerButton.hitTestable().evaluate().isNotEmpty,
      timeout: Duration(milliseconds: panelPollMs),
      perf: perf,
      phaseName: 'pump_until_naval_rail_or_marker_hit_testable',
    )) {
      panelPollMs = 25;
      continue;
    }
    panelPollMs = e2eAdaptivePollRampAfterIdle(panelPollMs);
  }
  fail(
    'Timed out after ${timeout.inSeconds}s opening naval panel '
    '(empire naval rail or first-fleet marker). '
    'Last exception: ${tester.takeException()}',
  );
}

/// Opens a map-marker panel when [markerButton] is tappable and [panelRoot] mounts.
///
/// Shared full-turn path for tile-scoped civilian/naval markers (GitHub #2336 AC2).
Future<void> e2eOpenPanelFromMarker(
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
      await e2eDismissTransientUi(tester, perf: perf);
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
    'Last exception: ${tester.takeException()}',
  );
}

/// Opens the production screen from the empire rail, closing conflicting sheets
/// and dialogs first (GitHub #2336 H7 / shared full-turn path).
Future<void> e2eOpenProductionPanel(
  WidgetTester tester, {
  E2ePerfLog? perf,
  Duration timeout = const Duration(seconds: 20),
}) async {
  final productionPanel = find.byKey(kCtE2EProductionPanelRootKey);
  final productionButton = find.byKey(kEmpireProductionButtonKey);
  final sw = Stopwatch()..start();
  var idlePollMs = 25;
  while (sw.elapsed < timeout) {
    if (productionPanel.evaluate().isNotEmpty) {
      perf?.timing('open_panel_production', sw.elapsed);
      return;
    }

    if (find.byType(BottomSheet).evaluate().isNotEmpty) {
      await e2eCloseBottomSheet(tester, perf: perf);
      await e2ePumpUntilConditionOrIdle(
        tester,
        () => find.byType(BottomSheet).evaluate().isEmpty,
        timeout: const Duration(milliseconds: 600),
        perf: perf,
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
        perf: perf,
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
      if (productionPanel.evaluate().isNotEmpty) {
        perf?.timing('open_panel_production', sw.elapsed);
        return;
      }
      idlePollMs = 25;
      await tester.pump();
      if (productionPanel.evaluate().isNotEmpty) {
        perf?.timing('open_panel_production', sw.elapsed);
        return;
      }
      await e2eWaitUntilFound(
        tester,
        productionPanel,
        timeout: const Duration(seconds: 5),
        perf: perf,
        phaseName: 'wait_until_production_panel_after_rail_tap',
      );
      if (productionPanel.evaluate().isNotEmpty) {
        perf?.timing('open_panel_production', sw.elapsed);
        return;
      }
      if (await e2ePumpUntilConditionOrIdle(
        tester,
        () => productionPanel.evaluate().isNotEmpty,
        timeout: const Duration(milliseconds: 600),
        perf: perf,
        phaseName: 'pump_until_production_panel_after_rail_tap_miss',
      )) {
        perf?.timing('open_panel_production', sw.elapsed);
        return;
      }
      idlePollMs = 25;
      continue;
    }
    await e2eDismissTransientUi(tester, perf: perf);
    if (await e2ePumpUntilConditionOrIdle(
      tester,
      () =>
          productionPanel.evaluate().isNotEmpty ||
          productionButton.hitTestable().evaluate().isNotEmpty,
      timeout: Duration(milliseconds: idlePollMs),
      perf: perf,
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

/// Splits the home fleet once via the naval panel (GitHub #2336 H8).
Future<void> e2eSplitHomeFleetOnce(
  WidgetTester tester,
  AppLocalizations l10n, {
  E2ePerfLog? perf,
  Duration openNavalTimeout = kE2eDefaultNavalOpenTimeout,
  Duration bottomSheetCloseTimeout = kE2eDefaultBottomSheetCloseTimeout,
}) async {
  final phaseSw = Stopwatch()..start();
  await e2eOpenNavalPanel(
    tester,
    perf: perf,
    timeout: openNavalTimeout,
    bottomSheetCloseTimeout: bottomSheetCloseTimeout,
  );
  await e2eExpandEachExpansionTileOnce(tester);
  final navalPanelRoot = find.byKey(kCtE2ENavalPanelRootKey);
  final split = find.descendant(
    of: navalPanelRoot,
    matching: find.text('Split'),
  );
  expect(split, findsWidgets);
  await tester.tap(split.first, warnIfMissed: false);
  await e2eWaitUntilFound(
    tester,
    find.descendant(
      of: find.byType(CtDialogShell),
      matching: find.widgetWithText(CtNinePatchButton, '>'),
    ),
    timeout: const Duration(seconds: 4),
    perf: perf,
    phaseName: 'wait_until_found_split_nudge_right',
  );

  final moveOneRight = find.descendant(
    of: find.byType(CtDialogShell),
    matching: find.widgetWithText(CtNinePatchButton, '>'),
  );
  expect(moveOneRight, findsWidgets);
  await tester.tap(moveOneRight.first);
  await e2eWaitUntilFound(
    tester,
    find.text(l10n.splitFleet_confirm),
    timeout: const Duration(seconds: 4),
    perf: perf,
    phaseName: 'wait_until_found_split_confirm',
  );
  await tester.tap(find.text(l10n.splitFleet_confirm));
  await e2ePumpUntilConditionOrIdle(
    tester,
    () => find.byType(CtDialogShell).evaluate().isEmpty,
    timeout: const Duration(milliseconds: 500),
    perf: perf,
    phaseName: 'pump_until_split_dialog_shell_cleared',
  );
  await e2eExpandEachExpansionTileOnce(tester);
  perf?.timing('fleet_split', phaseSw.elapsed);
}
