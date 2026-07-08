// Compact applyBuildAndWorkOrders work-order application assertions (Refs #3949 wave 3).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'orders_application_test_support.dart';

/// Pins for [workOrderApplicationScenarios] rows.
enum WorkOrderApplicationTarget {
  prospectAddsTilePlayerProspectedTilesWhenTerrainEligible,
  prospectOnNonMineralEligibleTerrainDoesNotAddTile,
  prospectAddsTileWhenMineralResourcePresentWithoutTileMap,
  prospectDoesNotAddTileWhenNonMineralResourcePresentWithoutTileMap,
  buildImprovementWorkOrderSetsCurrentWorkThenCompletesWhenTotalTurns1,
  buildFortAssignsCurrentWorkTotalTurnsFromTotalTurnsForWorkFortLevel,
  counterSpyWorkOrderSetsCurrentWorkForSpyUnit,
  purchaseLandSuccessTreasuryDeductedTileRecordedPurchasedTilesByTileKey,
  purchaseLandRejectedWhenNoEmbassyWithProvinceOwnerMinorTribe,
  purchaseLandRejectedWhenAtWarWithProvinceOwnerMinorTribe,
  purchaseLandSameTileByTwoGPsFirstWinsSecondDoesNotDeductOverwrite,
  buildFortWithSufficientMaterialsDeductsMaterials,
  buildFortLevel2SkippedWithoutMineEngineering,
  buildFortLevel3SkippedWithoutModernForts,
  upgradeTownCompletionIncreasesProvinceTownDevelopmentLevel,
  counterSpyProcessWorkKeepsOngoingAssignmentWithoutKillingBuildWork,
  unknownWorkTargetSkippedUnitStaysIdle,
  buildRoadWithInsufficientMaterialsDoesNotSetCurrentWorkDeductStockpile,
  buildRoadWithSufficientMaterialsDeductsMaterialsSetsCurrentWork,
  counterSpyWorkOrderSetsCurrentWorkForSpyUnitOnOwnedCapitalProvince,
  exploreWorkOrderSetsCurrentWorkWhenProvinceHasTiles,
  exploreWorkOrderTotalTurnsUsesRegionScopedFormulaCeil3TilesInPMaxTilesInRegion,
  engineerBuildRoadWorkOrderSetsCurrentWork,
  buildPortWorkOrderSetsCurrentWorkWhenMaterialsSufficient,
}

void runWorkOrderApplicationExpectation(WorkOrderApplicationTarget target) {
  switch (target) {
    case WorkOrderApplicationTarget
        .prospectAddsTilePlayerProspectedTilesWhenTerrainEligible:
      _prospectAddsTilePlayerProspectedTilesWhenTerrainEligible();
    case WorkOrderApplicationTarget
        .prospectOnNonMineralEligibleTerrainDoesNotAddTile:
      _prospectOnNonMineralEligibleTerrainDoesNotAddTile();
    case WorkOrderApplicationTarget
        .prospectAddsTileWhenMineralResourcePresentWithoutTileMap:
      _prospectAddsTileWhenMineralResourcePresentWithoutTileMap();
    case WorkOrderApplicationTarget
        .prospectDoesNotAddTileWhenNonMineralResourcePresentWithoutTileMap:
      _prospectDoesNotAddTileWhenNonMineralResourcePresentWithoutTileMap();
    case WorkOrderApplicationTarget
        .buildImprovementWorkOrderSetsCurrentWorkThenCompletesWhenTotalTurns1:
      _buildImprovementWorkOrderSetsCurrentWorkThenCompletesWhenTotalTurns1();
    case WorkOrderApplicationTarget
        .buildFortAssignsCurrentWorkTotalTurnsFromTotalTurnsForWorkFortLevel:
      _buildFortAssignsCurrentWorkTotalTurnsFromTotalTurnsForWorkFortLevel();
    case WorkOrderApplicationTarget
        .counterSpyWorkOrderSetsCurrentWorkForSpyUnit:
      _counterSpyWorkOrderSetsCurrentWorkForSpyUnit();
    case WorkOrderApplicationTarget
        .purchaseLandSuccessTreasuryDeductedTileRecordedPurchasedTilesByTileKey:
      _purchaseLandSuccessTreasuryDeductedTileRecordedPurchasedTilesByTileKey();
    case WorkOrderApplicationTarget
        .purchaseLandRejectedWhenNoEmbassyWithProvinceOwnerMinorTribe:
      _purchaseLandRejectedWhenNoEmbassyWithProvinceOwnerMinorTribe();
    case WorkOrderApplicationTarget
        .purchaseLandRejectedWhenAtWarWithProvinceOwnerMinorTribe:
      _purchaseLandRejectedWhenAtWarWithProvinceOwnerMinorTribe();
    case WorkOrderApplicationTarget
        .purchaseLandSameTileByTwoGPsFirstWinsSecondDoesNotDeductOverwrite:
      _purchaseLandSameTileByTwoGPsFirstWinsSecondDoesNotDeductOverwrite();
    case WorkOrderApplicationTarget
        .buildFortWithSufficientMaterialsDeductsMaterials:
      _buildFortWithSufficientMaterialsDeductsMaterials();
    case WorkOrderApplicationTarget
        .buildFortLevel2SkippedWithoutMineEngineering:
      _buildFortLevel2SkippedWithoutMineEngineering();
    case WorkOrderApplicationTarget.buildFortLevel3SkippedWithoutModernForts:
      _buildFortLevel3SkippedWithoutModernForts();
    case WorkOrderApplicationTarget
        .upgradeTownCompletionIncreasesProvinceTownDevelopmentLevel:
      _upgradeTownCompletionIncreasesProvinceTownDevelopmentLevel();
    case WorkOrderApplicationTarget
        .counterSpyProcessWorkKeepsOngoingAssignmentWithoutKillingBuildWork:
      _counterSpyProcessWorkKeepsOngoingAssignmentWithoutKillingBuildWork();
    case WorkOrderApplicationTarget.unknownWorkTargetSkippedUnitStaysIdle:
      _unknownWorkTargetSkippedUnitStaysIdle();
    case WorkOrderApplicationTarget
        .buildRoadWithInsufficientMaterialsDoesNotSetCurrentWorkDeductStockpile:
      _buildRoadWithInsufficientMaterialsDoesNotSetCurrentWorkDeductStockpile();
    case WorkOrderApplicationTarget
        .buildRoadWithSufficientMaterialsDeductsMaterialsSetsCurrentWork:
      _buildRoadWithSufficientMaterialsDeductsMaterialsSetsCurrentWork();
    case WorkOrderApplicationTarget
        .counterSpyWorkOrderSetsCurrentWorkForSpyUnitOnOwnedCapitalProvince:
      _counterSpyWorkOrderSetsCurrentWorkForSpyUnitOnOwnedCapitalProvince();
    case WorkOrderApplicationTarget
        .exploreWorkOrderSetsCurrentWorkWhenProvinceHasTiles:
      _exploreWorkOrderSetsCurrentWorkWhenProvinceHasTiles();
    case WorkOrderApplicationTarget
        .exploreWorkOrderTotalTurnsUsesRegionScopedFormulaCeil3TilesInPMaxTilesInRegion:
      _exploreWorkOrderTotalTurnsUsesRegionScopedFormulaCeil3TilesInPMaxTilesInRegion();
    case WorkOrderApplicationTarget.engineerBuildRoadWorkOrderSetsCurrentWork:
      _engineerBuildRoadWorkOrderSetsCurrentWork();
    case WorkOrderApplicationTarget
        .buildPortWorkOrderSetsCurrentWorkWhenMaterialsSufficient:
      _buildPortWorkOrderSetsCurrentWorkWhenMaterialsSufficient();
  }
}

