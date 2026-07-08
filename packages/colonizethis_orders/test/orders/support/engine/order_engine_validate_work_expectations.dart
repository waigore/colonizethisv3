// Compact OrderEngine validateWork assertions (Refs #3949 wave 3).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'order_engine_purchase_land_test_support.dart';
import 'order_engine_validate_work_fixtures.dart';

/// Pins for [orderEngineValidateWorkScenarios] rows.
enum OrderEngineValidateWorkTarget {
  rejectsSecondPendingWorkOrderForSameUnitInOneTurn,
  rejectsPurchaseLandWhenNoEmbassyWithMinor,
  rejectsPurchaseLandWhenAtWarWithFaction,
  rejectsPurchaseLandWhenInsufficientTreasury,
  rejectsPurchaseLandWhenTileHasNoResource,
  rejectsPurchaseLandWhenMineralTileNotProspected,
  acceptsPurchaseLandWithEmbassyAtPeaceSufficientTreasuryTileWithResource,
  rejectsSecondBuilderEngineerMerchantWorkOrderOnSameTileForSamePlayerPerTileExclusivity,
  acceptsPurchaseLandForMineralWhenProspected,
  rejectsPurchaseLandWhenTileAlreadyPurchasedByAnotherGP,
  rejectsPurchaseLandWhenTileAlreadyOwnedBySamePlayer,
  rejectsBuildImprovementOnMineralTileWhenNotProspected,
  acceptsBuildImprovementOnMineralTileAfterProspected,
  acceptsBuildImprovementOnGrainWhenTileNotProspected,
  rejectsBuildImprovementWhenTileHasNoResource,
  rejectsBuildImprovementWhenImprovementLevelAlready4,
  rejectsBuildImprovementWhenTechCapWouldBeExceededEmptyTech,
  rejectsBuildImprovementWhenTechCapWouldBeExceeded,
  acceptsGrainUpgradeWhenExactNextLevelGrainTechIsUnlocked,
  acceptsBuildImprovementWhenTileHasResourceLevel4TechCapAllows,
  rejectsBuildImprovementInForeignUnpurchasedProvince,
  rejectsRaisingScrubTimberFromLevel1EvenWithCircularSaw,
  acceptsRaisingHardwoodTimberFromLevel1WithCircularSaw,
  acceptsInitialScrubTimberImprovementLevel01,
  acceptsBuildImprovementOnPurchasedTileInForeignProvince,
  rejectsBuildFortToLevel2WithoutMineEngineering,
  rejectsBuildFortToLevel3WithoutModernForts,
  rejectsBuildRailWhenTileTerrainDataIsMissing,
  rejectsBuildRailWhenRoadLevelIs0,
  rejectsBuildRailOnHillsWithOnlyEarlySteam,
  acceptsBuildRailOnPlainsWithEarlySteamAndRoad1,
  rejectsBuildRoadInMinorProvinceWithoutEmbassyPath,
  rejectsBuildRoadInMinorProvinceEvenWithEmbassyWhenOccupancyDisallowsTile,
  rejectsUpgradeTownWithoutNationalBureaucracy,
  acceptsUpgradeTownWhenNationalBureaucracyUnlocked,
}

