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
  final results = engine.validatePlayerOrdersWithContext(
    game,
    topology ?? ValidateWorkOw.topology(),
    playerId,
  );
  expect(results, hasLength(statuses.length));
  for (var i = 0; i < statuses.length; i++) {
    expect(results[i].status, statuses[i]);
  }
  if (lastReasonContains != null) {
    expect(results.last.reason, contains(lastReasonContains));
  }
}

WorkOrder vwMinorProvinceRoadOrder() => WorkOrder(
      unitId: 'e1',
      target: kWorkTargetBuildRoad,
      targetTileKey: minorProvinceRoadTileKey(),
    );

void vwExpectRejectFortLevel3WithoutModernForts() {
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

void vwExpectRejectRailMissingTerrain() {
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

void vwExpectRejectRailWhenRoadLevelZero() {
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

void vwExpectRejectRailOnHillsWithEarlySteamOnly() {
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

void vwExpectAcceptRailOnPlainsWithEarlySteam() {
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

void vwExpectRejectMinorProvinceRoad({
  required Game game,
  required String reasonContains,
}) {
  vwExpectRejected(
    vwValidateSingleWork(
      game: game,
      playerId: 'gp1',
      order: vwMinorProvinceRoadOrder(),
      topology: minorProvinceRoadTopology(),
    ),
    reasonContains: reasonContains,
  );
}

void vwExpectRejectUpgradeTownWithoutNationalBureaucracy() {
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

void vwExpectAcceptUpgradeTownWithNationalBureaucracy() {
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

void vwExpectBuildImprovementMineral({required bool prospected}) {
  const tileKey = ValidateWorkOw.tileKey;
  final result = vwValidateBuildImprovement(
    game: buildImprovementBaseGame(
      resourceByTileKey: {tileKey: 'iron'},
      playerProspectedTiles: prospected
          ? {
              'p1': {tileKey},
            }
          : null,
    ),
  );
  if (prospected) {
    vwExpectAccepted(result);
  } else {
    vwExpectRejected(result, reasonContains: 'prospected');
  }
}
