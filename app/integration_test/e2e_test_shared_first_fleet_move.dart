import 'package:colonizethis_app/config/ct_e2e.dart';
import 'package:colonizethis_app/l10n/app_localizations_contract.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'e2e_test_shared.dart';

/// Outcome of one [e2eAttemptFirstFleetMoveOrCancel] invocation.
///
/// The full-turn E2E scenario (`new_game_full_turn_e2e_test.dart`) inlined
/// the post-split "tap first Move; cancel if no destinations" block until
/// this lift (Refs GitHub #2336 AC1 / AC2). Exposing the three outcomes as
/// distinct enum values lets call sites attribute wall-clock segments
/// without re-decoding which branch fired (replaces ad-hoc `if`
/// branching on the helper's side effects).
enum E2eFirstFleetMoveOutcome {
  /// No keyed Move button ([kCtE2EFleetMoveActionKey]) descendant of
  /// [kCtE2ENavalPanelRootKey] was found; no dialog was opened.
  noMoveButton,

  /// The move dialog opened but contained no `RadioListTile<dynamic>`
  /// destinations; the helper tapped Cancel and waited until the dialog
  /// dismissed.
  cancelled,

  /// The move dialog opened, a destination was tapped, Confirm was tapped,
  /// and the dialog dismissed within the budget.
  confirmed,
}

/// Default cap for `wait_until_move_dialog_after_tap` inside
/// [e2eAttemptFirstFleetMoveOrCancel]. Matches the legacy 5 s `waitUntilFound`
/// timeout the inline full-turn block used (Refs GitHub #2336 AC1 / AC2).
const Duration kE2eDefaultFirstFleetMoveDialogOpenTimeout = Duration(seconds: 5);

/// Default cap for `pump_until_move_confirm_tappable` inside
/// [e2eAttemptFirstFleetMoveOrCancel]. Matches the legacy 2 s adaptive wait
/// the inline full-turn block used after tapping a destination radio
/// (Refs GitHub #2336 AC1 / AC2).
const Duration kE2eDefaultFirstFleetMoveConfirmReadyTimeout =
    Duration(seconds: 2);

/// Default cap for `pump_until_move_dialog_closed*` inside
/// [e2eAttemptFirstFleetMoveOrCancel]. Matches the legacy 10 s cap the
/// inline full-turn block used for both the confirm and cancel paths
/// (Refs GitHub #2336 AC1 / AC2).
const Duration kE2eDefaultFirstFleetMoveDialogCloseTimeout =
    Duration(seconds: 10);

