import 'package:colonizethis_models/colonizethis_models.dart';

import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_world/colonizethis_world.dart';
import '../turn_pipeline_state.dart';
import '../turn_resolver_config.dart';

/// Production phase using idle labour from [acc].
TurnPipelineState runProductionPipelinePhase(
  TurnPipelineState acc,
  List<AssignedRecipe> defaultAssignments,
  Map<String, List<AssignedRecipe>>? defaultAssignmentsByPlayerId,
  void Function(Map<String, Map<String, int>> productionByRecipeByPlayerId)?
  onProductionComplete,
) {
  final game = acc.game;
  final productionByRecipeByPlayerId = <String, Map<String, int>>{};

  final mappedGame = game.mapPlayers((player) {
    final assignments =
        defaultAssignmentsByPlayerId?[player.id] ?? defaultAssignments;
    final idleLabour =
        acc.idleLabourByPlayerId[player.id] ?? WorkerIdleCounts.zero;
    final result = resolveProduction(
      stockpile: player.stockpile,
      workers: player.workerPool,
      idleLabour: idleLabour,
      assignments: assignments,
    );
    if (result.productionByRecipe.isNotEmpty) {
      productionByRecipeByPlayerId[player.id] = Map<String, int>.from(
        result.productionByRecipe,
      );
    }
    return player.copyWith(
      stockpile: result.stockpile,
      workerPool: result.workerPool,
    );
  });

  onProductionComplete?.call(productionByRecipeByPlayerId);
  return acc.copyWith(game: mappedGame);
}

TurnPhaseStepOutcome productionTurnPhaseHandler(
  TurnPipelineState acc,
  TurnResolverConfig config,
  int turn,
) => TurnPhaseStepContinue(
  runProductionPipelinePhase(
    acc,
    config.defaultAssignments,
    config.defaultAssignmentsByPlayerId,
    config.onProductionComplete,
  ),
);
