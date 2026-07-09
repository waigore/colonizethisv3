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

void vwExpectPurchaseLandRejected({
  int treasury = 500,
  List<OvertureState>? overtureStates = purchaseLandEmbassyOverture,
  List<DiplomacyRelation>? diplomacyRelations,
  Map<String, String>? resourceByTileKey,
  Map<String, Set<String>>? playerProspectedTiles,
  Map<String, String>? purchasedTilesByTileKey,
  required String reasonContains,
}) {
  vwExpectRejected(
    vwRunPurchaseLand(
      vwPurchaseLandGame(
        treasury: treasury,
        overtureStates: overtureStates,
        diplomacyRelations: diplomacyRelations,
        resourceByTileKey: resourceByTileKey,
        playerProspectedTiles: playerProspectedTiles,
        purchasedTilesByTileKey: purchasedTilesByTileKey,
      ),
    ),
    reasonContains: reasonContains,
  );
}

void vwExpectPurchaseLandAccepted({
  int treasury = 500,
  List<OvertureState>? overtureStates = purchaseLandEmbassyOverture,
  Map<String, String>? resourceByTileKey,
  Map<String, Set<String>>? playerProspectedTiles,
}) {
  vwExpectAccepted(
    vwRunPurchaseLand(
      vwPurchaseLandGame(
        treasury: treasury,
        overtureStates: overtureStates,
        resourceByTileKey: resourceByTileKey,
        playerProspectedTiles: playerProspectedTiles,
      ),
    ),
  );
}

void vwExpectPurchaseLandMineral({required bool prospected}) {
  final tk = PurchaseLandTestFixture.tileKey;
  if (prospected) {
    vwExpectPurchaseLandAccepted(
      resourceByTileKey: {tk: 'iron'},
      playerProspectedTiles: {'p1': {tk}},
    );
  } else {
    vwExpectPurchaseLandRejected(
      resourceByTileKey: {tk: 'iron'},
      playerProspectedTiles: {},
      reasonContains: 'prospected',
    );
  }
}

void vwExpectBuildImprovementOutcome({
  required Game game,
  Map<String, TileMapResult>? tileMapByRegion,
  String targetTileKey = ValidateWorkOw.tileKey,
  required bool accepted,
  String? reasonContains,
  void Function(OrderValidationResult result)? onRejected,
}) {
  final result = vwValidateBuildImprovement(
    game: game,
    tileMapByRegion: tileMapByRegion,
    targetTileKey: targetTileKey,
  );
  if (accepted) {
    vwExpectAccepted(result);
  } else {
    vwExpectRejected(result, reasonContains: reasonContains);
    onRejected?.call(result);
  }
}

void vwExpectDualPendingWorkRejected() {
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

void vwExpectBuilderEngineerSameTileExclusivityRejected() {
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

void vwExpectBuildImprovementTechCapEmptyTechRejected() {
  vwExpectBuildImprovementOutcome(
    game: buildImprovementBaseGame(
      techUnlocked: const {},
      tileState: const TileMapState(improvementByTile: {'oldWorld|P1|0|0': 1}),
      stockpile: lumberCastIronStockpile(10),
    ),
    accepted: false,
    reasonContains: 'Insufficient tech',
    onRejected: (result) {
      expect(result.reason, contains('grain'));
      expect(result.reason, contains('cap 1'));
    },
  );
}

void vwExpectScrubTimberRejectAtLevel1() {
  vwExpectBuildImprovementOutcome(
    game: scrubCapBaseGame(level: 1),
    tileMapByRegion: scrubCapTileMaps(TerrainType.scrubForest),
    accepted: false,
    reasonContains: 'Terrain caps',
    onRejected: (result) => expect(result.reason, contains('level 1')),
  );
}

void vwExpectHardwoodTimberAcceptAtLevel1() {
  vwExpectBuildImprovementOutcome(
    game: scrubCapBaseGame(level: 1),
    tileMapByRegion: scrubCapTileMaps(TerrainType.hardwoodForest),
    accepted: true,
  );
}

void vwExpectInitialScrubTimberAcceptAtLevel0() {
  vwExpectBuildImprovementOutcome(
    game: scrubCapBaseGame(level: 0),
    tileMapByRegion: scrubCapTileMaps(TerrainType.scrubForest),
    accepted: true,
  );
}

void vwExpectBuildImprovementOnPurchasedForeignTile() {
  final foreignTileKey = validateWorkForeignTileKey();
  vwExpectBuildImprovementOutcome(
    game: buildImprovementForeignProvinceGame(
      purchasedTilesByTileKey: {foreignTileKey: 'p1'},
    ),
    targetTileKey: foreignTileKey,
    accepted: true,
  );
}

void vwExpectRejectFortLevel2WithoutMineEngineering() {
  vwExpectRejected(
    vwValidateOwWorkTarget(
      game: fortWorkGame(
        fortLevel: 1,
        stockpile: Stockpile()
            .applyDelta(CommodityCatalog.lumber.id, 4)
            .applyDelta(CommodityCatalog.bronze.id, 4),
        techUnlocked: const {},
      ),
      unitId: 'eng1',
      target: kWorkTargetBuildFort,
    ),
    reasonContains: 'Mine Engineering',
  );
}
