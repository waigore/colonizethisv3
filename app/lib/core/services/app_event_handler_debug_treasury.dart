import 'package:colonizethis_models/colonizethis_models.dart';

import 'debug_command_helpers.dart';

/// Apply immediate treasury credit for the active human player (debug console).
DebugCommandResult applyDebugTreasuryCredit({
  required Game? currentGame,
  required CreditDebugTreasuryEvent event,
}) {
  if (currentGame == null) {
    return (
      game: null,
      message: 'Debug treasury credit ignored: no active game.',
    );
  }
  if (currentGame.worldState.turnState.phase != TurnPhase.orders) {
    return (
      game: null,
      message:
          'Debug add_money rejected: command is allowed only during human Orders phase.',
    );
  }
  if (event.creditedAmount < 1) {
    return (
      game: null,
      message: 'Debug treasury credit ignored: credited amount must be >= 1.',
    );
  }
  final player = findPlayerById(currentGame, event.humanPlayerId);
  if (player == null) {
    return (
      game: null,
      message:
          'Debug treasury credit ignored: unknown player ${event.humanPlayerId}.',
    );
  }
  final oldTreasury = player.treasury;
  final newTreasury = oldTreasury + event.creditedAmount;
  final updatedPlayers = currentGame.players
      .map(
        (p) =>
            p.id == event.humanPlayerId ? p.copyWith(treasury: newTreasury) : p,
      )
      .toList(growable: false);
  final nextGame = currentGame.copyWith(players: updatedPlayers);

  final String message;
  if (event.requestedAmount != event.creditedAmount) {
    message =
        'Treasury +${event.creditedAmount} (requested ${event.requestedAmount}, '
        'credited ${event.creditedAmount}). New balance: $newTreasury.';
  } else {
    message = 'Treasury +${event.creditedAmount}. New balance: $newTreasury.';
  }

  return (game: nextGame, message: message);
}