void runOrderEngineValidateWorkExpectation(
  OrderEngineValidateWorkTarget target,
) {
  switch (target) {
    case OrderEngineValidateWorkTarget
        .rejectsSecondPendingWorkOrderForSameUnitInOneTurn:
      _rejectsSecondPendingWorkOrderForSameUnitInOneTurn();
    case OrderEngineValidateWorkTarget
        .rejectsPurchaseLandWhenNoEmbassyWithMinor:
      _rejectsPurchaseLandWhenNoEmbassyWithMinor();
    case OrderEngineValidateWorkTarget.rejectsPurchaseLandWhenAtWarWithFaction:
      _rejectsPurchaseLandWhenAtWarWithFaction();
    case OrderEngineValidateWorkTarget
        .rejectsPurchaseLandWhenInsufficientTreasury:
      _rejectsPurchaseLandWhenInsufficientTreasury();
    case OrderEngineValidateWorkTarget.rejectsPurchaseLandWhenTileHasNoResource:
      _rejectsPurchaseLandWhenTileHasNoResource();
    case OrderEngineValidateWorkTarget
        .rejectsPurchaseLandWhenMineralTileNotProspected:
      _rejectsPurchaseLandWhenMineralTileNotProspected();
    case OrderEngineValidateWorkTarget
        .acceptsPurchaseLandWithEmbassyAtPeaceSufficientTreasuryTileWithResource:
      _acceptsPurchaseLandWithEmbassyAtPeaceSufficientTreasuryTileWithResource();
    case OrderEngineValidateWorkTarget
        .rejectsSecondBuilderEngineerMerchantWorkOrderOnSameTileForSamePlayerPerTileExclusivity:
      _rejectsSecondBuilderEngineerMerchantWorkOrderOnSameTileForSamePlayerPerTileExclusivity();
    case OrderEngineValidateWorkTarget
        .acceptsPurchaseLandForMineralWhenProspected:
      _acceptsPurchaseLandForMineralWhenProspected();
    case OrderEngineValidateWorkTarget
        .rejectsPurchaseLandWhenTileAlreadyPurchasedByAnotherGP:
      _rejectsPurchaseLandWhenTileAlreadyPurchasedByAnotherGP();
    case OrderEngineValidateWorkTarget
        .rejectsPurchaseLandWhenTileAlreadyOwnedBySamePlayer:
      _rejectsPurchaseLandWhenTileAlreadyOwnedBySamePlayer();
    case OrderEngineValidateWorkTarget
        .rejectsBuildImprovementOnMineralTileWhenNotProspected:
      _rejectsBuildImprovementOnMineralTileWhenNotProspected();
    case OrderEngineValidateWorkTarget
        .acceptsBuildImprovementOnMineralTileAfterProspected:
      _acceptsBuildImprovementOnMineralTileAfterProspected();
    case OrderEngineValidateWorkTarget
        .acceptsBuildImprovementOnGrainWhenTileNotProspected:
      _acceptsBuildImprovementOnGrainWhenTileNotProspected();
    case OrderEngineValidateWorkTarget
        .rejectsBuildImprovementWhenTileHasNoResource:
      _rejectsBuildImprovementWhenTileHasNoResource();
    case OrderEngineValidateWorkTarget
        .rejectsBuildImprovementWhenImprovementLevelAlready4:
      _rejectsBuildImprovementWhenImprovementLevelAlready4();
    case OrderEngineValidateWorkTarget
        .rejectsBuildImprovementWhenTechCapWouldBeExceededEmptyTech:
      _rejectsBuildImprovementWhenTechCapWouldBeExceededEmptyTech();
    case OrderEngineValidateWorkTarget
        .rejectsBuildImprovementWhenTechCapWouldBeExceeded:
      _rejectsBuildImprovementWhenTechCapWouldBeExceeded();
    case OrderEngineValidateWorkTarget
        .acceptsGrainUpgradeWhenExactNextLevelGrainTechIsUnlocked:
      _acceptsGrainUpgradeWhenExactNextLevelGrainTechIsUnlocked();
    case OrderEngineValidateWorkTarget
        .acceptsBuildImprovementWhenTileHasResourceLevel4TechCapAllows:
      _acceptsBuildImprovementWhenTileHasResourceLevel4TechCapAllows();
    case OrderEngineValidateWorkTarget
        .rejectsBuildImprovementInForeignUnpurchasedProvince:
      _rejectsBuildImprovementInForeignUnpurchasedProvince();
    case OrderEngineValidateWorkTarget
        .rejectsRaisingScrubTimberFromLevel1EvenWithCircularSaw:
      _rejectsRaisingScrubTimberFromLevel1EvenWithCircularSaw();
    case OrderEngineValidateWorkTarget
        .acceptsRaisingHardwoodTimberFromLevel1WithCircularSaw:
      _acceptsRaisingHardwoodTimberFromLevel1WithCircularSaw();
    case OrderEngineValidateWorkTarget
        .acceptsInitialScrubTimberImprovementLevel01:
      _acceptsInitialScrubTimberImprovementLevel01();
    case OrderEngineValidateWorkTarget
        .acceptsBuildImprovementOnPurchasedTileInForeignProvince:
      _acceptsBuildImprovementOnPurchasedTileInForeignProvince();
    case OrderEngineValidateWorkTarget
        .rejectsBuildFortToLevel2WithoutMineEngineering:
      _rejectsBuildFortToLevel2WithoutMineEngineering();
    case OrderEngineValidateWorkTarget
        .rejectsBuildFortToLevel3WithoutModernForts:
      _rejectsBuildFortToLevel3WithoutModernForts();
    case OrderEngineValidateWorkTarget
        .rejectsBuildRailWhenTileTerrainDataIsMissing:
      _rejectsBuildRailWhenTileTerrainDataIsMissing();
    case OrderEngineValidateWorkTarget.rejectsBuildRailWhenRoadLevelIs0:
      _rejectsBuildRailWhenRoadLevelIs0();
    case OrderEngineValidateWorkTarget
        .rejectsBuildRailOnHillsWithOnlyEarlySteam:
      _rejectsBuildRailOnHillsWithOnlyEarlySteam();
    case OrderEngineValidateWorkTarget
        .acceptsBuildRailOnPlainsWithEarlySteamAndRoad1:
      _acceptsBuildRailOnPlainsWithEarlySteamAndRoad1();
    case OrderEngineValidateWorkTarget
        .rejectsBuildRoadInMinorProvinceWithoutEmbassyPath:
      _rejectsBuildRoadInMinorProvinceWithoutEmbassyPath();
    case OrderEngineValidateWorkTarget
        .rejectsBuildRoadInMinorProvinceEvenWithEmbassyWhenOccupancyDisallowsTile:
      _rejectsBuildRoadInMinorProvinceEvenWithEmbassyWhenOccupancyDisallowsTile();
    case OrderEngineValidateWorkTarget
        .rejectsUpgradeTownWithoutNationalBureaucracy:
      _rejectsUpgradeTownWithoutNationalBureaucracy();
    case OrderEngineValidateWorkTarget
        .acceptsUpgradeTownWhenNationalBureaucracyUnlocked:
      _acceptsUpgradeTownWhenNationalBureaucracyUnlocked();
  }
}

void _rejectsSecondPendingWorkOrderForSameUnitInOneTurn() {
  const regionId = 'oldWorld';
  const provinceId = '$regionId|P1';
  const tileA = '$provinceId|0|0';
  const tileB = '$provinceId|1|0';

  final game = Game(
    id: 'g',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
      oldWorld: RegionData(
        provinces: [
          Province(id: provinceId, regionId: regionId, ownerId: 'p1'),
        ],
        units: [
          Unit(
            id: 'builder1',
            type: kUnitTypeBuilder,
            ownerId: 'p1',
            locationProvinceId: provinceId,
            tileKey: tileA,
          ),
        ],
      ),
      newWorld: const RegionData(),
      tileKeysByRegionAndProvince: const {
        regionId: {
          provinceId: [tileA, tileB],
        },
      },
      resourceByTileKey: const {tileA: 'grain', tileB: 'grain'},
      playerVisibilityByTile: const {
        'p1': {tileA: 'fullyVisible', tileB: 'fullyVisible'},
      },
    ),
    players: [
      Player(
        id: 'p1',
        displayName: 'P1',
        isHuman: true,
        capitalProvinceId: provinceId,
        stockpile: Stockpile()
            .applyDelta(CommodityCatalog.lumber.id, 20)
            .applyDelta(CommodityCatalog.castIron.id, 20),
        techUnlocked: const {kTechIdCircularSaw: true},
      ),
    ],
  );

  final topology = MapTopology(
    nodes: const [
      TopologyNode(
        id: 'P1',
        regionId: regionId,
        type: TopologyNodeType.province,
      ),
    ],
    edges: const [],
  );

  final engine = OrderEngine();
  engine.addWorkOrder(
    'p1',
    const WorkOrder(
      unitId: 'builder1',
      target: kWorkTargetBuildImprovement,
      targetTileKey: tileA,
    ),
  );
  engine.addWorkOrder(
    'p1',
    const WorkOrder(
      unitId: 'builder1',
      target: kWorkTargetBuildImprovement,
      targetTileKey: tileB,
    ),
  );

  final results = engine.validatePlayerOrdersWithContext(game, topology, 'p1');
  expect(results, hasLength(2));
  expect(results.first.status, OrderValidationStatus.accepted);
  expect(results.last.status, OrderValidationStatus.rejected);
  expect(
    results.last.reason,
    contains('Only one work order per unit is allowed each turn'),
  );
}

void _rejectsPurchaseLandWhenNoEmbassyWithMinor() {
  final topology = PurchaseLandTestFixture.topology();
  final game = PurchaseLandTestFixture.baseGame(treasury: 500);
  final engine = OrderEngine();
  engine.addWorkOrder(
    'p1',
    WorkOrder(
      unitId: 'merchant1',
      target: kWorkTargetPurchaseLand,
      targetTileKey: PurchaseLandTestFixture.tileKey,
    ),
  );
  final results = engine.validatePlayerOrdersWithContext(game, topology, 'p1');
  expect(results.single.status, OrderValidationStatus.rejected);
  expect(results.single.reason, contains('embassy'));
}

