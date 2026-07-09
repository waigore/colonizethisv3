// Compact order-engine validateWork expectation shorthands (Refs #3949).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'order_engine_purchase_land_test_support.dart';
import 'order_engine_validate_work_fixtures.dart';

List<OrderValidationResult> vwRunPurchaseLand(Game game) {
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

OrderValidationResult vwRunUpgradeTown(Game game) {
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

OrderValidationResult vwRunMinorProvinceRoad(Game game) {
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

Game vwPurchaseLandGame({
  required int treasury,
  List<OvertureState>? overtureStates,
  List<DiplomacyRelation>? diplomacyRelations,
  Map<String, String>? resourceByTileKey,
  Map<String, Set<String>>? playerProspectedTiles,
  Map<String, String>? purchasedTilesByTileKey,
}) =>
    PurchaseLandTestFixture.baseGame(
      treasury: treasury,
      overtureStates: overtureStates,
      diplomacyRelations: diplomacyRelations,
      resourceByTileKey: resourceByTileKey,
      playerProspectedTiles: playerProspectedTiles,
      purchasedTilesByTileKey: purchasedTilesByTileKey,
    );

OrderValidationResult vwValidateSingleWork({
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

OrderValidationResult vwValidateBuildImprovement({
  required Game game,
  Map<String, TileMapResult>? tileMapByRegion,
  String targetTileKey = ValidateWorkOw.tileKey,
  String unitId = 'builder1',
}) =>
    vwValidateSingleWork(
      game: game,
      order: WorkOrder(
        unitId: unitId,
        target: kWorkTargetBuildImprovement,
        targetTileKey: targetTileKey,
      ),
      tileMapByRegion: tileMapByRegion,
    );

OrderValidationResult vwValidateOwWorkTarget({
  required Game game,
  required String unitId,
  required String target,
  Map<String, TileMapResult>? tileMapByRegion,
}) =>
    vwValidateSingleWork(
      game: game,
      order: WorkOrder(
        unitId: unitId,
        target: target,
        targetTileKey: ValidateWorkOw.tileKey,
      ),
      tileMapByRegion: tileMapByRegion,
    );

void vwExpectRejected(
  OrderValidationResult result, {
  String? reasonContains,
}) {
  expect(result.status, OrderValidationStatus.rejected);
  if (reasonContains != null) {
    expect(result.reason, contains(reasonContains));
  }
}

void vwExpectAccepted(OrderValidationResult result) {
  expect(result.status, OrderValidationStatus.accepted);
}

void vwExpectPurchaseLandRejected(
  Game game, {
  String? reasonContains,
}) =>
    vwExpectRejected(
      vwRunPurchaseLand(game).single,
      reasonContains: reasonContains,
    );

void vwExpectPurchaseLandAccepted(Game game) =>
    vwExpectAccepted(vwRunPurchaseLand(game).single);

void vwExpectPurchaseLandRejectedNoEmbassy() => vwExpectPurchaseLandRejected(
  vwPurchaseLandGame(treasury: 500),
  reasonContains: 'embassy',
);

void vwExpectPurchaseLandRejectedAtWar() => vwExpectPurchaseLandRejected(
  vwPurchaseLandGame(
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
  reasonContains: 'war',
);

void vwExpectPurchaseLandRejectedInsufficientTreasury() {
  const cost = 15 * 10;
  vwExpectPurchaseLandRejected(
    vwPurchaseLandGame(
      treasury: cost - 1,
      overtureStates: purchaseLandEmbassyOverture,
    ),
    reasonContains: 'Insufficient treasury',
  );
}

void vwExpectPurchaseLandRejectedNoResource() => vwExpectPurchaseLandRejected(
  vwPurchaseLandGame(
    treasury: 500,
    overtureStates: purchaseLandEmbassyOverture,
    resourceByTileKey: {},
  ),
  reasonContains: 'no resource',
);

void vwExpectPurchaseLandRejectedMineralNotProspected() {
  final tk = PurchaseLandTestFixture.tileKey;
  vwExpectPurchaseLandRejected(
    vwPurchaseLandGame(
      treasury: 500,
      overtureStates: purchaseLandEmbassyOverture,
      resourceByTileKey: {tk: 'iron'},
      playerProspectedTiles: {},
    ),
    reasonContains: 'prospected',
  );
}

void vwExpectPurchaseLandAcceptedEmbassy() => vwExpectPurchaseLandAccepted(
  vwPurchaseLandGame(
    treasury: 500,
    overtureStates: purchaseLandEmbassyOverture,
  ),
);

void vwExpectPurchaseLandAcceptedMineralProspected() {
  final tk = PurchaseLandTestFixture.tileKey;
  vwExpectPurchaseLandAccepted(
    vwPurchaseLandGame(
      treasury: 500,
      overtureStates: purchaseLandEmbassyOverture,
      resourceByTileKey: {tk: 'iron'},
      playerProspectedTiles: {
        'p1': {tk},
      },
    ),
  );
}

void vwExpectPurchaseLandRejectedAlreadyPurchasedByOther() =>
    vwExpectPurchaseLandRejected(
      vwPurchaseLandGame(
        treasury: 500,
        overtureStates: purchaseLandEmbassyOverture,
        purchasedTilesByTileKey: {PurchaseLandTestFixture.tileKey: 'p2'},
      ),
      reasonContains: 'Tile already purchased by another power',
    );

void vwExpectPurchaseLandRejectedAlreadyOwnedBySelf() =>
    vwExpectPurchaseLandRejected(
      vwPurchaseLandGame(
        treasury: 500,
        overtureStates: purchaseLandEmbassyOverture,
        purchasedTilesByTileKey: {PurchaseLandTestFixture.tileKey: 'p1'},
      ),
      reasonContains: 'You already own this tile',
    );

void vwExpectBuildImprovementRejected({
  required Game game,
  String? reasonContains,
  Map<String, TileMapResult>? tileMapByRegion,
  String targetTileKey = ValidateWorkOw.tileKey,
  String unitId = 'builder1',
}) =>
    vwExpectRejected(
      vwValidateBuildImprovement(
        game: game,
        tileMapByRegion: tileMapByRegion,
        targetTileKey: targetTileKey,
        unitId: unitId,
      ),
      reasonContains: reasonContains,
    );

void vwExpectBuildImprovementAccepted({
  required Game game,
  Map<String, TileMapResult>? tileMapByRegion,
  String targetTileKey = ValidateWorkOw.tileKey,
  String unitId = 'builder1',
}) =>
    vwExpectAccepted(
      vwValidateBuildImprovement(
        game: game,
        tileMapByRegion: tileMapByRegion,
        targetTileKey: targetTileKey,
        unitId: unitId,
      ),
    );

void vwExpectOwWorkTargetRejected({
  required Game game,
  required String unitId,
  required String target,
  String? reasonContains,
  Map<String, TileMapResult>? tileMapByRegion,
}) =>
    vwExpectRejected(
      vwValidateOwWorkTarget(
        game: game,
        unitId: unitId,
        target: target,
        tileMapByRegion: tileMapByRegion,
      ),
      reasonContains: reasonContains,
    );

void vwExpectOwWorkTargetAccepted({
  required Game game,
  required String unitId,
  required String target,
  Map<String, TileMapResult>? tileMapByRegion,
}) =>
    vwExpectAccepted(
      vwValidateOwWorkTarget(
        game: game,
        unitId: unitId,
        target: target,
        tileMapByRegion: tileMapByRegion,
      ),
    );

void vwExpectWorkResults(
  List<OrderValidationResult> results, {
  required List<OrderValidationStatus> statuses,
  String? lastReasonContains,
}) {
  expect(results, hasLength(statuses.length));
  for (var i = 0; i < statuses.length; i++) {
    expect(results[i].status, statuses[i]);
  }
  if (lastReasonContains != null) {
    expect(results.last.reason, contains(lastReasonContains));
  }
}

void vwExpectDualWorkOrders({
  required Game game,
  required WorkOrder first,
  required WorkOrder second,
  required List<OrderValidationStatus> statuses,
  String? lastReasonContains,
  MapTopology? topology,
  String playerId = 'p1',
}) {
  final engine = OrderEngine();
  engine
    ..addWorkOrder(playerId, first)
    ..addWorkOrder(playerId, second);
  vwExpectWorkResults(
    engine.validatePlayerOrdersWithContext(
      game,
      topology ?? ValidateWorkOw.topology(),
      playerId,
    ),
    statuses: statuses,
    lastReasonContains: lastReasonContains,
  );
}

void vwExpectSecondPendingWorkOrderRejected() {
  const tileA = ValidateWorkOw.tileKey;
  const tileB = '${ValidateWorkOw.provinceId}|1|0';
  vwExpectDualWorkOrders(
    game: dualTilePendingWorkGame(),
    first: const WorkOrder(
      unitId: 'builder1',
      target: kWorkTargetBuildImprovement,
      targetTileKey: tileA,
    ),
    second: const WorkOrder(
      unitId: 'builder1',
      target: kWorkTargetBuildImprovement,
      targetTileKey: tileB,
    ),
    statuses: const [
      OrderValidationStatus.accepted,
      OrderValidationStatus.rejected,
    ],
    lastReasonContains: 'Only one work order per unit is allowed each turn',
  );
}

void vwExpectSameTileDevelopmentExclusivityRejected() {
  const tileKey = ValidateWorkOw.tileKey;
  vwExpectDualWorkOrders(
    game: builderEngineerSameTileExclusivityGame(),
    first: const WorkOrder(
      unitId: 'builder1',
      target: kWorkTargetBuildImprovement,
      targetTileKey: tileKey,
    ),
    second: const WorkOrder(
      unitId: 'engineer1',
      target: kWorkTargetBuildRoad,
      targetTileKey: tileKey,
    ),
    statuses: const [
      OrderValidationStatus.accepted,
      OrderValidationStatus.rejected,
    ],
    lastReasonContains: 'Tile already has development or purchase work',
  );
}

void vwExpectScrubTimberRejected({
  required int level,
  required TerrainType terrain,
  String reasonContains = 'Terrain caps',
}) {
  final result = vwValidateBuildImprovement(
    game: scrubCapBaseGame(level: level),
    tileMapByRegion: scrubCapTileMaps(terrain),
  );
  vwExpectRejected(result, reasonContains: reasonContains);
  if (level == 1) {
    expect(result.reason, contains('level 1'));
  }
}

void vwExpectScrubTimberAccepted({
  required int level,
  required TerrainType terrain,
}) {
  vwExpectBuildImprovementAccepted(
    game: scrubCapBaseGame(level: level),
    tileMapByRegion: scrubCapTileMaps(terrain),
  );
}

void vwExpectFortRejected({
  required int fortLevel,
  required Stockpile stockpile,
  required Map<String, bool> techUnlocked,
  required String reasonContains,
}) {
  vwExpectOwWorkTargetRejected(
    game: fortWorkGame(
      fortLevel: fortLevel,
      stockpile: stockpile,
      techUnlocked: techUnlocked,
    ),
    unitId: 'eng1',
    target: kWorkTargetBuildFort,
    reasonContains: reasonContains,
  );
}

void vwExpectRailRejected({
  required Game game,
  required Map<String, TileMapResult> tileMapByRegion,
  required String reasonContains,
}) {
  vwExpectOwWorkTargetRejected(
    game: game,
    unitId: 'rail1',
    target: kWorkTargetBuildRail,
    tileMapByRegion: tileMapByRegion,
    reasonContains: reasonContains,
  );
}

void vwExpectRailAccepted({
  required Game game,
  required Map<String, TileMapResult> tileMapByRegion,
}) {
  vwExpectOwWorkTargetAccepted(
    game: game,
    unitId: 'rail1',
    target: kWorkTargetBuildRail,
    tileMapByRegion: tileMapByRegion,
  );
}

void vwExpectUpgradeTownOutcome({
  required Map<String, bool> techUnlocked,
  required bool accepted,
  String? reasonContains,
}) {
  final result = vwRunUpgradeTown(upgradeTownWorkGame(techUnlocked: techUnlocked));
  if (accepted) {
    vwExpectAccepted(result);
  } else {
    vwExpectRejected(result, reasonContains: reasonContains!);
  }
}

void vwExpectEmptyTechCapBuildImprovementRejected() {
  final result = vwValidateBuildImprovement(
    game: buildImprovementBaseGame(
      techUnlocked: const {},
      tileState: const TileMapState(improvementByTile: {'oldWorld|P1|0|0': 1}),
      stockpile: lumberCastIronStockpile(10),
    ),
  );
  vwExpectRejected(result, reasonContains: 'Insufficient tech');
  expect(result.reason, contains('grain'));
  expect(result.reason, contains('cap 1'));
}

void vwExpectTechCapBuildImprovementRejected() {
  vwExpectBuildImprovementRejected(
    game: buildImprovementBaseGame(
      techUnlocked: const {kTechIdSawMill: true},
      tileState: const TileMapState(improvementByTile: {'oldWorld|P1|0|0': 1}),
      stockpile: lumberCastIronStockpile(10),
    ),
    reasonContains: 'Insufficient tech',
  );
}

void vwExpectRailTerrainRejected({
  required TerrainType terrain,
  Map<String, bool>? techUnlocked,
  int roadLevel = 1,
  String reasonContains = 'existing road',
}) {
  const ow = ValidateWorkOw.ow;
  const tileKey = ValidateWorkOw.tileKey;
  vwExpectRailRejected(
    game: gameWithRailUnit(
      tileState: TileMapState().setRoadLevel(tileKey, roadLevel),
      techUnlocked: techUnlocked,
    ),
    tileMapByRegion: {ow: railTileMap(terrain)},
    reasonContains: reasonContains,
  );
}

void vwExpectRailTerrainAccepted({required TerrainType terrain}) {
  const ow = ValidateWorkOw.ow;
  const tileKey = ValidateWorkOw.tileKey;
  vwExpectRailAccepted(
    game: gameWithRailUnit(tileState: TileMapState().setRoadLevel(tileKey, 1)),
    tileMapByRegion: {ow: railTileMap(terrain)},
  );
}

void vwExpectMinorProvinceRoadRejected(
  Game game, {
  required String reasonContains,
}) =>
    vwExpectRejected(
      vwRunMinorProvinceRoad(game),
      reasonContains: reasonContains,
    );

void vwExpectMineralBuildImprovementRejectedWhenNotProspected() {
  vwExpectBuildImprovementRejected(
    game: buildImprovementBaseGame(
      resourceByTileKey: {ValidateWorkOw.tileKey: 'iron'},
    ),
    reasonContains: 'prospected',
  );
}

void vwExpectMineralBuildImprovementAcceptedWhenProspected() {
  const tileKey = ValidateWorkOw.tileKey;
  vwExpectBuildImprovementAccepted(
    game: buildImprovementBaseGame(
      resourceByTileKey: {tileKey: 'iron'},
      playerProspectedTiles: {
        'p1': {tileKey},
      },
    ),
  );
}

void vwExpectGrainBuildImprovementAcceptedWhenNotProspected() {
  vwExpectBuildImprovementAccepted(
    game: buildImprovementBaseGame(
      resourceByTileKey: {ValidateWorkOw.tileKey: 'grain'},
    ),
  );
}

void vwExpectBuildImprovementRejectedNoResource() {
  vwExpectBuildImprovementRejected(
    game: buildImprovementBaseGame(resourceByTileKey: {}),
    reasonContains: 'no resource',
  );
}

void vwExpectBuildImprovementRejectedAtLevel4() {
  vwExpectBuildImprovementRejected(
    game: buildImprovementBaseGame(
      tileState: const TileMapState(improvementByTile: {'oldWorld|P1|0|0': 4}),
      stockpile: lumberCastIronStockpile(20),
    ),
    reasonContains: 'maximum',
  );
}

void vwExpectGrainUpgradeWithLandEnclosure() {
  vwExpectBuildImprovementAccepted(
    game: buildImprovementBaseGame(
      techUnlocked: const {kTechIdLandEnclosure: true},
      tileState: const TileMapState(improvementByTile: {'oldWorld|P1|0|0': 1}),
      stockpile: lumberCastIronStockpile(10),
    ),
  );
}

void vwExpectBuildImprovementAcceptedAtLevel4TechCap() {
  vwExpectBuildImprovementAccepted(
    game: buildImprovementBaseGame(
      resourceByTileKey: {ValidateWorkOw.tileKey: 'grain'},
      tileState: const TileMapState(),
      techUnlocked: const {kTechIdCircularSaw: true},
    ),
  );
}

void vwExpectBuildImprovementRejectedForeignUnpurchased() {
  vwExpectBuildImprovementRejected(
    game: buildImprovementForeignProvinceGame(),
    targetTileKey: validateWorkForeignTileKey(),
    reasonContains: 'foreign or uncontrolled province',
  );
}

void vwExpectBuildImprovementAcceptedOnPurchasedForeignTile() {
  final foreignTileKey = validateWorkForeignTileKey();
  vwExpectBuildImprovementAccepted(
    game: buildImprovementForeignProvinceGame(
      purchasedTilesByTileKey: {foreignTileKey: 'p1'},
    ),
    targetTileKey: foreignTileKey,
  );
}

void vwExpectMinorProvinceRoadRejectedWithoutEmbassy() {
  vwExpectMinorProvinceRoadRejected(
    minorProvinceEngineerRoadGame(),
    reasonContains: 'foreign province',
  );
}

void vwExpectMinorProvinceRoadRejectedDespiteEmbassy() {
  vwExpectMinorProvinceRoadRejected(
    minorProvinceEngineerRoadGame(overtureStates: minorProvinceEmbassyOverture),
    reasonContains: 'cannot occupy',
  );
}

void vwExpectFortLevel2RejectedWithoutMineEngineering() {
  vwExpectFortRejected(
    fortLevel: 1,
    stockpile: Stockpile()
        .applyDelta(CommodityCatalog.lumber.id, 4)
        .applyDelta(CommodityCatalog.bronze.id, 4),
    techUnlocked: const {},
    reasonContains: 'Mine Engineering',
  );
}

void vwExpectFortLevel3RejectedWithoutModernForts() {
  vwExpectFortRejected(
    fortLevel: 2,
    stockpile: Stockpile()
        .applyDelta(CommodityCatalog.steel.id, 5)
        .applyDelta(CommodityCatalog.lumber.id, 5),
    techUnlocked: const {kTechIdMineEngineering: true},
    reasonContains: 'Modern Forts',
  );
}

void vwExpectRailMissingTerrainDataRejected() {
  vwExpectRailRejected(
    game: gameWithRailUnit(
      tileState: TileMapState().setRoadLevel(ValidateWorkOw.tileKey, 1),
    ),
    tileMapByRegion: const {},
    reasonContains: 'terrain data required',
  );
}
