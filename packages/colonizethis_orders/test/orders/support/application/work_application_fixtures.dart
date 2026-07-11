// Shared fixtures for work-order application / completion scenarios (Refs #3949 / #3971).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../common/game_graphs.dart';
import 'orders_application_test_support.dart';

/// Canonical OW ids used across application expectation bodies.
abstract final class WorkAppIds {
  static const ow = OrdersApplicationTestSupport.ow;
  static const provinceId = OrdersApplicationTestSupport.provinceId;
  static const tileKey = OrdersApplicationTestSupport.tileKey;
  static const originTileKey = '$ow|P1|1|0';
  static const minorProvinceId = '$ow|M1';
  static const tileKeyMinor = '$ow|M1|0|0';
  static const purchaseLandGrainCost = 15 * 10; // grain base price 10
}

Unit workAppUnit({
  required String type,
  String id = 'u1',
  String ownerId = 'p1',
  String? locationProvinceId,
  String? tileKey,
  UnitStatus status = UnitStatus.idle,
  CurrentWork? currentWork,
  String? originTileKey,
  String? assignedTileKey,
}) {
  return Unit(
    id: id,
    type: type,
    ownerId: ownerId,
    locationProvinceId: locationProvinceId ?? WorkAppIds.provinceId,
    tileKey: tileKey ?? WorkAppIds.tileKey,
    status: status,
    currentWork: currentWork,
    originTileKey: originTileKey,
    assignedTileKey: assignedTileKey,
  );
}

Province workAppOwnedProvince({
  String ownerId = 'p1',
  int fortLevel = 0,
  int townDevelopmentLevel = 0,
  String? id,
}) {
  return Province(
    id: id ?? WorkAppIds.provinceId,
    regionId: WorkAppIds.ow,
    ownerId: ownerId,
    fortLevel: fortLevel,
    townDevelopmentLevel: townDevelopmentLevel,
  );
}

/// Compact OW capital tile at ([x], [y]) for application fixtures (Refs #3949).
CapitalTile workAppCapitalTile({
  int x = 0,
  int y = 0,
  String provinceId = WorkAppIds.provinceId,
}) => CapitalTile(
  regionId: WorkAppIds.ow,
  provinceId: provinceId,
  x: x,
  y: y,
);

Player workAppPlayer({
  String id = 'p1',
  bool isHuman = true,
  int treasury = 0,
  Stockpile? stockpile,
  Map<String, bool>? techUnlocked,
  String? capitalProvinceId,
  CapitalTile? capitalTile,
  String displayName = 'P1',
}) {
  return Player(
    id: id,
    displayName: displayName,
    isHuman: isHuman,
    treasury: treasury,
    stockpile: stockpile ?? const Stockpile(),
    techUnlocked: techUnlocked ?? const {},
    capitalProvinceId: capitalProvinceId,
    capitalTile: capitalTile,
  );
}

Game workAppOwnedGame({
  required List<Unit> units,
  List<Province>? provinces,
  List<Player>? players,
  Map<String, String>? resourceByTileKey,
  Map<String, Map<String, List<String>>>? tileKeysByRegionAndProvince,
  TileMapState? tileState,
  int turnNumber = 0,
  int? globalGameSeed,
  List<MinorNation>? minorNations,
  List<OvertureState>? overtureStates,
  List<DiplomacyRelation>? diplomacyRelations,
  Map<String, bool>? aiControlByGpId,
  String? lastHumanCompletedResearchCategory,
  int? lastHumanResearchCategoryCompletionTurn,
  Map<String, Map<String, String>>? playerVisibilityByTile,
  Map<String, String>? portsByProvinceSeaboard,
}) {
  final base = ordersOwRegionGame(
    id: 'g',
    turnNumber: turnNumber,
    players: players ?? const [OrdersApplicationTestSupport.defaultPlayer],
    oldWorld: RegionData(
      provinces: provinces ?? [workAppOwnedProvince()],
      units: units,
    ),
    resourceByTileKey: resourceByTileKey,
    tileKeysByRegionAndProvince: tileKeysByRegionAndProvince ?? const {},
    tileState: tileState,
    playerVisibilityByTile: playerVisibilityByTile,
    portsByProvinceSeaboard: portsByProvinceSeaboard,
    minorNations: minorNations ?? const [],
    overtureStates: overtureStates ?? const [],
    diplomacyRelations: diplomacyRelations ?? const [],
  );
  if (globalGameSeed == null &&
      (aiControlByGpId == null || aiControlByGpId.isEmpty) &&
      lastHumanCompletedResearchCategory == null &&
      lastHumanResearchCategoryCompletionTurn == null) {
    return base;
  }
  return base.copyWith(
    globalGameSeed: globalGameSeed,
    aiControlByGpId: aiControlByGpId,
    lastHumanCompletedResearchCategory: lastHumanCompletedResearchCategory,
    lastHumanResearchCategoryCompletionTurn:
        lastHumanResearchCategoryCompletionTurn,
  );
}

