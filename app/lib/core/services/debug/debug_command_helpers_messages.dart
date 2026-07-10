part of 'debug_command_helpers.dart';

/// Canonical `Debug <label>` message prefix shared by all debug handlers.
String debugCommandPrefix(String label) => 'Debug $label';

/// Short-circuit result for the no-active-game guard.
DebugCommandResult debugNoActiveGame(String label) => (
  game: null,
  message: '${debugCommandPrefix(label)} ignored: no active game.',
);

/// Short-circuit result for the human Orders-phase gate.
DebugCommandResult debugOrdersPhaseRejected(String label) => (
  game: null,
  message:
      '${debugCommandPrefix(label)} rejected: command is allowed only during '
      'human Orders phase.',
);

/// Short-circuit result for the credited-amount `>= 1` guard.
DebugCommandResult debugCreditedAmountBelowMin(String label) => (
  game: null,
  message:
      '${debugCommandPrefix(label)} ignored: credited amount must be >= 1.',
);

/// Short-circuit result for the count `>= 1` guard (spawn handlers).
DebugCommandResult debugCountBelowMin(String label) => (
  game: null,
  message: '${debugCommandPrefix(label)} ignored: count must be >= 1.',
);

/// Short-circuit result for the unknown-player guard.
DebugCommandResult debugUnknownPlayer(String label, String playerId) => (
  game: null,
  message: '${debugCommandPrefix(label)} ignored: unknown player $playerId.',
);

/// Short-circuit result for the human-player gate (spawn handlers).
DebugCommandResult debugPlayerNotHuman(String label, String playerId) => (
  game: null,
  message:
      '${debugCommandPrefix(label)} ignored: player $playerId is not human.',
);

/// Short-circuit result for the capital-province presence guard.
DebugCommandResult debugNoCapitalProvince(String label) => (
  game: null,
  message: '${debugCommandPrefix(label)} ignored: player has no capital '
      'province.',
);

/// Formats the shared "requested vs credited" credit-success message.
///
/// Produces `'<subject> +<credited>. <balanceLabel>: <balanceValue>.'`, adding
/// a `(requested <r>, credited <c>)` clause only when the amounts differ.
String debugCreditedAmountMessage({
  required String subject,
  required int requestedAmount,
  required int creditedAmount,
  required String balanceLabel,
  required Object balanceValue,
}) {
  final creditedClause = requestedAmount != creditedAmount
      ? ' (requested $requestedAmount, credited $creditedAmount)'
      : '';
  return '$subject +$creditedAmount$creditedClause. '
      '$balanceLabel: $balanceValue.';
}
