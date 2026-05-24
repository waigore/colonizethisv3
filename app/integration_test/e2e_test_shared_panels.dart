import 'package:colonizethis_app/config/ct_e2e.dart';
import 'package:colonizethis_app/config/ct_e2e_last_panel_snapshot.dart'
    show ctE2eCivilianPanelSnapshot, ctE2eNavalPanelSnapshot;
import 'package:colonizethis_app/features/game/flame/game_screen_shared.dart';
import 'package:colonizethis_app/features/game/widgets/units/shared/units_panel_region_label.dart';
import 'package:colonizethis_app/l10n/app_localizations_contract.dart';
import 'package:colonizethis_app/widgets/ct_dialog_shell.dart';
import 'package:colonizethis_app/widgets/ct_nine_patch_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'e2e_test_shared.dart';

export 'e2e_test_shared_fleet_reach_loop.dart';
export 'e2e_test_shared_panel_text_assertions.dart';

// `_e2eTapFirstEnabledTransferButtonInSplitDialog` previously lived here as a
// helper for split-fleet transfer-row taps but was never wired into any caller
// (`e2eSplitHomeFleetOnce` inlines its own `enabledLeftNudge` finder for the
// `>>` / `>` transfer keys). Static analysis flagged the symbol with
// `unused_element` since at least PR #2596. The dead declaration is removed
// here rather than carried forward so the shared-helpers surface only ships
// reachable code (Refs GitHub #2336 AC1 / AC2 shared-helper hygiene).

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
  await e2eAdvanceGameStartIntroUntilDismissed(tester, perf: perf);

  var panelPollMs = 25;
  // The loop checks ready conditions **before** the first pump so a panel
  // opener that is already on-screen (typical after bootstrap) short-circuits
  // without paying a leading 25ms frame. Idle pumps happen at the bottom of
  // the loop with adaptive backoff. Refs GitHub #2336 AC5 / pump-reduction.
  while (sw.elapsed < timeout) {
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
    await tester.pump(Duration(milliseconds: panelPollMs));
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
    final hit = trigger.hitTestable();
    final target = hit.evaluate().isNotEmpty ? hit : trigger;
    await tester.tap(target.first, warnIfMissed: false);
    if (navalPanel.evaluate().isNotEmpty) {
      return true;
    }
    await tester.pump();
    if (navalPanel.evaluate().isNotEmpty) {
      return true;
    }
    // Match [e2eOpenCivilianPanel] tryOpen: bounded poll without fail() so the
    // outer opener loop can dismiss sheets and retry rail/marker (Refs #2336).
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
  await e2eAdvanceGameStartIntroUntilDismissed(tester, perf: perf);

  var panelPollMs = 25;
  // The loop checks ready conditions **before** the first pump so a naval
  // opener that is already on-screen (typical after bootstrap) short-circuits
  // without paying a leading 25ms frame. Idle pumps happen at the bottom of
  // the loop with adaptive backoff. Refs GitHub #2336 AC5 / pump-reduction.
  while (sw.elapsed < timeout) {
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
      if (empireRailButton.hitTestable().evaluate().isEmpty) {
        await e2eWaitUntilAnyFinderHitTestable(
          tester,
          [empireRailButton, markerButton],
          timeout: const Duration(seconds: 5),
          perf: perf,
          phaseName: 'wait_until_naval_rail_hit_testable',
        );
      }
      if (await tryOpen(empireRailButton)) {
        perf?.timing('open_panel_naval', sw.elapsed);
        return;
      }
      panelPollMs = 25;
      continue;
    }
    if (markerButton.evaluate().isNotEmpty) {
      if (markerButton.hitTestable().evaluate().isEmpty) {
        await e2eWaitUntilAnyFinderHitTestable(
          tester,
          [markerButton, empireRailButton],
          timeout: const Duration(seconds: 5),
          perf: perf,
          phaseName: 'wait_until_naval_marker_hit_testable',
        );
      }
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
    await tester.pump(Duration(milliseconds: panelPollMs));
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
  await e2eAdvanceGameStartIntroUntilDismissed(tester, perf: perf);
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
      await e2eDismissTransientUi(tester, perf: perf);
      if (find.byType(CtDialogShell).evaluate().isNotEmpty) {
        await tester.binding.handlePopRoute();
        await e2ePumpUntil(
          tester,
          () => find.byType(CtDialogShell).evaluate().isEmpty,
          timeout: const Duration(seconds: 5),
          perf: perf,
          phaseName: 'pump_until_production_path_shell_cleared',
        );
      }
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
      await tester.pump();
      if (productionPanel.evaluate().isNotEmpty) {
        perf?.timing('open_panel_production', sw.elapsed);
        return;
      }
      // Match civilian/naval `tryOpen` contract: bounded poll without `fail()`
      // so the outer opener loop can dismiss transient overlays and retry the
      // rail tap when a race covers the panel mount. Without this, a single
      // rail-tap miss surfaced as a hard `TestFailure` (`wait_until_...` path)
      // even though the outer loop still had budget to recover. Aligns with
      // PR #2555 fix for the naval opener (Refs GitHub #2336).
      if (await e2ePumpUntilConditionOrIdle(
        tester,
        () => productionPanel.evaluate().isNotEmpty,
        timeout: const Duration(seconds: 5),
        perf: perf,
        phaseName: 'pump_until_production_panel_after_rail_tap',
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
  bool navalPanelAlreadyOpen = false,
}) async {
  final phaseSw = Stopwatch()..start();
  if (!navalPanelAlreadyOpen) {
    await e2eOpenNavalPanel(
      tester,
      perf: perf,
      timeout: openNavalTimeout,
      bottomSheetCloseTimeout: bottomSheetCloseTimeout,
    );
    await e2eExpandEachExpansionTileOnce(tester);
  }
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
      matching: find.byWidgetPredicate(
        (w) =>
            w is CtNinePatchButton &&
            w.enabled &&
            w.key is ValueKey<String> &&
            (w.key! as ValueKey<String>).value.startsWith('ctTransfer.left.>'),
      ),
    ),
    timeout: const Duration(seconds: 4),
    perf: perf,
    phaseName: 'wait_until_found_split_nudge_right',
  );
  final confirmButton = find.widgetWithText(
    CtNinePatchButton,
    l10n.splitFleet_confirm,
  );
  bool splitConfirmEnabled() {
    if (confirmButton.evaluate().isEmpty) {
      return false;
    }
    return tester.widget<CtNinePatchButton>(confirmButton.first).enabled;
  }

  Finder enabledLeftNudge(String prefix) => find.descendant(
    of: find.byType(CtDialogShell),
    matching: find.byWidgetPredicate((w) {
      if (w is! CtNinePatchButton || !w.enabled) {
        return false;
      }
      final key = w.key;
      return key is ValueKey<String> && key.value.startsWith(prefix);
    }),
  );

  for (var attempt = 0; attempt < 6 && !splitConfirmEnabled(); attempt++) {
    final moveAll = enabledLeftNudge('ctTransfer.left.>>');
    if (moveAll.evaluate().isNotEmpty) {
      await tester.tap(moveAll.first, warnIfMissed: false);
    } else {
      final moveOne = enabledLeftNudge('ctTransfer.left.>');
      if (moveOne.evaluate().isEmpty) {
        break;
      }
      await tester.tap(moveOne.first, warnIfMissed: false);
    }
    await e2ePumpUntilConditionOrIdle(
      tester,
      splitConfirmEnabled,
      timeout: const Duration(milliseconds: 400),
      perf: perf,
      phaseName: 'pump_until_split_confirm_enabled_attempt_$attempt',
    );
  }
  await e2ePumpUntil(
    tester,
    splitConfirmEnabled,
    timeout: const Duration(seconds: 5),
    perf: perf,
    phaseName: 'pump_until_split_confirm_enabled',
  );
  await tester.tap(confirmButton.first, warnIfMissed: false);
  final splitTitle = find.text(l10n.splitFleet_dialogTitle);
  await e2ePumpUntil(
    tester,
    () => splitTitle.evaluate().isEmpty,
    timeout: const Duration(seconds: 10),
    perf: perf,
    phaseName: 'pump_until_split_fleet_dialog_dismissed',
  );
  await e2eExpandEachExpansionTileOnce(tester);
  perf?.timing('fleet_split', phaseSw.elapsed);
}