void _rejectsPurchaseLandWhenAtWarWithFaction() {
  final topology = PurchaseLandTestFixture.topology();
  final game = PurchaseLandTestFixture.baseGame(
    treasury: 500,
    overtureStates: [
      const OvertureState(
        gpId: 'p1',
        targetId: 'minor1',
        stage: OvertureStage.embassy,
        sinceTurn: 0,
      ),
    ],
    diplomacyRelations: [
      const DiplomacyRelation(
        factionId1: 'p1',
        factionId2: 'minor1',
        state: RelationState.atWar,
      ),
    ],
  );
  final engine = OrderEngine();
  engine.addWorkOrder(
    'p1',
    WorkOrder(
      unitId: 'merchant1',
      target: kWorkTargetPurchaseLand,
      targetTileKey: PurchaseLandTestFixture.tileKey,
    ),
  );
  final results = engine.validatePlayerOrdersWithContext(game, topology, 'p1');
  expect(results.single.status, OrderValidationStatus.rejected);
  expect(results.single.reason, contains('war'));
}

void _rejectsPurchaseLandWhenInsufficientTreasury() {
  final topology = PurchaseLandTestFixture.topology();
  const cost = 15 * 10; // grain default base 10
  final game = PurchaseLandTestFixture.baseGame(
    treasury: cost - 1,
    overtureStates: [
      const OvertureState(
        gpId: 'p1',
        targetId: 'minor1',
        stage: OvertureStage.embassy,
        sinceTurn: 0,
      ),
    ],
  );
  final engine = OrderEngine();
  engine.addWorkOrder(
    'p1',
    WorkOrder(
      unitId: 'merchant1',
      target: kWorkTargetPurchaseLand,
      targetTileKey: PurchaseLandTestFixture.tileKey,
    ),
  );
  final results = engine.validatePlayerOrdersWithContext(game, topology, 'p1');
  expect(results.single.status, OrderValidationStatus.rejected);
  expect(results.single.reason, contains('Insufficient treasury'));
}

void _rejectsPurchaseLandWhenTileHasNoResource() {
  final topology = PurchaseLandTestFixture.topology();
  final game = PurchaseLandTestFixture.baseGame(
    treasury: 500,
    overtureStates: [
      const OvertureState(
        gpId: 'p1',
        targetId: 'minor1',
        stage: OvertureStage.embassy,
        sinceTurn: 0,
      ),
    ],
    resourceByTileKey: {},
  );
  final engine = OrderEngine();
  engine.addWorkOrder(
    'p1',
    WorkOrder(
      unitId: 'merchant1',
      target: kWorkTargetPurchaseLand,
      targetTileKey: PurchaseLandTestFixture.tileKey,
    ),
  );
  final results = engine.validatePlayerOrdersWithContext(game, topology, 'p1');
  expect(results.single.status, OrderValidationStatus.rejected);
  expect(results.single.reason, contains('no resource'));
}

void _rejectsPurchaseLandWhenMineralTileNotProspected() {
  final topology = PurchaseLandTestFixture.topology();
  final tk = PurchaseLandTestFixture.tileKey;
  final game = PurchaseLandTestFixture.baseGame(
    treasury: 500,
    overtureStates: [
      const OvertureState(
        gpId: 'p1',
        targetId: 'minor1',
        stage: OvertureStage.embassy,
        sinceTurn: 0,
      ),
    ],
    resourceByTileKey: {tk: 'iron'},
    playerProspectedTiles: {}, // p1 has not prospected this tile
  );
  final engine = OrderEngine();
  engine.addWorkOrder(
    'p1',
    WorkOrder(
      unitId: 'merchant1',
      target: kWorkTargetPurchaseLand,
      targetTileKey: PurchaseLandTestFixture.tileKey,
    ),
  );
  final results = engine.validatePlayerOrdersWithContext(game, topology, 'p1');
  expect(results.single.status, OrderValidationStatus.rejected);
  expect(results.single.reason, contains('prospected'));
}

void
_acceptsPurchaseLandWithEmbassyAtPeaceSufficientTreasuryTileWithResource() {
  final topology = PurchaseLandTestFixture.topology();
  final game = PurchaseLandTestFixture.baseGame(
    treasury: 500,
    overtureStates: [
      const OvertureState(
        gpId: 'p1',
        targetId: 'minor1',
        stage: OvertureStage.embassy,
        sinceTurn: 0,
      ),
    ],
  );
  final engine = OrderEngine();
  engine.addWorkOrder(
    'p1',
    WorkOrder(
      unitId: 'merchant1',
      target: kWorkTargetPurchaseLand,
      targetTileKey: PurchaseLandTestFixture.tileKey,
    ),
  );
  final results = engine.validatePlayerOrdersWithContext(game, topology, 'p1');
  expect(results.single.status, OrderValidationStatus.accepted);
}

void
_rejectsSecondBuilderEngineerMerchantWorkOrderOnSameTileForSamePlayerPerTileExclusivity() {
  const ow = 'oldWorld';
  const provinceId = '$ow|P1';
  const tileKey = '$ow|P1|0|0';
  final tileTopology = MapTopology(
    nodes: const [
      TopologyNode(id: 'P1', regionId: ow, type: TopologyNodeType.province),
    ],
    edges: const [],
  );

  final game = Game(
    id: 'g1',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
      oldWorld: RegionData(
        provinces: const [
          Province(id: provinceId, regionId: ow, ownerId: 'p1'),
        ],
        units: [
          Unit(
            id: 'builder1',
            type: kUnitTypeBuilder,
            ownerId: 'p1',
            locationProvinceId: provinceId,
            tileKey: tileKey,
          ),
          Unit(
            id: 'engineer1',
            type: kUnitTypeEngineer,
            ownerId: 'p1',
            locationProvinceId: provinceId,
            tileKey: tileKey,
          ),
        ],
      ),
      newWorld: const RegionData(),
      resourceByTileKey: const {tileKey: 'grain'},
      // Tile is fully visible so visibility is not the rejecting reason.
      playerVisibilityByTile: const {
        'p1': {tileKey: 'fullyVisible'},
      },
      tileKeysByRegionAndProvince: const {
        ow: {
          provinceId: [tileKey],
        },
      },
    ),
    players: [
      Player(
        id: 'p1',
        displayName: 'P1',
        isHuman: true,
        capitalProvinceId: provinceId,
        // Provide enough materials so material-cost validation passes and
        // the first work order can be accepted.
        stockpile: Stockpile()
            .applyDelta(CommodityCatalog.lumber.id, 10)
            .applyDelta(CommodityCatalog.castIron.id, 10),
      ),
    ],
  );

  final engine = OrderEngine();
  engine
    ..addWorkOrder(
      'p1',
      const WorkOrder(
        unitId: 'builder1',
        target: kWorkTargetBuildImprovement,
        targetTileKey: tileKey,
      ),
    )
    ..addWorkOrder(
      'p1',
      const WorkOrder(
        unitId: 'engineer1',
        target: kWorkTargetBuildRoad,
        targetTileKey: tileKey,
      ),
    );

  final results = engine.validatePlayerOrdersWithContext(
    game,
    tileTopology,
    'p1',
  );

  expect(results.length, 2);
  expect(results[0].status, OrderValidationStatus.accepted);
  expect(results[1].status, OrderValidationStatus.rejected);
  expect(
    results[1].reason,
    contains('Tile already has development or purchase work'),
  );
}