void _prospectAddsTilePlayerProspectedTilesWhenTerrainEligible() {
  const ow = OrdersApplicationTestSupport.ow;
  const provinceId = OrdersApplicationTestSupport.provinceId;
  const tileKey = OrdersApplicationTestSupport.tileKey;
  final unit = Unit(
    id: 'u1',
    type: kUnitTypeExplorer,
    ownerId: 'p1',
    locationProvinceId: provinceId,
    tileKey: tileKey,
  );
  final game = OrdersApplicationTestSupport.workOrderApplicationGame(
    provinces: [Province(id: provinceId, regionId: ow, ownerId: 'p1')],
    units: [unit],
  );
  final orders = Orders(
    workOrdersByPlayerId: {
      'p1': [
        WorkOrder(
          unitId: 'u1',
          target: kWorkTargetProspect,
          targetTileKey: tileKey,
        ),
      ],
    },
  );
  final next = applyBuildAndWorkOrders(
    game,
    orders,
    tileMapByRegion: {
      ow: OrdersApplicationTestSupport.tileMapWithTerrain(TerrainType.hills),
    },
  );
  expect(next.worldState.playerProspectedTiles['p1'], contains(tileKey));
  final explorerAfter = next.worldState.oldWorld.units.single;
  expect(explorerAfter.tileKey, tileKey);
  expect(explorerAfter.status, UnitStatus.idle);
  expect(explorerAfter.currentWork, isNull);
  expect(explorerAfter.originTileKey, isNull);
  expect(explorerAfter.assignedTileKey, isNull);
}

void _prospectOnNonMineralEligibleTerrainDoesNotAddTile() {
  const ow = OrdersApplicationTestSupport.ow;
  const provinceId = OrdersApplicationTestSupport.provinceId;
  const tileKey = OrdersApplicationTestSupport.tileKey;
  final unit = Unit(
    id: 'u1',
    type: kUnitTypeExplorer,
    ownerId: 'p1',
    locationProvinceId: provinceId,
    tileKey: tileKey,
  );
  final game = OrdersApplicationTestSupport.workOrderApplicationGame(
    provinces: [Province(id: provinceId, regionId: ow, ownerId: 'p1')],
    units: [unit],
  );
  final orders = Orders(
    workOrdersByPlayerId: {
      'p1': [
        WorkOrder(
          unitId: 'u1',
          target: kWorkTargetProspect,
          targetTileKey: tileKey,
        ),
      ],
    },
  );
  final next = applyBuildAndWorkOrders(
    game,
    orders,
    tileMapByRegion: {
      ow: OrdersApplicationTestSupport.tileMapWithTerrain(TerrainType.plains),
    },
  );
  final prospected =
      next.worldState.playerProspectedTiles['p1'] ?? const <String>{};
  expect(prospected, isNot(contains(tileKey)));
}

void _prospectAddsTileWhenMineralResourcePresentWithoutTileMap() {
  const ow = OrdersApplicationTestSupport.ow;
  const provinceId = OrdersApplicationTestSupport.provinceId;
  const tileKey = OrdersApplicationTestSupport.tileKey;
  final unit = Unit(
    id: 'u1',
    type: kUnitTypeExplorer,
    ownerId: 'p1',
    locationProvinceId: provinceId,
    tileKey: tileKey,
  );
  final game = OrdersApplicationTestSupport.workOrderApplicationGame(
    provinces: [Province(id: provinceId, regionId: ow, ownerId: 'p1')],
    units: [unit],
    resourceByTileKey: {tileKey: 'iron'},
  );
  final orders = Orders(
    workOrdersByPlayerId: {
      'p1': [
        WorkOrder(
          unitId: 'u1',
          target: kWorkTargetProspect,
          targetTileKey: tileKey,
        ),
      ],
    },
  );

  final next = applyBuildAndWorkOrders(game, orders);
  expect(next.worldState.playerProspectedTiles['p1'], contains(tileKey));
}