/// Taps **Move** on the first non-home human fleet rendered under
/// [kCtE2ENavalPanelRootKey] and waits for the resulting move dialog to mount.
///
/// Lifted from the formerly private `_tapMoveOnFirstNonHomeFleet` in
/// `new_game_fleet_reaches_new_world_e2e_helpers_part2.dart` (Refs GitHub
/// #2336 AC1 / AC2). The fleet-reach loop calls this helper through
/// `_tryNavalMoveSegment` up to `_kMaxNextTurnTapsForNwFleetReach (35)`
/// times per scenario, so a silent rename / fail-open here would stall the
/// fleet-reach loop at the 35-turn cap × the dialog wait — Bottleneck 4 in
/// `SPEC/program/e2e-integration-tests.md` § Determinism.
///
/// The integration suite cannot validate this directly today
/// (`app_e2e_linux` is a no-op per
/// `SPEC/program/e2e-integration-tests.md` § CI), so the widget-test pin
/// in `app/test/e2e_tap_move_on_first_non_home_fleet_test.dart` carries the
/// behavioural contract.
///
/// Contract:
///
/// - Returns `false` when [kCtE2ENavalPanelRootKey] is not in the tree, or
///   when no [ExpansionTile] has rendered under it within a 2 s adaptive
///   wait (`pump_until_naval_expansion_tiles_render`).
/// - When the panel has exactly one tile and that tile shows a
///   `Text('Home Fleet')` descendant, returns `false` without tapping
///   (the fleet split has not yet produced a non-home fleet).
/// - Iterates non-home fleet tiles in stable tree order; skips tiles that
///   are themselves the home fleet, and skips tiles that lack a
///   `Text` whose `data` starts with `'Fleet '`.
/// - When a candidate tile's `Move` text is not visible, taps the tile's
///   `Icons.expand_more` icon and waits up to 3 s
///   (`wait_until_found_move_after_expand`) for the `Move` text to appear.
/// - **Prefers** tiles whose subtitle reads as a New World location row
///   (per [e2eTextLooksLikeNewWorldLocationLine]): the first such tile's
///   hit-testable `Move` button is tapped immediately, the helper waits up
///   to 3 s for an [AlertDialog] to mount
///   (`wait_until_found_move_dialog_after_move_tap`), and returns `true`.
/// - When no NW-preferred tile yields a tap, falls back to the **first**
///   non-home tile with a hit-testable `Move` button; same
///   tap-and-wait-for-dialog contract
///   (`wait_until_found_move_dialog_after_move_tap_fallback`).
/// - When the first pass finds nothing tappable, calls
///   [e2eExpandEachExpansionTileOnce] to expand every collapsed tile, then
///   retries once **without** a further expand fallback so the helper does
///   not spin past two passes. Returns `false` if even the retry yields
///   nothing.
Future<bool> e2eTapMoveOnFirstNonHomeFleet(WidgetTester tester) async {
  Future<bool> tryTap({required bool allowExpandAllFallback}) async {
    final navalRoot = find.byKey(kCtE2ENavalPanelRootKey);
    final tiles = find.descendant(
      of: navalRoot,
      matching: find.byType(ExpansionTile),
    );
    var n = tiles.evaluate().length;
    if (n == 0) {
      // Panel can mount before fleet rows render; poll instead of a fixed delay.
      await e2ePumpUntilConditionOrIdle(
        tester,
        () => tiles.evaluate().isNotEmpty,
        timeout: const Duration(seconds: 2),
        phaseName: 'pump_until_naval_expansion_tiles_render',
      );
      n = tiles.evaluate().length;
      if (n == 0) {
        return false;
      }
    }
    if (n == 1) {
      final onlyTile = tiles.first;
      final onlyHome = find.descendant(
        of: onlyTile,
        matching: find.text('Home Fleet'),
      );
      if (onlyHome.evaluate().isNotEmpty) {
        return false;
      }
    }
    Finder? fallbackMove;
    for (var i = 0; i < n; i++) {
      final sub = tiles.at(i);
      final home = find.descendant(of: sub, matching: find.text('Home Fleet'));
      if (home.evaluate().isNotEmpty) {
        continue;
      }
      final fleetTitle = find.descendant(
        of: sub,
        matching: find.byWidgetPredicate(
          (w) => w is Text && (w.data?.startsWith('Fleet ') ?? false),
        ),
      );
      if (fleetTitle.evaluate().isEmpty) {
        continue;
      }
      var move = find.descendant(of: sub, matching: find.text('Move'));
      if (move.evaluate().isEmpty) {
        final expandIcon = find.descendant(
          of: sub,
          matching: find.byIcon(Icons.expand_more),
        );
        if (expandIcon.evaluate().isNotEmpty) {
          final iconHit = expandIcon.first;
          await tester.ensureVisible(iconHit);
          await tester.tap(iconHit, warnIfMissed: false);
          await e2eWaitUntilFound(
            tester,
            find.descendant(of: sub, matching: find.text('Move')),
            timeout: const Duration(seconds: 3),
            phaseName: 'wait_until_found_move_after_expand',
          );
        }
        move = find.descendant(of: sub, matching: find.text('Move'));
      }
      if (move.evaluate().isEmpty) {
        continue;
      }
      final loc = find.descendant(
        of: sub,
        matching: find.byWidgetPredicate(
          (w) => w is Text && e2eTextLooksLikeNewWorldLocationLine(w.data),
        ),
      );
      final hit = move.hitTestable();
      if (hit.evaluate().isEmpty) {
        continue;
      }
      if (loc.evaluate().isNotEmpty) {
        await tester.tap(hit.first, warnIfMissed: false);
        await e2eWaitUntilFound(
          tester,
          find.byType(AlertDialog),
          timeout: const Duration(seconds: 3),
          phaseName: 'wait_until_found_move_dialog_after_move_tap',
        );
        return true;
      }
      fallbackMove ??= hit.first;
    }
    if (fallbackMove != null) {
      await tester.tap(fallbackMove, warnIfMissed: false);
      await e2eWaitUntilFound(
        tester,
        find.byType(AlertDialog),
        timeout: const Duration(seconds: 3),
        phaseName: 'wait_until_found_move_dialog_after_move_tap_fallback',
      );
      return true;
    }
    if (allowExpandAllFallback) {
      await e2eExpandEachExpansionTileOnce(tester);
      return false;
    }
    return false;
  }

  if (await tryTap(allowExpandAllFallback: true)) {
    return true;
  }
  if (await tryTap(allowExpandAllFallback: false)) {
    return true;
  }
  return false;
}

