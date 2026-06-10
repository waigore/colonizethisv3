import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../constants.dart';
import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_orders/colonizethis_orders.dart'
    show WorkOrderCostCalculator;
import 'package:colonizethis_world/colonizethis_world.dart';
import 'phases/consumption_phase.dart';
import 'phases/extraction_phase.dart';
import 'phases/production_phase.dart';
import 'phases/riches_to_treasury_phase.dart';
import 'turn_pipeline_state.dart';

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

/// Pending [RecruitWorkerOrder] costs from [Orders.recruitWorkerOrdersByPlayerId],
/// applied **before** unit-build and material-work pending costs to mirror the
/// live Build / work resolver order (worker pool sub-phase runs before
/// [BuildUnitOrder]).
///
/// Deducts treasury, materials, and the consumed peasant per
/// [WorkerActionEconomyCatalog]; increments the order's target tier on the
/// preview clone. Re-uses [canAffordRecruitWorker] / [applyRecruitWorkerCostDeduction]
/// so the projection shares the validator/resolver cost source of truth.
/// SPEC/program/order-projections.md § Production panel stockpile preview phases.
Game _applyPendingRecruitWorkerOrderCostsForPreview({
  required Game game,
  required Orders currentOrders,
}) {
  if (currentOrders.recruitWorkerOrdersByPlayerId.isEmpty) {
    return game;
  }
  return game.mapPlayers((player) {
    final orders = currentOrders.recruitWorkerOrdersByPlayerId[player.id];
    if (orders == null || orders.isEmpty) {
      return player;
    }
    var workers = player.workerPool;
    var stockpile = player.stockpile;
    var treasury = player.treasury;
    for (final order in orders) {
      final check = canAffordRecruitWorker(
        player,
        order,
        workers,
        stockpile,
        treasury,
      );
      if (!check.canAfford) {
        continue;
      }
      final after = applyRecruitWorkerCostDeduction(
        order,
        workers,
        stockpile,
        treasury,
      );
      workers = after.workers;
      stockpile = after.stockpile;
      treasury = after.treasury;
    }
    return player.copyWith(
      workerPool: workers,
      stockpile: stockpile,
      treasury: treasury,
    );
  });
}

Game _applyPendingBuildOrderCostsForPreview({
  required Game game,
  required Orders currentOrders,
}) {
  if (currentOrders.buildUnitOrdersByPlayerId.isEmpty) {
    return game;
  }
  return game.mapPlayers((player) {
    var workers = player.workerPool;
    var stockpile = player.stockpile;
    var treasury = player.treasury;
    final orders =
        currentOrders.buildUnitOrdersByPlayerId[player.id] ?? const [];
    if (orders.isEmpty) {
      return player;
    }
    for (final order in orders) {
      final check = ProjectedCostEngine.canAffordBuildOrder(
        player,
        order,
        workers,
        stockpile,
        treasury,
      );
      if (!check.canAfford) {
        continue;
      }
      final after = ProjectedCostEngine.applyBuildOrderCostDeduction(
        player,
        order,
        workers,
        stockpile,
        treasury,
      );
      workers = after.workers;
      stockpile = after.stockpile;
      treasury = after.treasury;
    }
    return player.copyWith(
      workerPool: workers,
      stockpile: stockpile,
      treasury: treasury,
    );
  });
}

const Set<String> _pendingStockpileWorkTargetsForPreview = {
  kWorkTargetBuildImprovement,
  kWorkTargetUpgradeTown,
  kWorkTargetBuildRoad,
  kWorkTargetBuildPort,
  kWorkTargetBuildFort,
  kWorkTargetBuildRail,
};

