/// Outcome of one [e2eAttemptFirstFleetMoveOrCancel] invocation.
///
/// The full-turn E2E scenario (`new_game_full_turn_e2e_test.dart`) inlined
/// the post-split "tap first Move; cancel if no destinations" block until
/// this lift (Refs GitHub #2336 AC1 / AC2). Exposing the three outcomes as
/// distinct enum values lets call sites attribute wall-clock segments
/// without re-decoding which branch fired (replaces ad-hoc `if`
/// branching on the helper's side effects).
enum E2eFirstFleetMoveOutcome {
  /// No keyed Move button (`kCtE2EFleetMoveActionKey`) descendant of
  /// `kCtE2ENavalPanelRootKey` was found; no dialog was opened.
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
const Duration kE2eDefaultFirstFleetMoveDialogOpenTimeout = Duration(
  seconds: 5,
);

/// Default cap for `pump_until_move_confirm_tappable` inside
/// [e2eAttemptFirstFleetMoveOrCancel]. Matches the legacy 2 s adaptive wait
/// the inline full-turn block used after tapping a destination radio
/// (Refs GitHub #2336 AC1 / AC2).
const Duration kE2eDefaultFirstFleetMoveConfirmReadyTimeout = Duration(
  seconds: 2,
);

/// Default cap for `pump_until_move_dialog_closed*` inside
/// [e2eAttemptFirstFleetMoveOrCancel]. Matches the legacy 10 s cap the
/// inline full-turn block used for both the confirm and cancel paths
/// (Refs GitHub #2336 AC1 / AC2).
const Duration kE2eDefaultFirstFleetMoveDialogCloseTimeout = Duration(
  seconds: 10,
);