/// Default UI-response timeout cap for the bundled-Explore enabled-Assign
/// panel sweep (parity with the `_kMaxUiResponseWait` constant in
/// `new_game_fleet_reaches_new_world_e2e_helpers.dart`).
const Duration kE2eDefaultBundledExploreSweepWait = Duration(seconds: 5);

/// Returns `true` when at least one civilian unit row exposes an **enabled**
/// `Explore` assign target reachable through the civilian panel
/// ([kCtE2ECivilianPanelRootKey]).
///
/// Lifted from the formerly private `_anyExplorerHasEnabledExploreAssignFleetE2e`
/// in `new_game_fleet_reaches_new_world_e2e_helpers_part2.dart` (Refs GitHub
/// #2336 AC1 / AC2 / AC5 / Bottleneck 5). The fleet bundled-Explore retry
/// loop in `new_game_fleet_reaches_new_world_e2e_test.dart` calls this
/// helper through the AC1 barrel alias `anyExplorerHasEnabledExploreAssignFleet`
/// up to `maxBoundedTurnRetries (8)` times per scenario, so a silent rename
/// / fail-open here would stall the retry loop on the slow `maxPanelSweepSteps
/// (16) × per-step Assign sweep` path — Bottleneck 5 in
/// `SPEC/program/e2e-integration-tests.md` § Determinism.
///
/// The integration suite cannot validate this directly today
/// (`app_e2e_linux` is a no-op per
/// `SPEC/program/e2e-integration-tests.md` § CI), so the widget-test pin
/// in `app/test/e2e_any_explorer_has_enabled_explore_assign_fleet_test.dart`
/// carries the behavioural contract.
///
/// Contract:
///
/// - First, consults [e2eExploreAssignEnabledFromCivilianSnapshot] with the
///   current [ctE2eCivilianPanelSnapshot]. A non-`null` snapshot result is
///   returned verbatim (`true` / `false`); the panel-sweep walk is only
///   entered when the snapshot is `null` (no plumbing yet this turn).
/// - Expects exactly one [ListView] descendant of [kCtE2ECivilianPanelRootKey];
///   throws via [expect] otherwise (fail-fast on a malformed panel — the
///   pre-#2336 helper had the same precondition).
/// - Walks `Assign` text rows under that ListView in tree order, tapping
///   each unique button (identityHashCode-deduped) and bounded-polling for
///   an `Explore` [ListTile] to mount.
/// - When the tapped row's `Explore` tile appears and reports
///   `enabled == true`, returns `true`. When `enabled == false`, dismisses
///   the assign sheet and continues the sweep.
/// - When the sweep exhausts [maxPanelSweepSteps] (defaults to **16**, the
///   narrowed bound from issue #2336 § Bottleneck 5 / AC1; the pre-#2336
///   helper used 24), returns `false`.
/// - Between sweep steps, drags the panel `Scrollable` upward by
///   `Offset(0, -180)` and pumps a single 25 ms frame so the next iteration
///   can short-circuit on freshly revealed `Assign` rows without paying a
///   leading fixed-delay settle (AC5 adaptive polling).
/// - The `Explore`-tile-settled and assign-sheet-dismissed waits are
///   bounded by [maxUiResponseWait] (5 s default, the legacy constant) and
///   a 400 ms dismissed-poll respectively; both ramp via
///   [e2eAdaptivePollRampAfterIdle].
Future<bool> e2eAnyExplorerHasEnabledExploreAssignFleet(
  WidgetTester tester, {
  Duration maxUiResponseWait = kE2eDefaultBundledExploreSweepWait,
  int maxPanelSweepSteps = 16,
}) async {
  final snapshotHint = e2eExploreAssignEnabledFromCivilianSnapshot(
    ctE2eCivilianPanelSnapshot,
  );
  if (snapshotHint != null) {
    return snapshotHint;
  }

  final root = find.byKey(kCtE2ECivilianPanelRootKey);
  final listView = find.descendant(of: root, matching: find.byType(ListView));
  expect(listView, findsOneWidget);
  final panelScrollable = find.descendant(
    of: listView,
    matching: find.byType(Scrollable),
  );
  expect(panelScrollable, findsOneWidget);
  final exploreTile = find.widgetWithText(ListTile, 'Explore');
  // Adaptive replacement (#2336 AC5 / Bottleneck 5): the prior 300ms post-tap
  // settle plus 50ms fixed wait loop is replaced by a single condition-based
  // wait that evaluates [exploreTile] before the first pump and ramps the
  // pump interval via [e2eAdaptivePollRampAfterIdle]. The hard
  // [maxUiResponseWait] cap is preserved.
  Future<void> waitForAssignSheetSettled() async {
    final wait = Stopwatch()..start();
    var assignPollMs = 25;
    while (wait.elapsed < maxUiResponseWait) {
      if (exploreTile.evaluate().isNotEmpty) {
        return;
      }
      await tester.pump(Duration(milliseconds: assignPollMs));
      assignPollMs = e2eAdaptivePollRampAfterIdle(assignPollMs);
    }
  }

  // After [handlePopRoute] the assign sheet can take a frame or two to leave
  // the tree. Replace the prior fixed 200ms pump with a bounded adaptive
  // poll that returns as soon as the sheet finishes dismissing.
  Future<void> waitForAssignSheetDismissed() async {
    await e2ePumpUntilConditionOrIdle(
      tester,
      () => exploreTile.evaluate().isEmpty,
      timeout: const Duration(milliseconds: 400),
      phaseName: 'pump_until_assign_sheet_dismissed',
    );
  }

  final visitedAssignWidgets = <int>{};
  for (var step = 0; step < maxPanelSweepSteps; step++) {
    final assignCandidates = find
        .descendant(of: listView, matching: find.text('Assign'))
        .evaluate()
        .toList();
    for (final assignElement in assignCandidates) {
      final marker = identityHashCode(assignElement.widget);
      if (!visitedAssignWidgets.add(marker)) {
        continue;
      }
      final assignFinder = find.byWidget(assignElement.widget);
      try {
        await tester.ensureVisible(assignFinder);
      } catch (_) {
        continue;
      }
      await tester.tap(assignFinder.first, warnIfMissed: false);
      await waitForAssignSheetSettled();
      if (exploreTile.evaluate().isNotEmpty) {
        final enabled = tester.widget<ListTile>(exploreTile.first).enabled;
        await tester.binding.handlePopRoute();
        await waitForAssignSheetDismissed();
        if (enabled == true) {
          return true;
        }
      } else {
        await tester.binding.handlePopRoute();
        await waitForAssignSheetDismissed();
      }
    }

    await tester.drag(panelScrollable, const Offset(0, -180));
    // Adaptive replacement for the prior 120ms post-drag settle (#2336 AC5):
    // pump a single short frame and let the next iteration short-circuit if
    // new Assign rows are already visible.
    await tester.pump(const Duration(milliseconds: 25));
  }
  return false;
}