void _prospectDoesNotAddTileWhenNonMineralResourcePresentWithoutTileMap() {
  const ow = OrdersApplicationTestSupport.ow;
  const provinceId = OrdersApplicationTestSupport.provinceId;
  const tileKey = OrdersApplicationTestSupport.tileKey;
  final unit = Unit(
    id: 'u1',
    type: kUnitTypeExplorer,
    ownerId: 'p1',
    locationProvinceId: provinceId,
    tileKey: tileKey,
  );
  final game = OrdersApplicationTestSupport.workOrderApplicationGame(
    provinces: [Province(id: provinceId, regionId: ow, ownerId: 'p1')],
    units: [unit],
    resourceByTileKey: {tileKey: 'grain'},
  );
  final orders = Orders(
    workOrdersByPlayerId: {
      'p1': [
        WorkOrder(
          unitId: 'u1',
          target: kWorkTargetProspect,
          targetTileKey: tileKey,
        ),
      ],
    },
  );

  final next = applyBuildAndWorkOrders(game, orders);
  final prospected =
      next.worldState.playerProspectedTiles['p1'] ?? const <String>{};
  expect(prospected, isNot(contains(tileKey)));
}

void _buildImprovementWorkOrderSetsCurrentWorkThenCompletesWhenTotalTurns1() {
  const ow = OrdersApplicationTestSupport.ow;
  const provinceId = OrdersApplicationTestSupport.provinceId;
  const tileKey = OrdersApplicationTestSupport.tileKey;
  final unit = Unit(
    id: 'u1',
    type: kUnitTypeBuilder,
    ownerId: 'p1',
    locationProvinceId: provinceId,
    tileKey: tileKey,
  );
  final cost = workOrderCostBuildImprovement(0);
  final game = OrdersApplicationTestSupport.workOrderApplicationGame(
    provinces: [Province(id: provinceId, regionId: ow, ownerId: 'p1')],
    units: [unit],
    resourceByTileKey: {tileKey: 'grain'},
    players: [
      Player(
        id: 'p1',
        displayName: 'P1',
        isHuman: true,
        stockpile: OrdersApplicationTestSupport.stockpileCovering(cost),
      ),
    ],
  );
  final orders = Orders(
    workOrdersByPlayerId: {
      'p1': [
        WorkOrder(
          unitId: 'u1',
          target: kWorkTargetBuildImprovement,
          targetTileKey: tileKey,
        ),
      ],
    },
  );
  final next = applyBuildAndWorkOrders(game, orders);
  final u = next.worldState.oldWorld.units.single;
  // totalTurns=1 for build_improvement at level 0, so work completes in same phase; unit is idle and tile improved.
  expect(u.currentWork, isNull);
  expect(u.status, UnitStatus.idle);
  expect(next.worldState.tileState.improvementLevel(tileKey), 1);
}

void _buildFortAssignsCurrentWorkTotalTurnsFromTotalTurnsForWorkFortLevel() {
  const ow = OrdersApplicationTestSupport.ow;
  const provinceId = OrdersApplicationTestSupport.provinceId;
  const tileKey = OrdersApplicationTestSupport.tileKey;
  final unit = Unit(
    id: 'u1',
    type: kUnitTypeEngineer,
    ownerId: 'p1',
    locationProvinceId: provinceId,
    tileKey: tileKey,
  );
  final cost = workOrderCostBuildFort(1);
  final game = OrdersApplicationTestSupport.workOrderApplicationGame(
    provinces: [
      Province(id: provinceId, regionId: ow, ownerId: 'p1', fortLevel: 1),
    ],
    units: [unit],
    players: [
      Player(
        id: 'p1',
        displayName: 'P1',
        isHuman: true,
        stockpile: OrdersApplicationTestSupport.stockpileCovering(cost),
        techUnlocked: const {kTechIdMineEngineering: true},
      ),
    ],
  );
  final orders = Orders(
    workOrdersByPlayerId: {
      'p1': [
        WorkOrder(
          unitId: 'u1',
          target: kWorkTargetBuildFort,
          targetTileKey: tileKey,
        ),
      ],
    },
  );
  final next = applyBuildAndWorkOrders(game, orders);
  final u = next.worldState.oldWorld.units.single;
  expect(
    u.currentWork!.totalTurns,
    totalTurnsForWork(kWorkTargetBuildFort, fortLevel: 1),
  );
  expect(u.currentWork!.remainingTurns, 1);
  expect(u.originTileKey, tileKey);
  expect(u.assignedTileKey, tileKey);
  expect(next.worldState.oldWorld.provinces.single.fortLevel, 1);
}

void _counterSpyWorkOrderSetsCurrentWorkForSpyUnit() {
  const ow = OrdersApplicationTestSupport.ow;
  const provinceId = OrdersApplicationTestSupport.provinceId;
  const tileKey = OrdersApplicationTestSupport.tileKey;
  final unit = Unit(
    id: 'spy1',
    type: kUnitTypeSpy,
    ownerId: 'p1',
    locationProvinceId: provinceId,
    tileKey: tileKey,
  );
  final game = OrdersApplicationTestSupport.workOrderApplicationGame(
    provinces: [Province(id: provinceId, regionId: ow, ownerId: 'p2')],
    units: [unit],
    players: const [
      Player(id: 'p1', displayName: 'P1', isHuman: true),
      Player(id: 'p2', displayName: 'P2', isHuman: true),
    ],
  );
  final orders = Orders(
    workOrdersByPlayerId: {
      'p1': [
        WorkOrder(
          unitId: 'spy1',
          target: kWorkTargetCounterSpy,
          targetTileKey: tileKey,
        ),
      ],
    },
  );
  final next = applyBuildAndWorkOrders(game, orders);
  final spyAfter = next.worldState.oldWorld.units.single;
  expect(spyAfter.currentWork, isNotNull);
  expect(spyAfter.currentWork!.workTarget, kWorkTargetCounterSpy);
  expect(spyAfter.currentWork!.totalTurns, 0);
  expect(spyAfter.currentWork!.remainingTurns, 1);
}

