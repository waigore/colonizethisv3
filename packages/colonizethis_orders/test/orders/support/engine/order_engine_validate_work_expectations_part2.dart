part of 'order_engine_validate_work_expectations.dart';


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
