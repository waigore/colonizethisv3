// Shared fixtures for valid-work-tiles / suggest-work scenarios (Refs #3949).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'valid_work_tiles_test_support.dart';

/// NW home + adjacent target province with partial visibility (home full, t0
/// unknown, t1 fogged). Used by suggest explore/prospect scenario bodies.
class NwPartialRevealHomeTarget {
  NwPartialRevealHomeTarget({
    required this.homeLocalId,
    required this.targetLocalId,
    this.homeOwnerId = ValidWorkTilesTestSupport.playerId,
    required this.targetOwnerId,
    this.unitId = 'ex1',
    this.resourceByTileKey = const {},
    this.playerProspectedTiles = const {},
  }) : provHome = ValidWorkTilesTestSupport.provinceId(
         homeLocalId,
         regionId: ValidWorkTilesTestSupport.nw,
       ),
       provTarget = ValidWorkTilesTestSupport.provinceId(
         targetLocalId,
         regionId: ValidWorkTilesTestSupport.nw,
       ),
       tileHome = ValidWorkTilesTestSupport.tileKey(
         homeLocalId,
         0,
         0,
         regionId: ValidWorkTilesTestSupport.nw,
       ),
       t0 = ValidWorkTilesTestSupport.tileKey(
         targetLocalId,
         0,
         0,
         regionId: ValidWorkTilesTestSupport.nw,
       ),
       t1 = ValidWorkTilesTestSupport.tileKey(
         targetLocalId,
         1,
         0,
         regionId: ValidWorkTilesTestSupport.nw,
       );

  final String homeLocalId;
  final String targetLocalId;
  final String homeOwnerId;
  final String targetOwnerId;
  final String unitId;
  final Map<String, String> resourceByTileKey;
  final Map<String, Set<String>> playerProspectedTiles;

  final String provHome;
  final String provTarget;
  final String tileHome;
  final String t0;
  final String t1;

  WorldState world({Unit? unit}) {
    final actor =
        unit ??
        ValidWorkTilesTestSupport.explorerUnit(
          id: unitId,
          locationProvinceId: provHome,
          tileKey: tileHome,
        );
    return WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
      oldWorld: const RegionData(),
      newWorld: RegionData(
        provinces: [
          Province(
            id: provHome,
            regionId: ValidWorkTilesTestSupport.nw,
            ownerId: homeOwnerId,
          ),
          Province(
            id: provTarget,
            regionId: ValidWorkTilesTestSupport.nw,
            ownerId: targetOwnerId,
          ),
        ],
        units: [actor],
      ),
      tileKeysByRegionAndProvince: ValidWorkTilesTestSupport.tileKeysByProvince(
        {
          provHome: [tileHome],
          provTarget: [t0, t1],
        },
        regionId: ValidWorkTilesTestSupport.nw,
      ),
      resourceByTileKey: resourceByTileKey,
      playerProspectedTiles: playerProspectedTiles,
      playerVisibilityByTile: {
        ValidWorkTilesTestSupport.playerId: {
          tileHome: 'fullyVisible',
          t0: 'unknown',
          t1: 'fogged',
        },
      },
    );
  }

  MapTopology topology() => MapTopology(
    nodes: [
      TopologyNode(
        id: homeLocalId,
        regionId: ValidWorkTilesTestSupport.nw,
        type: TopologyNodeType.province,
      ),
      TopologyNode(
        id: targetLocalId,
        regionId: ValidWorkTilesTestSupport.nw,
        type: TopologyNodeType.province,
      ),
    ],
    edges: [TopologyEdge(id1: homeLocalId, id2: targetLocalId)],
  );

  Game game({
    required String id,
    List<Player>? players,
    List<Tribe>? tribes,
    List<MinorNation>? minorNations,
    List<OvertureState>? overtureStates,
    Unit? unit,
  }) => Game(
    id: id,
    worldState: world(unit: unit),
    players: players ?? const [ValidWorkTilesTestSupport.defaultPlayer],
    tribes: tribes ?? const [],
    minorNations: minorNations ?? const [],
    overtureStates: overtureStates ?? const [],
  );
}