void _purchaseLandSuccessTreasuryDeductedTileRecordedPurchasedTilesByTileKey() {
  const ow = OrdersApplicationTestSupport.ow;
  const provinceId = OrdersApplicationTestSupport.provinceId;
  const tileKey = OrdersApplicationTestSupport.tileKey;
  const minorProvinceId = 'oldWorld|M1';
  const tileKeyMinor = 'oldWorld|M1|0|0';
  const cost = 15 * 10; // grain base price 10
  final unit = Unit(
    id: 'merchant1',
    type: kUnitTypeMerchant,
    ownerId: 'p1',
    locationProvinceId: minorProvinceId,
    tileKey: tileKeyMinor,
  );
  final game = Game(
    id: 'g',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
      oldWorld: RegionData(
        provinces: [
          Province(id: provinceId, regionId: ow, ownerId: 'p1'),
          Province(id: minorProvinceId, regionId: ow, ownerId: 'minor1'),
        ],
        units: [unit],
      ),
      newWorld: const RegionData(),
      resourceByTileKey: {tileKeyMinor: 'grain'},
      tileKeysByRegionAndProvince: {
        ow: {
          provinceId: [tileKey],
          minorProvinceId: [tileKeyMinor],
        },
      },
    ),
    players: [
      Player(id: 'p1', displayName: 'P1', isHuman: true, treasury: cost + 100),
    ],
    minorNations: const [MinorNation(id: 'minor1', displayName: 'Minor 1')],
    overtureStates: const [
      OvertureState(
        gpId: 'p1',
        targetId: 'minor1',
        stage: OvertureStage.embassy,
        sinceTurn: 0,
      ),
    ],
  );
  final orders = Orders(
    workOrdersByPlayerId: {
      'p1': [
        const WorkOrder(
          unitId: 'merchant1',
          target: kWorkTargetPurchaseLand,
          targetTileKey: tileKeyMinor,
        ),
      ],
    },
  );
  final next = applyBuildAndWorkOrders(game, orders);
  expect(next.worldState.purchasedTilesByTileKey[tileKeyMinor], 'p1');
  expect(next.players.single.treasury, game.players.single.treasury - cost);
  final merchantAfter = next.worldState.oldWorld.units.single;
  expect(merchantAfter.tileKey, tileKeyMinor);
  expect(merchantAfter.status, UnitStatus.idle);
  expect(merchantAfter.currentWork, isNull);
  expect(merchantAfter.originTileKey, isNull);
  expect(merchantAfter.assignedTileKey, isNull);
}

void _purchaseLandRejectedWhenNoEmbassyWithProvinceOwnerMinorTribe() {
  const ow = OrdersApplicationTestSupport.ow;
  const provinceId = OrdersApplicationTestSupport.provinceId;
  const tileKey = OrdersApplicationTestSupport.tileKey;
  const minorProvinceId = 'oldWorld|M1';
  const tileKeyMinor = 'oldWorld|M1|0|0';
  const cost = 15 * 10; // grain base price 10
  final unit = Unit(
    id: 'merchant1',
    type: kUnitTypeMerchant,
    ownerId: 'p1',
    locationProvinceId: minorProvinceId,
    tileKey: tileKeyMinor,
  );
  final game = Game(
    id: 'g',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
      oldWorld: RegionData(
        provinces: const [
          Province(id: provinceId, regionId: ow, ownerId: 'p1'),
          Province(id: minorProvinceId, regionId: ow, ownerId: 'minor1'),
        ],
        units: [unit],
      ),
      newWorld: const RegionData(),
      resourceByTileKey: const {tileKeyMinor: 'grain'},
      tileKeysByRegionAndProvince: const {
        ow: {
          provinceId: [tileKey],
          minorProvinceId: [tileKeyMinor],
        },
      },
    ),
    players: [
      Player(id: 'p1', displayName: 'P1', isHuman: true, treasury: cost + 100),
    ],
    minorNations: const [MinorNation(id: 'minor1', displayName: 'Minor 1')],
    // No overtureStates → no Embassy with province owner.
    overtureStates: const [],
  );
  final orders = Orders(
    workOrdersByPlayerId: {
      'p1': [
        const WorkOrder(
          unitId: 'merchant1',
          target: kWorkTargetPurchaseLand,
          targetTileKey: tileKeyMinor,
        ),
      ],
    },
  );
  final next = applyBuildAndWorkOrders(game, orders);
  expect(next.worldState.purchasedTilesByTileKey[tileKeyMinor], isNull);
  expect(next.players.single.treasury, game.players.single.treasury);
}

void _purchaseLandRejectedWhenAtWarWithProvinceOwnerMinorTribe() {
  const ow = OrdersApplicationTestSupport.ow;
  const provinceId = OrdersApplicationTestSupport.provinceId;
  const tileKey = OrdersApplicationTestSupport.tileKey;
  const minorProvinceId = 'oldWorld|M1';
  const tileKeyMinor = 'oldWorld|M1|0|0';
  const cost = 15 * 10; // grain base price 10
  final unit = Unit(
    id: 'merchant1',
    type: kUnitTypeMerchant,
    ownerId: 'p1',
    locationProvinceId: minorProvinceId,
    tileKey: tileKeyMinor,
  );
  final game = Game(
    id: 'g',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
      oldWorld: RegionData(
        provinces: const [
          Province(id: provinceId, regionId: ow, ownerId: 'p1'),
          Province(id: minorProvinceId, regionId: ow, ownerId: 'minor1'),
        ],
        units: [unit],
      ),
      newWorld: const RegionData(),
      resourceByTileKey: const {tileKeyMinor: 'grain'},
      tileKeysByRegionAndProvince: const {
        ow: {
          provinceId: [tileKey],
          minorProvinceId: [tileKeyMinor],
        },
      },
    ),
    players: [
      Player(id: 'p1', displayName: 'P1', isHuman: true, treasury: cost + 100),
    ],
    minorNations: const [MinorNation(id: 'minor1', displayName: 'Minor 1')],
    diplomacyRelations: const [
      DiplomacyRelation(
        factionId1: 'p1',
        factionId2: 'minor1',
        state: RelationState.atWar,
      ),
    ],
  );
  final orders = Orders(
    workOrdersByPlayerId: {
      'p1': [
        const WorkOrder(
          unitId: 'merchant1',
          target: kWorkTargetPurchaseLand,
          targetTileKey: tileKeyMinor,
        ),
      ],
    },
  );
  final next = applyBuildAndWorkOrders(game, orders);
  expect(next.worldState.purchasedTilesByTileKey[tileKeyMinor], isNull);
  expect(next.players.single.treasury, game.players.single.treasury);
}

