/// Development panel one-tap Builder improve assign helpers. Refs #4175 Slice B.
///
/// SPEC: SPEC/ui/development-panel.md, SPEC/program/development-panel-read-model.md
library;

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_world/colonizethis_world.dart';

import 'incremental_candidate_validator.dart';
import 'order_resolution_context.dart';
import 'order_suggestion_context.dart';
import 'order_work_constants.dart';
import 'unit_type_helpers.dart';
import 'validators/work_order_cost_calculator.dart';
import 'work_tile_candidacy/work_tile_candidacy.dart';

/// Selected Builder + tile for a pending `build_improvement` assign.
class DevelopmentImproveAssignCandidate {
  const DevelopmentImproveAssignCandidate({
    required this.builderUnitId,
    required this.targetTileKey,
    required this.isCapitalConnected,
  });

  final String builderUnitId;
  final String targetTileKey;
  final bool isCapitalConnected;

  WorkOrder toWorkOrder() => WorkOrder(
    unitId: builderUnitId,
    target: kWorkTargetBuildImprovement,
    targetTileKey: targetTileKey,
  );
}

/// Assign row affordance for one improvable commodity row.
class DevelopmentAssignRowState {
  const DevelopmentAssignRowState({
    required this.enabled,
    this.disabledReason,
    this.candidate,
  });

  final bool enabled;
  final String? disabledReason;
  final DevelopmentImproveAssignCandidate? candidate;
}

/// Compares improvable tiles for Development panel assign priority.
///
/// Connected tiles first, then lower improvement level, then stable tile key.
int compareDevelopmentImproveTilePriority({
  required String a,
  required String b,
  required Set<String> connectedTileKeys,
  required TileMapState tileState,
}) {
  final aConnected = connectedTileKeys.contains(a);
  final bConnected = connectedTileKeys.contains(b);
  if (aConnected != bConnected) {
    return aConnected ? -1 : 1;
  }
  final aLevel = tileState.improvementLevel(a);
  final bLevel = tileState.improvementLevel(b);
  if (aLevel != bLevel) {
    return aLevel.compareTo(bLevel);
  }
  return a.compareTo(b);
}

List<String> sortedDevelopmentImproveTileCandidates({
  required Iterable<String> tileKeys,
  required Set<String> connectedTileKeys,
  required TileMapState tileState,
}) {
  final sorted = tileKeys.toList()
    ..sort(
      (a, b) => compareDevelopmentImproveTilePriority(
        a: a,
        b: b,
        connectedTileKeys: connectedTileKeys,
        tileState: tileState,
      ),
    );
  return sorted;
}

/// Idle Builders with no pending work, stable unit-id order.
List<Unit> idleBuildersForDevelopmentAssign({
  required Game game,
  required String playerId,
  required Orders currentOrders,
}) {
  final pendingUnitIds = {
    for (final order in currentOrders.workOrdersByPlayerId[playerId] ?? const [])
      order.unitId,
  };
  final builders = <Unit>[];
  for (final unit in [
    ...game.worldState.oldWorld.units,
    ...game.worldState.newWorld.units,
  ]) {
    if (unit.ownerId != playerId) continue;
    if (unit.type != kUnitTypeBuilder) continue;
    if (unit.status != UnitStatus.idle) continue;
    if (unit.currentWork != null) continue;
    if (pendingUnitIds.contains(unit.id)) continue;
    builders.add(unit);
  }
  builders.sort((a, b) => a.id.compareTo(b.id));
  return builders;
}

String? _priorityTileForCommodity({
  required Set<String> commodityTileKeys,
  required Set<String> connectedTileKeys,
  required TileMapState tileState,
}) {
  if (commodityTileKeys.isEmpty) return null;
  return sortedDevelopmentImproveTileCandidates(
    tileKeys: commodityTileKeys,
    connectedTileKeys: connectedTileKeys,
    tileState: tileState,
  ).first;
}

DevelopmentImproveAssignCandidate? _hypotheticalAssignCandidate({
  required Game game,
  required String playerId,
  required Orders currentOrders,
  required Set<String> commodityTileKeys,
  required Set<String> connectedTileKeys,
}) {
  final builders = idleBuildersForDevelopmentAssign(
    game: game,
    playerId: playerId,
    currentOrders: currentOrders,
  );
  if (builders.isEmpty) return null;
  final tileKey = _priorityTileForCommodity(
    commodityTileKeys: commodityTileKeys,
    connectedTileKeys: connectedTileKeys,
    tileState: game.worldState.tileState,
  );
  if (tileKey == null) return null;
  return DevelopmentImproveAssignCandidate(
    builderUnitId: builders.first.id,
    targetTileKey: tileKey,
    isCapitalConnected: connectedTileKeys.contains(tileKey),
  );
}

