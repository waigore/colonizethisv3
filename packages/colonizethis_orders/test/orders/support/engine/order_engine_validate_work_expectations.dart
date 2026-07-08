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

OrderValidationResult _validateSingleWork({
  required Game game,
  required WorkOrder order,
  MapTopology? topology,
  Map<String, TileMapResult>? tileMapByRegion,
  String playerId = 'p1',
}) {
  final engine = OrderEngine();
  engine.addWorkOrder(playerId, order);
  return engine
      .validatePlayerOrdersWithContext(
        game,
        topology ?? ValidateWorkOw.topology(),
        playerId,
        tileMapByRegion: tileMapByRegion,
      )
      .single;
}

OrderValidationResult _validateBuildImprovement({
  required Game game,
  Map<String, TileMapResult>? tileMapByRegion,
  String targetTileKey = ValidateWorkOw.tileKey,
  String unitId = 'builder1',
}) => _validateSingleWork(
  game: game,
  order: WorkOrder(
    unitId: unitId,
    target: kWorkTargetBuildImprovement,
    targetTileKey: targetTileKey,
  ),
  tileMapByRegion: tileMapByRegion,
);

OrderValidationResult _validateOwWorkTarget({
  required Game game,
  required String unitId,
  required String target,
  Map<String, TileMapResult>? tileMapByRegion,
}) => _validateSingleWork(
  game: game,
  order: WorkOrder(
    unitId: unitId,
    target: target,
    targetTileKey: ValidateWorkOw.tileKey,
  ),
  tileMapByRegion: tileMapByRegion,
);

List<OrderValidationResult> _runPurchaseLandValidation(Game game) {
  final engine = OrderEngine();
  engine.addWorkOrder(
    'p1',
    WorkOrder(
      unitId: 'merchant1',
      target: kWorkTargetPurchaseLand,
      targetTileKey: PurchaseLandTestFixture.tileKey,
    ),
  );
  return engine.validatePlayerOrdersWithContext(
    game,
    PurchaseLandTestFixture.topology(),
    'p1',
  );
}

OrderValidationResult _runUpgradeTownValidation(Game game) {
  final engine = OrderEngine();
  engine.addWorkOrder(
    'p1',
    const WorkOrder(
      unitId: 'b1',
      target: kWorkTargetUpgradeTown,
      targetTileKey: ValidateWorkOw.tileKey,
    ),
  );
  return engine
      .validatePlayerOrdersWithContext(
        game,
        ValidateWorkOw.topology(),
        'p1',
      )
      .single;
}

OrderValidationResult _runMinorProvinceRoadValidation(Game game) {
  final engine = OrderEngine();
  engine.addWorkOrder(
    'gp1',
    WorkOrder(
      unitId: 'e1',
      target: kWorkTargetBuildRoad,
      targetTileKey: minorProvinceRoadTileKey(),
    ),
  );
  return engine
      .validatePlayerOrdersWithContext(
        game,
        minorProvinceRoadTopology(),
        'gp1',
      )
      .single;
}

void _rejectsSecondPendingWorkOrderForSameUnitInOneTurn() {
  final game = dualTilePendingWorkGame();
  const tileA = ValidateWorkOw.tileKey;
  const tileB = '${ValidateWorkOw.provinceId}|1|0';

  final engine = OrderEngine();
  engine
    ..addWorkOrder(
      'p1',
      const WorkOrder(
        unitId: 'builder1',
        target: kWorkTargetBuildImprovement,
        targetTileKey: tileA,
      ),
    )
    ..addWorkOrder(
      'p1',
      const WorkOrder(
        unitId: 'builder1',
        target: kWorkTargetBuildImprovement,
        targetTileKey: tileB,
      ),
    );

  final results = engine.validatePlayerOrdersWithContext(
    game,
    ValidateWorkOw.topology(),
    'p1',
  );
  expect(results, hasLength(2));
  expect(results.first.status, OrderValidationStatus.accepted);
  expect(results.last.status, OrderValidationStatus.rejected);
  expect(
    results.last.reason,
    contains('Only one work order per unit is allowed each turn'),
  );
}

void _rejectsPurchaseLandWhenNoEmbassyWithMinor() {
  final results = _runPurchaseLandValidation(
    PurchaseLandTestFixture.baseGame(treasury: 500),
  );
  expect(results.single.status, OrderValidationStatus.rejected);
  expect(results.single.reason, contains('embassy'));
}

void _rejectsPurchaseLandWhenAtWarWithFaction() {
  final results = _runPurchaseLandValidation(
    PurchaseLandTestFixture.baseGame(
      treasury: 500,
      overtureStates: purchaseLandEmbassyOverture,
      diplomacyRelations: const [
        DiplomacyRelation(
          factionId1: 'p1',
          factionId2: 'minor1',
          state: RelationState.atWar,
        ),
      ],
    ),
  );
  expect(results.single.status, OrderValidationStatus.rejected);
  expect(results.single.reason, contains('war'));
}

