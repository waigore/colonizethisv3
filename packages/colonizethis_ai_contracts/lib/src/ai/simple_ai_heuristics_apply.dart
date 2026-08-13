import 'dart:math' as math;

import 'package:colonizethis_models/colonizethis_models.dart';

import 'package:colonizethis_orders/colonizethis_orders.dart';

import 'simple_ai_heuristics_category.dart';

// Applies one chosen simple-heuristic suggestion category (Refs #4368 Slice B).

Orders applyChosenSimpleHeuristicCategory({
  required SimpleHeuristicSuggestionCategory chosenCategory,
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
    case SimpleHeuristicSuggestionCategory.moves:
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
    case SimpleHeuristicSuggestionCategory.work:
      final idx = rng.nextInt(workSuggestions.length);
      final chosen = workSuggestions[idx];
      final list = List<WorkOrder>.from(
        current.workOrdersByPlayerId[playerId] ?? const [],
      )..add(chosen);
      return current.copyWith(
        workOrdersByPlayerId: {...current.workOrdersByPlayerId, playerId: list},
      );
    case SimpleHeuristicSuggestionCategory.build:
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
    case SimpleHeuristicSuggestionCategory.research:
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