/// Default per-call budget for [e2ePickMoveDestinationAndConfirm]. Matches the
/// pre-lift private `_kMaxUiResponseWait = Duration(seconds: 5)` constant in
/// `new_game_fleet_reaches_new_world_e2e_helpers.dart` (Refs GitHub #2336
/// Bottleneck 4 / AC5).
const Duration kE2eDefaultMoveFleetDialogBudget = Duration(seconds: 5);

/// Default upper bound on the warp-row drag-probe loop inside
/// [e2ePickMoveDestinationAndConfirm]. Matches the pre-lift private
/// `maxWarpDragProbes = 8` constant in
/// `new_game_fleet_reaches_new_world_e2e_helpers.dart` (Refs GitHub #2336
/// Bottleneck 4 / H4 hot path).
const int kE2eDefaultMoveFleetWarpDragProbes = 8;

/// Picks a destination on the mounted [MoveFleetDialog] and confirms it.
///
/// Lifted from the formerly private `_pickMoveDestinationAndConfirm` in
/// `new_game_fleet_reaches_new_world_e2e_helpers.dart` (Refs GitHub #2336 AC1
/// / AC2 / AC4 / Bottleneck 4 / H4). The fleet-reach loop in
/// `new_game_fleet_reaches_new_world_e2e_test.dart` calls this helper through
/// `_tryNavalMoveSegment` up to `_kMaxNextTurnTapsForNwFleetReach (35)` times
/// per scenario, so a silent rename / behavioural drift here would either
/// stall the fleet-reach loop at the per-call [moveDialogBudget] cap or
/// silently flip warp vs sea-radio selection — both regress the bundled-
/// Explore wall clock issue #2336 § AC9 is shrinking.
///
/// The integration suite cannot validate this directly today
/// (`app_e2e_linux` is a no-op per
/// `SPEC/program/e2e-integration-tests.md` § CI), so the widget-test pin in
/// `app/test/e2e_pick_move_destination_and_confirm_test.dart` carries the
/// behavioural contract.
///
/// Contract:
///
/// - Waits up to 2 s for an [AlertDialog] to mount
///   (`wait_until_found_move_dialog`) before evaluating any destination
///   finders.
/// - When [allowWarpDestinations] is `true` **and** a row labelled
///   `l10n.moveFleet_warpLinkToRegion(unitsPanelRegionLabel('newWorld'))`
///   exists in the dialog: scrolls to make the warp row hit-testable using
///   the [MoveFleetDialog] scroll root keyed by
///   [kCtE2EMoveFleetDialogScrollRootKey] (or the dialog's [Scrollable] as
///   fallback), then taps the ancestor `RadioListTile<…>` so the dialog
///   selection state updates before Confirm. Headless Linux CI can miss
///   implicit tile taps when the inner `Text` is tapped directly.
/// - The warp-row drag-probe loop is bounded by [maxWarpDragProbes]
///   (defaults to [kE2eDefaultMoveFleetWarpDragProbes] = 8). Each probe drags
///   the [Scrollable] by `Offset(0, -120)` and short-circuits via
///   [e2ePumpUntilConditionOrIdle] (400 ms cap) as soon as the warp row
///   becomes hit-testable — replacing the legacy per-drag fixed pump
///   (AC5 adaptive polling).
/// - When [allowWarpDestinations] is `false`, or the warp row is absent,
///   taps the first [RadioListTile] returned by
///   [e2eRadioListTilesInAlertDialogs] (scoped to the active [AlertDialog]).
/// - Waits up to 2 s for the [Text(l10n.common_confirm)] button to mount
///   (`wait_until_found_move_confirm`), then taps it and pumps until the
///   [AlertDialog] leaves the tree
///   (`pump_until_move_dialog_closed`, 2 s cap).
/// - The whole call is bounded by [moveDialogBudget]
///   (defaults to [kE2eDefaultMoveFleetDialogBudget] = 5 s); exceeding the
///   budget mid-flow fails via [fail] with the breached `step` label.
/// - When the warp row cannot be made hit-testable after
///   [maxWarpDragProbes] drag probes, fails via [fail] with a deterministic
///   diagnostic message rather than silently falling back to the sea radio.
Future<void> e2ePickMoveDestinationAndConfirm(
  WidgetTester tester,
  AppLocalizations l10n, {
  bool allowWarpDestinations = true,
  Duration moveDialogBudget = kE2eDefaultMoveFleetDialogBudget,
  int maxWarpDragProbes = kE2eDefaultMoveFleetWarpDragProbes,
}) async {
  final budget = Stopwatch()..start();
  void ensureBudget(String step) {
    if (budget.elapsed > moveDialogBudget) {
      fail(
        'Move fleet dialog exceeded ${moveDialogBudget.inSeconds}s at $step',
      );
    }
  }

  ensureBudget('start');
  await e2eWaitUntilFound(
    tester,
    find.byType(AlertDialog),
    timeout: const Duration(seconds: 2),
    phaseName: 'wait_until_found_move_dialog',
  );
  final warpSuffix = l10n.moveFleet_warpLinkToRegion(
    unitsPanelRegionLabel('newWorld'),
  );
  final warp = find.textContaining(warpSuffix);
  if (allowWarpDestinations && warp.evaluate().isNotEmpty) {
    final scrollRoot = find.byKey(kCtE2EMoveFleetDialogScrollRootKey);
    final Finder scrollable;
    if (scrollRoot.evaluate().isNotEmpty) {
      scrollable = find.descendant(
        of: scrollRoot,
        matching: find.byType(Scrollable),
      );
    } else {
      scrollable = find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byType(Scrollable),
      );
    }
    if (scrollable.evaluate().isNotEmpty) {
      final sc = scrollable.first;
      if (warp.hitTestable().evaluate().isEmpty) {
        try {
          await tester.scrollUntilVisible(warp.first, 200, scrollable: sc);
        } catch (_) {
          // Row may not be built yet; fall back to drag probing below.
        }
      }
      for (
        var i = 0;
        i < maxWarpDragProbes && warp.hitTestable().evaluate().isEmpty;
        i++
      ) {
        ensureBudget('warp drag $i');
        await tester.drag(sc, const Offset(0, -120));
        // Short-circuit as soon as the warp row becomes hit-testable instead of
        // a single frame pump per drag (Refs #2336 H4 / adaptive polling).
        await e2ePumpUntilConditionOrIdle(
          tester,
          () => warp.hitTestable().evaluate().isNotEmpty,
          timeout: const Duration(milliseconds: 400),
          phaseName: 'pump_until_warp_row_visible_after_move_dialog_drag',
        );
      }
      if (warp.hitTestable().evaluate().isEmpty) {
        fail(
          'Warp row not hit-testable after drag attempts '
          '(within ${moveDialogBudget.inSeconds}s dialog budget).',
        );
      }
    }
    ensureBudget('before warp tap');
    final hit = warp.hitTestable();
    expect(hit, findsWidgets);
    // Tap the RadioListTile, not only the inner Text, so the tile's selection
    // updates before Confirm (Linux CI / headless can miss implicit tile taps).
    final warpTile = find.ancestor(
      of: hit.first,
      matching: find.byWidgetPredicate(
        (w) => w.runtimeType.toString().startsWith('RadioListTile<'),
      ),
    );
    expect(warpTile, findsWidgets);
    await tester.tap(warpTile.first, warnIfMissed: false);
  } else {
    ensureBudget('sea radio');
    final seaRadio = e2eRadioListTilesInAlertDialogs();
    expect(seaRadio, findsWidgets);
    await tester.tap(seaRadio.first, warnIfMissed: false);
  }
  await e2eWaitUntilFound(
    tester,
    find.text(l10n.common_confirm),
    timeout: const Duration(seconds: 2),
    phaseName: 'wait_until_found_move_confirm',
  );
  ensureBudget('confirm');
  final confirm = find.text(l10n.common_confirm).hitTestable();
  expect(confirm, findsWidgets);
  await tester.tap(confirm.first, warnIfMissed: false);
  await e2ePumpUntil(
    tester,
    () => find.byType(AlertDialog).evaluate().isEmpty,
    timeout: const Duration(seconds: 2),
    phaseName: 'pump_until_move_dialog_closed',
  );
  ensureBudget('after confirm');
}

