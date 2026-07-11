// Shared fixtures for valid-work-tiles / suggest-work scenarios (Refs #3971).
//
// Wave-4: absorbed former `valid_work_tiles_fixtures_tail.dart`; NW partial-
// reveal graph lives in `nw_partial_reveal_home_target.dart`.

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../common/game_graphs.dart';
import 'valid_work_tiles_test_support.dart';

export 'nw_partial_reveal_home_target.dart';
export 'valid_work_tiles_explore_fixtures.dart';

// dart format off
Province vwtOwnedProvince(String localId) => Province(
  id: ValidWorkTilesTestSupport.provinceId(localId),
  regionId: ValidWorkTilesTestSupport.ow,
  ownerId: ValidWorkTilesTestSupport.playerId,
);

Province vwtProvince(String localId, String ownerId) => Province(
  id: ValidWorkTilesTestSupport.provinceId(localId),
  regionId: ValidWorkTilesTestSupport.ow,
  ownerId: ownerId,
);

const _vwtTopology = ValidWorkTilesTestSupport.emptyTopology;

Set<String> validWorkTilesWithVisibility({
  required Game game,
  required MapTopology topology,
  required String unitId,
  required String workTarget,
  Orders currentOrders = const Orders(),
  Map<String, TileMapResult>? tileMapByRegion,
}) {
  final view = buildPlayerView(game, topology, ValidWorkTilesTestSupport.playerId);
  return getValidWorkOrderTileKeysWithVisibility(
    game: game,
    topology: topology,
    view: view,
    unitId: unitId,
    workTarget: workTarget,
    currentOrders: currentOrders,
    tileMapByRegion: tileMapByRegion,
  );
}

List<WorkOrder> suggestedWorkOrders({
  required Game game,
  required MapTopology topology,
  Orders currentOrders = const Orders(),
}) {
  final view = buildPlayerView(game, topology, ValidWorkTilesTestSupport.playerId);
  return suggestWorkOrders(view, game, topology, currentOrders);
}

Game vwtSingleTileGame({bool withExplorer = false}) {
  final provinceId = ValidWorkTilesTestSupport.provinceId('p1');
  final tile = ValidWorkTilesTestSupport.tileKey('p1', 0, 0);
  return ValidWorkTilesTestSupport.minimalValidWorkTilesGame(
    oldWorld: withExplorer
        ? RegionData(
            provinces: [Province(id: provinceId, regionId: ValidWorkTilesTestSupport.ow, ownerId: ValidWorkTilesTestSupport.playerId)],
            units: [ValidWorkTilesTestSupport.explorerUnit(locationProvinceId: provinceId, tileKey: tile)],
          )
        : null,
    tileKeysByRegionAndProvince: ValidWorkTilesTestSupport.tileKeysByProvince({provinceId: [tile]}),
  );
}

Set<String> vwtPlainKeys(Game game, String unitId, String workTarget) =>
    getValidWorkOrderTileKeys(game, _vwtTopology, ValidWorkTilesTestSupport.playerId, unitId, workTarget, const Orders());

Set<String> vwtVisKeys(Game game, String unitId, String workTarget) =>
    validWorkTilesWithVisibility(game: game, topology: _vwtTopology, unitId: unitId, workTarget: workTarget);