void _acceptsPurchaseLandForMineralWhenProspected() {
  final topology = PurchaseLandTestFixture.topology();
  final tk = PurchaseLandTestFixture.tileKey;
  final game = PurchaseLandTestFixture.baseGame(
    treasury: 500,
    overtureStates: [
      const OvertureState(
        gpId: 'p1',
        targetId: 'minor1',
        stage: OvertureStage.embassy,
        sinceTurn: 0,
      ),
    ],
    resourceByTileKey: {tk: 'iron'},
    playerProspectedTiles: {
      'p1': {tk},
    },
  );
  final engine = OrderEngine();
  engine.addWorkOrder(
    'p1',
    WorkOrder(
      unitId: 'merchant1',
      target: kWorkTargetPurchaseLand,
      targetTileKey: PurchaseLandTestFixture.tileKey,
    ),
  );
  final results = engine.validatePlayerOrdersWithContext(game, topology, 'p1');
  expect(results.single.status, OrderValidationStatus.accepted);
}

void _rejectsPurchaseLandWhenTileAlreadyPurchasedByAnotherGP() {
  final topology = PurchaseLandTestFixture.topology();
  final game = PurchaseLandTestFixture.baseGame(
    treasury: 500,
    overtureStates: [
      const OvertureState(
        gpId: 'p1',
        targetId: 'minor1',
        stage: OvertureStage.embassy,
        sinceTurn: 0,
      ),
    ],
    purchasedTilesByTileKey: {PurchaseLandTestFixture.tileKey: 'p2'},
  );
  final engine = OrderEngine();
  engine.addWorkOrder(
    'p1',
    WorkOrder(
      unitId: 'merchant1',
      target: kWorkTargetPurchaseLand,
      targetTileKey: PurchaseLandTestFixture.tileKey,
    ),
  );
  final results = engine.validatePlayerOrdersWithContext(game, topology, 'p1');
  expect(results.single.status, OrderValidationStatus.rejected);
  expect(
    results.single.reason,
    contains('Tile already purchased by another power'),
  );
}

void _rejectsPurchaseLandWhenTileAlreadyOwnedBySamePlayer() {
  final topology = PurchaseLandTestFixture.topology();
  final game = PurchaseLandTestFixture.baseGame(
    treasury: 500,
    overtureStates: [
      const OvertureState(
        gpId: 'p1',
        targetId: 'minor1',
        stage: OvertureStage.embassy,
        sinceTurn: 0,
      ),
    ],
    purchasedTilesByTileKey: {PurchaseLandTestFixture.tileKey: 'p1'},
  );
  final engine = OrderEngine();
  engine.addWorkOrder(
    'p1',
    WorkOrder(
      unitId: 'merchant1',
      target: kWorkTargetPurchaseLand,
      targetTileKey: PurchaseLandTestFixture.tileKey,
    ),
  );
  final results = engine.validatePlayerOrdersWithContext(game, topology, 'p1');
  expect(results.single.status, OrderValidationStatus.rejected);
  expect(results.single.reason, contains('You already own this tile'));
}

void _rejectsBuildImprovementOnMineralTileWhenNotProspected() {
  const tileKey = ValidateWorkOw.tileKey;
  final game = buildImprovementBaseGame(resourceByTileKey: {tileKey: 'iron'});
  final engine = OrderEngine();
  engine.addWorkOrder(
    'p1',
    const WorkOrder(
      unitId: 'builder1',
      target: kWorkTargetBuildImprovement,
      targetTileKey: tileKey,
    ),
  );
  final results = engine.validatePlayerOrdersWithContext(
    game,
    ValidateWorkOw.topology(),
    'p1',
  );
  expect(results.single.status, OrderValidationStatus.rejected);
  expect(results.single.reason, contains('prospected'));
}

void _acceptsBuildImprovementOnMineralTileAfterProspected() {
  const tileKey = ValidateWorkOw.tileKey;
  final game = buildImprovementBaseGame(
    resourceByTileKey: {tileKey: 'iron'},
    playerProspectedTiles: {
      'p1': {tileKey},
    },
  );
  final engine = OrderEngine();
  engine.addWorkOrder(
    'p1',
    const WorkOrder(
      unitId: 'builder1',
      target: kWorkTargetBuildImprovement,
      targetTileKey: tileKey,
    ),
  );
  final results = engine.validatePlayerOrdersWithContext(
    game,
    ValidateWorkOw.topology(),
    'p1',
  );
  expect(results.single.status, OrderValidationStatus.accepted);
}

void _acceptsBuildImprovementOnGrainWhenTileNotProspected() {
  const tileKey = ValidateWorkOw.tileKey;
  final game = buildImprovementBaseGame(resourceByTileKey: {tileKey: 'grain'});
  final engine = OrderEngine();
  engine.addWorkOrder(
    'p1',
    const WorkOrder(
      unitId: 'builder1',
      target: kWorkTargetBuildImprovement,
      targetTileKey: tileKey,
    ),
  );
  final results = engine.validatePlayerOrdersWithContext(
    game,
    ValidateWorkOw.topology(),
    'p1',
  );
  expect(results.single.status, OrderValidationStatus.accepted);
}

void _rejectsBuildImprovementWhenTileHasNoResource() {
  const tileKey = ValidateWorkOw.tileKey;
  final game = buildImprovementBaseGame(resourceByTileKey: {});
  final engine = OrderEngine();
  engine.addWorkOrder(
    'p1',
    const WorkOrder(
      unitId: 'builder1',
      target: kWorkTargetBuildImprovement,
      targetTileKey: tileKey,
    ),
  );
  final results = engine.validatePlayerOrdersWithContext(
    game,
    ValidateWorkOw.topology(),
    'p1',
  );
  expect(results.single.status, OrderValidationStatus.rejected);
  expect(results.single.reason, contains('no resource'));
}

