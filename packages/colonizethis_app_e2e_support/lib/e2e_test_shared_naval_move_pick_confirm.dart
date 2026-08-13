import 'package:colonizethis_app_fixtures/config/ct_e2e.dart';
import 'package:colonizethis_app/features/game/widgets/units/shared/region_labels.dart';
import 'package:colonizethis_app_l10n/l10n/app_localizations_contract.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app_e2e_support/e2e_test_shared_adaptive_polling.dart';
import 'package:colonizethis_app_e2e_support/e2e_test_shared_move_dialog_finders.dart';
import 'package:colonizethis_app_e2e_support/e2e_test_shared_naval_move_pick_sea.dart';

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
    await e2eTapSeaZoneDestinationTowardNewWorld(tester);
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
