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
  final guard = resolveDebugCommandGuards(
    currentGame: currentGame,
    label: DebugCommandLabel.addWorker,
    creditedAmount: event.creditedAmount,
    playerId: event.humanPlayerId,
  );
  if (guard is DebugGuardFailure) return guard.result;
  guard as DebugGuardPass;

  final nextPool = _bumpWorkerPoolTier(
    guard.player.workerPool,
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
  final nextGame = updateDebugPlayer(
    guard.game,
    event.humanPlayerId,
    (p) => p.copyWith(workerPool: nextPool),
  );
  final message = debugCreditedAmountMessage(
    subject: 'Worker pool ${event.workerTierId}',
    requestedAmount: event.requestedAmount,
    creditedAmount: event.creditedAmount,
    balanceLabel: 'New ${event.workerTierId} count',
    balanceValue: newTierCount,
  );

  return (game: nextGame, message: message);
}
