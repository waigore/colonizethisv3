/// Shared simple heuristics for AI order generation. SPEC/program/ai-planner.md,
/// sim-game-default-ai.md. Used by AIPlanner and defaultSimGameAi.
library;

import 'dart:math' as math;

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/src/logging.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../constants.dart';
import '../orders/draft_orders_mutations.dart';
import '../orders/order_suggestion.dart';
import '../orders/order_resolution_context.dart';
import '../orders/order_suggestion_context.dart';
import '../world/army_migration.dart';
import '../world/faction_membership.dart';
import '../world/player_view.dart';
import '../world/unit_lookup.dart';

/// Derives turn seed per ai-planner: turnSeed = hash(globalGameSeed, aiSeed[P], T).
/// When [fallbackAiSeed] is provided and [game.aiSeedByGpId] has no entry for
/// [playerId], it is used so that Option A (same seed when same role) holds.
int turnSeedForPlayer(
  Game game,
  String playerId,
  int turnNumber, {
  int? fallbackAiSeed,
}) {
  final global = game.globalGameSeed ?? 0;
  final aiSeed =
      game.aiSeedByGpId[playerId] ?? fallbackAiSeed ?? playerId.hashCode;
  var h = global ^ (turnNumber * kDeterministicHashMixPrime32);
  h ^= aiSeed * kDeterministicHashMixPrime32;
  return h & kDeterministicLcg31Mask;
}

enum _SuggestionCategory { moves, work, build, research }

/// Picks the next suggestion category. When both move and work have candidates,
/// uses [rng] so work (e.g. `build_rail` with tile maps) is not always starved.
/// SPEC/program/sim-game-default-ai.md, ai-planner.md.
_SuggestionCategory _chooseSuggestionCategory(
  List<_SuggestionCategory> categories,
  math.Random rng,
) {
  categories.sort((a, b) => a.index.compareTo(b.index));
  final hasMoves = categories.contains(_SuggestionCategory.moves);
  final hasWork = categories.contains(_SuggestionCategory.work);
  if (hasMoves && hasWork) {
    return rng.nextBool()
        ? _SuggestionCategory.moves
        : _SuggestionCategory.work;
  }
  return categories.first;
}

List<_SuggestionCategory> _categoriesPresent({
  required List<MoveOrder> moveSuggestions,
  required List<ArmyMoveOrder> armyMoveSuggestions,
  required List<WorkOrder> workSuggestions,
  required List<BuildUnitOrder> buildSuggestions,
  required List<ResearchOrder> researchSuggestions,
}) {
  final categories = <_SuggestionCategory>[];
  if (moveSuggestions.isNotEmpty || armyMoveSuggestions.isNotEmpty) {
    categories.add(_SuggestionCategory.moves);
  }
  if (workSuggestions.isNotEmpty) {
    categories.add(_SuggestionCategory.work);
  }
  if (buildSuggestions.isNotEmpty) {
    categories.add(_SuggestionCategory.build);
  }
  if (researchSuggestions.isNotEmpty) {
    categories.add(_SuggestionCategory.research);
  }
  return categories;
}

_SuggestionCategory _resolveSimpleHeuristicCategory({
  required List<_SuggestionCategory> categories,
  required List<WorkOrder> workSuggestions,
  required math.Random rng,
}) {
  if (categories.contains(_SuggestionCategory.moves) &&
      categories.contains(_SuggestionCategory.work) &&
      workSuggestions.any((w) => w.target == kWorkTargetBuildRail)) {
    return _SuggestionCategory.work;
  }
  return _chooseSuggestionCategory(
    List<_SuggestionCategory>.from(categories),
    rng,
  );
}