Orders workAppSingleWorkOrder({
  required String target,
  String unitId = 'u1',
  String playerId = 'p1',
  String? targetTileKey,
}) {
  return Orders(
    workOrdersByPlayerId: {
      playerId: [
        WorkOrder(
          unitId: unitId,
          target: target,
          targetTileKey: targetTileKey ?? WorkAppIds.tileKey,
        ),
      ],
    },
  );
}

Orders workAppProcessWorkOrders({Iterable<String> playerIds = const ['p1']}) {
  return Orders(
    buildUnitOrdersByPlayerId: {
      for (final id in playerIds) id: <BuildUnitOrder>[],
    },
  );
}

CurrentWork workAppCurrentWork({
  required String workTarget,
  String? tileKey,
  int totalTurns = 1,
  int remainingTurns = 1,
}) {
  return CurrentWork(
    workTarget: workTarget,
    tileKey: tileKey ?? WorkAppIds.tileKey,
    totalTurns: totalTurns,
    remainingTurns: remainingTurns,
  );
}

Unit workAppWorkingUnit({
  required String type,
  required String workTarget,
  String id = 'u1',
  String ownerId = 'p1',
  int totalTurns = 1,
  int remainingTurns = 1,
  String? originTileKey,
  String? assignedTileKey,
  String? tileKey,
}) {
  return workAppUnit(
    id: id,
    type: type,
    ownerId: ownerId,
    tileKey: tileKey,
    status: UnitStatus.working,
    currentWork: workAppCurrentWork(
      workTarget: workTarget,
      tileKey: tileKey,
      totalTurns: totalTurns,
      remainingTurns: remainingTurns,
    ),
    originTileKey: originTileKey,
    assignedTileKey: assignedTileKey,
  );
}

Unit workAppPurchaseLandMerchant({
  String id = 'merchant1',
  String ownerId = 'p1',
}) => workAppUnit(
  id: id,
  type: kUnitTypeMerchant,
  ownerId: ownerId,
  locationProvinceId: WorkAppIds.minorProvinceId,
  tileKey: WorkAppIds.tileKeyMinor,
);

Game workAppSingleGpPurchaseLandGame({
  List<OvertureState> overtureStates = const [],
  List<DiplomacyRelation> diplomacyRelations = const [],
  int treasuryExtra = 100,
}) => workAppPurchaseLandGame(
  units: [workAppPurchaseLandMerchant()],
  players: [
    workAppPlayer(treasury: WorkAppIds.purchaseLandGrainCost + treasuryExtra),
  ],
  overtureStates: overtureStates,
  diplomacyRelations: diplomacyRelations,
);

Orders workAppPurchaseLandOrders({
  String unitId = 'merchant1',
  String playerId = 'p1',
}) => workAppSingleWorkOrder(
  unitId: unitId,
  playerId: playerId,
  target: kWorkTargetPurchaseLand,
  targetTileKey: WorkAppIds.tileKeyMinor,
);

/// Home + minor province purchase-land setup (merchant on minor tile).
Game workAppPurchaseLandGame({
  required List<Unit> units,
  required List<Player> players,
  List<OvertureState> overtureStates = const [],
  List<DiplomacyRelation> diplomacyRelations = const [],
}) {
  return workAppOwnedGame(
    units: units,
    provinces: [
      workAppOwnedProvince(),
      const Province(
        id: WorkAppIds.minorProvinceId,
        regionId: WorkAppIds.ow,
        ownerId: 'minor1',
      ),
    ],
    players: players,
    resourceByTileKey: const {WorkAppIds.tileKeyMinor: 'grain'},
    tileKeysByRegionAndProvince: const {
      WorkAppIds.ow: {
        WorkAppIds.provinceId: [WorkAppIds.tileKey],
        WorkAppIds.minorProvinceId: [WorkAppIds.tileKeyMinor],
      },
    },
    minorNations: const [MinorNation(id: 'minor1', displayName: 'Minor 1')],
    overtureStates: overtureStates,
    diplomacyRelations: diplomacyRelations,
  );
}

TileMapResult workAppSimpleTileMap() {
  return TileMapResult(
    width: 3,
    height: 3,
    grid: const [
      ['P1', 'P1', 'P1'],
      ['P1', 'P1', 'P1'],
      ['P1', 'P1', 'P1'],
    ],
  );
}

TileMapResult workAppRailMap() {
  return TileMapResult(
    width: 1,
    height: 1,
    grid: const [
      ['P1'],
    ],
    terrainGrid: [
      [TerrainType.plains],
    ],
  );
}