DevelopmentImproveAssignCandidate? selectDevelopmentImproveAssignCandidate({
  required Game game,
  required String playerId,
  required Orders currentOrders,
  required MapTopology topology,
  required Map<String, TileMapResult> tileMapByRegion,
  required Set<String> commodityTileKeys,
  required Set<String> connectedTileKeys,
}) {
  if (commodityTileKeys.isEmpty) return null;

  final builders = idleBuildersForDevelopmentAssign(
    game: game,
    playerId: playerId,
    currentOrders: currentOrders,
  );
  if (builders.isEmpty) return null;

  final view = buildPlayerView(game, topology, playerId);
  final tileState = game.worldState.tileState;
  final validator = buildIncrementalCandidateValidator(
    game: game,
    topology: topology,
    playerId: playerId,
    baseOrders: currentOrders,
    tileMapByRegion: tileMapByRegion,
  );
  final resolution = orderResolutionContextFromView(view, game);

  for (final builder in builders) {
    final validTiles = getValidWorkOrderTileKeysWithVisibility(
      game: game,
      topology: topology,
      view: view,
      unitId: builder.id,
      workTarget: kWorkTargetBuildImprovement,
      currentOrders: currentOrders,
      tileMapByRegion: tileMapByRegion,
      sharedCandidateValidator: validator,
      resolution: resolution,
    );
    final scoped = validTiles.where(commodityTileKeys.contains).toSet();
    if (scoped.isEmpty) continue;

    final bestTile = sortedDevelopmentImproveTileCandidates(
      tileKeys: scoped,
      connectedTileKeys: connectedTileKeys,
      tileState: tileState,
    ).first;

    return DevelopmentImproveAssignCandidate(
      builderUnitId: builder.id,
      targetTileKey: bestTile,
      isCapitalConnected: connectedTileKeys.contains(bestTile),
    );
  }
  return null;
}

bool _canAffordDevelopmentImproveAssign({
  required Game game,
  required String playerId,
  required Orders currentOrders,
  required DevelopmentImproveAssignCandidate candidate,
}) {
  final player = game.playerById(playerId);
  if (player == null) return false;

  final stockpile = _effectiveStockpileAfterPendingMaterialWorkOrders(
    game: game,
    playerId: playerId,
    currentOrders: currentOrders,
  );
  final tileState = game.worldState.tileState;
  final provinceId = Unit.provinceIdFromTileKey(candidate.targetTileKey);
  final province = provinceId == null
      ? null
      : game.worldState.tryGetProvince(provinceId);
  final cost = WorkOrderCostCalculator(game, playerId: playerId).calculateCost(
    kWorkTargetBuildImprovement,
    candidate.targetTileKey,
    improvementLevel: tileState.improvementLevel(candidate.targetTileKey),
    fortLevel: province?.fortLevel ?? 0,
  );
  if (cost == null || cost.isEmpty) return true;
  return ProjectedCostEngine.canAffordWorkMaterialCost(stockpile, cost);
}

