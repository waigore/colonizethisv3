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
