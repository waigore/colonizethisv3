import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_world/colonizethis_world.dart';

import 'orders_application_build_phase.dart';
import 'orders_application_context.dart';
import 'orders_application_helpers.dart';
import 'orders_application_work_phase.dart';
import 'orders_application_worker_pool_phase.dart';
import 'orders_application_work_units.dart';

/// Order application helpers for build and work phases.
/// SPEC/program/orders.md

/// Returns a new [Game] with [unitId]'s in-progress work cleared (currentWork
/// null, status idle). No material refund. SPEC/program/development-resolution.md
/// § Player-initiated cancel. Returns [game] unchanged if unit not found or
/// has no currentWork.
Game clearUnitCurrentWork(Game game, String unitId) {
  final ws = game.worldState;
  final unit = ws.tryGetUnitById(unitId);
  if (unit == null || unit.currentWork == null) return game;
  final regionId = ws.tryGetRegionIdForUnit(unit);
  if (regionId == null) return game;
  final cleared = cancelUnitWork(unit);
  final updatedWs = ws.mapBothRegions((rid, region) {
    if (rid != regionId) return region;
    final list = region.units.map((u) => u.id == unitId ? cleared : u).toList();
    return RegionData(provinces: region.provinces, units: list);
  });
  return game.withWorldState(updatedWs);
}

/// Applies BuildUnitOrder and WorkOrder for all players in [game].
///
/// When [topology] is provided, ship builds spawn in home fleet.
/// When [onDialogue] is provided, reactive dialogue (e.g. forts_on_border) may be emitted for AI leaders.
/// BuildUnitOrder is applied by unit type category (civilian / military / naval) per buildUnitCategoryForUnitType.
/// - Civilian: deduct treasury + paper, add unit with tileKey.
/// - Military: deduct cost + worker, add unit.
/// - Naval: deduct cost + one peasant, add ship to home fleet at capital port.
/// - WorkOrder: sets the unit status to working; no terrain change yet.
Game applyBuildAndWorkOrders(
  Game game,
  Orders orders, {
  MapTopology? topology,
  Map<String, TileMapResult>? tileMapByRegion,
  void Function(DialogueEvent)? onDialogue,
  WorkOrderTraceCallback? onWorkOrderTrace,
}) {
  final recruitWorkerOrders = orders.recruitWorkerOrdersByPlayerId;
  final buildOrders = orders.buildUnitOrdersByPlayerId;
  final workOrders = orders.workOrdersByPlayerId;
  if (recruitWorkerOrders.isEmpty &&
      buildOrders.isEmpty &&
      workOrders.isEmpty) {
    return game;
  }

  final initialProvincesByRegion = game.worldState
      .mutableProvinceListsByRegion();
  final work = WorkOrderState(
    unitsById: (
      oldWorld: copyUnitsById(unitsByIdFromRegion(game.worldState.oldWorld)),
      newWorld: copyUnitsById(unitsByIdFromRegion(game.worldState.newWorld)),
    ),
    tileState: game.worldState.tileState,
    visibilityByTile: Map<String, Map<String, String>>.from(
      game.worldState.playerVisibilityByTile.map(
        (k, v) => MapEntry(k, Map<String, String>.from(v)),
      ),
    ),
    portsByProvinceSeaboard: Map<String, String>.from(
      game.worldState.portsByProvinceSeaboard,
    ),
    purchasedTilesByTileKey: Map<String, String>.from(
      game.worldState.purchasedTilesByTileKey,
    ),
    oldProvinces: initialProvincesByRegion[kRegionOldWorld]!,
    newProvinces: initialProvincesByRegion[kRegionNewWorld]!,
  );
  var state = BuildWorkState(
    game: game,
    recruitWorkerOrders: recruitWorkerOrders,
    buildOrders: buildOrders,
    workOrders: workOrders,
    topology: topology,
    tileMapByRegion: tileMapByRegion,
    onDialogue: onDialogue,
    onWorkOrderTrace: onWorkOrderTrace,
    work: work,
  );

  // Worker pool sub-phase runs before unit builds so any recruit / train
  // peasant consumes settle before military / naval builds re-evaluate the
  // peasant pool (SPEC/program/turn-resolution-phase-details.md § Build /
  // work).
  state = runWorkerPoolPhase(state);
  state = runBuildPhase(state);
  state = runWorkPhase(
    state,
    applyExploreCompletionForWorkUnit,
    applyCompletedWorkTargetForWorkUnit,
  );

  state = processWorkUnitsInRegion(
    state,
    true,
    () => state.work.oldProvinces,
    (w, p) => w.copyWith(oldProvinces: p),
  );
  state = processWorkUnitsInRegion(
    state,
    false,
    () => state.work.newProvinces,
    (w, p) => w.copyWith(newProvinces: p),
  );

  final provincesByRegion = <String, List<Province>>{
    kRegionOldWorld: state.work.oldProvinces,
    kRegionNewWorld: state.work.newProvinces,
  };
  final unitsByRegion = <String, List<Unit>>{
    kRegionOldWorld: state.work.unitsById.oldWorld.values.toList(),
    kRegionNewWorld: state.work.unitsById.newWorld.values.toList(),
  };
  var nextWorldState = state.game.worldState.copyWith(
    tileState: state.work.tileState,
    playerVisibilityByTile: state.work.visibilityByTile,
    portsByProvinceSeaboard: state.work.portsByProvinceSeaboard,
    purchasedTilesByTileKey: state.work.purchasedTilesByTileKey,
  );
  nextWorldState = nextWorldState.updateRegionById(
    kRegionOldWorld,
    (_) => RegionData(
      provinces: provincesByRegion[kRegionOldWorld]!,
      units: unitsByRegion[kRegionOldWorld]!,
    ),
  );
  nextWorldState = nextWorldState.updateRegionById(
    kRegionNewWorld,
    (_) => RegionData(
      provinces: provincesByRegion[kRegionNewWorld]!,
      units: unitsByRegion[kRegionNewWorld]!,
    ),
  );

  final nextWorldStateForWork = nextWorldState
      .copyWith(purchasedTilesByTileKey: state.work.purchasedTilesByTileKey)
      .mapBothRegionUnits(
        (regionId, _) => unitsByRegion[regionId] ?? const <Unit>[],
      );

  return state.game.copyWith(
    players: state.work.updatedPlayers,
    worldState: nextWorldStateForWork,
  );
}
