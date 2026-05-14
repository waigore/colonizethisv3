/// AIPlanner: generates orders for AI-controlled GPs. SPEC/program/ai-planner.md.
library;

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../constants.dart';
import '../world/army_migration.dart';
import 'ai_control.dart';
import 'simple_ai_heuristics.dart';

/// Generates orders for a single AI-controlled GP. Deterministic given game
/// state and seeds. Respects diplomacy: no attacks against factions at peace.
/// Uses the shared simple heuristics (PlayerView, suggestion API, diplomacy filter).
Orders generateOrdersForPlayer(
  Game game,
  MapTopology topology,
  String playerId, {
  Map<String, TileMapResult>? tileMapByRegion,
  /// When true, [game] must already satisfy [ensureMilitaryArmiesForGame]
  /// (used by [generateOrdersForGame] after a single batch ensure).
  bool armiesAlreadyEnsured = false,
}) {
  final player = game.playerById(playerId);
  if (player == null || !isAiControlled(game, player.id)) {
    return const Orders();
  }

  final turn = game.worldState.turnState.turnNumber;
  final turnSeed = turnSeedForPlayer(game, player.id, turn);
  return generateOrdersWithSimpleHeuristics(
    game,
    topology,
    player.id,
    turnSeed,
    tileMapByRegion: tileMapByRegion,
    skipEnsureMilitaryArmies: armiesAlreadyEnsured,
  );
}

/// Merges a per-player order list into an aggregate map when non-null and non-empty.
void _addOrdersIfNonEmpty<T>(
  Map<String, List<T>> aggregate,
  String playerId,
  List<T>? list,
) {
  if (list != null && list.isNotEmpty) aggregate[playerId] = list;
}

/// Generates orders for all AI-controlled GPs. Deterministic given game state and seeds.
/// Respects diplomacy: no attacks against factions at peace.
Orders generateOrdersForGame(
  Game game,
  MapTopology topology, {
  Map<String, TileMapResult>? tileMapByRegion,
}) {
  final moveByPlayer = <String, List<MoveOrder>>{};
  final armyMoveByPlayer = <String, List<ArmyMoveOrder>>{};
  final buildByPlayer = <String, List<BuildUnitOrder>>{};
  final workByPlayer = <String, List<WorkOrder>>{};
  final researchByPlayer = <String, List<ResearchOrder>>{};

  final gameWithArmies = ensureMilitaryArmiesForGame(game);
  for (final player in game.players) {
    if (!isAiControlled(game, player.id)) continue;
    final ordersForPlayer = generateOrdersForPlayer(
      gameWithArmies,
      topology,
      player.id,
      tileMapByRegion: tileMapByRegion,
      armiesAlreadyEnsured: true,
    );
    _addOrdersIfNonEmpty(moveByPlayer, player.id, ordersForPlayer.moveOrdersByPlayerId[player.id]);
    _addOrdersIfNonEmpty(
      armyMoveByPlayer,
      player.id,
      ordersForPlayer.armyMoveOrdersByPlayerId[player.id],
    );
    _addOrdersIfNonEmpty(buildByPlayer, player.id, ordersForPlayer.buildUnitOrdersByPlayerId[player.id]);
    _addOrdersIfNonEmpty(workByPlayer, player.id, ordersForPlayer.workOrdersByPlayerId[player.id]);
    _addOrdersIfNonEmpty(researchByPlayer, player.id, ordersForPlayer.researchOrdersByPlayerId[player.id]);
  }

  return Orders(
    moveOrdersByPlayerId: moveByPlayer,
    armyMoveOrdersByPlayerId: armyMoveByPlayer,
    buildUnitOrdersByPlayerId: buildByPlayer,
    workOrdersByPlayerId: workByPlayer,
    diplomaticOrdersByPlayerId: const {},
    researchOrdersByPlayerId: researchByPlayer,
    navalMoveOrdersByPlayerId: const {},
  );
}
