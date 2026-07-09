part of 'order_engine_validate_work_expectation_shorthand.dart';

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

void vwExpectScrubTimberLevel1Rejected() {
  vwExpectScrubTimberRejected(
    level: 1,
    terrain: TerrainType.scrubForest,
  );
}

void vwExpectHardwoodTimberLevel1Accepted() {
  vwExpectScrubTimberAccepted(
    level: 1,
    terrain: TerrainType.hardwoodForest,
  );
}

void vwExpectScrubTimberLevel0Accepted() {
  vwExpectScrubTimberAccepted(
    level: 0,
    terrain: TerrainType.scrubForest,
  );
}

void vwExpectRailRejectedPlainsNoRoad() {
  vwExpectRailTerrainRejected(
    terrain: TerrainType.plains,
    roadLevel: 0,
  );
}

void vwExpectRailRejectedHillsEarlySteamOnly() {
  vwExpectRailTerrainRejected(
    terrain: TerrainType.hills,
    techUnlocked: const {kTechIdEarlySteamEngine: true},
    reasonContains: 'Later Steam',
  );
}

void vwExpectUpgradeTownRejectedNoBureaucracy() {
  vwExpectUpgradeTownOutcome(
    techUnlocked: const {},
    accepted: false,
    reasonContains: 'National Bureaucracy',
  );
}

void vwExpectUpgradeTownAcceptedWithBureaucracy() {
  vwExpectUpgradeTownOutcome(
    techUnlocked: const {kTechIdNationalBureaucracy: true},
    accepted: true,
  );
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