/// Default per-call UI wait for [e2eTryNavalMoveSegment] (naval panel open,
/// move-dialog picker budget). Matches the pre-lift private
/// `_kMaxUiResponseWait = Duration(seconds: 5)` in
/// `new_game_fleet_reaches_new_world_e2e_helpers.dart` (Refs GitHub #2336
/// Bottleneck 4 / H1–H3).
const Duration kE2eDefaultNavalMoveSegmentUiWait =
    kE2eDefaultMoveFleetDialogBudget;

/// Composes region-tab selection, optional naval-panel open, non-home Move tap,
/// and move-dialog destination pick for one fleet-reach turn iteration.
///
/// Lifted from the formerly private `_tryNavalMoveSegment` in
/// `new_game_fleet_reaches_new_world_e2e_helpers.dart` (Refs GitHub #2336 AC1
/// / AC2 / Bottleneck 4 / H1–H4). The fleet-reach loop in
/// `new_game_fleet_reaches_new_world_e2e_test.dart` calls this helper up to
/// `_kMaxNextTurnTapsForNwFleetReach (35)` times per scenario; the widget-test
/// pin in `app/test/e2e_try_naval_move_segment_test.dart` carries the
/// behavioural contract because the integration suite cannot validate it
/// directly today (`app_e2e_linux` is a no-op per
/// `SPEC/program/e2e-integration-tests.md` § CI).
///
/// Contract:
///
/// - When [useNewWorldMapTabFirst] is `true`, taps the New World region tab
///   via [e2eTapNewWorldRegionTabIfPresent]; otherwise taps the Old World tab
///   via [e2eTapOldWorldRegionTab].
/// - Opens the naval panel via [e2eOpenNavalPanel] unless
///   [navalPanelAlreadyOpen] is `true` (Refs #2336 Bottleneck 4 — avoids
///   redundant close/reopen inside the 35-turn loop).
/// - Invokes [e2eTapMoveOnFirstNonHomeFleet]; when it returns `false`, records
///   `result=no_non_home_move_control` on [perf] and returns without opening a
///   move dialog.
/// - Waits up to 2 s for an [AlertDialog] after Move (`wait_until_found_move_
///   dialog_after_tap`).
/// - When `l10n.moveFleet_noAdjacentSeaZones` is visible, taps
///   `l10n.common_cancel`, pumps until the dialog dismisses, records
///   `result=no_legal_step` on [perf], and returns.
/// - Otherwise, when an [AlertDialog] remains mounted, delegates to
///   [e2ePickMoveDestinationAndConfirm] with [allowWarpDestinations] and
///   [maxUiResponseWait] as [moveDialogBudget].
Future<void> e2eTryNavalMoveSegment(
  WidgetTester tester,
  AppLocalizations l10n, {
  bool useNewWorldMapTabFirst = false,
  bool allowWarpDestinations = true,
  bool navalPanelAlreadyOpen = false,
  E2ePerfLog? perf,
  Duration maxUiResponseWait = kE2eDefaultNavalMoveSegmentUiWait,
}) async {
  final phaseSw = Stopwatch()..start();
  if (useNewWorldMapTabFirst) {
    await e2eTapNewWorldRegionTabIfPresent(tester);
  } else {
    await e2eTapOldWorldRegionTab(tester, l10n);
  }
  if (!navalPanelAlreadyOpen) {
    await e2eOpenNavalPanel(
      tester,
      perf: perf,
      timeout: maxUiResponseWait,
      bottomSheetCloseTimeout: maxUiResponseWait,
    );
  }
  final tappedMove = await e2eTapMoveOnFirstNonHomeFleet(tester);
  if (!tappedMove) {
    perf?.timing(
      'fleet_move_segment',
      phaseSw.elapsed,
      meta: 'result=no_non_home_move_control',
    );
    return;
  }
  await e2eWaitUntilFound(
    tester,
    find.byType(AlertDialog),
    timeout: const Duration(seconds: 2),
    phaseName: 'wait_until_found_move_dialog_after_tap',
  );
  // No legal sea-step this turn: close dialog and rely on the outer loop +
  // next turn (Refs #1831 heuristic path).
  if (find.text(l10n.moveFleet_noAdjacentSeaZones).evaluate().isNotEmpty) {
    final cancel = find.text(l10n.common_cancel).hitTestable();
    expect(cancel, findsOneWidget);
    await tester.tap(cancel, warnIfMissed: false);
    await e2ePumpUntil(
      tester,
      () => find.byType(AlertDialog).evaluate().isEmpty,
      timeout: const Duration(seconds: 2),
      perf: perf,
      phaseName: 'pump_until_cancel_move_dialog_closed',
    );
    perf?.timing(
      'fleet_move_segment',
      phaseSw.elapsed,
      meta: 'result=no_legal_step',
    );
    return;
  }
  if (find.byType(AlertDialog).evaluate().isNotEmpty) {
    await e2ePickMoveDestinationAndConfirm(
      tester,
      l10n,
      allowWarpDestinations: allowWarpDestinations,
      moveDialogBudget: maxUiResponseWait,
    );
  }
  perf?.timing('fleet_move_segment', phaseSw.elapsed);
}

