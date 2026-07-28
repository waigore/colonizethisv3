/// Development panel Road first Engineer assign helpers. Refs #4175 Slice C.
///
/// SPEC: SPEC/ui/development-panel.md, SPEC/game/capital-and-connectivity.md
library;

import 'dart:collection';

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_world/colonizethis_world.dart';

import 'development_panel_assign.dart';
import 'incremental_candidate_validator.dart';
import 'order_resolution_context.dart';
import 'order_suggestion_context.dart';
import 'order_work_constants.dart';
import 'unit_type_helpers.dart';
import 'validators/work_order_cost_calculator.dart';
import 'work_tile_candidacy/work_tile_candidacy.dart';

/// Selected Engineer + tile for a pending `build_road` Road-first gesture.
class DevelopmentRoadFirstCandidate {
  const DevelopmentRoadFirstCandidate({
    required this.engineerUnitId,
    required this.targetTileKey,
  });

  final String engineerUnitId;
  final String targetTileKey;

  WorkOrder toWorkOrder() => WorkOrder(
    unitId: engineerUnitId,
    target: kWorkTargetBuildRoad,
    targetTileKey: targetTileKey,
  );
}

/// Road-first affordance for the disconnected improve warn dialog.
class DevelopmentRoadFirstState {
  const DevelopmentRoadFirstState({
    required this.enabled,
    this.disabledReason,
    this.candidate,
  });

  final bool enabled;
  final String? disabledReason;
  final DevelopmentRoadFirstCandidate? candidate;
}

/// Idle Engineers with no pending work, stable unit-id order.
List<Unit> idleEngineersForDevelopmentAssign({
  required Game game,
  required String playerId,
  required Orders currentOrders,
}) {
  final pendingUnitIds = {
    for (final order in currentOrders.workOrdersByPlayerId[playerId] ?? const [])
      order.unitId,
  };
  final engineers = <Unit>[];
  for (final unit in [
    ...game.worldState.oldWorld.units,
    ...game.worldState.newWorld.units,
  ]) {
    if (unit.ownerId != playerId) continue;
    if (unit.type != kUnitTypeEngineer) continue;
    if (unit.status != UnitStatus.idle) continue;
    if (unit.currentWork != null) continue;
    if (pendingUnitIds.contains(unit.id)) continue;
    engineers.add(unit);
  }
  engineers.sort((a, b) => a.id.compareTo(b.id));
  return engineers;
}

List<String> _sortedNeighborTileKeys({
  required String tileKey,
  required Map<String, TileMapResult> tileMapByRegion,
  required Set<String> provinceNodeIds,
}) {
  final coords = parseTileKeyCoordinates(tileKey);
  if (coords == null) return const [];

  final map = tileMapByRegion[coords.regionId];
  if (map == null) return const [];

  final neighbors = <String>[];
  final w = map.width;
  final h = map.height;
  for (final d in kGridNeighborsCardinal4) {
    final nx = coords.x + d.$1;
    final ny = coords.y + d.$2;
    if (nx < 0 || nx >= w || ny < 0 || ny >= h) continue;
    final cellId = map.cell(nx, ny);
    final fullProvinceId = provinceNodeIds.contains(cellId)
        ? ProvinceId.full(coords.regionId, cellId)
        : (provinceNodeIds.contains(ProvinceId.full(coords.regionId, cellId))
              ? ProvinceId.full(coords.regionId, cellId)
              : null);
    if (fullProvinceId == null) continue;
    neighbors.add(
      CapitalTile.tileKey(coords.regionId, fullProvinceId, nx, ny),
    );
  }
  neighbors.sort();
  return neighbors;
}

bool _isOwnedPlayerTile({
  required Game game,
  required String playerId,
  required String tileKey,
}) {
  final provinceId = Unit.provinceIdFromTileKey(tileKey);
  if (provinceId == null) return false;
  final province = game.worldState.tryGetProvince(provinceId);
  return province?.ownerId == playerId;
}

/// Shortest owned-tile path from [startTileKey] to any [connectedTileKeys] tile.
///
/// Neighbor expansion uses stable tile-key ordering. Returns `null` when no path
/// exists on owned land tiles.
List<String>? shortestOwnedTilePathToConnectedNetwork({
  required Game game,
  required String playerId,
  required String startTileKey,
  required Set<String> connectedTileKeys,
  required Map<String, TileMapResult> tileMapByRegion,
  required MapTopology topology,
}) {
  if (connectedTileKeys.contains(startTileKey)) {
    return [startTileKey];
  }

  final landProvinceIds = provinceNodeIds(topology);
  final parent = <String, String?>{startTileKey: null};
  final queue = Queue<String>()..add(startTileKey);

  while (queue.isNotEmpty) {
    final current = queue.removeFirst();
    if (connectedTileKeys.contains(current)) {
      final path = <String>[];
      var walk = current;
      while (true) {
        path.insert(0, walk);
        final previous = parent[walk];
        if (previous == null) break;
        walk = previous;
      }
      return path;
    }

    for (final neighbor in _sortedNeighborTileKeys(
      tileKey: current,
      tileMapByRegion: tileMapByRegion,
      provinceNodeIds: landProvinceIds,
    )) {
      if (!_isOwnedPlayerTile(
        game: game,
        playerId: playerId,
        tileKey: neighbor,
      )) {
        continue;
      }
      if (parent.containsKey(neighbor)) continue;
      parent[neighbor] = current;
      queue.add(neighbor);
    }
  }
  return null;
}

