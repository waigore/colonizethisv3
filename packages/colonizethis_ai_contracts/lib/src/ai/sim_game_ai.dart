import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'simple_ai_heuristics.dart';

/// Default sim_game AI. SPEC/program/sim-game-default-ai.md.
///
/// Produces orders for one Great Power (e.g. human placeholder in sim) using
/// the same channels and strategy as the minimal AIPlanner: PlayerView, order
/// suggestion API, shared simple heuristics, and diplomacy post-filter.
/// [baseSeed] is used as fallback when [game.aiSeedByGpId] has no entry for
/// this player so that Option A (same seed when same role) holds.
Orders defaultSimGameAi({
  required Game game,
  required Player player,
  required MapTopology topology,
  required int baseSeed,
  Map<String, TileMapResult>? tileMapByRegion,
}) {
  final turnNumber = game.worldState.turnState.turnNumber;
  final turnSeed = turnSeedForPlayer(
    game,
    player.id,
    turnNumber,
    fallbackAiSeed: baseSeed,
  );
  return generateOrdersWithSimpleHeuristics(
    game,
    topology,
    player.id,
    turnSeed,
    tileMapByRegion: tileMapByRegion,
  );
}