/// Opportunistically taps the first `Move` text descendant of the open naval
/// panel, picks the first destination radio in the resulting
/// [AlertDialog] (or taps Cancel when no destinations are present), and
/// pumps until the dialog dismisses.
///
/// Lifted from the inline "post-split, try first Move or dismiss" block in
/// `new_game_full_turn_e2e_test.dart` so the full-turn scenario consumes a
/// shared, unit-pinned helper (Refs GitHub #2336 AC1 / AC2 / Bottleneck 2).
///
/// Distinct from the fleet-reach helpers:
///
/// - [e2eTryNavalMoveSegment] composes region-tab navigation, naval-panel
///   open, [e2eTapMoveOnFirstNonHomeFleet] (skipping the home fleet),
///   and [e2ePickMoveDestinationAndConfirm] (warp / sea-radio picker
///   with drag-probe). It is the canonical helper for the 35-turn
///   fleet-reach loop and fails on empty destination radios.
/// - [e2ePickMoveDestinationAndConfirm] is the warp-vs-sea picker used
///   inside [e2eTryNavalMoveSegment]; it fails when no radios are found
///   because the fleet-reach loop relies on
///   `l10n.moveFleet_noAdjacentSeaZones` to short-circuit instead.
/// - [e2eAttemptFirstFleetMoveOrCancel] is the opportunistic single-fleet
///   move used after [e2eSplitHomeFleetOnce] in the full-turn scenario.
///   It taps the first Move in the panel (no home-fleet skip), tolerates
///   an empty-radios dialog by tapping Cancel, and never enters the
///   warp-row drag-probe path.
///
/// The integration suite cannot validate this directly today
/// (`app_e2e_linux` is a no-op per `SPEC/program/e2e-integration-tests.md`
/// § CI), so the widget-test pin in
/// `app/test/e2e_attempt_first_fleet_move_or_cancel_test.dart` carries the
/// behavioural contract.
///
/// Contract:
///
/// - Scopes the keyed Move finder ([kCtE2EFleetMoveActionKey]) to descendants
///   of [kCtE2ENavalPanelRootKey]. Returns
///   [E2eFirstFleetMoveOutcome.noMoveButton] without opening a dialog when no
///   keyed Move button is present (the label collapses to icon-only at narrow
///   viewports, so the key — not the `Move` text — is authoritative).
/// - When `Move` is tapped, waits up to [moveDialogOpenTimeout] for an
///   [AlertDialog] to mount
///   (`wait_until_move_dialog_after_tap`).
/// - When the mounted dialog has no
///   `RadioListTile<dynamic>` descendants, taps the
///   [AppLocalizations.common_cancel] text inside the dialog, pumps until
///   the dialog leaves the tree
///   (`pump_until_move_dialog_closed_after_cancel`, [dialogCloseTimeout]
///   cap), and returns [E2eFirstFleetMoveOutcome.cancelled].
/// - Otherwise taps the first `RadioListTile<dynamic>` descendant, waits
///   adaptively up to [confirmReadyTimeout] for the
///   [AppLocalizations.common_confirm] text inside the dialog to become
///   hit-testable (`pump_until_move_confirm_tappable`), taps it, pumps
///   until the dialog leaves the tree (`pump_until_move_dialog_closed`,
///   [dialogCloseTimeout] cap), and returns
///   [E2eFirstFleetMoveOutcome.confirmed].
/// - Emits an `E2E_TIMING|...|phase=attempt_first_fleet_move` line via
///   [perf] when supplied, with `meta=result=no_move_button`,
///   `meta=result=cancelled`, or `meta=result=confirmed`.
///
/// **Legacy quirk preserved:** the destination-radio finder is
/// `find.byType(RadioListTile<dynamic>)` — Flutter `byType` is **exact**
/// `runtimeType ==` match, so generic-instantiated `RadioListTile<int>`,
/// `RadioListTile<_MovePick>`, etc. **do not** match. The pre-lift inline
/// block in `new_game_full_turn_e2e_test.dart` always took the cancel branch
/// against the production `MoveFleetDialog` (which builds
/// `RadioListTile<_MovePick>`); the lift preserves that semantic
/// bit-for-bit so the surrounding snapshot assertions stay deterministic.
/// Callers that want the production-matching generic-instantiation finder
/// should compose [e2eRadioListTilesInAlertDialogs] instead — that is
/// [e2ePickMoveDestinationAndConfirm]'s contract and is unit-pinned in
/// `e2e_radio_list_tiles_in_alert_dialogs_test.dart`.
Future<E2eFirstFleetMoveOutcome> e2eAttemptFirstFleetMoveOrCancel(
  WidgetTester tester,
  AppLocalizations l10n, {
  E2ePerfLog? perf,
  Duration moveDialogOpenTimeout = kE2eDefaultFirstFleetMoveDialogOpenTimeout,
  Duration confirmReadyTimeout = kE2eDefaultFirstFleetMoveConfirmReadyTimeout,
  Duration dialogCloseTimeout = kE2eDefaultFirstFleetMoveDialogCloseTimeout,
}) async {
  final phaseSw = Stopwatch()..start();
  final navalPanelRoot = find.byKey(kCtE2ENavalPanelRootKey);
  // Locate Move by stable key, not the `Move` label: the naval action cluster
  // collapses to icon-only at narrow test-host viewports (Refs #2336).
  final moveButtons = find.descendant(
    of: navalPanelRoot,
    matching: find.byKey(kCtE2EFleetMoveActionKey),
  );
  if (moveButtons.evaluate().isEmpty) {
    perf?.timing(
      'attempt_first_fleet_move',
      phaseSw.elapsed,
      meta: 'result=no_move_button',
    );
    return E2eFirstFleetMoveOutcome.noMoveButton;
  }
  await tester.tap(moveButtons.first, warnIfMissed: false);
  await e2eWaitUntilFound(
    tester,
    find.byType(AlertDialog),
    timeout: moveDialogOpenTimeout,
    perf: perf,
    phaseName: 'wait_until_move_dialog_after_tap',
  );
  final moveDialog = find.byType(AlertDialog);
  final destinationRadios = find.descendant(
    of: moveDialog,
    matching: find.byType(RadioListTile<dynamic>),
  );
  if (destinationRadios.evaluate().isEmpty) {
    final cancel = find
        .descendant(
          of: moveDialog,
          matching: find.text(l10n.common_cancel),
        )
        .hitTestable();
    expect(
      cancel,
      findsOneWidget,
      reason:
          'Move dialog with no destination radios must expose a hit-testable '
          'Cancel control so [e2eAttemptFirstFleetMoveOrCancel] can dismiss '
          'it without forcing a Confirm on an invalid pick.',
    );
    await tester.tap(cancel.first, warnIfMissed: false);
    await e2ePumpUntil(
      tester,
      () => find.byType(AlertDialog).evaluate().isEmpty,
      timeout: dialogCloseTimeout,
      perf: perf,
      phaseName: 'pump_until_move_dialog_closed_after_cancel',
    );
    perf?.timing(
      'attempt_first_fleet_move',
      phaseSw.elapsed,
      meta: 'result=cancelled',
    );
    return E2eFirstFleetMoveOutcome.cancelled;
  }
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
    timeout: confirmReadyTimeout,
    perf: perf,
    phaseName: 'pump_until_move_confirm_tappable',
  );
  final confirm = find
      .descendant(
        of: moveDialog,
        matching: find.text(l10n.common_confirm),
      )
      .hitTestable();
  expect(
    confirm,
    findsWidgets,
    reason:
        'Move dialog must expose a hit-testable Confirm control after a '
        'destination radio is tapped so [e2eAttemptFirstFleetMoveOrCancel] '
        'can commit the move without timing out at the dialog-close '
        'pump_until below.',
  );
  await tester.tap(confirm.first, warnIfMissed: false);
  await e2ePumpUntil(
    tester,
    () => find.byType(AlertDialog).evaluate().isEmpty,
    timeout: dialogCloseTimeout,
    perf: perf,
    phaseName: 'pump_until_move_dialog_closed',
  );
  perf?.timing(
    'attempt_first_fleet_move',
    phaseSw.elapsed,
    meta: 'result=confirmed',
  );
  return E2eFirstFleetMoveOutcome.confirmed;
}
