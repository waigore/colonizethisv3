import 'package:colonizethis_models/colonizethis_models.dart';

import 'debug_command_helpers.dart';

/// Apply immediate stockpile commodity credit for the active human player.
DebugCommandResult applyDebugStockpileCredit({
  required Game? currentGame,
  required CreditDebugStockpileCommodityEvent event,
}) {
  if (currentGame == null) {
    return (game: null, message: 'Debug add_resource ignored: no active game.');
  }
  if (currentGame.worldState.turnState.phase != TurnPhase.orders) {
    return (
      game: null,
      message:
          'Debug add_resource rejected: command is allowed only during human Orders phase.',
    );
  }
  if (event.creditedAmount < 1) {
    return (
      game: null,
      message: 'Debug add_resource ignored: credited amount must be >= 1.',
    );
  }
  final player = findPlayerById(currentGame, event.humanPlayerId);
  if (player == null) {
    return (
      game: null,
      message:
          'Debug add_resource ignored: unknown player ${event.humanPlayerId}.',
    );
  }

  final nextStockpile = player.stockpile.applyDelta(
    event.commodityId,
    event.creditedAmount,
  );
  final newQuantity = nextStockpile.quantityOf(event.commodityId);
  final updatedPlayers = currentGame.players
      .map(
        (p) => p.id == event.humanPlayerId
            ? p.copyWith(stockpile: nextStockpile)
            : p,
      )
      .toList(growable: false);
  final nextGame = currentGame.copyWith(players: updatedPlayers);

  final String message;
  if (event.requestedAmount != event.creditedAmount) {
    message =
        'Stockpile ${event.commodityId} +${event.creditedAmount} (requested '
        '${event.requestedAmount}, credited ${event.creditedAmount}). '
        'New balance: $newQuantity.';
  } else {
    message =
        'Stockpile ${event.commodityId} +${event.creditedAmount}. New balance: '
        '$newQuantity.';
  }
  return (game: nextGame, message: message);
}
