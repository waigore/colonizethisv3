/// Shared simple heuristics for AI order generation. SPEC/program/ai-planner.md,
/// sim-game-default-ai.md. Used by AIPlanner and defaultSimGameAi.

import 'dart:math' as math;

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:logger/logger.dart';
import 'diplomacy_resolver.dart';
import 'order_suggestion.dart';
import 'player_view.dart';

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
  final aiSeed = game.aiSeedByGpId[playerId] ??
      fallbackAiSeed ??
      playerId.hashCode;
  const int prime = 0x9E3779B1;
  var h = global ^ (turnNumber * prime);
  h ^= aiSeed * prime;
  return h & 0x7fffffff;
}

enum _SuggestionCategory {
  moves,
  work,
  build,
  research,
}

Map<String, String> _provinceOwnerMap(Game game) {
  final out = <String, String>{};
  for (final p in game.worldState.oldWorld.provinces) {
    if (p.ownerId != null && p.ownerId!.isNotEmpty) {
      out[p.id] = p.ownerId!;
    }
  }
  for (final p in game.worldState.newWorld.provinces) {
    if (p.ownerId != null && p.ownerId!.isNotEmpty) {
      out[p.id] = p.ownerId!;
    }
  }
  return out;
}

/// Generates orders for a single player using the shared simple heuristics:
/// PlayerView, order suggestion API, category order (move → work → build →
/// research), seeded random choice within category, and diplomacy post-filter.
/// Returns Orders for that player only (no diplomatic orders).
Orders generateOrdersWithSimpleHeuristics(
  Game game,
  MapTopology topology,
  String playerId,
  int turnSeed,
) {
  final player = game.players.cast<Player?>().firstWhere(
        (p) => p?.id == playerId,
        orElse: () => null,
      );
  if (player == null) {
    return const Orders();
  }

  final provinceOwner = _provinceOwnerMap(game);
  final rng = math.Random(turnSeed);
  var current = const Orders();
  final view = buildPlayerView(game, topology, player.id);

  const maxIterationsPerPlayer = 32;
  for (var i = 0; i < maxIterationsPerPlayer; i++) {
    final moveSuggestions = suggestMoveOrders(view, game, topology, current);
    final workSuggestions = suggestWorkOrders(view, game, topology, current);
    final buildSuggestions = suggestBuildOrders(view, game, topology, current);
    final researchSuggestions =
        suggestResearchOrders(view, game, topology, current);

    final categories = <_SuggestionCategory>[];
    if (moveSuggestions.isNotEmpty) {
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
        final idx = rng.nextInt(moveSuggestions.length);
        final chosen = moveSuggestions[idx];
        final list = List<MoveOrder>.from(
          current.moveOrdersByPlayerId[player.id] ?? const [],
        )..add(chosen);
        current = Orders(
          moveOrdersByPlayerId: {
            ...current.moveOrdersByPlayerId,
            player.id: list,
          },
          buildUnitOrdersByPlayerId: current.buildUnitOrdersByPlayerId,
          workOrdersByPlayerId: current.workOrdersByPlayerId,
          diplomaticOrdersByPlayerId: current.diplomaticOrdersByPlayerId,
          researchOrdersByPlayerId: current.researchOrdersByPlayerId,
        );
        break;
      case _SuggestionCategory.work:
        final idx = rng.nextInt(workSuggestions.length);
        final chosen = workSuggestions[idx];
        final list = List<WorkOrder>.from(
          current.workOrdersByPlayerId[player.id] ?? const [],
        )..add(chosen);
        current = Orders(
          moveOrdersByPlayerId: current.moveOrdersByPlayerId,
          buildUnitOrdersByPlayerId: current.buildUnitOrdersByPlayerId,
          workOrdersByPlayerId: {
            ...current.workOrdersByPlayerId,
            player.id: list,
          },
          diplomaticOrdersByPlayerId: current.diplomaticOrdersByPlayerId,
          researchOrdersByPlayerId: current.researchOrdersByPlayerId,
        );
        break;
      case _SuggestionCategory.build:
        final idx = rng.nextInt(buildSuggestions.length);
        final chosen = buildSuggestions[idx];
        final list = List<BuildUnitOrder>.from(
          current.buildUnitOrdersByPlayerId[player.id] ?? const [],
        )..add(chosen);
        current = Orders(
          moveOrdersByPlayerId: current.moveOrdersByPlayerId,
          buildUnitOrdersByPlayerId: {
            ...current.buildUnitOrdersByPlayerId,
            player.id: list,
          },
          workOrdersByPlayerId: current.workOrdersByPlayerId,
          diplomaticOrdersByPlayerId: current.diplomaticOrdersByPlayerId,
          researchOrdersByPlayerId: current.researchOrdersByPlayerId,
        );
        break;
      case _SuggestionCategory.research:
        final chosen = researchSuggestions.first;
        final list = <ResearchOrder>[
          ...current.researchOrdersByPlayerId[player.id] ?? const [],
          chosen,
        ];
        current = Orders(
          moveOrdersByPlayerId: current.moveOrdersByPlayerId,
          buildUnitOrdersByPlayerId: current.buildUnitOrdersByPlayerId,
          workOrdersByPlayerId: current.workOrdersByPlayerId,
          diplomaticOrdersByPlayerId: current.diplomaticOrdersByPlayerId,
          researchOrdersByPlayerId: {
            ...current.researchOrdersByPlayerId,
            player.id: list,
          },
        );
        break;
    }
  }

  final moveByPlayer = <String, List<MoveOrder>>{};
  final buildByPlayer = <String, List<BuildUnitOrder>>{};
  final workByPlayer = <String, List<WorkOrder>>{};
  final researchByPlayer = <String, List<ResearchOrder>>{};

  final rawMoves = current.moveOrdersByPlayerId[player.id];
  if (rawMoves != null && rawMoves.isNotEmpty) {
    final filtered = <MoveOrder>[];
    for (final m in rawMoves) {
      final destOwner = provinceOwner[m.destinationProvinceId];
      if (destOwner == null || destOwner == player.id) {
        filtered.add(m);
        continue;
      }
      final rel = getRelation(game, player.id, destOwner);
      if (rel != null && rel.atPeace) {
        continue;
      }
      if (rel == null) {
        final isMinor =
            game.minorNations.any((mn) => mn.id == destOwner);
        if (isMinor) continue;
      }
      filtered.add(m);
    }
    if (filtered.isNotEmpty) {
      moveByPlayer[player.id] = filtered;
    }
  }
  if (current.buildUnitOrdersByPlayerId.containsKey(player.id)) {
    buildByPlayer[player.id] =
        List<BuildUnitOrder>.from(current.buildUnitOrdersByPlayerId[player.id]!);
  }
  if (current.workOrdersByPlayerId.containsKey(player.id)) {
    workByPlayer[player.id] =
        List<WorkOrder>.from(current.workOrdersByPlayerId[player.id]!);
  }
  if (current.researchOrdersByPlayerId.containsKey(player.id)) {
    researchByPlayer[player.id] =
        List<ResearchOrder>.from(current.researchOrdersByPlayerId[player.id]!);
  }

  final m = moveByPlayer[player.id]?.length ?? 0;
  final b = buildByPlayer[player.id]?.length ?? 0;
  final w = workByPlayer[player.id]?.length ?? 0;
  final r = researchByPlayer[player.id]?.length ?? 0;
  Logger().i('ai: simple heuristics generated orders player=${player.id} move=$m build=$b work=$w research=$r');

  return Orders(
    moveOrdersByPlayerId: moveByPlayer,
    buildUnitOrdersByPlayerId: buildByPlayer,
    workOrdersByPlayerId: workByPlayer,
    diplomaticOrdersByPlayerId: const {},
    researchOrdersByPlayerId: researchByPlayer,
  );
}