void _rejectsPurchaseLandWhenInsufficientTreasury() {
  const cost = 15 * 10; // grain default base 10
  final results = _runPurchaseLandValidation(
    PurchaseLandTestFixture.baseGame(
      treasury: cost - 1,
      overtureStates: purchaseLandEmbassyOverture,
    ),
  );
  expect(results.single.status, OrderValidationStatus.rejected);
  expect(results.single.reason, contains('Insufficient treasury'));
}

void _rejectsPurchaseLandWhenTileHasNoResource() {
  final results = _runPurchaseLandValidation(
    PurchaseLandTestFixture.baseGame(
      treasury: 500,
      overtureStates: purchaseLandEmbassyOverture,
      resourceByTileKey: {},
    ),
  );
  expect(results.single.status, OrderValidationStatus.rejected);
  expect(results.single.reason, contains('no resource'));
}

void _rejectsPurchaseLandWhenMineralTileNotProspected() {
  final tk = PurchaseLandTestFixture.tileKey;
  final results = _runPurchaseLandValidation(
    PurchaseLandTestFixture.baseGame(
      treasury: 500,
      overtureStates: purchaseLandEmbassyOverture,
      resourceByTileKey: {tk: 'iron'},
      playerProspectedTiles: {},
    ),
  );
  expect(results.single.status, OrderValidationStatus.rejected);
  expect(results.single.reason, contains('prospected'));
}

void
_acceptsPurchaseLandWithEmbassyAtPeaceSufficientTreasuryTileWithResource() {
  final results = _runPurchaseLandValidation(
    PurchaseLandTestFixture.baseGame(
      treasury: 500,
      overtureStates: purchaseLandEmbassyOverture,
    ),
  );
  expect(results.single.status, OrderValidationStatus.accepted);
}

void
_rejectsSecondBuilderEngineerMerchantWorkOrderOnSameTileForSamePlayerPerTileExclusivity() {
  const tileKey = ValidateWorkOw.tileKey;
  final game = builderEngineerSameTileExclusivityGame();

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
    ValidateWorkOw.topology(),
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
  final tk = PurchaseLandTestFixture.tileKey;
  final results = _runPurchaseLandValidation(
    PurchaseLandTestFixture.baseGame(
      treasury: 500,
      overtureStates: purchaseLandEmbassyOverture,
      resourceByTileKey: {tk: 'iron'},
      playerProspectedTiles: {
        'p1': {tk},
      },
    ),
  );
  expect(results.single.status, OrderValidationStatus.accepted);
}

void _rejectsPurchaseLandWhenTileAlreadyPurchasedByAnotherGP() {
  final results = _runPurchaseLandValidation(
    PurchaseLandTestFixture.baseGame(
      treasury: 500,
      overtureStates: purchaseLandEmbassyOverture,
      purchasedTilesByTileKey: {PurchaseLandTestFixture.tileKey: 'p2'},
    ),
  );
  expect(results.single.status, OrderValidationStatus.rejected);
  expect(
    results.single.reason,
    contains('Tile already purchased by another power'),
  );
}

void _rejectsPurchaseLandWhenTileAlreadyOwnedBySamePlayer() {
  final results = _runPurchaseLandValidation(
    PurchaseLandTestFixture.baseGame(
      treasury: 500,
      overtureStates: purchaseLandEmbassyOverture,
      purchasedTilesByTileKey: {PurchaseLandTestFixture.tileKey: 'p1'},
    ),
  );
  expect(results.single.status, OrderValidationStatus.rejected);
  expect(results.single.reason, contains('You already own this tile'));
}

void _rejectsBuildImprovementOnMineralTileWhenNotProspected() {
  const tileKey = ValidateWorkOw.tileKey;
  final result = _validateBuildImprovement(
    game: buildImprovementBaseGame(resourceByTileKey: {tileKey: 'iron'}),
  );
  expect(result.status, OrderValidationStatus.rejected);
  expect(result.reason, contains('prospected'));
}

void _acceptsBuildImprovementOnMineralTileAfterProspected() {
  const tileKey = ValidateWorkOw.tileKey;
  final result = _validateBuildImprovement(
    game: buildImprovementBaseGame(
      resourceByTileKey: {tileKey: 'iron'},
      playerProspectedTiles: {
        'p1': {tileKey},
      },
    ),
  );
  expect(result.status, OrderValidationStatus.accepted);
}

void _acceptsBuildImprovementOnGrainWhenTileNotProspected() {
  const tileKey = ValidateWorkOw.tileKey;
  final result = _validateBuildImprovement(
    game: buildImprovementBaseGame(resourceByTileKey: {tileKey: 'grain'}),
  );
  expect(result.status, OrderValidationStatus.accepted);
}