void _rejectsBuildImprovementWhenImprovementLevelAlready4() {
  const tileKey = ValidateWorkOw.tileKey;
  final game = buildImprovementBaseGame(
    tileState: const TileMapState(improvementByTile: {'oldWorld|P1|0|0': 4}),
    stockpile: Stockpile()
        .applyDelta(CommodityCatalog.lumber.id, 20)
        .applyDelta(CommodityCatalog.castIron.id, 20),
  );
  final engine = OrderEngine();
  engine.addWorkOrder(
    'p1',
    const WorkOrder(
      unitId: 'builder1',
      target: kWorkTargetBuildImprovement,
      targetTileKey: tileKey,
    ),
  );
  final results = engine.validatePlayerOrdersWithContext(
    game,
    ValidateWorkOw.topology(),
    'p1',
  );
  expect(results.single.status, OrderValidationStatus.rejected);
  expect(results.single.reason, contains('maximum'));
}

void _rejectsBuildImprovementWhenTechCapWouldBeExceededEmptyTech() {
  const tileKey = ValidateWorkOw.tileKey;
  final game = buildImprovementBaseGame(
    techUnlocked: const {},
    tileState: const TileMapState(improvementByTile: {'oldWorld|P1|0|0': 1}),
    stockpile: Stockpile()
        .applyDelta(CommodityCatalog.lumber.id, 10)
        .applyDelta(CommodityCatalog.castIron.id, 10),
  );
  final engine = OrderEngine();
  engine.addWorkOrder(
    'p1',
    const WorkOrder(
      unitId: 'builder1',
      target: kWorkTargetBuildImprovement,
      targetTileKey: tileKey,
    ),
  );
  final results = engine.validatePlayerOrdersWithContext(
    game,
    ValidateWorkOw.topology(),
    'p1',
  );
  expect(results.single.status, OrderValidationStatus.rejected);
  expect(results.single.reason, contains('Insufficient tech'));
  expect(results.single.reason, contains('grain'));
  expect(results.single.reason, contains('cap 1'));
}

void _rejectsBuildImprovementWhenTechCapWouldBeExceeded() {
  const tileKey = ValidateWorkOw.tileKey;
  // With no grain-cap tech, grain stays at cap 1; tile at level 1 cannot upgrade.
  final game = buildImprovementBaseGame(
    techUnlocked: const {kTechIdSawMill: true},
    tileState: const TileMapState(improvementByTile: {'oldWorld|P1|0|0': 1}),
    stockpile: Stockpile()
        .applyDelta(CommodityCatalog.lumber.id, 10)
        .applyDelta(CommodityCatalog.castIron.id, 10),
  );
  final engine = OrderEngine();
  engine.addWorkOrder(
    'p1',
    const WorkOrder(
      unitId: 'builder1',
      target: kWorkTargetBuildImprovement,
      targetTileKey: tileKey,
    ),
  );
  final results = engine.validatePlayerOrdersWithContext(
    game,
    ValidateWorkOw.topology(),
    'p1',
  );
  expect(results.single.status, OrderValidationStatus.rejected);
  expect(results.single.reason, contains('Insufficient tech'));
  expect(results.single.reason, contains('cap 1'));
}

void _acceptsGrainUpgradeWhenExactNextLevelGrainTechIsUnlocked() {
  const tileKey = ValidateWorkOw.tileKey;
  final game = buildImprovementBaseGame(
    techUnlocked: const {kTechIdLandEnclosure: true},
    tileState: const TileMapState(improvementByTile: {'oldWorld|P1|0|0': 1}),
    stockpile: Stockpile()
        .applyDelta(CommodityCatalog.lumber.id, 10)
        .applyDelta(CommodityCatalog.castIron.id, 10),
  );
  final engine = OrderEngine();
  engine.addWorkOrder(
    'p1',
    const WorkOrder(
      unitId: 'builder1',
      target: kWorkTargetBuildImprovement,
      targetTileKey: tileKey,
    ),
  );
  final results = engine.validatePlayerOrdersWithContext(
    game,
    ValidateWorkOw.topology(),
    'p1',
  );
  expect(results.single.status, OrderValidationStatus.accepted);
}

void _acceptsBuildImprovementWhenTileHasResourceLevel4TechCapAllows() {
  const tileKey = ValidateWorkOw.tileKey;
  final game = buildImprovementBaseGame(
    resourceByTileKey: {tileKey: 'grain'},
    tileState: const TileMapState(),
    techUnlocked: const {kTechIdCircularSaw: true},
  );
  final engine = OrderEngine();
  engine.addWorkOrder(
    'p1',
    const WorkOrder(
      unitId: 'builder1',
      target: kWorkTargetBuildImprovement,
      targetTileKey: tileKey,
    ),
  );
  final results = engine.validatePlayerOrdersWithContext(
    game,
    ValidateWorkOw.topology(),
    'p1',
  );
  expect(results.single.status, OrderValidationStatus.accepted);
}

void _rejectsBuildImprovementInForeignUnpurchasedProvince() {
  const ow = ValidateWorkOw.ow;
  const provinceId = ValidateWorkOw.provinceId;
  const tileKey = ValidateWorkOw.tileKey;
  final foreignProvinceId = '$ow|P2';
  final foreignTileKey = '$foreignProvinceId|0|0';
  final game = Game(
    id: 'g1',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
      oldWorld: RegionData(
        provinces: [
          Province(id: provinceId, regionId: ow, ownerId: 'p1'),
          Province(id: foreignProvinceId, regionId: ow, ownerId: 'p2'),
        ],
        units: [
          Unit(
            id: 'builder1',
            type: kUnitTypeBuilder,
            ownerId: 'p1',
            locationProvinceId: provinceId,
            tileKey: tileKey,
          ),
        ],
      ),
      newWorld: const RegionData(),
      resourceByTileKey: {tileKey: 'grain', foreignTileKey: 'grain'},
      tileState: const TileMapState(),
      tileKeysByRegionAndProvince: {
        ow: {
          provinceId: [tileKey],
          foreignProvinceId: [foreignTileKey],
        },
      },
      playerVisibilityByTile: {
        'p1': {tileKey: 'fullyVisible', foreignTileKey: 'fullyVisible'},
      },
    ),
    players: [
      Player(
        id: 'p1',
        displayName: 'P1',
        isHuman: true,
        capitalProvinceId: provinceId,
        stockpile: Stockpile()
            .applyDelta(CommodityCatalog.lumber.id, 2)
            .applyDelta(CommodityCatalog.castIron.id, 2),
        techUnlocked: const {kTechIdCircularSaw: true},
      ),
      const Player(id: 'p2', displayName: 'P2', isHuman: false),
    ],
  );
  final engine = OrderEngine();
  engine.addWorkOrder(
    'p1',
    WorkOrder(
      unitId: 'builder1',
      target: kWorkTargetBuildImprovement,
      targetTileKey: foreignTileKey,
    ),
  );
  final results = engine.validatePlayerOrdersWithContext(
    game,
    ValidateWorkOw.topology(),
    'p1',
  );
  expect(results.single.status, OrderValidationStatus.rejected);
  expect(results.single.reason, contains('foreign or uncontrolled province'));
}

