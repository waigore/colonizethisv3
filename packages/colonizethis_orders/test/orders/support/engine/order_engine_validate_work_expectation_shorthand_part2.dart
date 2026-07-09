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

