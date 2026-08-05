// Shared scenario Games + host re-exports for `civilian_units_panel_part*`.
//
// The three part files previously inlined ~14 near-identical `Game(` builders
// (OW Alpha province + one/few civilians). Named factories below keep each
// part file's assertions local while scenario wiring lives once (Refs #4021).
//
// SPEC: SPEC/ui/civilian-units-panel.md, SPEC/program/repo-lint.md.

import 'package:colonizethis_logic/colonizethis_logic.dart'
    show
        kUnitTypeBuilder,
        kUnitTypeEngineer,
        kUnitTypeSpy,
        kWorkTargetBuildImprovement,
        kWorkTargetCounterSpy;
import 'package:colonizethis_models/colonizethis_models.dart';

import 'panel_fixtures/core.dart';

export 'diplomacy_panel_test_support.dart'
    show
        CivilianPanelBusDialogHost,
        buildCivilianPanel;
export 'panel_fixtures/civilian.dart' show buildCivilianPanelTestGame;

/// Idle civilian [Unit] at [tileKey] in [provinceId].
Unit civilianIdleUnit({
  required String id,
  required String type,
  required String ownerId,
  required String provinceId,
  required String tileKey,
}) {
  return Unit(
    id: id,
    type: type,
    ownerId: ownerId,
    locationProvinceId: provinceId,
    tileKey: tileKey,
  );
}

/// OW civilian mini-game: one province (plus optional extras) and [units].
Game buildCivilianOwUnitsGame({
  required String id,
  String humanId = 'h1',
  String humanDisplayName = 'Human',
  String provinceId = 'oldWorld|p1',
  String provinceDisplayName = 'Alpha',
  int? fortLevel,
  required List<Unit> units,
  List<Province> extraProvinces = const [],
  Map<String, String> resourceByTileKey = const {},
  Map<String, Map<String, List<String>>> tileKeysByRegionAndProvince =
      const {},
}) {
  return buildPanelTestGame(
    id: id,
    players: [
      Player(id: humanId, displayName: humanDisplayName, isHuman: true),
    ],
    oldWorldProvinces: [
      Province(
        id: provinceId,
        regionId: 'oldWorld',
        displayName: provinceDisplayName,
        fortLevel: fortLevel ?? 0,
      ),
      ...extraProvinces,
    ],
    oldWorldUnits: units,
    resourceByTileKey: resourceByTileKey,
    tileKeysByRegionAndProvince: tileKeysByRegionAndProvince,
  );
}

/// Explorer + builder (or builder + explorer) on one OW tile for shortcut modes.
Game buildCivilianExplorerBuilderShortcutGame({
  required String id,
  String humanId = 'h1',
  String tileKey = 'oldWorld|p1|0|0',
  bool builderFirst = false,
}) {
  const provinceId = 'oldWorld|p1';
  final explorer = civilianIdleUnit(
    id: 'e1',
    type: kUnitTypeExplorer,
    ownerId: humanId,
    provinceId: provinceId,
    tileKey: tileKey,
  );
  final builder = civilianIdleUnit(
    id: 'b1',
    type: kUnitTypeBuilder,
    ownerId: humanId,
    provinceId: provinceId,
    tileKey: tileKey,
  );
  return buildCivilianOwUnitsGame(
    id: id,
    humanId: humanId,
    units: builderFirst ? [builder, explorer] : [explorer, builder],
  );
}

/// Engineer + builder on one OW tile for build-road shortcut mode.
Game buildCivilianEngineerBuilderShortcutGame({
  required String id,
  String humanId = 'h1',
  String tileKey = 'oldWorld|p1|0|0',
  bool engineerFirst = false,
}) {
  const provinceId = 'oldWorld|p1';
  final engineer = civilianIdleUnit(
    id: 'e_eng',
    type: kUnitTypeEngineer,
    ownerId: humanId,
    provinceId: provinceId,
    tileKey: tileKey,
  );
  final builder = civilianIdleUnit(
    id: 'b1',
    type: kUnitTypeBuilder,
    ownerId: humanId,
    provinceId: provinceId,
    tileKey: tileKey,
  );
  return buildCivilianOwUnitsGame(
    id: id,
    humanId: humanId,
    units: engineerFirst ? [engineer, builder] : [builder, engineer],
  );
}

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
        stockpile: const Stockpile(
          quantities: {'lumber': 1, 'castIron': 1},
        ),
      ),
    ],
    oldWorldProvinces: [
      Province(
        id: provinceId,
        regionId: 'oldWorld',
        displayName: 'Alpha',
      ),
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
      'oldWorld': {provinceId: [tileA, tileB]},
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
      Province(
        id: 'oldWorld|p2',
        regionId: 'oldWorld',
        displayName: 'Beta',
      ),
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
      WorkOrder(
        unitId: unitId,
        target: target,
        targetTileKey: targetTileKey,
      ),
    ],
  );
}

/// Human Spy on owned or foreign OW province (Refs #4219).
Game buildCivilianSpyFixtureGame({
  required String id,
  String humanId = 'h1',
  String rivalId = 'gp2',
  String spyId = 'spy1',
  bool foreignStation = false,
  String homeTileKey = 'oldWorld|p1|0|0',
  String foreignTileKey = 'oldWorld|p2|0|0',
}) {
  final tileKey = foreignStation ? foreignTileKey : homeTileKey;
  final provinceId = foreignStation ? 'oldWorld|p2' : 'oldWorld|p1';
  return buildPanelTestGame(
    id: id,
    players: [
      Player(id: humanId, displayName: 'Human', isHuman: true),
      Player(id: rivalId, displayName: 'Rival', isHuman: false),
    ],
    oldWorldProvinces: [
      Province(
        id: 'oldWorld|p1',
        regionId: 'oldWorld',
        displayName: 'Home',
        ownerId: humanId,
      ),
      Province(
        id: 'oldWorld|p2',
        regionId: 'oldWorld',
        displayName: 'Rival Land',
        ownerId: rivalId,
      ),
    ],
    oldWorldUnits: [
      Unit(
        id: spyId,
        type: kUnitTypeSpy,
        ownerId: humanId,
        locationProvinceId: provinceId,
        tileKey: tileKey,
      ),
    ],
  );
}

/// Pending counter-spy [WorkOrder] for [spyId].
Orders civilianSpyPendingCounterSpyOrder({
  required String humanId,
  required String spyId,
  required String targetTileKey,
}) {
  return civilianSinglePendingWorkOrder(
    humanId: humanId,
    unitId: spyId,
    target: kWorkTargetCounterSpy,
    targetTileKey: targetTileKey,
  );
}

/// Pending civilian [MoveOrder] for Spy [spyId] (Refs #4219).
Orders civilianSpyPendingMoveOrder({
  required String humanId,
  required String spyId,
  required String destinationTileKey,
}) {
  return Orders(
    moveOrdersByPlayerId: {
      humanId: [
        MoveOrder(unitId: spyId, destinationTileKey: destinationTileKey),
      ],
    },
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