void _rejectsRaisingScrubTimberFromLevel1EvenWithCircularSaw() {
  OrderValidationResult validate(Game game, TerrainType terrain) {
    final engine = OrderEngine();
    engine.addWorkOrder(
      'p1',
      const WorkOrder(
        unitId: 'builder1',
        target: kWorkTargetBuildImprovement,
        targetTileKey: ValidateWorkOw.tileKey,
      ),
    );
    return engine
        .validatePlayerOrdersWithContext(
          game,
          ValidateWorkOw.topology(),
          'p1',
          tileMapByRegion: scrubCapTileMaps(terrain),
        )
        .single;
  }

  final result = validate(scrubCapBaseGame(level: 1), TerrainType.scrubForest);
  expect(result.status, OrderValidationStatus.rejected);
  expect(result.reason, contains('Terrain caps'));
  expect(result.reason, contains('level 1'));
}

void _acceptsRaisingHardwoodTimberFromLevel1WithCircularSaw() {
  OrderValidationResult validate(Game game, TerrainType terrain) {
    final engine = OrderEngine();
    engine.addWorkOrder(
      'p1',
      const WorkOrder(
        unitId: 'builder1',
        target: kWorkTargetBuildImprovement,
        targetTileKey: ValidateWorkOw.tileKey,
      ),
    );
    return engine
        .validatePlayerOrdersWithContext(
          game,
          ValidateWorkOw.topology(),
          'p1',
          tileMapByRegion: scrubCapTileMaps(terrain),
        )
        .single;
  }

  final result = validate(
    scrubCapBaseGame(level: 1),
    TerrainType.hardwoodForest,
  );
  expect(result.status, OrderValidationStatus.accepted);
}

void _acceptsInitialScrubTimberImprovementLevel01() {
  OrderValidationResult validate(Game game, TerrainType terrain) {
    final engine = OrderEngine();
    engine.addWorkOrder(
      'p1',
      const WorkOrder(
        unitId: 'builder1',
        target: kWorkTargetBuildImprovement,
        targetTileKey: ValidateWorkOw.tileKey,
      ),
    );
    return engine
        .validatePlayerOrdersWithContext(
          game,
          ValidateWorkOw.topology(),
          'p1',
          tileMapByRegion: scrubCapTileMaps(terrain),
        )
        .single;
  }

  final result = validate(scrubCapBaseGame(level: 0), TerrainType.scrubForest);
  expect(result.status, OrderValidationStatus.accepted);
}

void _acceptsBuildImprovementOnPurchasedTileInForeignProvince() {
  const ow = ValidateWorkOw.ow;
  const provinceId = ValidateWorkOw.provinceId;
  const tileKey = ValidateWorkOw.tileKey;
  final foreignProvinceId = '$ow|P2';
  final foreignTileKey = '$foreignProvinceId|0|0';
  final game = Game(
    id: 'g1',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
      oldWorld: RegionData(
        provinces: [
          Province(id: provinceId, regionId: ow, ownerId: 'p1'),
          Province(id: foreignProvinceId, regionId: ow, ownerId: 'p2'),
        ],
        units: [
          Unit(
            id: 'builder1',
            type: kUnitTypeBuilder,
            ownerId: 'p1',
            locationProvinceId: provinceId,
            tileKey: tileKey,
          ),
        ],
      ),
      newWorld: const RegionData(),
      resourceByTileKey: {tileKey: 'grain', foreignTileKey: 'grain'},
      tileState: const TileMapState(),
      tileKeysByRegionAndProvince: {
        ow: {
          provinceId: [tileKey],
          foreignProvinceId: [foreignTileKey],
        },
      },
      playerVisibilityByTile: {
        'p1': {tileKey: 'fullyVisible', foreignTileKey: 'fullyVisible'},
      },
      purchasedTilesByTileKey: {foreignTileKey: 'p1'},
    ),
    players: [
      Player(
        id: 'p1',
        displayName: 'P1',
        isHuman: true,
        capitalProvinceId: provinceId,
        stockpile: Stockpile()
            .applyDelta(CommodityCatalog.lumber.id, 2)
            .applyDelta(CommodityCatalog.castIron.id, 2),
        techUnlocked: const {kTechIdCircularSaw: true},
      ),
      const Player(id: 'p2', displayName: 'P2', isHuman: false),
    ],
  );
  final engine = OrderEngine();
  engine.addWorkOrder(
    'p1',
    WorkOrder(
      unitId: 'builder1',
      target: kWorkTargetBuildImprovement,
      targetTileKey: foreignTileKey,
    ),
  );
  final results = engine.validatePlayerOrdersWithContext(
    game,
    ValidateWorkOw.topology(),
    'p1',
  );
  expect(results.single.status, OrderValidationStatus.accepted);
}

void _rejectsBuildFortToLevel2WithoutMineEngineering() {
  const ow = ValidateWorkOw.ow;
  const provinceId = ValidateWorkOw.provinceId;
  const tileKey = ValidateWorkOw.tileKey;
  final game = Game(
    id: 'g1',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
      oldWorld: RegionData(
        provinces: [
          Province(id: provinceId, regionId: ow, ownerId: 'p1', fortLevel: 1),
        ],
        units: [
          Unit(
            id: 'eng1',
            type: kUnitTypeEngineer,
            ownerId: 'p1',
            locationProvinceId: provinceId,
            tileKey: tileKey,
          ),
        ],
      ),
      newWorld: const RegionData(),
      tileKeysByRegionAndProvince: {
        ow: {
          provinceId: [tileKey],
        },
      },
      playerVisibilityByTile: const {
        'p1': {tileKey: 'fullyVisible'},
      },
    ),
    players: [
      Player(
        id: 'p1',
        displayName: 'P1',
        isHuman: true,
        capitalProvinceId: provinceId,
        stockpile: Stockpile()
            .applyDelta(CommodityCatalog.lumber.id, 4)
            .applyDelta(CommodityCatalog.bronze.id, 4),
        techUnlocked: {},
      ),
    ],
  );
  final engine = OrderEngine();
  engine.addWorkOrder(
    'p1',
    const WorkOrder(
      unitId: 'eng1',
      target: kWorkTargetBuildFort,
      targetTileKey: tileKey,
    ),
  );
  final results = engine.validatePlayerOrdersWithContext(
    game,
    ValidateWorkOw.topology(),
    'p1',
  );
  expect(results.single.status, OrderValidationStatus.rejected);
  expect(results.single.reason, contains('Mine Engineering'));
}

