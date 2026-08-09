import 'package:colonizethis_app_fixtures/config/ct_e2e.dart';
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
