// Shared fixtures for OrderEngine validateWork scenarios (Refs #3949 wave 3 / #3971).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../common/game_graphs.dart';
import 'order_engine_validate_work_constants.dart';

export 'order_engine_validate_work_constants.dart';
export 'order_engine_validate_work_fixtures_minor.dart';

// dart format off
Province _vwProvince({required String provinceId, required String ow, int fortLevel = 0, String? townTileKey, int? townDevelopmentLevel}) =>
    Province(id: provinceId, regionId: ow, ownerId: 'p1', fortLevel: fortLevel, townTileKey: townTileKey, townDevelopmentLevel: townDevelopmentLevel ?? kTownDevelopmentLevelMin);

Game vwSingleProvinceUnitGame({
  required String unitId,
  required String unitType,
  Map<String, String>? resourceByTileKey,
  TileMapState tileState = const TileMapState(),
  Map<String, bool>? techUnlocked,
  Stockpile? stockpile,
  Map<String, Set<String>>? playerProspectedTiles,
  int fortLevel = 0,
  String? townTileKey,
  int? townDevelopmentLevel,
  List<String>? extraTileKeys,
  List<Unit>? units,
  int turnNumber = 0,
}) {
  const ow = ValidateWorkOw.ow;
  const provinceId = ValidateWorkOw.provinceId;
  const tileKey = ValidateWorkOw.tileKey;
  final tileKeys = [tileKey, ...?extraTileKeys];
  return ordersOwRegionGame(
    turnNumber: turnNumber,
    players: [Player(id: 'p1', displayName: 'P1', isHuman: true, capitalProvinceId: provinceId, stockpile: stockpile ?? const Stockpile(), techUnlocked: techUnlocked ?? const {})],
    oldWorld: RegionData(
      provinces: [_vwProvince(provinceId: provinceId, ow: ow, fortLevel: fortLevel, townTileKey: townTileKey, townDevelopmentLevel: townDevelopmentLevel)],
      units: units ?? [Unit(id: unitId, type: unitType, ownerId: 'p1', locationProvinceId: provinceId, tileKey: tileKey)],
    ),
    resourceByTileKey: resourceByTileKey ?? const {},
    tileState: tileState,
    tileKeysByRegionAndProvince: {ow: {provinceId: tileKeys}},
    playerVisibilityByTile: {'p1': {for (final key in tileKeys) key: 'fullyVisible'}},
    playerProspectedTiles: playerProspectedTiles ?? const {},
  );
}

Game buildImprovementBaseGame({
  Map<String, String>? resourceByTileKey,
  TileMapState tileState = const TileMapState(),
  Map<String, bool>? techUnlocked,
  Stockpile? stockpile,
  Map<String, Set<String>>? playerProspectedTiles,
}) {
  const tileKey = ValidateWorkOw.tileKey;
  return vwSingleProvinceUnitGame(
    unitId: 'builder1',
    unitType: kUnitTypeBuilder,
    resourceByTileKey: resourceByTileKey ?? {tileKey: 'grain'},
    tileState: tileState,
    techUnlocked: techUnlocked ?? const {kTechIdCircularSaw: true},
    stockpile: stockpile ?? Stockpile().applyDelta(CommodityCatalog.lumber.id, 2).applyDelta(CommodityCatalog.castIron.id, 2),
    playerProspectedTiles: playerProspectedTiles,
  );
}

Map<String, TileMapResult> scrubCapTileMaps(TerrainType terrain) => {
  ValidateWorkOw.ow: TileMapResult(width: 1, height: 1, grid: const [['P1']], terrainGrid: [[terrain]], resourceGrid: const [[Resource.timber]]),
};

Game scrubCapBaseGame({required int level}) {
  const tileKey = ValidateWorkOw.tileKey;
  return vwSingleProvinceUnitGame(
    unitId: 'builder1',
    unitType: kUnitTypeBuilder,
    resourceByTileKey: {tileKey: 'timber'},
    tileState: TileMapState(improvementByTile: {tileKey: level}),
    stockpile: lumberCastIronStockpile(20),
    techUnlocked: const {kTechIdSawMill: true, kTechIdWindSawMill: true, kTechIdCircularSaw: true},
  );
}

TileMapResult railTileMap(TerrainType terrain) => TileMapResult(width: 1, height: 1, grid: const [['P1']], terrainGrid: [[terrain]]);

