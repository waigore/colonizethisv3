import 'package:colonizethis_models/colonizethis_models.dart';

import 'debug_command_helpers.dart';

/// Apply immediate treasury credit for the active human player (debug console).
DebugCommandResult applyDebugTreasuryCredit({
  required Game? currentGame,
  required CreditDebugTreasuryEvent event,
}) {
  final guard = resolveDebugCommandGuards(
    currentGame: currentGame,
    label: DebugCommandLabel.treasuryCredit,
    ordersPhaseLabel: DebugCommandLabel.addMoney,
    creditedAmount: event.creditedAmount,
    playerId: event.humanPlayerId,
  );
  if (guard is DebugGuardFailure) return guard.result;
  guard as DebugGuardPass;

  final newTreasury = guard.player.treasury + event.creditedAmount;
  final nextGame = updateDebugPlayer(
    guard.game,
    event.humanPlayerId,
    (p) => p.copyWith(treasury: newTreasury),
  );
  final message = debugCreditedAmountMessage(
    subject: 'Treasury',
    requestedAmount: event.requestedAmount,
    creditedAmount: event.creditedAmount,
    balanceLabel: 'New balance',
    balanceValue: newTreasury,
  );
  return (game: nextGame, message: message);
}