/// Pending material-backed work-order costs from [Orders.workOrdersByPlayerId],
/// after unit-build pending costs, mirroring [applyStandardWorkOrder] guards in
/// the work phase (unit present and idle, valid target tile key, unit type
/// allowed, sequential affordability). Non-stockpile work targets are excluded.
Game _applyPendingMaterialWorkOrderCostsForPreview({
  required Game game,
  required Orders currentOrders,
}) {
  if (currentOrders.workOrdersByPlayerId.isEmpty) {
    return game;
  }
  final tileState = game.worldState.tileState;
  return game.mapPlayers((player) {
    final orders = currentOrders.workOrdersByPlayerId[player.id];
    if (orders == null || orders.isEmpty) {
      return player;
    }
    var stockpile = player.stockpile;
    for (final order in orders) {
      final target = order.target;
      if (!_pendingStockpileWorkTargetsForPreview.contains(target)) {
        continue;
      }
      final u = game.worldState.tryGetUnitById(order.unitId);
      if (u == null || u.currentWork != null) {
        continue;
      }
      final targetTileKey = order.targetTileKey;
      if (targetTileKey.isEmpty) {
        continue;
      }
      if (!isWorkOrderTargetAllowedForUnitType(u.type, target)) {
        continue;
      }
      final province = game.worldState.tryGetProvince(u.locationProvinceId);
      final cost = WorkOrderCostCalculator(game, playerId: player.id)
          .calculateCost(
            target,
            targetTileKey,
            improvementLevel: tileState.improvementLevel(targetTileKey),
            fortLevel: province?.fortLevel ?? 0,
          );
      if (cost == null) {
        continue;
      }
      if (!ProjectedCostEngine.canAffordWorkMaterialCost(stockpile, cost)) {
        continue;
      }
      stockpile = ProjectedCostEngine.deductWorkMaterialCost(stockpile, cost);
    }
    return player.copyWith(stockpile: stockpile);
  });
}

Game _applyPendingStockpileCostsForPreview({
  required Game game,
  required Orders currentOrders,
}) {
  final afterRecruits = _applyPendingRecruitWorkerOrderCostsForPreview(
    game: game,
    currentOrders: currentOrders,
  );
  final afterBuilds = _applyPendingBuildOrderCostsForPreview(
    game: afterRecruits,
    currentOrders: currentOrders,
  );
  return _applyPendingMaterialWorkOrderCostsForPreview(
    game: afterBuilds,
    currentOrders: currentOrders,
  );
}

/// Per-phase stockpile commodity deltas for [playerId] when running the same
/// preview pipeline as [applyEconomyPhasesForPreview]. Maps omit zero deltas.
Map<EconomyPreviewStockpilePhase, Map<String, int>>
economyPreviewStockpilePhaseDeltasForPlayer({
  required Game game,
  required MapTopology topology,
  required String playerId,
  Map<String, TileMapResult>? tileMapByRegion,
  Map<String, Map<CommodityId, int>> extractedByPlayerId = const {},
  Orders currentOrders = const Orders(),
  List<AssignedRecipe> defaultAssignments = const [],
  Map<String, List<AssignedRecipe>>? defaultAssignmentsByPlayerId,
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
    game: _applyPendingStockpileCostsForPreview(
      game: acc.game,
      currentOrders: currentOrders,
    ),
  );
  final pendingBuildCosts = _stockpileCommodityDeltaMap(
    beforePendingBuildCosts,
    stockpileForViewed(acc.game),
  );

  final beforeExtraction = stockpileForViewed(acc.game);
  acc = acc.copyWith(
    game: runExtractionPhase(
      acc.game,
      topology,
      tileMapByRegion,
      extractedByPlayerId,
    ),
  );
  final extraction = _stockpileCommodityDeltaMap(
    beforeExtraction,
    stockpileForViewed(acc.game),
  );

  final beforeRiches = stockpileForViewed(acc.game);
  acc = acc.copyWith(game: runRichesToTreasuryPhase(acc.game));
  final richesToTreasury = _stockpileCommodityDeltaMap(
    beforeRiches,
    stockpileForViewed(acc.game),
  );

  final beforeConsumption = stockpileForViewed(acc.game);
  acc = runConsumptionPipelinePhase(acc);
  final consumption = _stockpileCommodityDeltaMap(
    beforeConsumption,
    stockpileForViewed(acc.game),
  );

  final beforeProduction = stockpileForViewed(acc.game);
  acc = runProductionPipelinePhase(
    acc,
    defaultAssignments,
    defaultAssignmentsByPlayerId,
    null,
  );
  final production = _stockpileCommodityDeltaMap(
    beforeProduction,
    stockpileForViewed(acc.game),
  );

  return {
    EconomyPreviewStockpilePhase.pendingBuildCosts: pendingBuildCosts,
    EconomyPreviewStockpilePhase.extraction: extraction,
    EconomyPreviewStockpilePhase.richesToTreasury: richesToTreasury,
    EconomyPreviewStockpilePhase.consumption: consumption,
    EconomyPreviewStockpilePhase.production: production,
  };
}