Orders _applyChosenSimpleHeuristicCategory({
  required _SuggestionCategory chosenCategory,
  required Game g,
  required String playerId,
  required math.Random rng,
  required Orders current,
  required List<MoveOrder> moveSuggestions,
  required List<ArmyMoveOrder> armyMoveSuggestions,
  required List<WorkOrder> workSuggestions,
  required List<BuildUnitOrder> buildSuggestions,
  required List<ResearchOrder> researchSuggestions,
}) {
  switch (chosenCategory) {
    case _SuggestionCategory.moves:
      if (moveSuggestions.isEmpty) {
        final idx = rng.nextInt(armyMoveSuggestions.length);
        final chosen = armyMoveSuggestions[idx];
        return applyArmyMoveOrderForPlayer(current, playerId, chosen);
      }
      if (armyMoveSuggestions.isEmpty) {
        final idx = rng.nextInt(moveSuggestions.length);
        final chosen = moveSuggestions[idx];
        final list = List<MoveOrder>.from(
          current.moveOrdersByPlayerId[playerId] ?? const [],
        )..add(chosen);
        return current.copyWith(
          moveOrdersByPlayerId: {
            ...current.moveOrdersByPlayerId,
            playerId: list,
          },
        );
      }
      if (rng.nextBool()) {
        final idx = rng.nextInt(moveSuggestions.length);
        final chosen = moveSuggestions[idx];
        final list = List<MoveOrder>.from(
          current.moveOrdersByPlayerId[playerId] ?? const [],
        )..add(chosen);
        return current.copyWith(
          moveOrdersByPlayerId: {
            ...current.moveOrdersByPlayerId,
            playerId: list,
          },
        );
      }
      final idx = rng.nextInt(armyMoveSuggestions.length);
      final chosen = armyMoveSuggestions[idx];
      return applyArmyMoveOrderForPlayer(current, playerId, chosen);
    case _SuggestionCategory.work:
      final idx = rng.nextInt(workSuggestions.length);
      final chosen = workSuggestions[idx];
      final list = List<WorkOrder>.from(
        current.workOrdersByPlayerId[playerId] ?? const [],
      )..add(chosen);
      return current.copyWith(
        workOrdersByPlayerId: {...current.workOrdersByPlayerId, playerId: list},
      );
    case _SuggestionCategory.build:
      final bidx = rng.nextInt(buildSuggestions.length);
      final bchosen = buildSuggestions[bidx];
      final blist = List<BuildUnitOrder>.from(
        current.buildUnitOrdersByPlayerId[playerId] ?? const [],
      )..add(bchosen);
      return current.copyWith(
        buildUnitOrdersByPlayerId: {
          ...current.buildUnitOrdersByPlayerId,
          playerId: blist,
        },
      );
    case _SuggestionCategory.research:
      final ridx = rng.nextInt(researchSuggestions.length);
      final rchosen = researchSuggestions[ridx];
      final rlist = <ResearchOrder>[
        ...current.researchOrdersByPlayerId[playerId] ?? const [],
        rchosen,
      ];
      return current.copyWith(
        researchOrdersByPlayerId: {
          ...current.researchOrdersByPlayerId,
          playerId: rlist,
        },
      );
  }
}

Orders _finalizeSimpleHeuristicOrdersForPlayer({
  required Game g,
  required String playerId,
  required Orders current,
}) {
  final moveByPlayer = <String, List<MoveOrder>>{};
  final armyMoveByPlayer = <String, List<ArmyMoveOrder>>{};
  final buildByPlayer = <String, List<BuildUnitOrder>>{};
  final workByPlayer = <String, List<WorkOrder>>{};
  final researchByPlayer = <String, List<ResearchOrder>>{};

  final rawMoves = current.moveOrdersByPlayerId[playerId];
  if (rawMoves != null && rawMoves.isNotEmpty) {
    final filtered = filterMoveOrdersByDiplomacy(g, playerId, rawMoves);
    if (filtered.isNotEmpty) {
      moveByPlayer[playerId] = filtered;
    }
  }
  final rawArmyMoves = current.armyMoveOrdersByPlayerId[playerId];
  if (rawArmyMoves != null && rawArmyMoves.isNotEmpty) {
    final filtered = filterArmyMoveOrdersByDiplomacy(g, playerId, rawArmyMoves);
    if (filtered.isNotEmpty) {
      armyMoveByPlayer[playerId] = filtered;
    }
  }
  if (current.buildUnitOrdersByPlayerId.containsKey(playerId)) {
    buildByPlayer[playerId] = List<BuildUnitOrder>.from(
      current.buildUnitOrdersByPlayerId[playerId]!,
    );
  }
  if (current.workOrdersByPlayerId.containsKey(playerId)) {
    workByPlayer[playerId] = List<WorkOrder>.from(
      current.workOrdersByPlayerId[playerId]!,
    );
  }
  if (current.researchOrdersByPlayerId.containsKey(playerId)) {
    researchByPlayer[playerId] = List<ResearchOrder>.from(
      current.researchOrdersByPlayerId[playerId]!,
    );
  }

  final m = moveByPlayer[playerId]?.length ?? 0;
  final a = armyMoveByPlayer[playerId]?.length ?? 0;
  final b = buildByPlayer[playerId]?.length ?? 0;
  final w = workByPlayer[playerId]?.length ?? 0;
  final r = researchByPlayer[playerId]?.length ?? 0;
  logicLog.i(
    'simple heuristics generated orders player=$playerId move=$m armyMove=$a build=$b work=$w research=$r',
  );

  return Orders(
    moveOrdersByPlayerId: moveByPlayer,
    armyMoveOrdersByPlayerId: armyMoveByPlayer,
    buildUnitOrdersByPlayerId: buildByPlayer,
    workOrdersByPlayerId: workByPlayer,
    diplomaticOrdersByPlayerId: const {},
    researchOrdersByPlayerId: researchByPlayer,
  );
}

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

    final categories = _categoriesPresent(
      moveSuggestions: moveSuggestions,
      armyMoveSuggestions: armyMoveSuggestions,
      workSuggestions: workSuggestions,
      buildSuggestions: buildSuggestions,
      researchSuggestions: researchSuggestions,
    );

    if (categories.isEmpty) break;

    final chosenCategory = _resolveSimpleHeuristicCategory(
      categories: categories,
      workSuggestions: workSuggestions,
      rng: rng,
    );

    current = _applyChosenSimpleHeuristicCategory(
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

  return _finalizeSimpleHeuristicOrdersForPlayer(
    g: g,
    playerId: player.id,
    current: current,
  );
}