void _rejectsBuildFortToLevel3WithoutModernForts() {
  const ow = ValidateWorkOw.ow;
  const provinceId = ValidateWorkOw.provinceId;
  const tileKey = ValidateWorkOw.tileKey;
  final game = Game(
    id: 'g1',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
      oldWorld: RegionData(
        provinces: [
          Province(id: provinceId, regionId: ow, ownerId: 'p1', fortLevel: 2),
        ],
        units: [
          Unit(
            id: 'eng1',
            type: kUnitTypeEngineer,
            ownerId: 'p1',
            locationProvinceId: provinceId,
            tileKey: tileKey,
          ),
        ],
      ),
      newWorld: const RegionData(),
      tileKeysByRegionAndProvince: {
        ow: {
          provinceId: [tileKey],
        },
      },
      playerVisibilityByTile: const {
        'p1': {tileKey: 'fullyVisible'},
      },
    ),
    players: [
      Player(
        id: 'p1',
        displayName: 'P1',
        isHuman: true,
        capitalProvinceId: provinceId,
        stockpile: Stockpile()
            .applyDelta(CommodityCatalog.steel.id, 5)
            .applyDelta(CommodityCatalog.lumber.id, 5),
        techUnlocked: const {kTechIdMineEngineering: true},
      ),
    ],
  );
  final engine = OrderEngine();
  engine.addWorkOrder(
    'p1',
    const WorkOrder(
      unitId: 'eng1',
      target: kWorkTargetBuildFort,
      targetTileKey: tileKey,
    ),
  );
  final results = engine.validatePlayerOrdersWithContext(
    game,
    ValidateWorkOw.topology(),
    'p1',
  );
  expect(results.single.status, OrderValidationStatus.rejected);
  expect(results.single.reason, contains('Modern Forts'));
}

void _rejectsBuildRailWhenTileTerrainDataIsMissing() {
  const tileKey = ValidateWorkOw.tileKey;
  final game = gameWithRailUnit(
    tileState: TileMapState().setRoadLevel(tileKey, 1),
  );
  final engine = OrderEngine();
  engine.addWorkOrder(
    'p1',
    const WorkOrder(
      unitId: 'rail1',
      target: kWorkTargetBuildRail,
      targetTileKey: tileKey,
    ),
  );
  final results = engine.validatePlayerOrdersWithContext(
    game,
    ValidateWorkOw.topology(),
    'p1',
    tileMapByRegion: null,
  );
  expect(results.single.status, OrderValidationStatus.rejected);
  expect(results.single.reason, contains('terrain data required'));
}

void _rejectsBuildRailWhenRoadLevelIs0() {
  const ow = ValidateWorkOw.ow;
  const tileKey = ValidateWorkOw.tileKey;
  final game = gameWithRailUnit(
    tileState: TileMapState().setRoadLevel(tileKey, 0),
  );
  final engine = OrderEngine();
  engine.addWorkOrder(
    'p1',
    const WorkOrder(
      unitId: 'rail1',
      target: kWorkTargetBuildRail,
      targetTileKey: tileKey,
    ),
  );
  final results = engine.validatePlayerOrdersWithContext(
    game,
    ValidateWorkOw.topology(),
    'p1',
    tileMapByRegion: {ow: railTileMap(TerrainType.plains)},
  );
  expect(results.single.status, OrderValidationStatus.rejected);
  expect(results.single.reason, contains('existing road'));
}

void _rejectsBuildRailOnHillsWithOnlyEarlySteam() {
  const ow = ValidateWorkOw.ow;
  const tileKey = ValidateWorkOw.tileKey;
  final game = gameWithRailUnit(
    tileState: TileMapState().setRoadLevel(tileKey, 1),
    techUnlocked: const {kTechIdEarlySteamEngine: true},
  );
  final engine = OrderEngine();
  engine.addWorkOrder(
    'p1',
    const WorkOrder(
      unitId: 'rail1',
      target: kWorkTargetBuildRail,
      targetTileKey: tileKey,
    ),
  );
  final results = engine.validatePlayerOrdersWithContext(
    game,
    ValidateWorkOw.topology(),
    'p1',
    tileMapByRegion: {ow: railTileMap(TerrainType.hills)},
  );
  expect(results.single.status, OrderValidationStatus.rejected);
  expect(results.single.reason, contains('Later Steam'));
}

void _acceptsBuildRailOnPlainsWithEarlySteamAndRoad1() {
  const ow = ValidateWorkOw.ow;
  const tileKey = ValidateWorkOw.tileKey;
  final game = gameWithRailUnit(
    tileState: TileMapState().setRoadLevel(tileKey, 1),
  );
  final engine = OrderEngine();
  engine.addWorkOrder(
    'p1',
    const WorkOrder(
      unitId: 'rail1',
      target: kWorkTargetBuildRail,
      targetTileKey: tileKey,
    ),
  );
  final results = engine.validatePlayerOrdersWithContext(
    game,
    ValidateWorkOw.topology(),
    'p1',
    tileMapByRegion: {ow: railTileMap(TerrainType.plains)},
  );
  expect(results.single.status, OrderValidationStatus.accepted);
}

void _rejectsBuildRoadInMinorProvinceWithoutEmbassyPath() {
  const ow = 'oldWorld';
  const minorProvId = '$ow|MN';
  const tileKey = '$minorProvId|0|0';
  final topology = MapTopology(
    nodes: const [
      TopologyNode(id: 'MN', regionId: ow, type: TopologyNodeType.province),
    ],
    edges: const [],
  );
  final game = Game(
    id: 'g1',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
      oldWorld: RegionData(
        provinces: [Province(id: minorProvId, regionId: ow, ownerId: 'minor1')],
        units: [
          Unit(
            id: 'e1',
            type: kUnitTypeEngineer,
            ownerId: 'gp1',
            locationProvinceId: minorProvId,
            tileKey: tileKey,
          ),
        ],
      ),
      newWorld: const RegionData(),
      tileKeysByRegionAndProvince: {
        ow: {
          minorProvId: [tileKey],
        },
      },
      playerVisibilityByTile: const {
        'gp1': {tileKey: 'fullyVisible'},
      },
    ),
    players: [
      Player(
        id: 'gp1',
        displayName: 'GP1',
        isHuman: true,
        capitalProvinceId: '$ow|CAP',
        stockpile: Stockpile()
            .applyDelta(CommodityCatalog.lumber.id, 4)
            .applyDelta(CommodityCatalog.castIron.id, 4),
        techUnlocked: const {kTechIdDiplomaticExpertise: true},
      ),
    ],
    minorNations: const [MinorNation(id: 'minor1', displayName: 'Minor')],
    diplomacyRelations: const [
      DiplomacyRelation(
        factionId1: 'gp1',
        factionId2: 'minor1',
        state: RelationState.atPeace,
        level: RelationLevel.neutral,
      ),
    ],
  );
  final engine = OrderEngine();
  engine.addWorkOrder(
    'gp1',
    const WorkOrder(
      unitId: 'e1',
      target: kWorkTargetBuildRoad,
      targetTileKey: tileKey,
    ),
  );
  final results = engine.validatePlayerOrdersWithContext(game, topology, 'gp1');
  expect(results.single.status, OrderValidationStatus.rejected);
  expect(results.single.reason, contains('foreign province'));
}

