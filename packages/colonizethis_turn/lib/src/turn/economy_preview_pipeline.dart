import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_world/colonizethis_world.dart';
import 'economy_phase_sequence.dart';
import 'economy_preview_pending_orders.dart';
export 'economy_preview_stockpile_phases.dart'
    show
        EconomyPreviewInputs,
        economyPreviewInputs,
        economyPreviewStockpilePhaseDeltasForPlayer,
        emptyEconomyPreviewInputs;

import 'economy_preview_stockpile_phases.dart';
import 'turn_pipeline_state.dart';

/// Runs pending build costs → Extraction → Riches-to-treasury only.
///
/// Used by Production labour readiness so food arriving this turn is included
/// without applying Consumption or Production (Refs #4237).
Game applyEconomyPhasesThroughRichesForPreview({
  required Game game,
  required MapTopology topology,
  EconomyPreviewInputs inputs = emptyEconomyPreviewInputs,
}) {
  var acc = TurnPipelineState(game: game);
  acc = acc.copyWith(
    game: applyPendingStockpileCostsForPreview(
      game: acc.game,
      currentOrders: inputs.currentOrders,
    ),
  );
  final ctx = economyPreviewStepContext(
    topology: topology,
    tileMapByRegion: inputs.tileMapByRegion,
    extractedByPlayerId: inputs.extractedByPlayerId,
    defaultAssignments: inputs.defaultAssignments,
    defaultAssignmentsByPlayerId: inputs.defaultAssignmentsByPlayerId,
  );
  acc = runEconomyExtractionStep(acc, ctx);
  acc = runEconomyRichesToTreasuryStep(acc, ctx);
  return acc.game;
}

/// Forces feeding readiness for one player using post-extraction preview stockpile.
ForceFeedingSnapshot forcesFeedingForPlayer({
  required Game game,
  required MapTopology topology,
  required String playerId,
  MilitaryNavyFoodCounts foodCounts = const MilitaryNavyFoodCounts(),
  EconomyPreviewInputs inputs = emptyEconomyPreviewInputs,
}) {
  final before = game.playerById(playerId);
  if (before == null) {
    return const ForceFeedingSnapshot(
      totalRegiments: 0,
      fullyFedRegiments: 0,
      totalShips: 0,
      fullyFedShips: 0,
      landCombatTier: ForceFeedingCombatTier.full,
      navalCombatTier: ForceFeedingCombatTier.full,
      forcesFoodDemand: 0,
    );
  }
  final previewGame = applyEconomyPhasesThroughRichesForPreview(
    game: game,
    topology: topology,
    inputs: inputs,
  );
  final previewPlayer = previewGame.playerById(playerId)!;
  return previewForceFeeding(
    stockpile: previewPlayer.stockpile,
    foodCounts: foodCounts,
  );
}

/// Labour readiness for one player using post-extraction preview stockpile.
LabourReadinessSnapshot labourReadinessForPlayer({
  required Game game,
  required MapTopology topology,
  required String playerId,
  MilitaryNavyFoodCounts foodCounts = const MilitaryNavyFoodCounts(),
  EconomyPreviewInputs inputs = emptyEconomyPreviewInputs,
}) {
  final before = game.playerById(playerId);
  if (before == null) {
    return const LabourReadinessSnapshot(
      effectiveLabour: 0,
      fullCapacity: 0,
      tierStatuses: [],
    );
  }
  final previewGame = applyEconomyPhasesThroughRichesForPreview(
    game: game,
    topology: topology,
    inputs: inputs,
  );
  final previewPlayer = previewGame.playerById(playerId)!;
  return computeLabourReadiness(
    workers: previewPlayer.workerPool,
    stockpile: previewPlayer.stockpile,
    foodCounts: foodCounts,
  );
}

/// Runs Extraction → Riches-to-treasury → Consumption → Production only.
Game applyEconomyPhasesForPreview({
  required Game game,
  required MapTopology topology,
  EconomyPreviewInputs inputs = emptyEconomyPreviewInputs,
}) {
  var acc = TurnPipelineState(game: game);
  acc = acc.copyWith(
    game: applyPendingStockpileCostsForPreview(
      game: acc.game,
      currentOrders: inputs.currentOrders,
    ),
  );
  acc = runEconomyPhaseSequence(
    acc,
    economyPreviewStepContext(
      topology: topology,
      tileMapByRegion: inputs.tileMapByRegion,
      extractedByPlayerId: inputs.extractedByPlayerId,
      defaultAssignments: inputs.defaultAssignments,
      defaultAssignmentsByPlayerId: inputs.defaultAssignmentsByPlayerId,
    ),
  );
  return acc.game;
}

/// Preview net stockpile change for one player after economy phases that feed
/// the production panel. SPEC/ui/production-panel.md.
///
/// Phases:
/// Pending build costs → Extraction → Riches-to-treasury → Consumption → Production,
/// using the same rules as [applyEconomyPhasesForPreview]. Pending build costs
/// apply in the live Build / work resolver order: pending
/// [RecruitWorkerOrder] (worker pool sub-phase costs and tier deltas) first,
/// then unresolved unit builds, then pending material-backed work-order costs
/// (work-phase rules). Other players are simulated in lockstep so extraction
/// ordering (e.g. fleet updates from trade interception) matches a full turn.
///
/// Returns only commodities whose quantity changes; omit zero deltas.
Map<String, int> previewStockpileNetDeltaByCommodityForPlayer({
  required Game game,
  required MapTopology topology,
  required String playerId,
  EconomyPreviewInputs inputs = emptyEconomyPreviewInputs,
}) {
  final beforePlayer = game.playerById(playerId);
  if (beforePlayer == null) {
    return {};
  }
  final before = beforePlayer.stockpile;
  final afterGame = applyEconomyPhasesForPreview(
    game: game,
    topology: topology,
    inputs: inputs,
  );
  final after = afterGame.playerById(playerId)?.stockpile ?? before;
  return stockpileCommodityDeltaMap(before, after);
}

/// Per-phase stockpile commodity deltas for the production panel breakdown
/// dialog. Same parameters and phase order as [previewStockpileNetDeltaByCommodityForPlayer].
///
/// Inner maps omit zero deltas. For every commodity id, the sum of deltas
/// across [EconomyPreviewStockpilePhase.values] equals
/// [previewStockpileNetDeltaByCommodityForPlayer] for that id (or zero if absent).
Map<EconomyPreviewStockpilePhase, Map<String, int>>
previewStockpilePhaseDeltasByCommodityForPlayer({
  required Game game,
  required MapTopology topology,
  required String playerId,
  EconomyPreviewInputs inputs = emptyEconomyPreviewInputs,
}) {
  return economyPreviewStockpilePhaseDeltasForPlayer(
    game: game,
    topology: topology,
    playerId: playerId,
    inputs: inputs,
  );
}