/// Runs Extraction → Riches-to-treasury → Consumption → Production only.
Game applyEconomyPhasesForPreview({
  required Game game,
  required MapTopology topology,
  Map<String, TileMapResult>? tileMapByRegion,
  Map<String, Map<CommodityId, int>> extractedByPlayerId = const {},
  Orders currentOrders = const Orders(),
  List<AssignedRecipe> defaultAssignments = const [],
  Map<String, List<AssignedRecipe>>? defaultAssignmentsByPlayerId,
}) {
  var acc = TurnPipelineState(game: game);
  acc = acc.copyWith(
    game: _applyPendingStockpileCostsForPreview(
      game: acc.game,
      currentOrders: currentOrders,
    ),
  );
  acc = acc.copyWith(
    game: runExtractionPhase(
      acc.game,
      topology,
      tileMapByRegion,
      extractedByPlayerId,
    ),
  );
  acc = acc.copyWith(game: runRichesToTreasuryPhase(acc.game));
  acc = runConsumptionPipelinePhase(acc);
  acc = runProductionPipelinePhase(
    acc,
    defaultAssignments,
    defaultAssignmentsByPlayerId,
    null,
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
  Map<String, TileMapResult>? tileMapByRegion,
  Map<String, Map<CommodityId, int>> extractedByPlayerId = const {},
  Orders currentOrders = const Orders(),
  List<AssignedRecipe> defaultAssignments = const [],
  Map<String, List<AssignedRecipe>>? defaultAssignmentsByPlayerId,
}) {
  final beforePlayer = game.playerById(playerId);
  if (beforePlayer == null) {
    return {};
  }
  final before = beforePlayer.stockpile;
  final afterGame = applyEconomyPhasesForPreview(
    game: game,
    topology: topology,
    tileMapByRegion: tileMapByRegion,
    extractedByPlayerId: extractedByPlayerId,
    currentOrders: currentOrders,
    defaultAssignments: defaultAssignments,
    defaultAssignmentsByPlayerId: defaultAssignmentsByPlayerId,
  );
  final after = afterGame.playerById(playerId)?.stockpile ?? before;
  final keys = <String>{...before.quantities.keys, ...after.quantities.keys};
  final out = <String, int>{};
  for (final id in keys) {
    final delta = after.quantityOf(id) - before.quantityOf(id);
    if (delta != 0) {
      out[id] = delta;
    }
  }
  return out;
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
  Map<String, TileMapResult>? tileMapByRegion,
  Map<String, Map<CommodityId, int>> extractedByPlayerId = const {},
  Orders currentOrders = const Orders(),
  List<AssignedRecipe> defaultAssignments = const [],
  Map<String, List<AssignedRecipe>>? defaultAssignmentsByPlayerId,
}) {
  return economyPreviewStockpilePhaseDeltasForPlayer(
    game: game,
    topology: topology,
    playerId: playerId,
    tileMapByRegion: tileMapByRegion,
    extractedByPlayerId: extractedByPlayerId,
    currentOrders: currentOrders,
    defaultAssignments: defaultAssignments,
    defaultAssignmentsByPlayerId: defaultAssignmentsByPlayerId,
  );
}
