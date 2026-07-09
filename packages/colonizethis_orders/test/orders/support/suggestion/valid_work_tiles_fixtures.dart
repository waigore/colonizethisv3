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

const _vwtTopology = ValidWorkTilesTestSupport.emptyTopology;

Game vwtMinimalSingleTileGame() {
  final p1 = ValidWorkTilesTestSupport.provinceId('p1');
  final tile = ValidWorkTilesTestSupport.tileKey('p1', 0, 0);
  return ValidWorkTilesTestSupport.minimalValidWorkTilesGame(
    tileKeysByRegionAndProvince: ValidWorkTilesTestSupport.tileKeysByProvince({
      p1: [tile],
    }),
  );
}

Game vwtExplorerSingleTileGame() {
  final provinceId = ValidWorkTilesTestSupport.provinceId('p1');
  final tile = ValidWorkTilesTestSupport.tileKey('p1', 0, 0);
  return ValidWorkTilesTestSupport.minimalValidWorkTilesGame(
    oldWorld: RegionData(
      provinces: [
        Province(
          id: provinceId,
          regionId: ValidWorkTilesTestSupport.ow,
          ownerId: ValidWorkTilesTestSupport.playerId,
        ),
      ],
      units: [
        ValidWorkTilesTestSupport.explorerUnit(
          locationProvinceId: provinceId,
          tileKey: tile,
        ),
      ],
    ),
    tileKeysByRegionAndProvince: ValidWorkTilesTestSupport.tileKeysByProvince({
      provinceId: [tile],
    }),
  );
}

Set<String> vwtPlainKeys(Game game, String unitId, String workTarget) =>
    getValidWorkOrderTileKeys(
      game,
      _vwtTopology,
      ValidWorkTilesTestSupport.playerId,
      unitId,
      workTarget,
      const Orders(),
    );

Set<String> vwtVisKeys(Game game, String unitId, String workTarget) =>
    validWorkTilesWithVisibility(
      game: game,
      topology: _vwtTopology,
      unitId: unitId,
      workTarget: workTarget,
    );

Set<String> vwtBuildVisKeys(Game game, {String unitId = 'u1'}) =>
    vwtVisKeys(game, unitId, kWorkTargetBuildImprovement);

/// Tribe-owned OW provinces with mixed visibility for explore visibility scans.
({Game game, String partialKnownTile, String fullTile, String unknownTile})
owTribeExploreMultiProvinceFixture() {
  const partialLocal = 'p_partial';
  const fullLocal = 'p_full';
  const unknownLocal = 'p_unknown';
  final partialProvince = ValidWorkTilesTestSupport.provinceId(partialLocal);
  final fullProvince = ValidWorkTilesTestSupport.provinceId(fullLocal);
  final unknownProvince = ValidWorkTilesTestSupport.provinceId(unknownLocal);
  final partialKnownTile = ValidWorkTilesTestSupport.tileKey(partialLocal, 0, 0);
  final partialUnknownTile = ValidWorkTilesTestSupport.tileKey(partialLocal, 1, 0);
  final fullTile = ValidWorkTilesTestSupport.tileKey(fullLocal, 0, 0);
  final unknownTile = ValidWorkTilesTestSupport.tileKey(unknownLocal, 0, 0);
  final explorer = ValidWorkTilesTestSupport.explorerUnit(
    locationProvinceId: partialProvince,
    tileKey: partialKnownTile,
  );
  final game = ValidWorkTilesTestSupport.minimalValidWorkTilesGame(
    tribes: const [ValidWorkTilesTestSupport.defaultTribe],
    // Refs #3753 R4: explore/prospect in a Tribe province require a
    // Consulate (or higher); the suggestion path shares the work-order
    // validator, so a consulate is needed for these tiles to be valid.
    overtureStates: const [ValidWorkTilesTestSupport.tribeConsulateOverture],
    oldWorld: RegionData(
      provinces: [
        Province(
          id: partialProvince,
          regionId: ValidWorkTilesTestSupport.ow,
          ownerId: 'tribe1',
        ),
        Province(
          id: fullProvince,
          regionId: ValidWorkTilesTestSupport.ow,
          ownerId: 'tribe1',
        ),
        Province(
          id: unknownProvince,
          regionId: ValidWorkTilesTestSupport.ow,
          ownerId: 'tribe1',
        ),
      ],
      units: [explorer],
    ),
    tileKeysByRegionAndProvince: ValidWorkTilesTestSupport.tileKeysByProvince({
      partialProvince: [partialKnownTile, partialUnknownTile],
      fullProvince: [fullTile],
      unknownProvince: [unknownTile],
    }),
    playerVisibilityByTile: {
      ValidWorkTilesTestSupport.playerId: {
        partialKnownTile: 'fogged',
        fullTile: 'fullyVisible',
        unknownTile: 'unknown',
      },
    },
  );
  return (
    game: game,
    partialKnownTile: partialKnownTile,
    fullTile: fullTile,
    unknownTile: unknownTile,
  );
}

