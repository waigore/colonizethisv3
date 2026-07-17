// Shared fixtures for advanced-start unit tests. SPEC/game/advanced-starts.md.

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/game_test_fixtures.dart';
import 'package:colonizethis_world/colonizethis_world.dart';

/// Minimal GP game with optional OW units, fleets, and minors.
Game advancedStartGpGame({
  required Player player,
  List<Unit> oldWorldUnits = const [],
  List<Fleet> fleets = const [],
  List<MinorNation> minorNations = const [],
  List<Tribe> tribes = const [],
  int turnNumber = 0,
}) {
  return TestFixtures.minimalGame(
    id: 'g1',
    turnNumber: turnNumber,
    oldWorld: RegionData(provinces: [], units: oldWorldUnits),
    newWorld: const RegionData(provinces: []),
    fleets: fleets,
    players: [player],
    minorNations: minorNations,
    tribes: tribes,
  );
}

/// Generic two-region advanced-start world fixture.
Game advancedStartWorldGame({
  required List<Province> oldWorldProvinces,
  required List<Province> newWorldProvinces,
  required Map<String, List<String>>? owTiles,
  required Map<String, List<String>>? nwTiles,
  required Map<String, String> resourceByTileKey,
  required Player player,
  List<MinorNation> minorNations = const [],
  List<Tribe> tribes = const [],
  int turnNumber = 50,
  Map<String, Map<String, String>>? playerVisibilityByTile,
  Map<String, Set<String>>? playerProspectedTiles,
  Map<String, String>? purchasedTilesByTileKey,
}) {
  return TestFixtures.minimalGame(
    id: 'g1',
    turnNumber: turnNumber,
    oldWorld: RegionData(provinces: oldWorldProvinces),
    newWorld: RegionData(provinces: newWorldProvinces),
    tileKeysByRegionAndProvince: {
      if (owTiles != null) kRegionOldWorld: owTiles,
      if (nwTiles != null) kRegionNewWorld: nwTiles,
    },
    resourceByTileKey: resourceByTileKey,
    playerVisibilityByTile: playerVisibilityByTile,
    playerProspectedTiles: playerProspectedTiles ?? const {'gp1': {}},
    purchasedTilesByTileKey: purchasedTilesByTileKey,
    players: [player],
    minorNations: minorNations,
    tribes: tribes,
  );
}

/// Default England human GP used across advanced-start slice tests.
const advancedStartDefaultPlayer = Player(
  id: 'gp1',
  displayName: 'England',
  isHuman: true,
  capitalProvinceId: 'oldWorld|p_cap',
);

/// OW capital province + sea zone topology (colonization / world knowledge).
MapTopology advancedStartOwCapitalTopology() => const MapTopology(
  nodes: [
    TopologyNode(
      id: 'p_cap',
      regionId: kRegionOldWorld,
      type: TopologyNodeType.province,
    ),
    TopologyNode(
      id: 's1',
      regionId: kRegionOldWorld,
      type: TopologyNodeType.seaZone,
    ),
  ],
  edges: [TopologyEdge(id1: 'p_cap', id2: 's1')],
);

/// Standard OW↔NW warp through sea zone `s1`.
const advancedStartDefaultWarpLinks = [
  WarpLink(
    regionId: kRegionOldWorld,
    seaZoneId: 's1',
    otherRegionId: kRegionNewWorld,
    otherSeaZoneId: 's1',
  ),
];

TileMapResult advancedStartOwDevelopmentTileMap() => TileMapResult(
  width: 4,
  height: 2,
  grid: const [
    ['m1', 'm1', 'm1', 'm1'],
    ['p1', 'p1', 'p1', 'p1'],
  ],
);

TileMapResult advancedStartNwColonizationTileMap() => TileMapResult(
  width: 3,
  height: 3,
  grid: const [
    ['p1', 'p2', 'p3'],
    ['p4', 'p5', 'p6'],
    ['p7', 'p8', 'p8'],
  ],
);

