/// Shared simple heuristics for AI order generation. SPEC/program/ai-planner.md,
/// sim-game-default-ai.md. Used by AIPlanner and defaultSimGameAi.

import 'dart:math' as math;

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logger/colonizethis_logger.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../constants.dart';
import '../orders/draft_orders_mutations.dart';
import '../orders/order_suggestion.dart';
import '../world/army_migration.dart';
import '../world/player_view.dart';

final _log = logicLogger();

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
  const int prime = 0x9E3779B1;
  var h = global ^ (turnNumber * prime);
  h ^= aiSeed * prime;
  return h & 0x7fffffff;
}

enum _SuggestionCategory { moves, work, build, research }

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
}) {
  final player = game.playerById(playerId);
  if (player == null) {
    return const Orders();
  }

  final g = ensureMilitaryArmiesForGame(game);
  final rng = math.Random(turnSeed);
  var current = const Orders();
  final view = buildPlayerView(g, topology, player.id);

  /// Max iterations per player per turn (cap to avoid unbounded loops).
  /// Documented in SPEC/program/sim-game-default-ai.md.
  const maxIterationsPerPlayer = 32;
  for (var i = 0; i < maxIterationsPerPlayer; i++) {
    final moveSuggestions = suggestMoveOrders(view, g, topology, current);
    final armyMoveSuggestions =
        suggestArmyMoveOrders(view, g, topology, current);
    final workSuggestions = suggestWorkOrders(
      view,
      g,
      topology,
      current,
      tileMapByRegion: tileMapByRegion,
    );
    final buildSuggestions = suggestBuildOrders(view, g, topology, current);
    final researchSuggestions = suggestResearchOrders(
      view,
      g,
      topology,
      current,
    );

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

    if (categories.isEmpty) break;

    categories.sort((a, b) => a.index.compareTo(b.index));
    final chosenCategory = categories.first;

    switch (chosenCategory) {
      case _SuggestionCategory.moves:
        if (moveSuggestions.isEmpty) {
          final idx = rng.nextInt(armyMoveSuggestions.length);
          final chosen = armyMoveSuggestions[idx];
          current = applyArmyMoveOrderForPlayer(current, player.id, chosen);
        } else if (armyMoveSuggestions.isEmpty) {
          final idx = rng.nextInt(moveSuggestions.length);
          final chosen = moveSuggestions[idx];
          final list = List<MoveOrder>.from(
            current.moveOrdersByPlayerId[player.id] ?? const [],
          )..add(chosen);
          current = current.copyWith(
            moveOrdersByPlayerId: {
              ...current.moveOrdersByPlayerId,
              player.id: list,
            },
          );
        } else {
          if (rng.nextBool()) {
            final idx = rng.nextInt(moveSuggestions.length);
            final chosen = moveSuggestions[idx];
            final list = List<MoveOrder>.from(
              current.moveOrdersByPlayerId[player.id] ?? const [],
            )..add(chosen);
            current = current.copyWith(
              moveOrdersByPlayerId: {
                ...current.moveOrdersByPlayerId,
                player.id: list,
              },
            );
          } else {
            final idx = rng.nextInt(armyMoveSuggestions.length);
            final chosen = armyMoveSuggestions[idx];
            current = applyArmyMoveOrderForPlayer(current, player.id, chosen);
          }
        }
        break;
      case _SuggestionCategory.work:
        final idx = rng.nextInt(workSuggestions.length);
        final chosen = workSuggestions[idx];
        final list = List<WorkOrder>.from(
          current.workOrdersByPlayerId[player.id] ?? const [],
        )..add(chosen);
        current = current.copyWith(
          workOrdersByPlayerId: {
            ...current.workOrdersByPlayerId,
            player.id: list,
          },
        );
        break;
      case _SuggestionCategory.build:
        final idx = rng.nextInt(buildSuggestions.length);
        final chosen = buildSuggestions[idx];
        final list = List<BuildUnitOrder>.from(
          current.buildUnitOrdersByPlayerId[player.id] ?? const [],
        )..add(chosen);
        current = current.copyWith(
          buildUnitOrdersByPlayerId: {
            ...current.buildUnitOrdersByPlayerId,
            player.id: list,
          },
        );
        break;
      case _SuggestionCategory.research:
        final idx = rng.nextInt(researchSuggestions.length);
        final chosen = researchSuggestions[idx];
        final list = <ResearchOrder>[
          ...current.researchOrdersByPlayerId[player.id] ?? const [],
          chosen,
        ];
        current = current.copyWith(
          researchOrdersByPlayerId: {
            ...current.researchOrdersByPlayerId,
            player.id: list,
          },
        );
        break;
    }
  }

  final moveByPlayer = <String, List<MoveOrder>>{};
  final armyMoveByPlayer = <String, List<ArmyMoveOrder>>{};
  final buildByPlayer = <String, List<BuildUnitOrder>>{};
  final workByPlayer = <String, List<WorkOrder>>{};
  final researchByPlayer = <String, List<ResearchOrder>>{};

  final rawMoves = current.moveOrdersByPlayerId[player.id];
  if (rawMoves != null && rawMoves.isNotEmpty) {
    final filtered = filterMoveOrdersByDiplomacy(g, player.id, rawMoves);
    if (filtered.isNotEmpty) {
      moveByPlayer[player.id] = filtered;
    }
  }
  final rawArmyMoves = current.armyMoveOrdersByPlayerId[player.id];
  if (rawArmyMoves != null && rawArmyMoves.isNotEmpty) {
    final filtered =
        filterArmyMoveOrdersByDiplomacy(g, player.id, rawArmyMoves);
    if (filtered.isNotEmpty) {
      armyMoveByPlayer[player.id] = filtered;
    }
  }
  if (current.buildUnitOrdersByPlayerId.containsKey(player.id)) {
    buildByPlayer[player.id] = List<BuildUnitOrder>.from(
      current.buildUnitOrdersByPlayerId[player.id]!,
    );
  }
  if (current.workOrdersByPlayerId.containsKey(player.id)) {
    workByPlayer[player.id] = List<WorkOrder>.from(
      current.workOrdersByPlayerId[player.id]!,
    );
  }
  if (current.researchOrdersByPlayerId.containsKey(player.id)) {
    researchByPlayer[player.id] = List<ResearchOrder>.from(
      current.researchOrdersByPlayerId[player.id]!,
    );
  }

  final m = moveByPlayer[player.id]?.length ?? 0;
  final a = armyMoveByPlayer[player.id]?.length ?? 0;
  final b = buildByPlayer[player.id]?.length ?? 0;
  final w = workByPlayer[player.id]?.length ?? 0;
  final r = researchByPlayer[player.id]?.length ?? 0;
  _log.i(
    'simple heuristics generated orders player=${player.id} move=$m armyMove=$a build=$b work=$w research=$r',
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