/// Default bound on the outer turn loop that drives the bundled-Explore
/// readiness wait (see [e2eAwaitNwCoastalOrVisibleLandForBundledExplore]).
///
/// Mirrors the legacy `maxTurns = 35` constant the helper carried as a
/// private literal before the lift (Refs GitHub #2336 AC1 / AC2). The 35-turn
/// budget tracks `_kMaxNextTurnTapsForNwFleetReach` in
/// `new_game_fleet_reaches_new_world_e2e_helpers.dart` so the bundled-Explore
/// readiness loop and the upstream fleet-reach loop share a common ceiling.
const int kE2eDefaultBundledExploreReadinessMaxTurns = 35;

/// Drives the bundled-Explore readiness wait: probes the live naval-panel
/// snapshot every loop iteration, opens the naval panel only when snapshot
/// plumbing is unavailable, attempts one bounded New-World move via
/// [e2eTryNavalMoveSegment], advances one human turn, and exits as soon as
/// either coastal-NW arrival or any NW fogged-or-better visibility is
/// observed.
///
/// Lifted from the formerly private
/// `_awaitNwCoastalOrVisibleLandForBundledExploreE2e` in
/// `new_game_fleet_reaches_new_world_e2e_helpers_part2.dart` (Refs GitHub
/// #2336 AC1 / AC2 / Bottleneck 4). The post-bundle Explore test calls this
/// helper exactly once per scenario to bridge the gap between
/// `e2eHarnessDetectsNonHomeFleetInNewWorld` (fleet has arrived at NW open
/// sea) and the strict `anyExplorerHasEnabledExploreAssignFleet` check that
/// requires coastal land visibility. The widget-test pin in
/// `app/test/e2e_await_nw_coastal_or_visible_land_for_bundled_explore_test.dart`
/// guards against silent regressions because the integration suite cannot
/// validate this directly today (`app_e2e_linux` is a no-op per
/// `SPEC/program/e2e-integration-tests.md` § CI).
///
/// Contract:
///
/// - Loops at most [maxTurns] iterations (default
///   [kE2eDefaultBundledExploreReadinessMaxTurns]); each iteration invokes
///   [ensureUnderWallClock] with `'NW bundled-explore readiness i=<idx>'`.
/// - Returns immediately when
///   [e2eNonHomeHumanFleetInCoastalNewWorldSeaFromCtSnapshot] **or**
///   [e2ePlayerHasAnyNewWorldFoggedOrBetterFromCtSnapshot] holds for
///   [ctE2eNavalPanelSnapshot] at any of the three probe points:
///   start-of-iteration, post-naval-open (when snapshot was null), and
///   post-`advanceOneHumanTurn`.
/// - When the snapshot is null, opens the naval panel via
///   [e2eOpenNavalPanel] (using [maxUiResponseWait] for both the open and
///   close timeouts), re-probes, and closes the bottom sheet via
///   [e2eCloseBottomSheet] before returning on success.
/// - Calls [e2eTryNavalMoveSegment] with `useNewWorldMapTabFirst: true`,
///   `allowWarpDestinations: false`, and `navalPanelAlreadyOpen` set to
///   `ctE2eNavalPanelSnapshot == null` (mirroring the pre-lift contract so
///   the snapshot-backed path keeps the naval sheet open across iterations).
/// - Closes the bottom sheet after each move attempt and advances one human
///   turn via [e2eAdvanceOneHumanTurn].
/// - Returns normally — without throwing — when the loop exhausts
///   [maxTurns] without satisfying either predicate. The caller is
///   responsible for the strict Explore-enabled assertion that follows.
Future<void> e2eAwaitNwCoastalOrVisibleLandForBundledExplore(
  WidgetTester tester,
  AppLocalizations l10n, {
  required void Function(String step) ensureUnderWallClock,
  int maxTurns = kE2eDefaultBundledExploreReadinessMaxTurns,
  Duration maxUiResponseWait = kE2eDefaultNavalMoveSegmentUiWait,
}) async {
  for (var i = 0; i < maxTurns; i++) {
    ensureUnderWallClock('NW bundled-explore readiness i=$i');
    await e2eDismissTransientUi(tester);
    await e2eTapNewWorldRegionTabIfPresent(tester);
    if (e2eNonHomeHumanFleetInCoastalNewWorldSeaFromCtSnapshot(
          ctE2eNavalPanelSnapshot,
        ) ||
        e2ePlayerHasAnyNewWorldFoggedOrBetterFromCtSnapshot(
          ctE2eNavalPanelSnapshot,
        )) {
      return;
    }
    if (ctE2eNavalPanelSnapshot == null) {
      await e2eOpenNavalPanel(
        tester,
        timeout: maxUiResponseWait,
        bottomSheetCloseTimeout: maxUiResponseWait,
      );
      if (e2eNonHomeHumanFleetInCoastalNewWorldSeaFromCtSnapshot(
            ctE2eNavalPanelSnapshot,
          ) ||
          e2ePlayerHasAnyNewWorldFoggedOrBetterFromCtSnapshot(
            ctE2eNavalPanelSnapshot,
          )) {
        await e2eCloseBottomSheet(tester, overallTimeout: maxUiResponseWait);
        return;
      }
    }
    await e2eTryNavalMoveSegment(
      tester,
      l10n,
      useNewWorldMapTabFirst: true,
      allowWarpDestinations: false,
      maxUiResponseWait: maxUiResponseWait,
      navalPanelAlreadyOpen: ctE2eNavalPanelSnapshot == null,
    );
    await e2eCloseBottomSheet(tester, overallTimeout: maxUiResponseWait);
    await e2eAdvanceOneHumanTurn(tester, l10n: l10n);
    if (e2eNonHomeHumanFleetInCoastalNewWorldSeaFromCtSnapshot(
          ctE2eNavalPanelSnapshot,
        ) ||
        e2ePlayerHasAnyNewWorldFoggedOrBetterFromCtSnapshot(
          ctE2eNavalPanelSnapshot,
        )) {
      return;
    }
  }
}