MapTopology advancedStartNwColonizationTopology() {
  return MapTopology(
    nodes: [
      const TopologyNode(
        id: 's1',
        regionId: kRegionNewWorld,
        type: TopologyNodeType.seaZone,
      ),
      for (var i = 1; i <= 8; i++)
        TopologyNode(
          id: 'p$i',
          regionId: kRegionNewWorld,
          type: TopologyNodeType.province,
        ),
    ],
    edges: const [
      TopologyEdge(id1: 's1', id2: 'p1'),
      TopologyEdge(id1: 'p1', id2: 'p2'),
      TopologyEdge(id1: 'p2', id2: 'p3'),
      TopologyEdge(id1: 'p3', id2: 'p4'),
      TopologyEdge(id1: 'p4', id2: 'p5'),
      TopologyEdge(id1: 'p5', id2: 'p6'),
      TopologyEdge(id1: 'p6', id2: 'p7'),
      TopologyEdge(id1: 'p7', id2: 'p8'),
    ],
  );
}

List<Province> advancedStartNwColonizationProvinces() {
  return [
    for (var i = 1; i <= 7; i++)
      Province(
        id: 'newWorld|p$i',
        regionId: kRegionNewWorld,
        ownerId: 'tribe1',
      ),
    Province(id: 'newWorld|p8', regionId: kRegionNewWorld, ownerId: 'tribe2'),
  ];
}

/// Development fixture: GP + minor OW capitals with towns and resources.
Game advancedStartDevelopmentFixture({
  Map<String, String>? resourceByTileKey,
  Map<String, Set<String>>? playerProspectedTiles,
  Map<String, List<String>>? owTiles,
}) {
  return advancedStartWorldGame(
    oldWorldProvinces: [
      Province(
        id: 'oldWorld|p1',
        regionId: kRegionOldWorld,
        ownerId: 'gp1',
        townTileKey: 'oldWorld|p1|1|1',
      ),
      Province(
        id: 'oldWorld|m1',
        regionId: kRegionOldWorld,
        ownerId: 'minor1',
        townTileKey: 'oldWorld|m1|0|0',
      ),
    ],
    newWorldProvinces: const [],
    owTiles:
        owTiles ??
        {
          'oldWorld|p1': [
            'oldWorld|p1|0|0',
            'oldWorld|p1|1|0',
            'oldWorld|p1|1|1',
            'oldWorld|p1|2|0',
          ],
          'oldWorld|m1': [
            'oldWorld|m1|0|0',
            'oldWorld|m1|1|0',
            'oldWorld|m1|2|0',
          ],
        },
    nwTiles: null,
    resourceByTileKey:
        resourceByTileKey ??
        {
          'oldWorld|p1|0|0': 'grain',
          'oldWorld|p1|1|0': 'timber',
          'oldWorld|p1|2|0': 'wool',
          'oldWorld|m1|1|0': 'grain',
          'oldWorld|m1|2|0': 'meat',
        },
    playerProspectedTiles: playerProspectedTiles,
    player: const Player(
      id: 'gp1',
      displayName: 'England',
      isHuman: true,
      capitalProvinceId: 'oldWorld|p1',
      capitalTile: CapitalTile(
        regionId: kRegionOldWorld,
        provinceId: 'p1',
        x: 1,
        y: 1,
      ),
    ),
    minorNations: const [
      MinorNation(
        id: 'minor1',
        displayName: 'Minor 1',
        capitalProvinceId: 'oldWorld|m1',
        capitalTile: CapitalTile(
          regionId: kRegionOldWorld,
          provinceId: 'm1',
          x: 0,
          y: 0,
        ),
      ),
    ],
    turnNumber: 50,
  );
}

Game advancedStartColonizationFixture({List<Province> nwProvinces = const []}) {
  return TestFixtures.minimalGame(
    id: 'g1',
    turnNumber: 100,
    oldWorld: const RegionData(provinces: []),
    newWorld: RegionData(provinces: nwProvinces),
    tileKeysByRegionAndProvince: {
      kRegionNewWorld: {
        for (final p in nwProvinces)
          (ProvinceId.isPrefixed(p.id)
              ? p.id
              : ProvinceId.full(p.regionId, p.id)): [
            '${ProvinceId.isPrefixed(p.id) ? p.id : ProvinceId.full(p.regionId, p.id)}|0|0',
          ],
      },
    },
    players: const [advancedStartDefaultPlayer],
    tribes: const [
      Tribe(id: 'tribe1', displayName: 'Tribe 1'),
      Tribe(id: 'tribe2', displayName: 'Tribe 2'),
    ],
  );
}