void _purchaseLandSameTileByTwoGPsFirstWinsSecondDoesNotDeductOverwrite() {
  const ow = OrdersApplicationTestSupport.ow;
  const provinceId = OrdersApplicationTestSupport.provinceId;
  const tileKey = OrdersApplicationTestSupport.tileKey;
  const minorProvinceId = 'oldWorld|M1';
  const tileKeyMinor = 'oldWorld|M1|0|0';
  const cost = 15 * 10; // grain base price 10
  final game = Game(
    id: 'g',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
      oldWorld: RegionData(
        provinces: [
          Province(id: provinceId, regionId: ow, ownerId: 'p1'),
          Province(id: minorProvinceId, regionId: ow, ownerId: 'minor1'),
        ],
        units: [
          Unit(
            id: 'merchant1',
            type: kUnitTypeMerchant,
            ownerId: 'p1',
            locationProvinceId: minorProvinceId,
            tileKey: tileKeyMinor,
          ),
          Unit(
            id: 'merchant2',
            type: kUnitTypeMerchant,
            ownerId: 'p2',
            locationProvinceId: minorProvinceId,
            tileKey: tileKeyMinor,
          ),
        ],
      ),
      newWorld: const RegionData(),
      resourceByTileKey: {tileKeyMinor: 'grain'},
      tileKeysByRegionAndProvince: {
        ow: {
          provinceId: [tileKey],
          minorProvinceId: [tileKeyMinor],
        },
      },
    ),
    players: [
      Player(
        id: 'p1',
        displayName: 'P1',
        isHuman: true,
        treasury: cost + 100,
        capitalProvinceId: provinceId,
      ),
      Player(
        id: 'p2',
        displayName: 'P2',
        isHuman: false,
        treasury: cost + 100,
        capitalProvinceId: provinceId,
      ),
    ],
    minorNations: const [MinorNation(id: 'minor1', displayName: 'Minor 1')],
    overtureStates: const [
      OvertureState(
        gpId: 'p1',
        targetId: 'minor1',
        stage: OvertureStage.embassy,
        sinceTurn: 0,
      ),
      OvertureState(
        gpId: 'p2',
        targetId: 'minor1',
        stage: OvertureStage.embassy,
        sinceTurn: 0,
      ),
    ],
  );
  final orders = Orders(
    workOrdersByPlayerId: {
      'p1': [
        const WorkOrder(
          unitId: 'merchant1',
          target: kWorkTargetPurchaseLand,
          targetTileKey: tileKeyMinor,
        ),
      ],
      'p2': [
        const WorkOrder(
          unitId: 'merchant2',
          target: kWorkTargetPurchaseLand,
          targetTileKey: tileKeyMinor,
        ),
      ],
    },
  );
  final next = applyBuildAndWorkOrders(game, orders);
  expect(next.worldState.purchasedTilesByTileKey[tileKeyMinor], 'p1');
  final p1After = next.playerById('p1')!;
  final p2After = next.playerById('p2')!;
  expect(p1After.treasury, game.playerById('p1')!.treasury - cost);
  expect(p2After.treasury, game.playerById('p2')!.treasury);
}

void _buildFortWithSufficientMaterialsDeductsMaterials() {
  const ow = OrdersApplicationTestSupport.ow;
  const provinceId = OrdersApplicationTestSupport.provinceId;
  const tileKey = OrdersApplicationTestSupport.tileKey;
  final unit = Unit(
    id: 'u1',
    type: kUnitTypeEngineer,
    ownerId: 'p1',
    locationProvinceId: provinceId,
    tileKey: tileKey,
  );
  final cost = workOrderCostBuildFort(0);
  final game = OrdersApplicationTestSupport.workOrderApplicationGame(
    provinces: [
      Province(id: provinceId, regionId: ow, ownerId: 'p1', fortLevel: 0),
    ],
    units: [unit],
    players: [
      Player(
        id: 'p1',
        displayName: 'P1',
        isHuman: true,
        stockpile: OrdersApplicationTestSupport.stockpileCovering(cost),
      ),
    ],
  );
  final orders = Orders(
    workOrdersByPlayerId: {
      'p1': [
        WorkOrder(
          unitId: 'u1',
          target: kWorkTargetBuildFort,
          targetTileKey: tileKey,
        ),
      ],
    },
  );
  final next = applyBuildAndWorkOrders(game, orders);
  for (final e in cost.entries) {
    expect(
      next.players.single.stockpile.quantityOf(e.key),
      game.players.single.stockpile.quantityOf(e.key) - e.value,
    );
  }
}

void _buildFortLevel2SkippedWithoutMineEngineering() {
  const ow = OrdersApplicationTestSupport.ow;
  const provinceId = OrdersApplicationTestSupport.provinceId;
  const tileKey = OrdersApplicationTestSupport.tileKey;
  final unit = Unit(
    id: 'u1',
    type: kUnitTypeEngineer,
    ownerId: 'p1',
    locationProvinceId: provinceId,
    tileKey: tileKey,
  );
  final game = OrdersApplicationTestSupport.workOrderApplicationGame(
    provinces: [
      Province(id: provinceId, regionId: ow, ownerId: 'p1', fortLevel: 1),
    ],
    units: [unit],
    players: const [
      Player(id: 'p1', displayName: 'P1', isHuman: true, techUnlocked: {}),
    ],
  );
  final orders = Orders(
    workOrdersByPlayerId: {
      'p1': [
        WorkOrder(
          unitId: 'u1',
          target: kWorkTargetBuildFort,
          targetTileKey: tileKey,
        ),
      ],
    },
  );
  final next = applyBuildAndWorkOrders(game, orders);
  expect(next.worldState.oldWorld.provinces.single.fortLevel, 1);
  expect(next.worldState.oldWorld.units.single.currentWork, isNull);
}

