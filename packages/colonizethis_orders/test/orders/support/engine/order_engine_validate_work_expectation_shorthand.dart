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
