// Civilian pending-work and dual-builder Games (Refs #4606 Slice D).

import 'package:colonizethis_logic/colonizethis_logic.dart'
    show kUnitTypeBuilder, kWorkTargetBuildImprovement;
import 'package:colonizethis_models/colonizethis_models.dart';

import 'civilian_units_panel_test_support.dart'
    show buildCivilianOwUnitsGame, civilianIdleUnit;
import 'panel_fixtures/core.dart';

/// Two builders on OW Alpha with grain tiles and minimal lumber/cast iron
/// stockpile for pending-order affordance scenarios (Refs #4262).
Game buildCivilianDualBuilderLowStockGame({
  required String id,
  String humanId = 'h1',
}) {
  const provinceId = 'oldWorld|p1';
  const tileA = 'oldWorld|p1|0|0';
  const tileB = 'oldWorld|p1|1|0';
  return buildPanelTestGame(
    id: id,
    players: [
      Player(
        id: humanId,
        displayName: 'Human',
        isHuman: true,
        stockpile: const Stockpile(quantities: {'lumber': 1, 'castIron': 1}),
      ),
    ],
    oldWorldProvinces: [
      Province(id: provinceId, regionId: 'oldWorld', displayName: 'Alpha'),
    ],
    oldWorldUnits: [
      civilianIdleUnit(
        id: 'b1',
        type: kUnitTypeBuilder,
        ownerId: humanId,
        provinceId: provinceId,
        tileKey: tileA,
      ),
      civilianIdleUnit(
        id: 'b2',
        type: kUnitTypeBuilder,
        ownerId: humanId,
        provinceId: provinceId,
        tileKey: tileA,
      ),
    ],
    tileKeysByRegionAndProvince: {
      'oldWorld': {
        provinceId: [tileA, tileB],
      },
    },
    playerVisibilityByTile: {
      humanId: {tileA: 'fullyVisible', tileB: 'fullyVisible'},
    },
    resourceByTileKey: {tileA: 'grain', tileB: 'grain'},
  );
}

/// Single civilian on OW Alpha (locate / pending-cost scenarios).
Game buildCivilianSingleUnitOwGame({
  required String id,
  required String unitId,
  required String unitType,
  String humanId = 'h1',
  String tileKey = 'oldWorld|p1|0|0',
  String provinceId = 'oldWorld|p1',
  Map<String, String> resourceByTileKey = const {},
  UnitStatus status = UnitStatus.idle,
  CurrentWork? currentWork,
}) {
  return buildCivilianOwUnitsGame(
    id: id,
    humanId: humanId,
    provinceId: provinceId,
    resourceByTileKey: resourceByTileKey,
    units: [
      Unit(
        id: unitId,
        type: unitType,
        ownerId: humanId,
        locationProvinceId: provinceId,
        tileKey: tileKey,
        status: status,
        currentWork: currentWork,
      ),
    ],
  );
}

/// Builder on Alpha with pending projection onto Beta.
Game buildCivilianPendingProjectionGame({
  String id = 'g_pending_projection',
  String humanId = 'gp1',
  String standingTile = 'oldWorld|p1|0|0',
  String unitId = 'u1',
}) {
  return buildCivilianOwUnitsGame(
    id: id,
    humanId: humanId,
    units: [
      civilianIdleUnit(
        id: unitId,
        type: kUnitTypeBuilder,
        ownerId: humanId,
        provinceId: 'oldWorld|p1',
        tileKey: standingTile,
      ),
    ],
    extraProvinces: const [
      Province(id: 'oldWorld|p2', regionId: 'oldWorld', displayName: 'Beta'),
    ],
  );
}

/// Pending [WorkOrder] list for [humanId].
Orders civilianPendingWorkOrders({
  required String humanId,
  required List<WorkOrder> workOrders,
}) {
  return Orders(workOrdersByPlayerId: {humanId: workOrders});
}

/// Convenience pending work order for a single unit/target/tile.
Orders civilianSinglePendingWorkOrder({
  required String humanId,
  required String unitId,
  required String target,
  required String targetTileKey,
}) {
  return civilianPendingWorkOrders(
    humanId: humanId,
    workOrders: [
      WorkOrder(unitId: unitId, target: target, targetTileKey: targetTileKey),
    ],
  );
}

/// In-progress builder row (no pending cost icons).
Game buildCivilianWorkingBuilderGame({
  String id = 'g_civ_working',
  String humanId = 'h1',
  String tileKey = 'oldWorld|p1|0|0',
}) {
  return buildCivilianSingleUnitOwGame(
    id: id,
    humanId: humanId,
    unitId: 'b1',
    unitType: kUnitTypeBuilder,
    tileKey: tileKey,
    status: UnitStatus.working,
    currentWork: CurrentWork(
      workTarget: kWorkTargetBuildImprovement,
      tileKey: tileKey,
      totalTurns: 5,
      remainingTurns: 2,
    ),
  );
}
