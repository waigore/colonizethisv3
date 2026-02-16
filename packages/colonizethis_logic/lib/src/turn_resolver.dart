import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'economy_consumption.dart';
import 'economy_extraction.dart';
import 'economy_production.dart';
import 'economy_riches_to_treasury.dart';
import 'movement.dart';
import 'orders_application.dart';

/// Resolution sequence. SPEC/program/turn-resolution-phases.md
const List<TurnPhase> turnResolutionSequence = [
  TurnPhase.orders,
  TurnPhase.extraction,
  TurnPhase.richesToTreasury,
  TurnPhase.production,
  TurnPhase.consumption,
  TurnPhase.movement,
  TurnPhase.buildWork,
  TurnPhase.endOfTurn,
];

/// Turn resolver stub (Phase 1 compatibility). Runs phase sequence; only
/// endOfTurn advances turn number.
WorldState resolveTurn(WorldState current) {
  WorldState state = current;
  for (final phase in turnResolutionSequence) {
    state = _runWorldStatePhase(state, phase);
  }
  return state;
}

WorldState _runWorldStatePhase(WorldState state, TurnPhase phase) {
  switch (phase) {
    case TurnPhase.orders:
    case TurnPhase.extraction:
    case TurnPhase.richesToTreasury:
    case TurnPhase.production:
    case TurnPhase.consumption:
    case TurnPhase.movement:
    case TurnPhase.buildWork:
      return state;
    case TurnPhase.endOfTurn:
      return state.copyWith(
        turnState: state.turnState.copyWith(
          turnNumber: state.turnState.turnNumber + 1,
          phase: TurnPhase.orders,
        ),
      );
  }
}

/// Game-level resolver that runs the full Phase 2 sequence over [game],
/// using shared economy and movement helpers.
///
/// [topology] is the static map topology; [orders] holds per-player orders
/// for this turn. In Phase 2 scope, only MoveOrders are applied; Build/Work
/// can be wired later.
Game resolveTurnForGame({
  required Game game,
  required MapTopology topology,
  required Orders orders,
  Map<String, Map<CommodityId, int>> extractedByPlayerId = const {},
  List<AssignedRecipe> defaultAssignments = const [],
}) {
  Game state = game;

  for (final phase in turnResolutionSequence) {
    switch (phase) {
      case TurnPhase.orders:
        // Orders are assumed to already be attached to the Game or passed in.
        break;
      case TurnPhase.extraction:
        // Phase 2: extraction from tiles → per-player vectors is not yet
        // implemented; callers may supply [extractedByPlayerId] directly.
        state = applyExtractionForPlayers(state, extractedByPlayerId);
        break;
      case TurnPhase.richesToTreasury:
        state = _runRichesToTreasuryPhase(state);
        break;
      case TurnPhase.production:
        state = _runProductionPhase(state, defaultAssignments);
        break;
      case TurnPhase.consumption:
        state = _runConsumptionPhase(state);
        break;
      case TurnPhase.movement:
        state = _runMovementPhase(state, topology, orders);
        break;
      case TurnPhase.buildWork:
        state = applyBuildAndWorkOrders(state, orders);
        break;
      case TurnPhase.endOfTurn:
        state = state.copyWith(
          worldState: state.worldState.copyWith(
            turnState: state.worldState.turnState.copyWith(
              turnNumber: state.worldState.turnState.turnNumber + 1,
              phase: TurnPhase.orders,
            ),
          ),
        );
        break;
    }
  }

  return state;
}

Game _runProductionPhase(Game game, List<AssignedRecipe> defaultAssignments) {
  final updatedPlayers = <Player>[];

  for (final player in game.players) {
    final result = resolveProduction(
      stockpile: player.stockpile,
      workers: player.workerPool,
      assignments: defaultAssignments,
    );
    updatedPlayers.add(
      Player(
        id: player.id,
        displayName: player.displayName,
        isHuman: player.isHuman,
        stockpile: result.stockpile,
        workerPool: result.workerPool,
        treasury: player.treasury,
      ),
    );
  }

  return game.copyWith(players: updatedPlayers);
}

Game _runConsumptionPhase(Game game) {
  final updatedPlayers = <Player>[];

  for (final player in game.players) {
    final result = resolveConsumption(
      stockpile: player.stockpile,
      workers: player.workerPool,
    );
    updatedPlayers.add(
      Player(
        id: player.id,
        displayName: player.displayName,
        isHuman: player.isHuman,
        stockpile: result.stockpile,
        workerPool: result.workerPool,
        treasury: player.treasury,
      ),
    );
  }

  return game.copyWith(players: updatedPlayers);
}

Game _runRichesToTreasuryPhase(Game game) {
  final updatedPlayers = <Player>[];

  for (final player in game.players) {
    final result = resolveRichesToTreasury(stockpile: player.stockpile);
    updatedPlayers.add(
      Player(
        id: player.id,
        displayName: player.displayName,
        isHuman: player.isHuman,
        stockpile: result.stockpile,
        workerPool: player.workerPool,
        treasury: player.treasury + result.treasuryDelta,
      ),
    );
  }

  return game.copyWith(players: updatedPlayers);
}

Game _runMovementPhase(
  Game game,
  MapTopology topology,
  Orders orders,
) {
  final moveOrders = orders.moveOrdersByPlayerId;
  if (moveOrders.isEmpty) return game;

  final oldWorld = applyMoveOrdersToRegion(
    game.worldState.oldWorld,
    topology,
    moveOrders,
  );

  // In Phase 2, New World uses same adjacency rules; reuse the same topology.
  final newWorld = applyMoveOrdersToRegion(
    game.worldState.newWorld,
    topology,
    moveOrders,
  );

  return game.copyWith(
    worldState: game.worldState.copyWith(
      oldWorld: oldWorld,
      newWorld: newWorld,
    ),
  );
}
