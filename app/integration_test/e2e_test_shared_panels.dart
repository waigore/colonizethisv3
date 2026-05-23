import 'package:colonizethis_app/config/ct_e2e.dart';
import 'package:colonizethis_app/features/game/flame/game_screen_shared.dart';
import 'package:colonizethis_app/l10n/app_localizations_contract.dart';
import 'package:colonizethis_app/widgets/ct_dialog_shell.dart';
import 'package:colonizethis_app/widgets/ct_nine_patch_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'e2e_test_shared.dart';

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
