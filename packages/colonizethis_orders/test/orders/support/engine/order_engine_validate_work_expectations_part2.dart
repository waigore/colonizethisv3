part of 'order_engine_validate_work_expectations.dart';

void _rejectsBuildImprovementOnMineralTileWhenNotProspected() {
  vwExpectBuildImprovementRejected(
    game: buildImprovementBaseGame(
      resourceByTileKey: {ValidateWorkOw.tileKey: 'iron'},
    ),
    reasonContains: 'prospected',
  );
}

void _acceptsBuildImprovementOnMineralTileAfterProspected() {
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

void _acceptsBuildImprovementOnGrainWhenTileNotProspected() {
  vwExpectBuildImprovementAccepted(
    game: buildImprovementBaseGame(
      resourceByTileKey: {ValidateWorkOw.tileKey: 'grain'},
    ),
  );
}

void _rejectsBuildImprovementWhenTileHasNoResource() {
  vwExpectBuildImprovementRejected(
    game: buildImprovementBaseGame(resourceByTileKey: {}),
    reasonContains: 'no resource',
  );
}

void _rejectsBuildImprovementWhenImprovementLevelAlready4() {
  vwExpectBuildImprovementRejected(
    game: buildImprovementBaseGame(
      tileState: const TileMapState(improvementByTile: {'oldWorld|P1|0|0': 4}),
      stockpile: lumberCastIronStockpile(20),
    ),
    reasonContains: 'maximum',
  );
}

void _rejectsBuildImprovementWhenTechCapWouldBeExceededEmptyTech() {
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

void _rejectsBuildImprovementWhenTechCapWouldBeExceeded() {
  vwExpectBuildImprovementRejected(
    game: buildImprovementBaseGame(
      techUnlocked: const {kTechIdSawMill: true},
      tileState: const TileMapState(improvementByTile: {'oldWorld|P1|0|0': 1}),
      stockpile: lumberCastIronStockpile(10),
    ),
    reasonContains: 'Insufficient tech',
  );
}

void _acceptsGrainUpgradeWhenExactNextLevelGrainTechIsUnlocked() {
  vwExpectBuildImprovementAccepted(
    game: buildImprovementBaseGame(
      techUnlocked: const {kTechIdLandEnclosure: true},
      tileState: const TileMapState(improvementByTile: {'oldWorld|P1|0|0': 1}),
      stockpile: lumberCastIronStockpile(10),
    ),
  );
}

void _acceptsBuildImprovementWhenTileHasResourceLevel4TechCapAllows() {
  vwExpectBuildImprovementAccepted(
    game: buildImprovementBaseGame(
      resourceByTileKey: {ValidateWorkOw.tileKey: 'grain'},
      tileState: const TileMapState(),
      techUnlocked: const {kTechIdCircularSaw: true},
    ),
  );
}

void _rejectsBuildImprovementInForeignUnpurchasedProvince() {
  vwExpectBuildImprovementRejected(
    game: buildImprovementForeignProvinceGame(),
    targetTileKey: validateWorkForeignTileKey(),
    reasonContains: 'foreign or uncontrolled province',
  );
}

void _rejectsRaisingScrubTimberFromLevel1EvenWithCircularSaw() {
  final result = vwValidateBuildImprovement(
    game: scrubCapBaseGame(level: 1),
    tileMapByRegion: scrubCapTileMaps(TerrainType.scrubForest),
  );
  vwExpectRejected(result, reasonContains: 'Terrain caps');
  expect(result.reason, contains('level 1'));
}

void _acceptsRaisingHardwoodTimberFromLevel1WithCircularSaw() {
  vwExpectBuildImprovementAccepted(
    game: scrubCapBaseGame(level: 1),
    tileMapByRegion: scrubCapTileMaps(TerrainType.hardwoodForest),
  );
}

void _acceptsInitialScrubTimberImprovementLevel01() {
  vwExpectBuildImprovementAccepted(
    game: scrubCapBaseGame(level: 0),
    tileMapByRegion: scrubCapTileMaps(TerrainType.scrubForest),
  );
}

void _acceptsBuildImprovementOnPurchasedTileInForeignProvince() {
  final foreignTileKey = validateWorkForeignTileKey();
  vwExpectBuildImprovementAccepted(
    game: buildImprovementForeignProvinceGame(
      purchasedTilesByTileKey: {foreignTileKey: 'p1'},
    ),
    targetTileKey: foreignTileKey,
  );
}

void _rejectsBuildFortToLevel2WithoutMineEngineering() {
  vwExpectOwWorkTargetRejected(
    game: fortWorkGame(
      fortLevel: 1,
      stockpile: Stockpile()
          .applyDelta(CommodityCatalog.lumber.id, 4)
          .applyDelta(CommodityCatalog.bronze.id, 4),
      techUnlocked: {},
    ),
    unitId: 'eng1',
    target: kWorkTargetBuildFort,
    reasonContains: 'Mine Engineering',
  );
}

void _rejectsBuildFortToLevel3WithoutModernForts() {
  vwExpectOwWorkTargetRejected(
    game: fortWorkGame(
      fortLevel: 2,
      stockpile: Stockpile()
          .applyDelta(CommodityCatalog.steel.id, 5)
          .applyDelta(CommodityCatalog.lumber.id, 5),
      techUnlocked: const {kTechIdMineEngineering: true},
    ),
    unitId: 'eng1',
    target: kWorkTargetBuildFort,
    reasonContains: 'Modern Forts',
  );
}

void _rejectsBuildRailWhenTileTerrainDataIsMissing() {
  vwExpectOwWorkTargetRejected(
    game: gameWithRailUnit(tileState: TileMapState().setRoadLevel(ValidateWorkOw.tileKey, 1)),
    unitId: 'rail1',
    target: kWorkTargetBuildRail,
    reasonContains: 'terrain data required',
  );
}

void _rejectsBuildRailWhenRoadLevelIs0() {
  const ow = ValidateWorkOw.ow;
  const tileKey = ValidateWorkOw.tileKey;
  vwExpectOwWorkTargetRejected(
    game: gameWithRailUnit(tileState: TileMapState().setRoadLevel(tileKey, 0)),
    unitId: 'rail1',
    target: kWorkTargetBuildRail,
    tileMapByRegion: {ow: railTileMap(TerrainType.plains)},
    reasonContains: 'existing road',
  );
}

void _rejectsBuildRailOnHillsWithOnlyEarlySteam() {
  const ow = ValidateWorkOw.ow;
  const tileKey = ValidateWorkOw.tileKey;
  vwExpectOwWorkTargetRejected(
    game: gameWithRailUnit(
      tileState: TileMapState().setRoadLevel(tileKey, 1),
      techUnlocked: const {kTechIdEarlySteamEngine: true},
    ),
    unitId: 'rail1',
    target: kWorkTargetBuildRail,
    tileMapByRegion: {ow: railTileMap(TerrainType.hills)},
    reasonContains: 'Later Steam',
  );
}

void _acceptsBuildRailOnPlainsWithEarlySteamAndRoad1() {
  const ow = ValidateWorkOw.ow;
  const tileKey = ValidateWorkOw.tileKey;
  vwExpectOwWorkTargetAccepted(
    game: gameWithRailUnit(tileState: TileMapState().setRoadLevel(tileKey, 1)),
    unitId: 'rail1',
    target: kWorkTargetBuildRail,
    tileMapByRegion: {ow: railTileMap(TerrainType.plains)},
  );
}

void _rejectsBuildRoadInMinorProvinceWithoutEmbassyPath() {
  vwExpectRejected(
    vwRunMinorProvinceRoad(minorProvinceEngineerRoadGame()),
    reasonContains: 'foreign province',
  );
}

void
_rejectsBuildRoadInMinorProvinceEvenWithEmbassyWhenOccupancyDisallowsTile() {
  vwExpectRejected(
    vwRunMinorProvinceRoad(
      minorProvinceEngineerRoadGame(overtureStates: minorProvinceEmbassyOverture),
    ),
    reasonContains: 'cannot occupy',
  );
}

void _rejectsUpgradeTownWithoutNationalBureaucracy() {
  vwExpectRejected(
    vwRunUpgradeTown(upgradeTownWorkGame(techUnlocked: const {})),
    reasonContains: 'National Bureaucracy',
  );
}

void _acceptsUpgradeTownWhenNationalBureaucracyUnlocked() {
  vwExpectAccepted(
    vwRunUpgradeTown(
      upgradeTownWorkGame(
        techUnlocked: const {kTechIdNationalBureaucracy: true},
      ),
    ),
  );
}