Game owBuilderVisibilityGame({
  required List<Province> provinces,
  required Map<String, List<String>> tilesByProvince,
  required Map<String, String> resourceByTileKey,
  required String builderTileKey,
  String builderProvinceLocalId = 'p1',
  Map<String, String>? purchasedTilesByTileKey,
  Map<String, Set<String>>? playerProspectedTiles,
  Map<String, int>? improvementByTile,
  List<Player>? extraPlayers,
  List<MinorNation>? minorNations,
  String? seaZoneId,
  List<String>? seaTiles,
}) {
  final p1 = ValidWorkTilesTestSupport.provinceId(builderProvinceLocalId);
  final unit = ValidWorkTilesTestSupport.builderUnit(locationProvinceId: p1, tileKey: builderTileKey);
  final tileKeys = Map<String, List<String>>.from(tilesByProvince);
  if (seaZoneId != null && seaTiles != null) tileKeys[seaZoneId] = seaTiles;
  final visibility = <String, String>{for (final tiles in tileKeys.values) for (final t in tiles) t: 'fullyVisible'};
  return ordersOwRegionGame(
    turnNumber: 1,
    players: [ValidWorkTilesTestSupport.playerWithBuildStockpile(), ...?extraPlayers],
    oldWorld: RegionData(provinces: provinces, units: [unit]),
    tileKeysByRegionAndProvince: seaZoneId == null
        ? ValidWorkTilesTestSupport.tileKeysByProvince(tilesByProvince)
        : {ValidWorkTilesTestSupport.ow: tileKeys},
    resourceByTileKey: resourceByTileKey,
    purchasedTilesByTileKey: purchasedTilesByTileKey,
    playerProspectedTiles: playerProspectedTiles,
    playerVisibilityByTile: {ValidWorkTilesTestSupport.playerId: visibility},
    tileState: TileMapState(improvementByTile: improvementByTile ?? const {}),
    minorNations: minorNations ?? const [],
  );
}

Game owTribeProspectGame({
  required String provinceLocalId,
  required List<String> tileKeys,
  required Map<String, String> resourceByTileKey,
  required Map<String, String> visibilityByTile,
  Map<String, Set<String>>? playerProspectedTiles,
}) {
  final provinceId = ValidWorkTilesTestSupport.provinceId(provinceLocalId);
  final unit = ValidWorkTilesTestSupport.explorerUnit(locationProvinceId: provinceId, tileKey: tileKeys.first);
  return ordersOwRegionGame(
    turnNumber: 1,
    players: const [ValidWorkTilesTestSupport.defaultPlayer],
    oldWorld: RegionData(
      provinces: [Province(id: provinceId, regionId: ValidWorkTilesTestSupport.ow, ownerId: 'tribe1')],
      units: [unit],
    ),
    playerVisibilityByTile: {ValidWorkTilesTestSupport.playerId: visibilityByTile},
    resourceByTileKey: resourceByTileKey,
    playerProspectedTiles: playerProspectedTiles,
    tileKeysByRegionAndProvince: ValidWorkTilesTestSupport.tileKeysByProvince({provinceId: tileKeys}),
    tribes: const [ValidWorkTilesTestSupport.defaultTribe],
    // Refs #3753 R4: a Consulate is required to prospect Tribe provinces.
    overtureStates: const [ValidWorkTilesTestSupport.tribeConsulateOverture],
  );
}

MapTopology owSingleProvinceTopology(String localId) => MapTopology(
  nodes: [TopologyNode(id: localId, regionId: ValidWorkTilesTestSupport.ow, type: TopologyNodeType.province)],
  edges: const [],
);

Game owGrainBuildSuggestGame({
  required List<String> tileKeys,
  Map<String, String>? visibilityOverride,
}) {
  final p1 = ValidWorkTilesTestSupport.provinceId('p1');
  final builder = ValidWorkTilesTestSupport.builderUnit(locationProvinceId: p1, tileKey: tileKeys.first);
  final visibility = visibilityOverride ?? {for (final t in tileKeys) t: 'fullyVisible'};
  return ordersOwRegionGame(
    turnNumber: 1,
    players: [ValidWorkTilesTestSupport.playerWithTreasury()],
    oldWorld: RegionData(
      provinces: [Province(id: p1, regionId: ValidWorkTilesTestSupport.ow, ownerId: ValidWorkTilesTestSupport.playerId)],
      units: [builder],
    ),
    playerVisibilityByTile: {ValidWorkTilesTestSupport.playerId: visibility},
    tileKeysByRegionAndProvince: ValidWorkTilesTestSupport.tileKeysByProvince({p1: tileKeys}),
    resourceByTileKey: {for (final t in tileKeys) t: 'grain'},
    tileState: TileMapState(improvementByTile: {for (final t in tileKeys) t: 0}),
  );
}
// dart format on
