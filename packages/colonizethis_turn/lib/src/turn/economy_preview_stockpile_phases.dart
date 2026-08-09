import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_world/colonizethis_world.dart';
import 'economy_phase_sequence.dart';
import 'economy_preview_pending_orders.dart';
import 'turn_pipeline_state.dart';

/// Bundled optional inputs shared by the economy-preview entry points.
typedef EconomyPreviewInputs = ({
  Map<String, TileMapResult>? tileMapByRegion,
  Map<String, Map<CommodityId, int>> extractedByPlayerId,
  Orders currentOrders,
  List<AssignedRecipe> defaultAssignments,
  Map<String, List<AssignedRecipe>>? defaultAssignmentsByPlayerId,
});

const EconomyPreviewInputs emptyEconomyPreviewInputs = (
  tileMapByRegion: null,
  extractedByPlayerId: <String, Map<CommodityId, int>>{},
  currentOrders: Orders(),
  defaultAssignments: <AssignedRecipe>[],
  defaultAssignmentsByPlayerId: null,
);

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

const List<EconomyPreviewStockpilePhase> economyPreviewStockpilePhases =
    <EconomyPreviewStockpilePhase>[
      EconomyPreviewStockpilePhase.extraction,
      EconomyPreviewStockpilePhase.richesToTreasury,
      EconomyPreviewStockpilePhase.consumption,
      EconomyPreviewStockpilePhase.production,
    ];

/// Builds the [EconomyPhaseStepContext] shared by preview entry points.
EconomyPhaseStepContext economyPreviewStepContext({
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

Map<String, int> stockpileCommodityDeltaMap(
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
  final pendingBuildCosts = stockpileCommodityDeltaMap(
    beforePendingBuildCosts,
    stockpileForViewed(acc.game),
  );

  final economyCtx = economyPreviewStepContext(
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
    economyDeltas[economyPreviewStockpilePhases[i]] =
        stockpileCommodityDeltaMap(before, stockpileForViewed(acc.game));
  }

  return {
    EconomyPreviewStockpilePhase.pendingBuildCosts: pendingBuildCosts,
    ...economyDeltas,
  };
}
