import 'package:colonizethis_models/colonizethis_models.dart';

import 'debug_command_helpers.dart';

/// Apply immediate stockpile commodity credit for the active human player.
DebugCommandResult applyDebugStockpileCredit({
  required Game? currentGame,
  required CreditDebugStockpileCommodityEvent event,
}) {
  final guard = resolveDebugCommandGuards(
    currentGame: currentGame,
    label: DebugCommandLabel.addResource,
    ordersPhaseLabel: DebugCommandLabel.addResource,
    creditedAmount: event.creditedAmount,
    playerId: event.humanPlayerId,
  );
  if (guard is DebugGuardFailure) return guard.result;
  guard as DebugGuardPass;

  final nextStockpile = guard.player.stockpile.applyDelta(
    event.commodityId,
    event.creditedAmount,
  );
  final newQuantity = nextStockpile.quantityOf(event.commodityId);
  final nextGame = updateDebugPlayer(
    guard.game,
    event.humanPlayerId,
    (p) => p.copyWith(stockpile: nextStockpile),
  );
  final message = debugCreditedAmountMessage(
    subject: 'Stockpile ${event.commodityId}',
    requestedAmount: event.requestedAmount,
    creditedAmount: event.creditedAmount,
    balanceLabel: 'New balance',
    balanceValue: newQuantity,
  );
  return (game: nextGame, message: message);
}
