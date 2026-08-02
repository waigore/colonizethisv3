import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_world/colonizethis_world.dart';
import 'economy_phase_sequence.dart';
import 'economy_preview_pending_orders.dart';
import 'turn_pipeline_state.dart';

const List<EconomyPreviewStockpilePhase> _economyPreviewStockpilePhases =
    <EconomyPreviewStockpilePhase>[
      EconomyPreviewStockpilePhase.extraction,
      EconomyPreviewStockpilePhase.richesToTreasury,
      EconomyPreviewStockpilePhase.consumption,
      EconomyPreviewStockpilePhase.production,
    ];

/// Bundled optional inputs shared by the economy-preview entry points
/// ([economyPreviewStockpilePhaseDeltasForPlayer], [applyEconomyPhasesForPreview],
/// [previewStockpileNetDeltaByCommodityForPlayer] and
/// [previewStockpilePhaseDeltasByCommodityForPlayer]). Bundling the formerly
/// duplicated five-field block into one record means a new preview input is
/// declared once here instead of in every public signature.
typedef EconomyPreviewInputs = ({
  Map<String, TileMapResult>? tileMapByRegion,
  Map<String, Map<CommodityId, int>> extractedByPlayerId,
  Orders currentOrders,
  List<AssignedRecipe> defaultAssignments,
  Map<String, List<AssignedRecipe>>? defaultAssignmentsByPlayerId,
});

/// Default [EconomyPreviewInputs] with empty/unset fields, matching the prior
/// per-parameter defaults declared individually on each preview entry point.
const EconomyPreviewInputs emptyEconomyPreviewInputs = (
  tileMapByRegion: null,
  extractedByPlayerId: <String, Map<CommodityId, int>>{},
  currentOrders: Orders(),
  defaultAssignments: <AssignedRecipe>[],
  defaultAssignmentsByPlayerId: null,
);

/// Builds [EconomyPreviewInputs] with the same defaults the preview entry points
/// previously declared individually, preserving named-argument ergonomics for
/// callers that set only a subset of fields.
EconomyPreviewInputs economyPreviewInputs({
  Map<String, TileMapResult>? tileMapByRegion,
  Map<String, Map<CommodityId, int>> extractedByPlayerId = const {},
  Orders currentOrders = const Orders(),
  List<AssignedRecipe> defaultAssignments = const [],
  Map<String, List<AssignedRecipe>>? defaultAssignmentsByPlayerId,
}) {
  return (
    tileMapByRegion: tileMapByRegion,
    extractedByPlayerId: extractedByPlayerId,
    currentOrders: currentOrders,
    defaultAssignments: defaultAssignments,
    defaultAssignmentsByPlayerId: defaultAssignmentsByPlayerId,
  );
}

/// Builds the [EconomyPhaseStepContext] shared by the preview entry points
/// ([economyPreviewStockpilePhaseDeltasForPlayer] and
/// [applyEconomyPhasesForPreview]). Centralizing construction keeps the common
/// economy-preview context fields in one place so a new field is threaded once
/// (extract-at-2+-uses; preview context is identical across both call sites).
EconomyPhaseStepContext _economyPreviewStepContext({
  required MapTopology topology,
  Map<String, TileMapResult>? tileMapByRegion,
  Map<String, Map<CommodityId, int>> extractedByPlayerId = const {},
  List<AssignedRecipe> defaultAssignments = const [],
  Map<String, List<AssignedRecipe>>? defaultAssignmentsByPlayerId,
}) {
  return EconomyPhaseStepContext(
    topology: topology,
    tileMapByRegion: tileMapByRegion,
    extractedByPlayerId: extractedByPlayerId,
    defaultAssignments: defaultAssignments,
    defaultAssignmentsByPlayerId: defaultAssignmentsByPlayerId,
  );
}

Map<String, int> _stockpileCommodityDeltaMap(
  Stockpile before,
  Stockpile after,
) {
  final keys = <String>{...before.quantities.keys, ...after.quantities.keys};
  final out = <String, int>{};
  for (final k in keys) {
    final d = after.quantityOf(k) - before.quantityOf(k);
    if (d != 0) {
      out[k] = d;
    }
  }
  return out;
}

/// Per-phase stockpile commodity deltas for [playerId] when running the same
/// preview pipeline as [applyEconomyPhasesForPreview]. Maps omit zero deltas.
Map<EconomyPreviewStockpilePhase, Map<String, int>>
economyPreviewStockpilePhaseDeltasForPlayer({
  required Game game,
  required MapTopology topology,
  required String playerId,
  EconomyPreviewInputs inputs = emptyEconomyPreviewInputs,
}) {
  final empty = {
    for (final p in EconomyPreviewStockpilePhase.values) p: <String, int>{},
  };
  if (game.playerById(playerId) == null) {
    return empty;
  }

  Stockpile stockpileForViewed(Game g) {
    final p = g.playerById(playerId);
    return p?.stockpile ?? const Stockpile();
  }

  var acc = TurnPipelineState(game: game);

  final beforePendingBuildCosts = stockpileForViewed(acc.game);
  acc = acc.copyWith(
    game: applyPendingStockpileCostsForPreview(
      game: acc.game,
      currentOrders: inputs.currentOrders,
    ),
  );
  final pendingBuildCosts = _stockpileCommodityDeltaMap(
    beforePendingBuildCosts,
    stockpileForViewed(acc.game),
  );

  final economyCtx = _economyPreviewStepContext(
    topology: topology,
    tileMapByRegion: inputs.tileMapByRegion,
    extractedByPlayerId: inputs.extractedByPlayerId,
    defaultAssignments: inputs.defaultAssignments,
    defaultAssignmentsByPlayerId: inputs.defaultAssignmentsByPlayerId,
  );
  final economyDeltas = <EconomyPreviewStockpilePhase, Map<String, int>>{};
  for (var i = 0; i < economyPhaseSteps.length; i++) {
    final before = stockpileForViewed(acc.game);
    acc = economyPhaseSteps[i](acc, economyCtx);
    economyDeltas[_economyPreviewStockpilePhases[i]] =
        _stockpileCommodityDeltaMap(before, stockpileForViewed(acc.game));
  }

  return {
    EconomyPreviewStockpilePhase.pendingBuildCosts: pendingBuildCosts,
    ...economyDeltas,
  };
}

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
  acc = runEconomyExtractionStep(
    acc,
    _economyPreviewStepContext(
      topology: topology,
      tileMapByRegion: inputs.tileMapByRegion,
      extractedByPlayerId: inputs.extractedByPlayerId,
      defaultAssignments: inputs.defaultAssignments,
      defaultAssignmentsByPlayerId: inputs.defaultAssignmentsByPlayerId,
    ),
  );
  acc = runEconomyRichesToTreasuryStep(
    acc,
    _economyPreviewStepContext(
      topology: topology,
      tileMapByRegion: inputs.tileMapByRegion,
      extractedByPlayerId: inputs.extractedByPlayerId,
      defaultAssignments: inputs.defaultAssignments,
      defaultAssignmentsByPlayerId: inputs.defaultAssignmentsByPlayerId,
    ),
  );
  return acc.game;
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
    _economyPreviewStepContext(
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
  return _stockpileCommodityDeltaMap(before, after);
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