Stockpile railStockpile() => Stockpile().applyDelta(CommodityCatalog.lumber.id, 10).applyDelta(CommodityCatalog.steel.id, 10);

Game gameWithRailUnit({required TileMapState tileState, Map<String, bool>? techUnlocked, Stockpile? stockpile}) =>
    vwSingleProvinceUnitGame(unitId: 'rail1', unitType: kUnitTypeRailBuilder, tileState: tileState, stockpile: stockpile ?? railStockpile(), techUnlocked: techUnlocked ?? const {kTechIdEarlySteamEngine: true});

Game buildImprovementForeignProvinceGame({Map<String, String>? purchasedTilesByTileKey}) {
  const ow = ValidateWorkOw.ow;
  const provinceId = ValidateWorkOw.provinceId;
  const tileKey = ValidateWorkOw.tileKey;
  final foreignProvinceId = '$ow|P2';
  final foreignTileKey = '$foreignProvinceId|0|0';
  return ordersOwRegionGame(
    players: [
      Player(id: 'p1', displayName: 'P1', isHuman: true, capitalProvinceId: provinceId, stockpile: Stockpile().applyDelta(CommodityCatalog.lumber.id, 2).applyDelta(CommodityCatalog.castIron.id, 2), techUnlocked: const {kTechIdCircularSaw: true}),
      const Player(id: 'p2', displayName: 'P2', isHuman: false),
    ],
    oldWorld: RegionData(
      provinces: [Province(id: provinceId, regionId: ow, ownerId: 'p1'), Province(id: foreignProvinceId, regionId: ow, ownerId: 'p2')],
      units: [Unit(id: 'builder1', type: kUnitTypeBuilder, ownerId: 'p1', locationProvinceId: provinceId, tileKey: tileKey)],
    ),
    resourceByTileKey: {tileKey: 'grain', foreignTileKey: 'grain'},
    tileKeysByRegionAndProvince: {ow: {provinceId: [tileKey], foreignProvinceId: [foreignTileKey]}},
    playerVisibilityByTile: {'p1': {tileKey: 'fullyVisible', foreignTileKey: 'fullyVisible'}},
    purchasedTilesByTileKey: purchasedTilesByTileKey ?? const {},
  );
}

String validateWorkForeignTileKey() => '${ValidateWorkOw.ow}|P2|0|0';

Game fortWorkGame({required int fortLevel, required Stockpile stockpile, Map<String, bool>? techUnlocked}) =>
    vwSingleProvinceUnitGame(unitId: 'eng1', unitType: kUnitTypeEngineer, fortLevel: fortLevel, stockpile: stockpile, techUnlocked: techUnlocked);

Game dualTilePendingWorkGame() {
  const tileB = '${ValidateWorkOw.provinceId}|1|0';
  const tileA = ValidateWorkOw.tileKey;
  return vwSingleProvinceUnitGame(unitId: 'builder1', unitType: kUnitTypeBuilder, extraTileKeys: [tileB], resourceByTileKey: const {tileA: 'grain', tileB: 'grain'}, stockpile: lumberCastIronStockpile(20), techUnlocked: const {kTechIdCircularSaw: true}, turnNumber: 1);
}

Game builderEngineerSameTileExclusivityGame() {
  const provinceId = ValidateWorkOw.provinceId;
  const tileKey = ValidateWorkOw.tileKey;
  return vwSingleProvinceUnitGame(
    unitId: 'builder1',
    unitType: kUnitTypeBuilder,
    units: [
      Unit(id: 'builder1', type: kUnitTypeBuilder, ownerId: 'p1', locationProvinceId: provinceId, tileKey: tileKey),
      Unit(id: 'engineer1', type: kUnitTypeEngineer, ownerId: 'p1', locationProvinceId: provinceId, tileKey: tileKey),
    ],
    resourceByTileKey: const {tileKey: 'grain'},
    stockpile: lumberCastIronStockpile(10),
  );
}

Game upgradeTownWorkGame({required Map<String, bool> techUnlocked}) => vwSingleProvinceUnitGame(
  unitId: 'b1',
  unitType: kUnitTypeBuilder,
  townTileKey: ValidateWorkOw.tileKey,
  townDevelopmentLevel: 1,
  techUnlocked: techUnlocked,
  stockpile: lumberCastIronStockpile(10),
);
// dart format on
