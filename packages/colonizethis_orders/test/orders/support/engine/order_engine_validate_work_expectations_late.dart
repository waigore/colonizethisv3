part of 'order_engine_validate_work_expectations.dart';

void vwLateRejectsBuildFortToLevel3WithoutModernForts() {
  vwExpectRejected(
    vwValidateOwWorkTarget(
      game: fortWorkGame(
        fortLevel: 2,
        stockpile: Stockpile()
            .applyDelta(CommodityCatalog.steel.id, 5)
            .applyDelta(CommodityCatalog.lumber.id, 5),
        techUnlocked: const {kTechIdMineEngineering: true},
      ),
      unitId: 'eng1',
      target: kWorkTargetBuildFort,
    ),
    reasonContains: 'Modern Forts',
  );
}

void vwLateRejectsBuildRailWhenTileTerrainDataIsMissing() {
  vwExpectRejected(
    vwValidateOwWorkTarget(
      game: gameWithRailUnit(
        tileState: TileMapState().setRoadLevel(ValidateWorkOw.tileKey, 1),
      ),
      unitId: 'rail1',
      target: kWorkTargetBuildRail,
      tileMapByRegion: const {},
    ),
    reasonContains: 'terrain data required',
  );
}

void vwLateRejectsBuildRailWhenRoadLevelIs0() {
  vwExpectRejected(
    vwValidateOwWorkTarget(
      game: gameWithRailUnit(
        tileState: TileMapState().setRoadLevel(ValidateWorkOw.tileKey, 0),
      ),
      unitId: 'rail1',
      target: kWorkTargetBuildRail,
      tileMapByRegion: {ValidateWorkOw.ow: railTileMap(TerrainType.plains)},
    ),
    reasonContains: 'existing road',
  );
}

void vwLateRejectsBuildRailOnHillsWithOnlyEarlySteam() {
  vwExpectRejected(
    vwValidateOwWorkTarget(
      game: gameWithRailUnit(
        tileState: TileMapState().setRoadLevel(ValidateWorkOw.tileKey, 1),
        techUnlocked: const {kTechIdEarlySteamEngine: true},
      ),
      unitId: 'rail1',
      target: kWorkTargetBuildRail,
      tileMapByRegion: {ValidateWorkOw.ow: railTileMap(TerrainType.hills)},
    ),
    reasonContains: 'Later Steam',
  );
}

void vwLateAcceptsBuildRailOnPlainsWithEarlySteamAndRoad1() {
  vwExpectAccepted(
    vwValidateOwWorkTarget(
      game: gameWithRailUnit(
        tileState: TileMapState().setRoadLevel(ValidateWorkOw.tileKey, 1),
      ),
      unitId: 'rail1',
      target: kWorkTargetBuildRail,
      tileMapByRegion: {ValidateWorkOw.ow: railTileMap(TerrainType.plains)},
    ),
  );
}

void vwLateRejectsBuildRoadInMinorProvinceWithoutEmbassyPath() {
  vwExpectRejected(
    vwValidateSingleWork(
      game: minorProvinceEngineerRoadGame(),
      playerId: 'gp1',
      order: WorkOrder(
        unitId: 'e1',
        target: kWorkTargetBuildRoad,
        targetTileKey: minorProvinceRoadTileKey(),
      ),
      topology: minorProvinceRoadTopology(),
    ),
    reasonContains: 'foreign province',
  );
}

void vwLateRejectsBuildRoadInMinorProvinceEvenWithEmbassyWhenOccupancyDisallowsTile() {
  vwExpectRejected(
    vwValidateSingleWork(
      game: minorProvinceEngineerRoadGame(
        overtureStates: minorProvinceEmbassyOverture,
      ),
      playerId: 'gp1',
      order: WorkOrder(
        unitId: 'e1',
        target: kWorkTargetBuildRoad,
        targetTileKey: minorProvinceRoadTileKey(),
      ),
      topology: minorProvinceRoadTopology(),
    ),
    reasonContains: 'cannot occupy',
  );
}

void vwLateRejectsUpgradeTownWithoutNationalBureaucracy() {
  vwExpectRejected(
    vwValidateSingleWork(
      game: upgradeTownWorkGame(techUnlocked: const {}),
      order: const WorkOrder(
        unitId: 'b1',
        target: kWorkTargetUpgradeTown,
        targetTileKey: ValidateWorkOw.tileKey,
      ),
    ),
    reasonContains: 'National Bureaucracy',
  );
}

void vwLateAcceptsUpgradeTownWhenNationalBureaucracyUnlocked() {
  vwExpectAccepted(
    vwValidateSingleWork(
      game: upgradeTownWorkGame(
        techUnlocked: const {kTechIdNationalBureaucracy: true},
      ),
      order: const WorkOrder(
        unitId: 'b1',
        target: kWorkTargetUpgradeTown,
        targetTileKey: ValidateWorkOw.tileKey,
      ),
    ),
  );
}