void _buildFortLevel3SkippedWithoutModernForts() {
  const ow = OrdersApplicationTestSupport.ow;
  const provinceId = OrdersApplicationTestSupport.provinceId;
  const tileKey = OrdersApplicationTestSupport.tileKey;
  final unit = Unit(
    id: 'u1',
    type: kUnitTypeEngineer,
    ownerId: 'p1',
    locationProvinceId: provinceId,
    tileKey: tileKey,
  );
  final game = OrdersApplicationTestSupport.workOrderApplicationGame(
    provinces: [
      Province(id: provinceId, regionId: ow, ownerId: 'p1', fortLevel: 2),
    ],
    units: [unit],
    players: const [
      Player(
        id: 'p1',
        displayName: 'P1',
        isHuman: true,
        techUnlocked: {kTechIdMineEngineering: true},
      ),
    ],
  );
  final orders = Orders(
    workOrdersByPlayerId: {
      'p1': [
        WorkOrder(
          unitId: 'u1',
          target: kWorkTargetBuildFort,
          targetTileKey: tileKey,
        ),
      ],
    },
  );
  final next = applyBuildAndWorkOrders(game, orders);
  expect(next.worldState.oldWorld.provinces.single.fortLevel, 2);
  expect(next.worldState.oldWorld.units.single.currentWork, isNull);
}

void _upgradeTownCompletionIncreasesProvinceTownDevelopmentLevel() {
  const ow = OrdersApplicationTestSupport.ow;
  const provinceId = OrdersApplicationTestSupport.provinceId;
  const tileKey = OrdersApplicationTestSupport.tileKey;
  final unit = Unit(
    id: 'u1',
    type: kUnitTypeBuilder,
    ownerId: 'p1',
    locationProvinceId: provinceId,
    tileKey: tileKey,
    status: UnitStatus.working,
    currentWork: const CurrentWork(
      workTarget: kWorkTargetUpgradeTown,
      tileKey: tileKey,
      totalTurns: 1,
      remainingTurns: 1,
    ),
  );
  final game = OrdersApplicationTestSupport.workOrderApplicationGame(
    provinces: [
      Province(
        id: provinceId,
        regionId: ow,
        ownerId: 'p1',
        townDevelopmentLevel: 1,
      ),
    ],
    units: [unit],
    players: [
      Player(
        id: 'p1',
        displayName: 'P1',
        isHuman: true,
        techUnlocked: const {kTechIdNationalBureaucracy: true},
      ),
    ],
  );
  final next = applyBuildAndWorkOrders(
    game,
    Orders(buildUnitOrdersByPlayerId: {'p1': <BuildUnitOrder>[]}),
  );
  expect(next.worldState.oldWorld.provinces.single.townDevelopmentLevel, 2);
}

void _counterSpyProcessWorkKeepsOngoingAssignmentWithoutKillingBuildWork() {
  const ow = OrdersApplicationTestSupport.ow;
  const provId = OrdersApplicationTestSupport.provinceId;
  const tileKeyP1 = OrdersApplicationTestSupport.tileKey;
  final p1Spy = Unit(
    id: 'spy1',
    type: kUnitTypeSpy,
    ownerId: 'p1',
    locationProvinceId: provId,
    tileKey: tileKeyP1,
    status: UnitStatus.working,
    currentWork: const CurrentWork(
      workTarget: kWorkTargetCounterSpy,
      tileKey: tileKeyP1,
      totalTurns: 0,
      remainingTurns: 1,
    ),
  );
  final p2Spy = Unit(
    id: 'spy2',
    type: kUnitTypeSpy,
    ownerId: 'p2',
    locationProvinceId: provId,
    tileKey: tileKeyP1,
  );
  final game = OrdersApplicationTestSupport.workOrderApplicationGame(
    turnNumber: 1,
    globalGameSeed: 12345,
    provinces: [Province(id: provId, regionId: ow, ownerId: 'p1')],
    units: [p1Spy, p2Spy],
    tileKeysByRegionAndProvince: {
      ow: {
        provId: [tileKeyP1],
      },
    },
    players: const [
      Player(id: 'p1', displayName: 'P1', isHuman: true),
      Player(id: 'p2', displayName: 'P2', isHuman: true),
    ],
  );
  final next = applyBuildAndWorkOrders(
    game,
    Orders(
      buildUnitOrdersByPlayerId: {
        'p1': <BuildUnitOrder>[],
        'p2': <BuildUnitOrder>[],
      },
    ),
  );
  final units = next.worldState.oldWorld.units;
  expect(units.any((u) => u.id == 'spy1'), isTrue);
  expect(units.any((u) => u.id == 'spy2'), isTrue);
  expect(units.length, 2);
}

void _unknownWorkTargetSkippedUnitStaysIdle() {
  const ow = OrdersApplicationTestSupport.ow;
  const provinceId = OrdersApplicationTestSupport.provinceId;
  const tileKey = OrdersApplicationTestSupport.tileKey;
  final unit = Unit(
    id: 'u1',
    type: kUnitTypeBuilder,
    ownerId: 'p1',
    locationProvinceId: provinceId,
    tileKey: tileKey,
  );
  final game = OrdersApplicationTestSupport.workOrderApplicationGame(
    provinces: [Province(id: provinceId, regionId: ow, ownerId: 'p1')],
    units: [unit],
  );
  final orders = Orders(
    workOrdersByPlayerId: {
      'p1': [
        WorkOrder(
          unitId: 'u1',
          target: 'unknown_target',
          targetTileKey: tileKey,
        ),
      ],
    },
  );
  final next = applyBuildAndWorkOrders(game, orders);
  final u = next.worldState.oldWorld.units.single;
  expect(u.status, UnitStatus.idle);
  expect(u.currentWork, isNull);
}