/// Large tribe-owned OW map for explore visibility latency checks.
Game owTribeExploreLatencyGame({
  int provinceCount = 120,
  int tilesPerProvince = 12,
}) {
  final byProvince = <String, List<String>>{};
  final visibility = <String, String>{};
  final provinces = <Province>[];

  for (var p = 0; p < provinceCount; p++) {
    final provinceId = ValidWorkTilesTestSupport.provinceId('p$p');
    provinces.add(
      Province(
        id: provinceId,
        regionId: ValidWorkTilesTestSupport.ow,
        ownerId: 'tribe1',
      ),
    );
    final tiles = <String>[];
    for (var t = 0; t < tilesPerProvince; t++) {
      final tileKey = ValidWorkTilesTestSupport.tileKey('p$p', t, 0);
      tiles.add(tileKey);
      visibility[tileKey] = (p.isEven && t == 0) ? 'fogged' : 'unknown';
    }
    byProvince[provinceId] = tiles;
  }

  final startTile = ValidWorkTilesTestSupport.tileKey('p0', 0, 0);
  final explorer = ValidWorkTilesTestSupport.explorerUnit(
    locationProvinceId: ValidWorkTilesTestSupport.provinceId('p0'),
    tileKey: startTile,
  );
  return ValidWorkTilesTestSupport.validWorkTilesGame(
    id: 'g-latency',
    tribes: const [ValidWorkTilesTestSupport.defaultTribe],
    // Refs #3753 R4: a Consulate is required to explore Tribe provinces.
    overtureStates: const [ValidWorkTilesTestSupport.tribeConsulateOverture],
    oldWorld: RegionData(provinces: provinces, units: [explorer]),
    tileKeysByRegionAndProvince:
        ValidWorkTilesTestSupport.tileKeysByProvince(byProvince),
    playerVisibilityByTile: {
      ValidWorkTilesTestSupport.playerId: visibility,
    },
  );
}

/// Adjacent owned + other-GP provinces for move-suggestion exclusion cases.
({Game game, MapTopology topology, String otherGpProvinceId})
owGpAdjacentMoveFixture({
  String otherGpId = 'gp2',
  String p1Local = 'p1',
  String p2Local = 'p2',
}) {
  final p1 = Province(
    id: ValidWorkTilesTestSupport.provinceId(p1Local),
    regionId: ValidWorkTilesTestSupport.ow,
    ownerId: ValidWorkTilesTestSupport.playerId,
  );
  final p2 = Province(
    id: ValidWorkTilesTestSupport.provinceId(p2Local),
    regionId: ValidWorkTilesTestSupport.ow,
    ownerId: otherGpId,
  );
  final unit = ValidWorkTilesTestSupport.builderUnit(
    locationProvinceId: p1.id,
  );
  final game = Game(
    id: 'g1',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
      oldWorld: RegionData(provinces: [p1, p2], units: [unit]),
      newWorld: const RegionData(),
      playerVisibilityByTile: const {
        ValidWorkTilesTestSupport.playerId: {
          'oldWorld|p1|0|0': 'fullyVisible',
          'oldWorld|p2|0|0': 'fullyVisible',
        },
      },
    ),
    players: [
      ValidWorkTilesTestSupport.defaultPlayer,
      Player(id: otherGpId, displayName: 'Other GP', isHuman: false),
    ],
  );
  final topology = MapTopology(
    nodes: const [
      TopologyNode(
        id: 'p1',
        regionId: 'oldWorld',
        type: TopologyNodeType.province,
      ),
      TopologyNode(
        id: 'p2',
        regionId: 'oldWorld',
        type: TopologyNodeType.province,
      ),
    ],
    edges: const [TopologyEdge(id1: 'p1', id2: 'p2')],
  );
  return (
    game: game,
    topology: topology,
    otherGpProvinceId: ValidWorkTilesTestSupport.provinceId(p2Local),
  );
}

Map<String, TileMapResult> vwtHillsWoolTileMap(String provinceLocal) =>
    <String, TileMapResult>{
      ValidWorkTilesTestSupport.ow: TileMapResult(
        width: 1,
        height: 1,
        grid: [
          [provinceLocal],
        ],
        terrainGrid: const [
          [TerrainType.hills],
        ],
        resourceGrid: const [
          [Resource.wool],
        ],
      ),
    };
