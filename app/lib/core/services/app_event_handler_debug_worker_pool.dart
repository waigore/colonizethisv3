import 'package:colonizethis_models/colonizethis_models.dart';

import 'debug_command_helpers.dart';

WorkerPool? _bumpWorkerPoolTier(WorkerPool from, String tierId, int delta) {
  return switch (tierId) {
    'peasants' => from.copyWith(peasants: from.peasants + delta),
    'apprentices' => from.copyWith(apprentices: from.apprentices + delta),
    'journeymen' => from.copyWith(journeymen: from.journeymen + delta),
    'masters' => from.copyWith(masters: from.masters + delta),
    _ => null,
  };
}

int _workerTierCount(WorkerPool pool, String tierId) {
  return switch (tierId) {
    'peasants' => pool.peasants,
    'apprentices' => pool.apprentices,
    'journeymen' => pool.journeymen,
    'masters' => pool.masters,
    _ => -1,
  };
}

/// Apply immediate worker-pool tier credit for the active human player (debug console).
DebugCommandResult applyDebugWorkerPoolCredit({
  required Game? currentGame,
  required CreditDebugWorkerPoolEvent event,
}) {
  if (currentGame == null) {
    return (
      game: null,
      message: 'Debug add_worker ignored: no active game.',
    );
  }
  if (event.creditedAmount < 1) {
    return (
      game: null,
      message: 'Debug add_worker ignored: credited amount must be >= 1.',
    );
  }
  final player = findPlayerById(currentGame, event.humanPlayerId);
  if (player == null) {
    return (
      game: null,
      message:
          'Debug add_worker ignored: unknown player ${event.humanPlayerId}.',
    );
  }
  final nextPool = _bumpWorkerPoolTier(
    player.workerPool,
    event.workerTierId,
    event.creditedAmount,
  );
  if (nextPool == null) {
    return (
      game: null,
      message:
          'Debug add_worker ignored: unknown worker tier ${event.workerTierId}.',
    );
  }
  final newTierCount = _workerTierCount(nextPool, event.workerTierId);
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
        'Worker pool ${event.workerTierId} +${event.creditedAmount} (requested ${event.requestedAmount}, '
        'credited ${event.creditedAmount}). New ${event.workerTierId} count: $newTierCount.';
  } else {
    message =
        'Worker pool ${event.workerTierId} +${event.creditedAmount}. New ${event.workerTierId} count: $newTierCount.';
  }

  return (game: nextGame, message: message);
}