/// Default `perf.timing` phase label emitted by
/// [e2eCheckExploreEnabledFromCivilianPanel].
///
/// Mirrors the pre-lift inline-closure literal in
/// `new_game_fleet_reaches_new_world_e2e_test.dart` so downstream
/// `E2E_TIMING|phase=...` log scrapers and dashboards remain stable across
/// the lift (Refs GitHub #2336 AC1 / AC2 / AC5 / Bottleneck 5). A silent
/// rename would orphan any existing telemetry keyed on this phase name.
const String kE2eDefaultBundledExploreRetryLoopPhase =
    'bundled_explore_retry_loop';

/// Default `afterSheetPanelsClearPhase` override forwarded into
/// [e2eOpenCivilianPanel] by [e2eCheckExploreEnabledFromCivilianPanel].
///
/// Mirrors the pre-lift fleet-scenario literal so the
/// `pump_until_panels_cleared_after_close_sheet_fleet_civilian_open` phase
/// label keeps attributing post-sheet-close settle time to the fleet
/// scenario rather than to the generic civilian-open path. The full-turn
/// scenario keeps the default `_civilian_open` label by going through
/// [e2eOpenCivilianPanel] directly (Refs GitHub #2336 AC1 / AC2).
const String kE2eDefaultFleetCivilianOpenAfterSheetClearPhase =
    'pump_until_panels_cleared_after_close_sheet_fleet_civilian_open';