void _rejectsBuildImprovementWhenTileHasNoResource() {
  final result = _validateBuildImprovement(
    game: buildImprovementBaseGame(resourceByTileKey: {}),
  );
  expect(result.status, OrderValidationStatus.rejected);
  expect(result.reason, contains('no resource'));
}

void _rejectsBuildImprovementWhenImprovementLevelAlready4() {
  final result = _validateBuildImprovement(
    game: buildImprovementBaseGame(
      tileState: const TileMapState(improvementByTile: {'oldWorld|P1|0|0': 4}),
      stockpile: lumberCastIronStockpile(20),
    ),
  );
  expect(result.status, OrderValidationStatus.rejected);
  expect(result.reason, contains('maximum'));
}

void _rejectsBuildImprovementWhenTechCapWouldBeExceededEmptyTech() {
  final result = _validateBuildImprovement(
    game: buildImprovementBaseGame(
      techUnlocked: const {},
      tileState: const TileMapState(improvementByTile: {'oldWorld|P1|0|0': 1}),
      stockpile: lumberCastIronStockpile(10),
    ),
  );
  expect(result.status, OrderValidationStatus.rejected);
  expect(result.reason, contains('Insufficient tech'));
  expect(result.reason, contains('grain'));
  expect(result.reason, contains('cap 1'));
}

void _rejectsBuildImprovementWhenTechCapWouldBeExceeded() {
  // With no grain-cap tech, grain stays at cap 1; tile at level 1 cannot upgrade.
  final result = _validateBuildImprovement(
    game: buildImprovementBaseGame(
      techUnlocked: const {kTechIdSawMill: true},
      tileState: const TileMapState(improvementByTile: {'oldWorld|P1|0|0': 1}),
      stockpile: lumberCastIronStockpile(10),
    ),
  );
  expect(result.status, OrderValidationStatus.rejected);
  expect(result.reason, contains('Insufficient tech'));
  expect(result.reason, contains('cap 1'));
}

void _acceptsGrainUpgradeWhenExactNextLevelGrainTechIsUnlocked() {
  final result = _validateBuildImprovement(
    game: buildImprovementBaseGame(
      techUnlocked: const {kTechIdLandEnclosure: true},
      tileState: const TileMapState(improvementByTile: {'oldWorld|P1|0|0': 1}),
      stockpile: lumberCastIronStockpile(10),
    ),
  );
  expect(result.status, OrderValidationStatus.accepted);
}

void _acceptsBuildImprovementWhenTileHasResourceLevel4TechCapAllows() {
  const tileKey = ValidateWorkOw.tileKey;
  final result = _validateBuildImprovement(
    game: buildImprovementBaseGame(
      resourceByTileKey: {tileKey: 'grain'},
      tileState: const TileMapState(),
      techUnlocked: const {kTechIdCircularSaw: true},
    ),
  );
  expect(result.status, OrderValidationStatus.accepted);
}

void _rejectsBuildImprovementInForeignUnpurchasedProvince() {
  final result = _validateBuildImprovement(
    game: buildImprovementForeignProvinceGame(),
    targetTileKey: validateWorkForeignTileKey(),
  );
  expect(result.status, OrderValidationStatus.rejected);
  expect(result.reason, contains('foreign or uncontrolled province'));
}

void _rejectsRaisingScrubTimberFromLevel1EvenWithCircularSaw() {
  final result = _validateBuildImprovement(
    game: scrubCapBaseGame(level: 1),
    tileMapByRegion: scrubCapTileMaps(TerrainType.scrubForest),
  );
  expect(result.status, OrderValidationStatus.rejected);
  expect(result.reason, contains('Terrain caps'));
  expect(result.reason, contains('level 1'));
}

void _acceptsRaisingHardwoodTimberFromLevel1WithCircularSaw() {
  final result = _validateBuildImprovement(
    game: scrubCapBaseGame(level: 1),
    tileMapByRegion: scrubCapTileMaps(TerrainType.hardwoodForest),
  );
  expect(result.status, OrderValidationStatus.accepted);
}

void _acceptsInitialScrubTimberImprovementLevel01() {
  final result = _validateBuildImprovement(
    game: scrubCapBaseGame(level: 0),
    tileMapByRegion: scrubCapTileMaps(TerrainType.scrubForest),
  );
  expect(result.status, OrderValidationStatus.accepted);
}

void _acceptsBuildImprovementOnPurchasedTileInForeignProvince() {
  final foreignTileKey = validateWorkForeignTileKey();
  final result = _validateBuildImprovement(
    game: buildImprovementForeignProvinceGame(
      purchasedTilesByTileKey: {foreignTileKey: 'p1'},
    ),
    targetTileKey: foreignTileKey,
  );
  expect(result.status, OrderValidationStatus.accepted);
}