bool _canAffordDevelopmentRoadFirst({
  required Game game,
  required String playerId,
  required Orders currentOrders,
  required DevelopmentRoadFirstCandidate candidate,
}) {
  final player = game.playerById(playerId);
  if (player == null) return false;

  final stockpile = effectiveStockpileAfterPendingDevelopmentMaterialWork(
    game: game,
    playerId: playerId,
    currentOrders: currentOrders,
  );
  final provinceId = Unit.provinceIdFromTileKey(candidate.targetTileKey);
  final province = provinceId == null
      ? null
      : game.worldState.tryGetProvince(provinceId);
  final cost = WorkOrderCostCalculator(game, playerId: playerId).calculateCost(
    kWorkTargetBuildRoad,
    candidate.targetTileKey,
    improvementLevel: game.worldState.tileState.improvementLevel(
      candidate.targetTileKey,
    ),
    fortLevel: province?.fortLevel ?? 0,
  );
  if (cost == null || cost.isEmpty) return true;
  return ProjectedCostEngine.canAffordWorkMaterialCost(stockpile, cost);
}

DevelopmentRoadFirstCandidate? selectDevelopmentRoadFirstCandidate({
  required Game game,
  required String playerId,
  required Orders currentOrders,
  required MapTopology topology,
  required Map<String, TileMapResult> tileMapByRegion,
  required String improveTargetTileKey,
  required Set<String> connectedTileKeys,
}) {
  if (connectedTileKeys.contains(improveTargetTileKey)) return null;

  final engineers = idleEngineersForDevelopmentAssign(
    game: game,
    playerId: playerId,
    currentOrders: currentOrders,
  );
  if (engineers.isEmpty) return null;

  final path = shortestOwnedTilePathToConnectedNetwork(
    game: game,
    playerId: playerId,
    startTileKey: improveTargetTileKey,
    connectedTileKeys: connectedTileKeys,
    tileMapByRegion: tileMapByRegion,
    topology: topology,
  );
  if (path == null || path.length < 2) return null;

  final view = buildPlayerView(game, topology, playerId);
  final validator = buildIncrementalCandidateValidator(
    game: game,
    topology: topology,
    playerId: playerId,
    baseOrders: currentOrders,
    tileMapByRegion: tileMapByRegion,
  );
  final resolution = orderResolutionContextFromView(view, game);

  final roadCandidates = <String>[
    for (var i = path.length - 2; i >= 0; i--) path[i],
  ];

  for (final engineer in engineers) {
    final validTiles = getValidWorkOrderTileKeysWithVisibility(
      game: game,
      topology: topology,
      view: view,
      unitId: engineer.id,
      workTarget: kWorkTargetBuildRoad,
      currentOrders: currentOrders,
      tileMapByRegion: tileMapByRegion,
      sharedCandidateValidator: validator,
      resolution: resolution,
    );
    for (final tileKey in roadCandidates) {
      if (!validTiles.contains(tileKey)) continue;
      return DevelopmentRoadFirstCandidate(
        engineerUnitId: engineer.id,
        targetTileKey: tileKey,
      );
    }
  }
  return null;
}

/// Resolves Road-first enablement for the disconnected improve warn dialog.
DevelopmentRoadFirstState resolveDevelopmentRoadFirstState({
  required Game game,
  required String playerId,
  required Orders currentOrders,
  required MapTopology topology,
  required Map<String, TileMapResult> tileMapByRegion,
  required String improveTargetTileKey,
  required Set<String> connectedTileKeys,
}) {
  final engineers = idleEngineersForDevelopmentAssign(
    game: game,
    playerId: playerId,
    currentOrders: currentOrders,
  );
  if (engineers.isEmpty) {
    return const DevelopmentRoadFirstState(
      enabled: false,
      disabledReason: 'No idle Engineers',
    );
  }

  final path = shortestOwnedTilePathToConnectedNetwork(
    game: game,
    playerId: playerId,
    startTileKey: improveTargetTileKey,
    connectedTileKeys: connectedTileKeys,
    tileMapByRegion: tileMapByRegion,
    topology: topology,
  );
  if (path == null) {
    return const DevelopmentRoadFirstState(
      enabled: false,
      disabledReason: 'No owned path to capital connection',
    );
  }

  final candidate = selectDevelopmentRoadFirstCandidate(
    game: game,
    playerId: playerId,
    currentOrders: currentOrders,
    topology: topology,
    tileMapByRegion: tileMapByRegion,
    improveTargetTileKey: improveTargetTileKey,
    connectedTileKeys: connectedTileKeys,
  );
  if (candidate == null) {
    return const DevelopmentRoadFirstState(
      enabled: false,
      disabledReason: 'No legal road step toward capital',
    );
  }

  if (!_canAffordDevelopmentRoadFirst(
    game: game,
    playerId: playerId,
    currentOrders: currentOrders,
    candidate: candidate,
  )) {
    return DevelopmentRoadFirstState(
      enabled: false,
      disabledReason: 'Insufficient materials',
      candidate: candidate,
    );
  }

  return DevelopmentRoadFirstState(enabled: true, candidate: candidate);
}