/// Opens the civilian panel from the fleet bundled-Explore retry context and
/// returns `true` when at least one civilian unit row exposes an enabled
/// `Explore` assign target.
///
/// Lifted from the formerly inline `checkExploreEnabledFromCivilianPanel`
/// closure in `new_game_fleet_reaches_new_world_e2e_test.dart` (Refs GitHub
/// #2336 AC1 / AC2 / AC5 / Bottleneck 5). The post-bundle Explore scenario
/// invokes this helper inside a bounded `maxBoundedTurnRetries (8)` retry
/// loop, so a silent rename / fail-open would either inflate the bundled-
/// Explore wall clock or mask a real Explore regression. The widget-test
/// pin in
/// `app/test/e2e_check_explore_enabled_from_civilian_panel_test.dart`
/// guards against silent regressions because the integration suite cannot
/// validate this directly today (`app_e2e_linux` is a no-op per
/// `SPEC/program/e2e-integration-tests.md` § CI).
///
/// Contract:
///
/// - Starts a fresh stopwatch and forwards [perf] / [maxUiResponseWait]
///   into [e2eOpenCivilianPanel]; the `afterSheetPanelsClearPhase` default
///   ([kE2eDefaultFleetCivilianOpenAfterSheetClearPhase]) preserves the
///   pre-lift fleet-scenario attribution label.
/// - Calls [e2eWaitUntilFound] on [kCtE2ECivilianPanelRootKey] with
///   `phaseName: 'wait_until_found_civilian_panel'` before evaluating any
///   Assign rows, matching the pre-lift closure exactly.
/// - Delegates to [e2eAnyExplorerHasEnabledExploreAssignFleet] for the
///   actual sweep, forwarding [maxUiResponseWait]. The Assign-sweep is the
///   only place where snapshot short-circuit / panel-walk semantics are
///   defined (Bottleneck 5).
/// - Calls [e2eCloseBottomSheet] with [maxUiResponseWait] regardless of
///   the Explore-enabled outcome so the next retry iteration starts from a
///   clean panel state. A regression that skipped the close would stall
///   the retry loop on a stale Assign sheet.
/// - When [perf] is non-`null`, emits a single `perf.timing(...)` event on
///   return with phase [phaseTimingLabel] (default
///   [kE2eDefaultBundledExploreRetryLoopPhase]) and
///   `meta: 'result=enabled'` or `meta: 'result=not_enabled'`.
/// - Returns the boolean reported by
///   [e2eAnyExplorerHasEnabledExploreAssignFleet] verbatim.
Future<bool> e2eCheckExploreEnabledFromCivilianPanel(
  WidgetTester tester, {
  E2ePerfLog? perf,
  Duration maxUiResponseWait = kE2eDefaultBundledExploreSweepWait,
  String afterSheetPanelsClearPhase =
      kE2eDefaultFleetCivilianOpenAfterSheetClearPhase,
  String phaseTimingLabel = kE2eDefaultBundledExploreRetryLoopPhase,
}) async {
  final phaseSw = Stopwatch()..start();
  await e2eOpenCivilianPanel(
    tester,
    perf: perf,
    afterSheetPanelsClearPhase: afterSheetPanelsClearPhase,
    bottomSheetCloseTimeout: maxUiResponseWait,
  );
  await e2eWaitUntilFound(
    tester,
    find.byKey(kCtE2ECivilianPanelRootKey),
    timeout: maxUiResponseWait,
    perf: perf,
    phaseName: 'wait_until_found_civilian_panel',
  );
  final enabled = await e2eAnyExplorerHasEnabledExploreAssignFleet(
    tester,
    maxUiResponseWait: maxUiResponseWait,
  );
  await e2eCloseBottomSheet(
    tester,
    perf: perf,
    overallTimeout: maxUiResponseWait,
  );
  perf?.timing(
    phaseTimingLabel,
    phaseSw.elapsed,
    meta: 'result=${enabled ? "enabled" : "not_enabled"}',
  );
  return enabled;
}

// `e2eExpectPanelTextsMatchSnapshot`, `kE2eDefaultExpectPanelTextsPhase`,
// and `kE2eDefaultExpectPanelTextsTimeout` live in
// `e2e_test_shared_panel_text_assertions.dart` and are surfaced from this
// barrel via the `export` directive at the top of the file so the snapshot
// text-assertion recipe stays separable from the panel-opener and
// panel-action helpers in this file (Refs GitHub #2336 AC1 / AC2).
//
// `e2eFleetReachTurnLoop`, `E2eFleetReachLoopExit`,
// `E2eFleetReachLoopResult`, and `kE2eDefaultFleetReachLoopMaxTurns` live in
// `e2e_test_shared_fleet_reach_loop.dart` and are surfaced from this barrel
// via the `export` directive at the top of the file so the per-turn
// fleet-reach orchestration stays separable from the panel-opener and
// panel-action helpers in this file. The extraction also keeps this file
// within the repo-lint `dart_file_non_comment_line_size` budget
// (`SPEC/program/repo-lint.md`, ≤ 1000 non-comment lines).

