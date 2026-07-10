part of 'valid_work_tiles_fixtures.dart';

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

Game _vwtSingleTileGame({Unit? explorerUnit}) {
  final provinceId = ValidWorkTilesTestSupport.provinceId('p1');
  final tile = ValidWorkTilesTestSupport.tileKey('p1', 0, 0);
  return ValidWorkTilesTestSupport.minimalValidWorkTilesGame(
    oldWorld: explorerUnit == null
        ? null
        : RegionData(
            provinces: [vwtOwnedProvince('p1')],
            units: [explorerUnit],
          ),
    tileKeysByRegionAndProvince: ValidWorkTilesTestSupport.tileKeysByProvince({
      provinceId: [tile],
    }),
  );
}

Game vwtSingleTileGame({bool withExplorer = false}) => _vwtSingleTileGame(
      explorerUnit: withExplorer
          ? ValidWorkTilesTestSupport.explorerUnit(
              locationProvinceId: ValidWorkTilesTestSupport.provinceId('p1'),
              tileKey: ValidWorkTilesTestSupport.tileKey('p1', 0, 0),
            )
          : null,
    );

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
