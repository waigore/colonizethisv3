import 'package:colonizethis_app_fixtures/config/ct_e2e.dart';
import 'package:colonizethis_app_fixtures/config/ct_e2e_last_panel_snapshot.dart'
    show ctE2eNavalPanelSnapshot;
import 'package:colonizethis_app/features/game/widgets/units/shared/region_labels.dart';
import 'package:colonizethis_app_l10n/l10n/app_localizations_contract.dart';
import 'package:colonizethis_app/widgets/ct_dialog_shell.dart';
import 'package:colonizethis_app/widgets/ct_nine_patch_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app_e2e_support/e2e_test_shared.dart';

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
/// - The Move control is located by its stable [kCtE2EFleetMoveActionKey],
///   not the `Move` label, because the naval action cluster collapses to
///   icon-only (no `Text('Move')`) at narrow viewports (Refs #2336).
/// - When a candidate tile's keyed Move button is not in the tree (collapsed
///   tile), taps the tile's `Icons.expand_more` icon and waits up to 3 s
///   (`wait_until_found_move_after_expand`) for the keyed button to appear.
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
      // Locate the Move control by its stable key, not the `Move` label:
      // the naval action cluster collapses to icon-only (no `Text('Move')`)
      // at narrow test-host viewports (Refs #2336; e2e deterministic locators).
      final moveByKey = find.descendant(
        of: sub,
        matching: find.byKey(kCtE2EFleetMoveActionKey),
      );
      var move = moveByKey;
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
            moveByKey,
            timeout: const Duration(seconds: 3),
            phaseName: 'wait_until_found_move_after_expand',
          );
        }
        move = moveByKey;
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
          e2eMoveFleetDialogFinder(),
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
        e2eMoveFleetDialogFinder(),
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
///   `l10n.moveFleet_warpLinkToRegion(regionDisplayLabel('newWorld'))`
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
/// Returns the [kCtE2EMoveFleetDestinationSeaZoneRowKey] for the adjacent sea
/// zone that makes the most BFS progress toward the New World, or `null` when
/// topology-guided selection is unavailable.
///
/// Reads the combined topology from the live [ctE2eNavalPanelSnapshot] and the
/// candidate sea-zone ids from the open move dialog's keyed rows. Returns
/// `null` (so the caller falls back to `seaRadio.first`) when the snapshot is
/// missing or no sea-zone-keyed rows are mounted — for example under the
/// widget-test fixtures that build legacy `RadioListTile` rows without the
/// `CT_E2E` sea-zone keys (Refs #2336 AC6/AC7).
Key? _e2eBestSeaZoneRowKeyTowardNewWorld() {
  final topology = ctE2eNavalPanelSnapshot?.topology;
  if (topology == null) {
    return null;
  }
  final candidateIds = <String>[];
  final seaRows = find.byWidgetPredicate((w) {
    final Key? key = w.key;
    return key is ValueKey<String> &&
        key.value.startsWith(kCtE2EMoveFleetDestinationSeaZoneRowKeyPrefix);
  });
  for (final element in seaRows.evaluate()) {
    final Key? key = element.widget.key;
    if (key is ValueKey<String>) {
      candidateIds.add(
        key.value.substring(
          kCtE2EMoveFleetDestinationSeaZoneRowKeyPrefix.length,
        ),
      );
    }
  }
  if (candidateIds.isEmpty) {
    return null;
  }
  final best = e2eBestSeaZoneTowardRegion(
    topology: topology,
    candidates: candidateIds,
  );
  if (best == null) {
    return null;
  }
  return kCtE2EMoveFleetDestinationSeaZoneRowKey(best);
}

/// Picks a sea-zone move destination, preferring the adjacent zone that makes
/// BFS progress toward the New World (Refs #2336 AC6/AC7).
///
/// When the live naval snapshot exposes the combined topology and the dialog
/// tags its sea-zone rows with `kCtE2EMoveFleetDestinationSeaZoneRowKey`, the
/// topology-best row is tapped (scrolling it into view first when needed).
/// Falls back to `e2eMoveFleetDestinationRows().first` when the snapshot/keys
/// are unavailable (e.g. the widget-test fixtures), preserving the legacy
/// contract pinned by
/// `app/test/e2e_pick_move_destination_and_confirm_test.dart`.
///
/// Extracted from `e2ePickMoveDestinationAndConfirm` to keep control-flow
/// nesting within the repo-lint depth budget (Refs #2336).
Future<void> _e2eTapSeaZoneDestinationTowardNewWorld(
  WidgetTester tester,
) async {
  final towardKey = _e2eBestSeaZoneRowKeyTowardNewWorld();
  if (towardKey == null) {
    final seaRadio = e2eMoveFleetDestinationRows();
    expect(seaRadio, findsWidgets);
    await tester.tap(seaRadio.first, warnIfMissed: false);
    return;
  }
  final towardRow = find.byKey(towardKey);
  if (towardRow.hitTestable().evaluate().isEmpty) {
    await _e2eScrollSeaZoneRowIntoView(tester, towardRow);
  }
  final towardHit = towardRow.hitTestable();
  await tester.tap(
    (towardHit.evaluate().isNotEmpty ? towardHit : towardRow).first,
    warnIfMissed: false,
  );
}