/// OW single-province builder game used by build_improvement visibility cases.
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
  final unit = ValidWorkTilesTestSupport.builderUnit(
    locationProvinceId: p1,
    tileKey: builderTileKey,
  );
  final tileKeys = Map<String, List<String>>.from(tilesByProvince);
  if (seaZoneId != null && seaTiles != null) {
    tileKeys[seaZoneId] = seaTiles;
  }
  final visibility = <String, String>{
    for (final tiles in tileKeys.values)
      for (final t in tiles) t: 'fullyVisible',
  };
  return Game(
    id: 'g1',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
      oldWorld: RegionData(provinces: provinces, units: [unit]),
      newWorld: const RegionData(),
      tileKeysByRegionAndProvince: seaZoneId == null
          ? ValidWorkTilesTestSupport.tileKeysByProvince(tilesByProvince)
          : {ValidWorkTilesTestSupport.ow: tileKeys},
      resourceByTileKey: resourceByTileKey,
      purchasedTilesByTileKey: purchasedTilesByTileKey ?? const {},
      playerProspectedTiles: playerProspectedTiles ?? const {},
      playerVisibilityByTile: {
        ValidWorkTilesTestSupport.playerId: visibility,
      },
      tileState: TileMapState(
        improvementByTile: improvementByTile ?? const {},
      ),
    ),
    players: [
      ValidWorkTilesTestSupport.playerWithBuildStockpile(),
      ...?extraPlayers,
    ],
    minorNations: minorNations ?? const [],
  );
}

/// Tribe-owned OW province explorer setup for prospect tile-key cases.
Game owTribeProspectGame({
  required String provinceLocalId,
  required List<String> tileKeys,
  required Map<String, String> resourceByTileKey,
  required Map<String, String> visibilityByTile,
  Map<String, Set<String>>? playerProspectedTiles,
}) {
  final provinceId = ValidWorkTilesTestSupport.provinceId(provinceLocalId);
  final startTile = tileKeys.first;
  final unit = ValidWorkTilesTestSupport.explorerUnit(
    locationProvinceId: provinceId,
    tileKey: startTile,
  );
  return Game(
    id: 'g1',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
      oldWorld: RegionData(
        provinces: [
          Province(
            id: provinceId,
            regionId: ValidWorkTilesTestSupport.ow,
            ownerId: 'tribe1',
          ),
        ],
        units: [unit],
      ),
      newWorld: const RegionData(),
      playerVisibilityByTile: {
        ValidWorkTilesTestSupport.playerId: visibilityByTile,
      },
      resourceByTileKey: resourceByTileKey,
      playerProspectedTiles: playerProspectedTiles ?? const {},
      tileKeysByRegionAndProvince: ValidWorkTilesTestSupport.tileKeysByProvince({
        provinceId: tileKeys,
      }),
    ),
    players: const [ValidWorkTilesTestSupport.defaultPlayer],
    tribes: const [ValidWorkTilesTestSupport.defaultTribe],
    // Refs #3753 R4: a Consulate is required to prospect Tribe provinces.
    overtureStates: const [ValidWorkTilesTestSupport.tribeConsulateOverture],
  );
}

MapTopology owSingleProvinceTopology(String localId) => MapTopology(
  nodes: [
    TopologyNode(
      id: localId,
      regionId: ValidWorkTilesTestSupport.ow,
      type: TopologyNodeType.province,
    ),
  ],
  edges: const [],
);

/// Grain tiles on owned province for suggestWorkOrders build_improvement cases.
Game owGrainBuildSuggestGame({
  required List<String> tileKeys,
  Map<String, String>? visibilityOverride,
}) {
  final p1 = ValidWorkTilesTestSupport.provinceId('p1');
  final tile0 = tileKeys.first;
  final builder = ValidWorkTilesTestSupport.builderUnit(
    locationProvinceId: p1,
    tileKey: tile0,
  );
  final visibility = visibilityOverride ??
      {for (final t in tileKeys) t: 'fullyVisible'};
  return Game(
    id: 'g1',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
      oldWorld: RegionData(
        provinces: [
          Province(
            id: p1,
            regionId: ValidWorkTilesTestSupport.ow,
            ownerId: ValidWorkTilesTestSupport.playerId,
          ),
        ],
        units: [builder],
      ),
      newWorld: const RegionData(),
      playerVisibilityByTile: {
        ValidWorkTilesTestSupport.playerId: visibility,
      },
      tileKeysByRegionAndProvince: ValidWorkTilesTestSupport.tileKeysByProvince({
        p1: tileKeys,
      }),
      resourceByTileKey: {for (final t in tileKeys) t: 'grain'},
      tileState: TileMapState(
        improvementByTile: {for (final t in tileKeys) t: 0},
      ),
    ),
    players: [ValidWorkTilesTestSupport.playerWithTreasury()],
  );
}

Set<String> validWorkTilesWithVisibility({
  required Game game,
  required MapTopology topology,
  required String unitId,
  required String workTarget,
  Orders currentOrders = const Orders(),
  Map<String, TileMapResult>? tileMapByRegion,
}) {
  final view = buildPlayerView(
    game,
    topology,
    ValidWorkTilesTestSupport.playerId,
  );
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
  final view = buildPlayerView(
    game,
    topology,
    ValidWorkTilesTestSupport.playerId,
  );
  return suggestWorkOrders(view, game, topology, currentOrders);
}