void _buildRoadWithInsufficientMaterialsDoesNotSetCurrentWorkDeductStockpile() {
  const ow = OrdersApplicationTestSupport.ow;
  const provinceId = OrdersApplicationTestSupport.provinceId;
  const tileKey = OrdersApplicationTestSupport.tileKey;
  final unit = Unit(
    id: 'u1',
    type: kUnitTypeEngineer,
    ownerId: 'p1',
    locationProvinceId: provinceId,
    tileKey: tileKey,
  );
  final game = OrdersApplicationTestSupport.workOrderApplicationGame(
    provinces: [Province(id: provinceId, regionId: ow, ownerId: 'p1')],
    units: [unit],
    players: const [
      Player(
        id: 'p1',
        displayName: 'P1',
        isHuman: true,
        stockpile: Stockpile(),
      ),
    ],
  );
  final orders = Orders(
    workOrdersByPlayerId: {
      'p1': [
        WorkOrder(
          unitId: 'u1',
          target: kWorkTargetBuildRoad,
          targetTileKey: tileKey,
        ),
      ],
    },
  );
  final next = applyBuildAndWorkOrders(game, orders);
  final u = next.worldState.oldWorld.units.single;
  expect(u.currentWork, isNull);
  expect(u.status, UnitStatus.idle);
  expect(
    next.players.single.stockpile.quantityOf(CommodityCatalog.lumber.id),
    0,
  );
}

void _buildRoadWithSufficientMaterialsDeductsMaterialsSetsCurrentWork() {
  const ow = OrdersApplicationTestSupport.ow;
  const provinceId = OrdersApplicationTestSupport.provinceId;
  const tileKey = OrdersApplicationTestSupport.tileKey;
  final unit = Unit(
    id: 'u1',
    type: kUnitTypeEngineer,
    ownerId: 'p1',
    locationProvinceId: provinceId,
    tileKey: tileKey,
  );
  final cost = workOrderCostBuildRoad;
  final game = OrdersApplicationTestSupport.workOrderApplicationGame(
    provinces: [Province(id: provinceId, regionId: ow, ownerId: 'p1')],
    units: [unit],
    players: [
      Player(
        id: 'p1',
        displayName: 'P1',
        isHuman: true,
        stockpile: OrdersApplicationTestSupport.stockpileCovering(cost),
      ),
    ],
  );
  final orders = Orders(
    workOrdersByPlayerId: {
      'p1': [
        WorkOrder(
          unitId: 'u1',
          target: kWorkTargetBuildRoad,
          targetTileKey: tileKey,
        ),
      ],
    },
  );
  final next = applyBuildAndWorkOrders(game, orders);
  final u = next.worldState.oldWorld.units.single;
  // build_road totalTurns=1, so work completes in same phase; unit idle and road level 1.
  expect(u.currentWork, isNull);
  expect(u.status, UnitStatus.idle);
  expect(next.worldState.tileState.roadLevel(tileKey), 1);
  for (final e in cost.entries) {
    expect(
      next.players.single.stockpile.quantityOf(e.key),
      game.players.single.stockpile.quantityOf(e.key) - e.value,
    );
  }
}

void _counterSpyWorkOrderSetsCurrentWorkForSpyUnitOnOwnedCapitalProvince() {
  const ow = OrdersApplicationTestSupport.ow;
  const provinceId = OrdersApplicationTestSupport.provinceId;
  const tileKey = OrdersApplicationTestSupport.tileKey;
  final spy = Unit(
    id: 'spy1',
    type: kUnitTypeSpy,
    ownerId: 'p1',
    locationProvinceId: provinceId,
    tileKey: tileKey,
  );
  final game = OrdersApplicationTestSupport.workOrderApplicationGame(
    provinces: [Province(id: provinceId, regionId: ow, ownerId: 'p1')],
    units: [spy],
    tileKeysByRegionAndProvince: const {
      ow: {
        provinceId: [tileKey],
      },
    },
    players: const [
      Player(
        id: 'p1',
        displayName: 'P1',
        isHuman: true,
        capitalProvinceId: provinceId,
      ),
    ],
  );
  final orders = Orders(
    workOrdersByPlayerId: {
      'p1': [
        WorkOrder(
          unitId: 'spy1',
          target: kWorkTargetCounterSpy,
          targetTileKey: tileKey,
        ),
      ],
    },
  );
  final next = applyBuildAndWorkOrders(game, orders);
  final spyAfter = next.worldState.oldWorld.units.single;
  expect(spyAfter.currentWork, isNotNull);
  expect(spyAfter.currentWork!.workTarget, kWorkTargetCounterSpy);
}

void _exploreWorkOrderSetsCurrentWorkWhenProvinceHasTiles() {
  const ow = OrdersApplicationTestSupport.ow;
  const provinceId = OrdersApplicationTestSupport.provinceId;
  const tileKey = OrdersApplicationTestSupport.tileKey;
  final unit = Unit(
    id: 'u1',
    type: kUnitTypeExplorer,
    ownerId: 'p1',
    locationProvinceId: provinceId,
    tileKey: tileKey,
  );
  final game = OrdersApplicationTestSupport.workOrderApplicationGame(
    provinces: [Province(id: provinceId, regionId: ow, ownerId: 'p1')],
    units: [unit],
    tileKeysByRegionAndProvince: {
      ow: {
        provinceId: [tileKey, 'oldWorld|P1|1|0'],
      },
    },
  );
  final orders = Orders(
    workOrdersByPlayerId: {
      'p1': [
        WorkOrder(
          unitId: 'u1',
          target: kWorkTargetExplore,
          targetTileKey: tileKey,
        ),
      ],
    },
  );
  final next = applyBuildAndWorkOrders(game, orders);
  final u = next.worldState.oldWorld.units.single;
  expect(u.currentWork, isNotNull);
  expect(u.currentWork!.workTarget, kWorkTargetExplore);
  expect(u.currentWork!.totalTurns, greaterThanOrEqualTo(1));
  // One turn processed in same phase after applying.
  expect(u.currentWork!.remainingTurns, u.currentWork!.totalTurns - 1);
}

