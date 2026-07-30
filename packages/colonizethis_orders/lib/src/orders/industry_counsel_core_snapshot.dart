/// Core production assignment snapshot for Industry Counsel Agree apply.
/// SPEC/program/industry-counsel-ranking.md (Refs #4191).
library;

import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_world/colonizethis_world.dart';

/// Desired output units per recipe from the neutral core labour allocator.
///
/// Recipes absent from the snapshot are not included; callers merge into the
/// player's current desired-output map so unrelated recipes stay unchanged.
Map<String, int> industryCounselCoreDesiredOutputByRecipe({
  required Game game,
  required String playerId,
}) {
  final player = game.playerById(playerId);
  if (player == null) return const {};

  final stockpile = player.stockpile;
  final workers = player.workerPool;
  final effectiveLabour = effectiveLabourForWorkers(
    workers: workers,
    stockpile: stockpile,
  );
  final growthStage = kIndustryCounselGrowthStageEnabled
      ? IndustryCounselGrowthStage.compute(game, playerId)
      : null;

  final coreAssignments = industryCounselAllocateLabourCore(
    stockpile: stockpile,
    workers: workers,
    effectiveLabour: effectiveLabour,
    techUnlocked: player.techUnlocked,
    growthStage: growthStage,
    growthStagePlannerEnabled: kIndustryCounselGrowthStageEnabled,
  );

  return {
    for (final assignment in coreAssignments)
      assignment.recipeId: industryCounselDesiredOutputForAssignment(
        assignment,
      ),
  };
}

/// Merges [coreSnapshot] into [currentDesired]; keys outside the snapshot are
/// preserved unchanged.
Map<String, int> mergeIndustryCounselCoreDesiredOutput({
  required Map<String, int> currentDesired,
  required Map<String, int> coreSnapshot,
}) {
  if (coreSnapshot.isEmpty) return currentDesired;
  final next = Map<String, int>.from(currentDesired);
  next.addAll(coreSnapshot);
  return next;
}