/// Resolves Assign enablement for one improvable commodity row.
DevelopmentAssignRowState resolveDevelopmentAssignRowState({
  required Game game,
  required String playerId,
  required Orders currentOrders,
  required MapTopology topology,
  required Map<String, TileMapResult> tileMapByRegion,
  required Set<String> commodityTileKeys,
  required Set<String> connectedTileKeys,
  bool allowDisconnectedAssign = false,
}) {
  if (commodityTileKeys.isEmpty) {
    return const DevelopmentAssignRowState(
      enabled: false,
      disabledReason: 'No improvable tiles',
    );
  }

  final builders = idleBuildersForDevelopmentAssign(
    game: game,
    playerId: playerId,
    currentOrders: currentOrders,
  );
  if (builders.isEmpty) {
    return const DevelopmentAssignRowState(
      enabled: false,
      disabledReason: 'No idle Builders',
    );
  }

  final candidate = selectDevelopmentImproveAssignCandidate(
    game: game,
    playerId: playerId,
    currentOrders: currentOrders,
    topology: topology,
    tileMapByRegion: tileMapByRegion,
    commodityTileKeys: commodityTileKeys,
    connectedTileKeys: connectedTileKeys,
  );
  if (candidate != null) {
    if (!candidate.isCapitalConnected && !allowDisconnectedAssign) {
      return DevelopmentAssignRowState(
        enabled: false,
        disabledReason: 'Not connected to capital',
        candidate: candidate,
      );
    }
    if (!_canAffordDevelopmentImproveAssign(
      game: game,
      playerId: playerId,
      currentOrders: currentOrders,
      candidate: candidate,
    )) {
      return DevelopmentAssignRowState(
        enabled: false,
        disabledReason: 'Insufficient materials',
        candidate: candidate,
      );
    }
    return DevelopmentAssignRowState(enabled: true, candidate: candidate);
  }

  final hypothetical = _hypotheticalAssignCandidate(
    game: game,
    playerId: playerId,
    currentOrders: currentOrders,
    commodityTileKeys: commodityTileKeys,
    connectedTileKeys: connectedTileKeys,
  );
  if (hypothetical == null) {
    return const DevelopmentAssignRowState(
      enabled: false,
      disabledReason: 'No valid assign target',
    );
  }

  if (!hypothetical.isCapitalConnected && !allowDisconnectedAssign) {
    return DevelopmentAssignRowState(
      enabled: false,
      disabledReason: 'Not connected to capital',
      candidate: hypothetical,
    );
  }

  if (!_canAffordDevelopmentImproveAssign(
    game: game,
    playerId: playerId,
    currentOrders: currentOrders,
    candidate: hypothetical,
  )) {
    return DevelopmentAssignRowState(
      enabled: false,
      disabledReason: 'Insufficient materials',
      candidate: hypothetical,
    );
  }

  return const DevelopmentAssignRowState(
    enabled: false,
    disabledReason: 'No valid assign target',
  );
}

/// Commodity ids with at least one improvable row blocked by materials shortage.
Set<String> developmentPanelMaterialShortageCommodityIds({
  required Game game,
  required String playerId,
  required Orders currentOrders,
  required MapTopology topology,
  required Map<String, TileMapResult> tileMapByRegion,
  required Iterable<({String commodityId, Set<String> tileKeys})> improvableRows,
  required Set<String> connectedTileKeys,
}) {
  final shortages = <String>{};
  for (final row in improvableRows) {
    final state = resolveDevelopmentAssignRowState(
      game: game,
      playerId: playerId,
      currentOrders: currentOrders,
      topology: topology,
      tileMapByRegion: tileMapByRegion,
      commodityTileKeys: row.tileKeys,
      connectedTileKeys: connectedTileKeys,
    );
    if (state.disabledReason == 'Insufficient materials') {
      shortages.add(row.commodityId);
    }
  }
  return shortages;
}

Stockpile _effectiveStockpileAfterPendingMaterialWorkOrders({
  required Game game,
  required String playerId,
  required Orders currentOrders,
}) {
  final player = game.playerById(playerId);
  if (player == null) return Stockpile.empty;

  final orders = currentOrders.workOrdersByPlayerId[playerId];
  if (orders == null || orders.isEmpty) return player.stockpile;

  var stockpile = player.stockpile;
  final tileState = game.worldState.tileState;
  for (final order in orders) {
    if (!_developmentPanelPendingMaterialWorkTargets.contains(order.target)) {
      continue;
    }
    final unit = game.worldState.tryGetUnitById(order.unitId);
    if (unit == null || unit.currentWork != null) continue;
    if (order.targetTileKey.isEmpty) continue;
    if (!isWorkOrderTargetAllowedForUnitType(unit.type, order.target)) continue;

    final provinceId = Unit.provinceIdFromTileKey(order.targetTileKey);
    final province = provinceId == null
        ? null
        : game.worldState.tryGetProvince(provinceId);
    final cost = WorkOrderCostCalculator(game, playerId: playerId).calculateCost(
      order.target,
      order.targetTileKey,
      improvementLevel: tileState.improvementLevel(order.targetTileKey),
      fortLevel: province?.fortLevel ?? 0,
    );
    if (cost == null) continue;
    if (!ProjectedCostEngine.canAffordWorkMaterialCost(stockpile, cost)) {
      continue;
    }
    stockpile = ProjectedCostEngine.deductWorkMaterialCost(stockpile, cost);
  }
  return stockpile;
}

const Set<String> _developmentPanelPendingMaterialWorkTargets = {
  kWorkTargetBuildImprovement,
  kWorkTargetUpgradeTown,
  kWorkTargetBuildRoad,
  kWorkTargetBuildPort,
  kWorkTargetBuildFort,
  kWorkTargetBuildRail,
};