/// Scrolls [towardRow] into view within the move-fleet dialog's scrollable when
/// one is present; a no-op when the row is already visible or has no scrollable
/// ancestor (Refs #2336).
Future<void> _e2eScrollSeaZoneRowIntoView(
  WidgetTester tester,
  Finder towardRow,
) async {
  final dialogScrollable = find.descendant(
    of: e2eMoveFleetDialogFinder(),
    matching: find.byType(Scrollable),
  );
  if (dialogScrollable.evaluate().isEmpty) {
    return;
  }
  try {
    await tester.scrollUntilVisible(
      towardRow.first,
      120,
      scrollable: dialogScrollable.first,
    );
  } catch (_) {
    // Row may already be visible or have no scrollable ancestor; the
    // hit-testable resolve below still taps from a sane position.
  }
}

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
    e2eMoveFleetDialogFinder(),
    timeout: const Duration(seconds: 2),
    phaseName: 'wait_until_found_move_dialog',
  );
  final warpSuffix = l10n.moveFleet_warpLinkToRegion(
    regionDisplayLabel('newWorld'),
  );
  final warp = find.textContaining(warpSuffix);
  if (allowWarpDestinations && warp.evaluate().isNotEmpty) {
    final scrollRoot = find.byKey(kCtE2EMoveFleetDialogScrollRootKey);
    Finder scrollable = find.descendant(
      of: scrollRoot,
      matching: find.byType(Scrollable),
    );
    // The production [CtDialogShell] hosts its `CustomScrollView` *outside* the
    // keyed scroll-root subtree, so fall back to the dialog's own scrollable
    // when the keyed subtree exposes none (Refs #2336).
    if (scrollable.evaluate().isEmpty) {
      scrollable = find.descendant(
        of: e2eMoveFleetDialogFinder(),
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
    // Tap the enclosing destination row, not only the inner Text, so the row's
    // selection updates before Confirm (Linux CI / headless can miss implicit
    // taps). Production rows are keyed `_MoveFleetDestinationRow`
    // ([kCtE2EMoveFleetDestinationRowKeyPrefix]); legacy widget-test fixtures
    // use `RadioListTile<…>`. Tolerate both, then fall back to the label text.
    final warpRow = find.ancestor(
      of: hit.first,
      matching: find.byWidgetPredicate((w) {
        final Key? key = w.key;
        if (key is ValueKey &&
            key.value is String &&
            (key.value as String).startsWith(
              kCtE2EMoveFleetDestinationRowKeyPrefix,
            )) {
          return true;
        }
        return w.runtimeType.toString().startsWith('RadioListTile<');
      }),
    );
    await tester.tap(
      warpRow.evaluate().isNotEmpty ? warpRow.first : hit.first,
      warnIfMissed: false,
    );
  } else {
    ensureBudget('sea radio');
    await _e2eTapSeaZoneDestinationTowardNewWorld(tester);
  }
  await e2eWaitUntilFound(
    tester,
    find.text(l10n.common_confirm),
    timeout: const Duration(seconds: 2),
    phaseName: 'wait_until_found_move_confirm',
  );
  ensureBudget('confirm');
  // In the production [CtDialogShell] the Confirm/Cancel buttons live inside the
  // dialog's `CustomScrollView`, so a long destination list can push Confirm
  // below the fold (unlike pinned `AlertDialog.actions`). Scroll it into view
  // before the hit-testable assertion so the tap lands (Refs #2336).
  final confirmText = find.text(l10n.common_confirm);
  if (confirmText.hitTestable().evaluate().isEmpty) {
    try {
      await tester.ensureVisible(confirmText.first);
      await tester.pump();
    } catch (_) {
      // Already visible or no scrollable ancestor; the assertion below reports.
    }
  }
  final confirm = confirmText.hitTestable();
  expect(confirm, findsWidgets);
  await tester.tap(confirm.first, warnIfMissed: false);
  await e2ePumpUntil(
    tester,
    () => e2eMoveFleetDialogFinder().evaluate().isEmpty,
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
    e2eMoveFleetDialogFinder(),
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
      () => e2eMoveFleetDialogFinder().evaluate().isEmpty,
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
  if (e2eMoveFleetDialogFinder().evaluate().isNotEmpty) {
    await e2ePickMoveDestinationAndConfirm(
      tester,
      l10n,
      allowWarpDestinations: allowWarpDestinations,
      moveDialogBudget: maxUiResponseWait,
    );
  }
  perf?.timing('fleet_move_segment', phaseSw.elapsed);
}
