/// AIPlanner: generates orders for AI-controlled GPs. SPEC/program/ai-planner.md.

import 'dart:math' as math;

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'diplomacy_resolver.dart';
import 'order_suggestion.dart';
import 'player_view.dart';

/// Returns true if [gpId] is AI-controlled. Uses aiControlByGpId when present,
/// otherwise !player.isHuman.
bool isAiControlled(Game game, String gpId) {
  final explicit = game.aiControlByGpId[gpId];
  if (explicit != null) return explicit;
  final player = game.players.cast<Player?>().firstWhere(
        (p) => p?.id == gpId,
        orElse: () => null,
      );
  return player != null && !player.isHuman;
}

/// Derives turn seed per ai-planner: turnSeed = hash(globalGameSeed, aiSeed[P], T).
int _turnSeed(Game game, String gpId, int turn) {
  final global = game.globalGameSeed ?? 0;
  final aiSeed = game.aiSeedByGpId[gpId] ?? gpId.hashCode;
  const int prime = 0x9E3779B1;
  var h = global ^ (turn * prime);
  h ^= aiSeed * prime;
  return h & 0x7fffffff;
}

/// Generates orders for a single AI-controlled GP. Deterministic given game
/// state and seeds. Respects diplomacy: no attacks against factions at peace.
Orders generateOrdersForPlayer(Game game, MapTopology topology, String playerId) {
  final turn = game.worldState.turnState.turnNumber;
  final provinceOwner = _provinceOwnerMap(game);

  final player = game.players.cast<Player?>().firstWhere(
        (p) => p?.id == playerId,
        orElse: () => null,
      );
  if (player == null || !isAiControlled(game, player.id)) {
    return const Orders();
  }

  final moveByPlayer = <String, List<MoveOrder>>{};
  final buildByPlayer = <String, List<BuildUnitOrder>>{};
  final workByPlayer = <String, List<WorkOrder>>{};
  final researchByPlayer = <String, List<ResearchOrder>>{};

  final turnSeed = _turnSeed(game, player.id, turn);
  final rng = math.Random(turnSeed);
  var current = const Orders();

  final view = buildPlayerView(game, topology, player.id);

    // Simple loop: at each step, gather suggestions and pick one order type
    // using shallow heuristics, then pick a specific candidate at random.
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

      // Basic heuristic: prefer moves first, then work, then build, then research.
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

  return Orders(
    moveOrdersByPlayerId: moveByPlayer,
    buildUnitOrdersByPlayerId: buildByPlayer,
    workOrdersByPlayerId: workByPlayer,
    diplomaticOrdersByPlayerId: const {},
    researchOrdersByPlayerId: researchByPlayer,
  );
}

/// Generates orders for all AI-controlled GPs. Deterministic given game state and seeds.
/// Respects diplomacy: no attacks against factions at peace.
Orders generateOrdersForGame(Game game, MapTopology topology) {
  final moveByPlayer = <String, List<MoveOrder>>{};
  final buildByPlayer = <String, List<BuildUnitOrder>>{};
  final workByPlayer = <String, List<WorkOrder>>{};
  final researchByPlayer = <String, List<ResearchOrder>>{};

  for (final player in game.players) {
    if (!isAiControlled(game, player.id)) continue;
    final ordersForPlayer = generateOrdersForPlayer(game, topology, player.id);
    final moves = ordersForPlayer.moveOrdersByPlayerId[player.id];
    final builds = ordersForPlayer.buildUnitOrdersByPlayerId[player.id];
    final works = ordersForPlayer.workOrdersByPlayerId[player.id];
    final research = ordersForPlayer.researchOrdersByPlayerId[player.id];

    if (moves != null && moves.isNotEmpty) {
      moveByPlayer[player.id] = moves;
    }
    if (builds != null && builds.isNotEmpty) {
      buildByPlayer[player.id] = builds;
    }
    if (works != null && works.isNotEmpty) {
      workByPlayer[player.id] = works;
    }
    if (research != null && research.isNotEmpty) {
      researchByPlayer[player.id] = research;
    }
  }

  return Orders(
    moveOrdersByPlayerId: moveByPlayer,
    buildUnitOrdersByPlayerId: buildByPlayer,
    workOrdersByPlayerId: workByPlayer,
    diplomaticOrdersByPlayerId: const {},
    researchOrdersByPlayerId: researchByPlayer,
  );
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