Game advancedStartProspectingFixture({
  required List<Province> owProvinces,
  required List<Province> nwProvinces,
  required Map<String, String> resourceByTileKey,
  required Map<String, List<String>> owTiles,
  required Map<String, List<String>> nwTiles,
}) {
  return advancedStartWorldGame(
    oldWorldProvinces: owProvinces,
    newWorldProvinces: nwProvinces,
    owTiles: owTiles,
    nwTiles: nwTiles,
    resourceByTileKey: resourceByTileKey,
    player: advancedStartDefaultPlayer,
    minorNations: const [MinorNation(id: 'minor1', displayName: 'Minor 1')],
    turnNumber: 50,
  );
}

const advancedStartWorldKnowledgeNwTiles = <String, List<String>>{
  'newWorld|p1': ['newWorld|p1|0|0', 'newWorld|p1|1|0'],
  'newWorld|p2': ['newWorld|p2|0|0'],
  'newWorld|p3': ['newWorld|p3|0|0'],
  'newWorld|s1': ['newWorld|s1|0|0'],
  'newWorld|s2': ['newWorld|s2|0|0'],
  'newWorld|s3': ['newWorld|s3|0|0'],
};

Game advancedStartWorldKnowledgeFixture() {
  return advancedStartWorldGame(
    oldWorldProvinces: const [],
    newWorldProvinces: [
      Province(id: 'newWorld|p1', regionId: kRegionNewWorld, ownerId: 'tribe1'),
      Province(id: 'newWorld|p2', regionId: kRegionNewWorld, ownerId: 'tribe1'),
      Province(id: 'newWorld|p3', regionId: kRegionNewWorld, ownerId: 'tribe2'),
    ],
    owTiles: null,
    nwTiles: advancedStartWorldKnowledgeNwTiles,
    resourceByTileKey: {
      'newWorld|p1|0|0': 'iron',
      'newWorld|p1|1|0': 'grain',
      'newWorld|p2|0|0': 'gold',
      'newWorld|p3|0|0': 'copper',
    },
    playerVisibilityByTile: {
      'gp1': {
        'newWorld|p1|0|0': VisibilityLevel.unknown.name,
        'newWorld|p1|1|0': VisibilityLevel.unknown.name,
        'newWorld|p2|0|0': VisibilityLevel.unknown.name,
        'newWorld|p3|0|0': VisibilityLevel.unknown.name,
        'newWorld|s1|0|0': VisibilityLevel.unknown.name,
        'newWorld|s2|0|0': VisibilityLevel.unknown.name,
        'newWorld|s3|0|0': VisibilityLevel.unknown.name,
      },
    },
    player: advancedStartDefaultPlayer,
    minorNations: const [MinorNation(id: 'minor1', displayName: 'Minor 1')],
    tribes: const [
      Tribe(id: 'tribe1', displayName: 'Tribe 1'),
      Tribe(id: 'tribe2', displayName: 'Tribe 2'),
    ],
    turnNumber: 50,
  );
}

MapTopology advancedStartWorldKnowledgeNwTopology() => const MapTopology(
  nodes: [
    TopologyNode(
      id: 's1',
      regionId: kRegionNewWorld,
      type: TopologyNodeType.seaZone,
    ),
    TopologyNode(
      id: 's2',
      regionId: kRegionNewWorld,
      type: TopologyNodeType.seaZone,
    ),
    TopologyNode(
      id: 's3',
      regionId: kRegionNewWorld,
      type: TopologyNodeType.seaZone,
    ),
    TopologyNode(
      id: 'p1',
      regionId: kRegionNewWorld,
      type: TopologyNodeType.province,
    ),
    TopologyNode(
      id: 'p2',
      regionId: kRegionNewWorld,
      type: TopologyNodeType.province,
    ),
    TopologyNode(
      id: 'p3',
      regionId: kRegionNewWorld,
      type: TopologyNodeType.province,
    ),
  ],
  edges: [
    TopologyEdge(id1: 's1', id2: 'p1'),
    TopologyEdge(id1: 's1', id2: 's2'),
    TopologyEdge(id1: 's2', id2: 'p2'),
    TopologyEdge(id1: 's2', id2: 's3'),
    TopologyEdge(id1: 's3', id2: 'p3'),
    TopologyEdge(id1: 'p1', id2: 'p2'),
    TopologyEdge(id1: 'p2', id2: 'p3'),
  ],
);