void _rejectsBuildFortToLevel2WithoutMineEngineering() {
  final result = _validateOwWorkTarget(
    game: fortWorkGame(
      fortLevel: 1,
      stockpile: Stockpile()
          .applyDelta(CommodityCatalog.lumber.id, 4)
          .applyDelta(CommodityCatalog.bronze.id, 4),
      techUnlocked: {},
    ),
    unitId: 'eng1',
    target: kWorkTargetBuildFort,
  );
  expect(result.status, OrderValidationStatus.rejected);
  expect(result.reason, contains('Mine Engineering'));
}

void _rejectsBuildFortToLevel3WithoutModernForts() {
  final result = _validateOwWorkTarget(
    game: fortWorkGame(
      fortLevel: 2,
      stockpile: Stockpile()
          .applyDelta(CommodityCatalog.steel.id, 5)
          .applyDelta(CommodityCatalog.lumber.id, 5),
      techUnlocked: const {kTechIdMineEngineering: true},
    ),
    unitId: 'eng1',
    target: kWorkTargetBuildFort,
  );
  expect(result.status, OrderValidationStatus.rejected);
  expect(result.reason, contains('Modern Forts'));
}

void _rejectsBuildRailWhenTileTerrainDataIsMissing() {
  const tileKey = ValidateWorkOw.tileKey;
  final result = _validateOwWorkTarget(
    game: gameWithRailUnit(tileState: TileMapState().setRoadLevel(tileKey, 1)),
    unitId: 'rail1',
    target: kWorkTargetBuildRail,
  );
  expect(result.status, OrderValidationStatus.rejected);
  expect(result.reason, contains('terrain data required'));
}

void _rejectsBuildRailWhenRoadLevelIs0() {
  const ow = ValidateWorkOw.ow;
  const tileKey = ValidateWorkOw.tileKey;
  final result = _validateOwWorkTarget(
    game: gameWithRailUnit(tileState: TileMapState().setRoadLevel(tileKey, 0)),
    unitId: 'rail1',
    target: kWorkTargetBuildRail,
    tileMapByRegion: {ow: railTileMap(TerrainType.plains)},
  );
  expect(result.status, OrderValidationStatus.rejected);
  expect(result.reason, contains('existing road'));
}

void _rejectsBuildRailOnHillsWithOnlyEarlySteam() {
  const ow = ValidateWorkOw.ow;
  const tileKey = ValidateWorkOw.tileKey;
  final result = _validateOwWorkTarget(
    game: gameWithRailUnit(
      tileState: TileMapState().setRoadLevel(tileKey, 1),
      techUnlocked: const {kTechIdEarlySteamEngine: true},
    ),
    unitId: 'rail1',
    target: kWorkTargetBuildRail,
    tileMapByRegion: {ow: railTileMap(TerrainType.hills)},
  );
  expect(result.status, OrderValidationStatus.rejected);
  expect(result.reason, contains('Later Steam'));
}

void _acceptsBuildRailOnPlainsWithEarlySteamAndRoad1() {
  const ow = ValidateWorkOw.ow;
  const tileKey = ValidateWorkOw.tileKey;
  final result = _validateOwWorkTarget(
    game: gameWithRailUnit(tileState: TileMapState().setRoadLevel(tileKey, 1)),
    unitId: 'rail1',
    target: kWorkTargetBuildRail,
    tileMapByRegion: {ow: railTileMap(TerrainType.plains)},
  );
  expect(result.status, OrderValidationStatus.accepted);
}

void _rejectsBuildRoadInMinorProvinceWithoutEmbassyPath() {
  final result = _runMinorProvinceRoadValidation(
    minorProvinceEngineerRoadGame(),
  );
  expect(result.status, OrderValidationStatus.rejected);
  expect(result.reason, contains('foreign province'));
}

void
_rejectsBuildRoadInMinorProvinceEvenWithEmbassyWhenOccupancyDisallowsTile() {
  final result = _runMinorProvinceRoadValidation(
    minorProvinceEngineerRoadGame(overtureStates: minorProvinceEmbassyOverture),
  );
  expect(result.status, OrderValidationStatus.rejected);
  expect(result.reason, contains('cannot occupy'));
}

void _rejectsUpgradeTownWithoutNationalBureaucracy() {
  final result = _runUpgradeTownValidation(
    upgradeTownWorkGame(techUnlocked: const {}),
  );
  expect(result.status, OrderValidationStatus.rejected);
  expect(result.reason, contains('National Bureaucracy'));
}

void _acceptsUpgradeTownWhenNationalBureaucracyUnlocked() {
  final result = _runUpgradeTownValidation(
    upgradeTownWorkGame(
      techUnlocked: const {kTechIdNationalBureaucracy: true},
    ),
  );
  expect(result.status, OrderValidationStatus.accepted);
}
