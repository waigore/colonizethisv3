/// Shared simple heuristics for AI order generation. SPEC/program/ai-planner.md,
/// sim-game-default-ai.md. Used by AIPlanner and defaultSimGameAi.
library;

import 'dart:math' as math;

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'package:colonizethis_orders/colonizethis_orders.dart';
import 'package:colonizethis_orders/src/orders/order_suggestion_context.dart';
import 'package:colonizethis_world/colonizethis_world.dart';

import 'simple_ai_heuristics_apply.dart';
import 'simple_ai_heuristics_category.dart';
import 'simple_ai_heuristics_finalize.dart';

export 'simple_ai_heuristics_seed.dart' show turnSeedForPlayer;

/// Generates orders for a single player using the shared simple heuristics:
/// PlayerView, order suggestion API, category order (move → work → build →
/// research), seeded random choice within category, and diplomacy post-filter.
/// Returns Orders for that player only (no diplomatic orders).
Orders generateOrdersWithSimpleHeuristics(
  Game game,
  MapTopology topology,
  String playerId,
  int turnSeed, {
  Map<String, TileMapResult>? tileMapByRegion,

  /// When true, [game] is used as-is (callers must already have run
  /// [ensureMilitaryArmiesForGame]). Used by [generateOrdersForGame] to avoid
  /// O(players) redundant full-world army reconciliation (Refs #2394).
  bool skipEnsureMilitaryArmies = false,
}) {
  final player = game.playerById(playerId);
  if (player == null) {
    return const Orders();
  }

  final g = skipEnsureMilitaryArmies ? game : ensureMilitaryArmiesForGame(game);
  final factionMembership = DiplomacyFactionMembership.from(g);
  final rng = math.Random(turnSeed);
  var current = const Orders();
  final view = buildPlayerView(g, topology, player.id);
  // Shared across iterations and across suggest families: PlayerView and
  // units-by-id are derived from [g] (stable across iterations - only
  // `current` orders accumulate), so the heavy world-state scans embedded in
  // [IncrementalCandidateValidator.forPlayer] are paid **once** per player
  // per turn instead of once per (iteration x suggestion family). Per
  // iteration, a single validator wraps these around the up-to-date
  // [current] basePrefix and feeds all four suggest families. Refs #2394;
  // SPEC/program/order-suggestions.md § Throughput bounds.
  final passResolution = orderResolutionContextFromView(view, g);

  /// Max iterations per player per turn (cap to avoid unbounded loops).
  /// Documented in SPEC/program/sim-game-default-ai.md.
  const maxIterationsPerPlayer = 32;
  var candidateValidator = buildIncrementalCandidateValidator(
    game: g,
    topology: topology,
    playerId: player.id,
    baseOrders: current,
    tileMapByRegion: tileMapByRegion,
    resolution: passResolution,
    factionMembership: factionMembership,
  );
  for (var i = 0; i < maxIterationsPerPlayer; i++) {
    if (i > 0) {
      candidateValidator = candidateValidator.forBasePrefix(current);
    }
    final moveSuggestions = suggestMoveOrders(
      view,
      g,
      topology,
      current,
      sharedCandidateValidator: candidateValidator,
    );
    final armyMoveSuggestions = suggestArmyMoveOrders(
      view,
      g,
      topology,
      current,
      sharedCandidateValidator: candidateValidator,
    );
    final workSuggestions = suggestWorkOrders(
      view,
      g,
      topology,
      current,
      tileMapByRegion: tileMapByRegion,
      sharedCandidateValidator: candidateValidator,
    );
    final buildSuggestions = suggestBuildOrders(
      view,
      g,
      topology,
      current,
      sharedCandidateValidator: candidateValidator,
    );
    final researchSuggestions = suggestResearchOrders(
      view,
      g,
      topology,
      current,
    );

    final categories = categoriesPresent(
      moveSuggestions: moveSuggestions,
      armyMoveSuggestions: armyMoveSuggestions,
      workSuggestions: workSuggestions,
      buildSuggestions: buildSuggestions,
      researchSuggestions: researchSuggestions,
    );

    if (categories.isEmpty) break;

    final chosenCategory = resolveSimpleHeuristicCategory(
      categories: categories,
      workSuggestions: workSuggestions,
      rng: rng,
    );

    current = applyChosenSimpleHeuristicCategory(
      chosenCategory: chosenCategory,
      g: g,
      playerId: player.id,
      rng: rng,
      current: current,
      moveSuggestions: moveSuggestions,
      armyMoveSuggestions: armyMoveSuggestions,
      workSuggestions: workSuggestions,
      buildSuggestions: buildSuggestions,
      researchSuggestions: researchSuggestions,
    );
  }

  return finalizeSimpleHeuristicOrdersForPlayer(
    g: g,
    playerId: player.id,
    current: current,
  );
}
