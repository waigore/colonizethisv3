import 'package:colonizethis_models/colonizethis_models.dart';

import 'debug_command_helpers.dart';

/// Apply immediate worker-pool tier credit for the active human player (debug console).
DebugCommandResult applyDebugWorkerPoolCredit({
  required Game? currentGame,
  required CreditDebugWorkerPoolEvent event,
}) {
  if (currentGame == null) {
    return (
      game: null,
      message: 'Debug worker pool credit ignored: no active game.',
    );
  }
  if (event.creditedAmount < 1) {
    return (
      game: null,
      message: 'Debug worker pool credit ignored: credited amount must be >= 1.',
    );
  }
  final player = findPlayerById(currentGame, event.humanPlayerId);
  if (player == null) {
    return (
      game: null,
      message:
          'Debug worker pool credit ignored: unknown player ${event.humanPlayerId}.',
    );
  }

  final WorkerPool pool = player.workerPool;
  final WorkerPool nextPool;
  final int newTierCount;
  switch (event.workerTierId) {
    case 'peasants':
      newTierCount = pool.peasants + event.creditedAmount;
      nextPool = pool.copyWith(peasants: newTierCount);
    case 'apprentices':
      newTierCount = pool.apprentices + event.creditedAmount;
      nextPool = pool.copyWith(apprentices: newTierCount);
    case 'journeymen':
      newTierCount = pool.journeymen + event.creditedAmount;
      nextPool = pool.copyWith(journeymen: newTierCount);
    case 'masters':
      newTierCount = pool.masters + event.creditedAmount;
      nextPool = pool.copyWith(masters: newTierCount);
    default:
      return (
        game: null,
        message:
            'Debug worker pool credit ignored: unsupported tier ${event.workerTierId}.',
      );
  }

  final updatedPlayers = currentGame.players
      .map(
        (p) =>
            p.id == event.humanPlayerId ? p.copyWith(workerPool: nextPool) : p,
      )
      .toList(growable: false);
  final nextGame = currentGame.copyWith(players: updatedPlayers);

  final String message;
  if (event.requestedAmount != event.creditedAmount) {
    message =
        'Worker pool +${event.creditedAmount} ${event.workerTierId} '
        '(requested ${event.requestedAmount}, credited ${event.creditedAmount}). '
        'New ${event.workerTierId} count: $newTierCount.';
  } else {
    message =
        'Worker pool +${event.creditedAmount} ${event.workerTierId}. '
        'New ${event.workerTierId} count: $newTierCount.';
  }

  return (game: nextGame, message: message);
}