void
_rejectsBuildRoadInMinorProvinceEvenWithEmbassyWhenOccupancyDisallowsTile() {
  const ow = 'oldWorld';
  const minorProvId = '$ow|MN';
  const tileKey = '$minorProvId|0|0';
  final topology = MapTopology(
    nodes: const [
      TopologyNode(id: 'MN', regionId: ow, type: TopologyNodeType.province),
    ],
    edges: const [],
  );
  final game = Game(
    id: 'g1',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
      oldWorld: RegionData(
        provinces: [Province(id: minorProvId, regionId: ow, ownerId: 'minor1')],
        units: [
          Unit(
            id: 'e1',
            type: kUnitTypeEngineer,
            ownerId: 'gp1',
            locationProvinceId: minorProvId,
            tileKey: tileKey,
          ),
        ],
      ),
      newWorld: const RegionData(),
      tileKeysByRegionAndProvince: {
        ow: {
          minorProvId: [tileKey],
        },
      },
      playerVisibilityByTile: const {
        'gp1': {tileKey: 'fullyVisible'},
      },
    ),
    players: [
      Player(
        id: 'gp1',
        displayName: 'GP1',
        isHuman: true,
        capitalProvinceId: '$ow|CAP',
        stockpile: Stockpile()
            .applyDelta(CommodityCatalog.lumber.id, 4)
            .applyDelta(CommodityCatalog.castIron.id, 4),
        techUnlocked: const {kTechIdDiplomaticExpertise: true},
      ),
    ],
    minorNations: const [MinorNation(id: 'minor1', displayName: 'Minor')],
    diplomacyRelations: const [
      DiplomacyRelation(
        factionId1: 'gp1',
        factionId2: 'minor1',
        state: RelationState.atPeace,
        level: RelationLevel.neutral,
      ),
    ],
    overtureStates: const [
      OvertureState(
        gpId: 'gp1',
        targetId: 'minor1',
        stage: OvertureStage.embassy,
        sinceTurn: 0,
      ),
    ],
  );
  final engine = OrderEngine();
  engine.addWorkOrder(
    'gp1',
    const WorkOrder(
      unitId: 'e1',
      target: kWorkTargetBuildRoad,
      targetTileKey: tileKey,
    ),
  );
  final results = engine.validatePlayerOrdersWithContext(game, topology, 'gp1');
  expect(results.single.status, OrderValidationStatus.rejected);
  expect(results.single.reason, contains('cannot occupy'));
}

void _rejectsUpgradeTownWithoutNationalBureaucracy() {
  const ow = ValidateWorkOw.ow;
  const provinceId = ValidateWorkOw.provinceId;
  const tileKey = ValidateWorkOw.tileKey;
  final game = Game(
    id: 'g1',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
      oldWorld: RegionData(
        provinces: [
          Province(
            id: provinceId,
            regionId: ow,
            ownerId: 'p1',
            townTileKey: tileKey,
            townDevelopmentLevel: 1,
          ),
        ],
        units: [
          Unit(
            id: 'b1',
            type: kUnitTypeBuilder,
            ownerId: 'p1',
            locationProvinceId: provinceId,
            tileKey: tileKey,
          ),
        ],
      ),
      newWorld: const RegionData(),
      tileKeysByRegionAndProvince: {
        ow: {
          provinceId: [tileKey],
        },
      },
      playerVisibilityByTile: const {
        'p1': {tileKey: 'fullyVisible'},
      },
    ),
    players: [
      Player(
        id: 'p1',
        displayName: 'P1',
        isHuman: true,
        capitalProvinceId: provinceId,
        stockpile: Stockpile()
            .applyDelta(CommodityCatalog.lumber.id, 10)
            .applyDelta(CommodityCatalog.castIron.id, 10),
        techUnlocked: const {},
      ),
    ],
  );
  final engine = OrderEngine();
  engine.addWorkOrder(
    'p1',
    const WorkOrder(
      unitId: 'b1',
      target: kWorkTargetUpgradeTown,
      targetTileKey: tileKey,
    ),
  );
  final results = engine.validatePlayerOrdersWithContext(
    game,
    ValidateWorkOw.topology(),
    'p1',
  );
  expect(results.single.status, OrderValidationStatus.rejected);
  expect(results.single.reason, contains('National Bureaucracy'));
}

void _acceptsUpgradeTownWhenNationalBureaucracyUnlocked() {
  const ow = ValidateWorkOw.ow;
  const provinceId = ValidateWorkOw.provinceId;
  const tileKey = ValidateWorkOw.tileKey;
  final game = Game(
    id: 'g1',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
      oldWorld: RegionData(
        provinces: [
          Province(
            id: provinceId,
            regionId: ow,
            ownerId: 'p1',
            townTileKey: tileKey,
            townDevelopmentLevel: 1,
          ),
        ],
        units: [
          Unit(
            id: 'b1',
            type: kUnitTypeBuilder,
            ownerId: 'p1',
            locationProvinceId: provinceId,
            tileKey: tileKey,
          ),
        ],
      ),
      newWorld: const RegionData(),
      tileKeysByRegionAndProvince: {
        ow: {
          provinceId: [tileKey],
        },
      },
      playerVisibilityByTile: const {
        'p1': {tileKey: 'fullyVisible'},
      },
    ),
    players: [
      Player(
        id: 'p1',
        displayName: 'P1',
        isHuman: true,
        capitalProvinceId: provinceId,
        stockpile: Stockpile()
            .applyDelta(CommodityCatalog.lumber.id, 10)
            .applyDelta(CommodityCatalog.castIron.id, 10),
        techUnlocked: const {kTechIdNationalBureaucracy: true},
      ),
    ],
  );
  final engine = OrderEngine();
  engine.addWorkOrder(
    'p1',
    const WorkOrder(
      unitId: 'b1',
      target: kWorkTargetUpgradeTown,
      targetTileKey: tileKey,
    ),
  );
  final results = engine.validatePlayerOrdersWithContext(
    game,
    ValidateWorkOw.topology(),
    'p1',
  );
  expect(results.single.status, OrderValidationStatus.accepted);
}
