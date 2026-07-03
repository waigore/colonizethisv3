import 'planning_imports.dart';

/// Cached player inputs for [effectiveLabourForWorkers] (Refs #3822 Phase 2).
class EffectiveLabourState {
  const EffectiveLabourState({
    required this.workers,
    required this.stockpile,
    required this.regimentCountsById,
    required this.shipCountsById,
  });

  final WorkerPool workers;
  final Stockpile stockpile;
  final Map<String, int> regimentCountsById;
  final Map<String, int> shipCountsById;

  factory EffectiveLabourState.fromGame(Game game, String playerId) {
    final player = game.playerById(playerId);
    if (player == null) {
      return const EffectiveLabourState(
        workers: WorkerPool(),
        stockpile: Stockpile(),
        regimentCountsById: {},
        shipCountsById: {},
      );
    }
    return EffectiveLabourState(
      workers: player.workerPool,
      stockpile: player.stockpile,
      regimentCountsById: regimentTypeCountsForPlayer(game.worldState, playerId),
      shipCountsById: shipTypeCountsForPlayer(game.worldState, playerId),
    );
  }

  int compute() => effectiveLabourForWorkers(
    workers: workers,
    stockpile: stockpile,
    regimentCountsById: regimentCountsById,
    shipCountsById: shipCountsById,
  );
}