void
_exploreWorkOrderTotalTurnsUsesRegionScopedFormulaCeil3TilesInPMaxTilesInRegion() {
  const ow = OrdersApplicationTestSupport.ow;
  // Region has two provinces with different tile counts; explorer in the
  // smaller one should get totalTurns = ceil(3 * tilesInP / maxTilesInRegion).
  const provinceSmall = '$ow|P1';
  const provinceLarge = '$ow|P2';
  const tileSmall1 = '$ow|P1|0|0';
  const tileSmall2 = '$ow|P1|1|0';
  const tileLarge1 = '$ow|P2|0|0';
  const tileLarge2 = '$ow|P2|1|0';
  const tileLarge3 = '$ow|P2|2|0';
  const tileLarge4 = '$ow|P2|3|0';

  final unit = Unit(
    id: 'u1',
    type: kUnitTypeExplorer,
    ownerId: 'p1',
    locationProvinceId: provinceSmall,
    tileKey: tileSmall1,
  );

  final game = OrdersApplicationTestSupport.workOrderApplicationGame(
    provinces: const [
      Province(id: provinceSmall, regionId: ow, ownerId: 'p1'),
      Province(id: provinceLarge, regionId: ow, ownerId: 'p1'),
    ],
    units: [unit],
    tileKeysByRegionAndProvince: const {
      ow: {
        provinceSmall: [tileSmall1, tileSmall2], // tilesInP = 2
        provinceLarge: [
          tileLarge1,
          tileLarge2,
          tileLarge3,
          tileLarge4,
        ], // maxTilesInRegion = 4
      },
    },
  );

  final orders = Orders(
    workOrdersByPlayerId: {
      'p1': [
        const WorkOrder(
          unitId: 'u1',
          target: kWorkTargetExplore,
          targetTileKey: tileSmall1,
        ),
      ],
    },
  );

  final next = applyBuildAndWorkOrders(game, orders);
  final u = next.worldState.oldWorld.units.single;

  // tilesInP = 2, maxTilesInRegion = 4 → ceil(3 * 2 / 4) = ceil(1.5) = 2.
  expect(u.currentWork, isNotNull);
  expect(u.currentWork!.workTarget, kWorkTargetExplore);
  expect(u.currentWork!.totalTurns, 2);
  // One turn processed in same phase after applying.
  expect(u.currentWork!.remainingTurns, 1);
}

void _engineerBuildRoadWorkOrderSetsCurrentWork() {
  const ow = OrdersApplicationTestSupport.ow;
  const provinceId = OrdersApplicationTestSupport.provinceId;
  const tileKey = OrdersApplicationTestSupport.tileKey;
  final unit = Unit(
    id: 'u1',
    type: kUnitTypeEngineer,
    ownerId: 'p1',
    locationProvinceId: provinceId,
    tileKey: tileKey,
  );
  final cost = workOrderCostBuildRoad;
  final game = OrdersApplicationTestSupport.workOrderApplicationGame(
    provinces: [Province(id: provinceId, regionId: ow, ownerId: 'p1')],
    units: [unit],
    players: [
      Player(
        id: 'p1',
        displayName: 'P1',
        isHuman: true,
        stockpile: OrdersApplicationTestSupport.stockpileCovering(cost),
      ),
    ],
  );
  final orders = Orders(
    workOrdersByPlayerId: {
      'p1': [
        WorkOrder(
          unitId: 'u1',
          target: kWorkTargetBuildRoad,
          targetTileKey: tileKey,
        ),
      ],
    },
  );
  final next = applyBuildAndWorkOrders(game, orders);
  final u = next.worldState.oldWorld.units.single;
  // build_road totalTurns=1, so work completes in same phase; unit idle and road level 1.
  expect(u.currentWork, isNull);
  expect(u.status, UnitStatus.idle);
  expect(next.worldState.tileState.roadLevel(tileKey), 1);
}

void _buildPortWorkOrderSetsCurrentWorkWhenMaterialsSufficient() {
  const ow = OrdersApplicationTestSupport.ow;
  const provinceId = OrdersApplicationTestSupport.provinceId;
  const tileKey = OrdersApplicationTestSupport.tileKey;
  final unit = Unit(
    id: 'u1',
    type: kUnitTypeEngineer,
    ownerId: 'p1',
    locationProvinceId: provinceId,
    tileKey: tileKey,
  );
  final cost = workOrderMaterialCost(kWorkTargetBuildPort);
  expect(cost, isNotNull);
  final game = OrdersApplicationTestSupport.workOrderApplicationGame(
    provinces: [Province(id: provinceId, regionId: ow, ownerId: 'p1')],
    units: [unit],
    players: [
      Player(
        id: 'p1',
        displayName: 'P1',
        isHuman: true,
        stockpile: OrdersApplicationTestSupport.stockpileCovering(cost!),
      ),
    ],
  );
  final orders = Orders(
    workOrdersByPlayerId: {
      'p1': [
        WorkOrder(
          unitId: 'u1',
          target: kWorkTargetBuildPort,
          targetTileKey: tileKey,
        ),
      ],
    },
  );
  final next = applyBuildAndWorkOrders(game, orders);
  final u = next.worldState.oldWorld.units.single;
  // build_port totalTurns=1, so work completes in same phase; unit idle.
  expect(u.currentWork, isNull);
  expect(u.status, UnitStatus.idle);
}
