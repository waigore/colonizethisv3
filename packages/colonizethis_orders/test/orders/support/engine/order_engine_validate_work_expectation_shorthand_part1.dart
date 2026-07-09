part of 'order_engine_validate_work_expectation_shorthand.dart';


OrderValidationResult vwRunPurchaseLand(Game game) => vwValidateSingleWork(
  game: game,
  order: WorkOrder(
    unitId: 'merchant1',
    target: kWorkTargetPurchaseLand,
    targetTileKey: PurchaseLandTestFixture.tileKey,
  ),
  topology: PurchaseLandTestFixture.topology(),
);

OrderValidationResult vwRunUpgradeTown(Game game) => vwValidateSingleWork(
  game: game,
  order: const WorkOrder(
    unitId: 'b1',
    target: kWorkTargetUpgradeTown,
    targetTileKey: ValidateWorkOw.tileKey,
  ),
);

OrderValidationResult vwRunMinorProvinceRoad(Game game) => vwValidateSingleWork(
  game: game,
  playerId: 'gp1',
  order: WorkOrder(
    unitId: 'e1',
    target: kWorkTargetBuildRoad,
    targetTileKey: minorProvinceRoadTileKey(),
  ),
  topology: minorProvinceRoadTopology(),
);

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
      vwRunPurchaseLand(game),
      reasonContains: reasonContains,
    );

void vwExpectPurchaseLandAccepted(Game game) =>
    vwExpectAccepted(vwRunPurchaseLand(game));




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

