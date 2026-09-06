// MapTopology / TileMapResult fixtures for province shortcut host suites.
// Refs #4450 Slice C; densify province_shortcut_host_emit_fixtures.dart (#4734).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_map/colonizethis_map.dart';

const String kProvinceShortcutHostHumanPlayerId = 'gp1';
const String kProvinceShortcutHostOldWorldProvinceId = 'oldWorld|p1';
const String kProvinceShortcutHostTileKey = 'oldWorld|p1|0|0';
const String kProvinceShortcutHostSecondTileKey = 'oldWorld|p1|1|0';
const String kProvinceShortcutHostOldWorldSeaId = 'oldWorld|s1';
const String kProvinceShortcutHostOldWorldLocalProvinceId = 'p1';
const String kProvinceShortcutHostOldWorldLocalSeaId = 's1';

MapTopology provinceShortcutHostCombinedTopology({
  bool includeNewWorld = false,
  bool includeSea = true,
}) {
  final nodes = <TopologyNode>[
    const TopologyNode(
      id: kProvinceShortcutHostOldWorldProvinceId,
      regionId: 'oldWorld',
      type: TopologyNodeType.province,
    ),
    if (includeSea)
      const TopologyNode(
        id: kProvinceShortcutHostOldWorldSeaId,
        regionId: 'oldWorld',
        type: TopologyNodeType.seaZone,
      ),
    if (includeNewWorld) ...[
      const TopologyNode(
        id: 'newWorld|p1',
        regionId: 'newWorld',
        type: TopologyNodeType.province,
      ),
      const TopologyNode(
        id: 'newWorld|s1',
        regionId: 'newWorld',
        type: TopologyNodeType.seaZone,
      ),
    ],
  ];
  final edges = <TopologyEdge>[
    if (includeSea)
      const TopologyEdge(
        id1: kProvinceShortcutHostOldWorldProvinceId,
        id2: kProvinceShortcutHostOldWorldSeaId,
      ),
    if (includeNewWorld)
      const TopologyEdge(id1: 'newWorld|p1', id2: 'newWorld|s1'),
  ];
  return MapTopology(nodes: nodes, edges: edges);
}

Map<String, MapTopology> provinceShortcutHostTopologyByRegion({
  bool includeNewWorld = false,
  bool includeSea = true,
}) {
  MapTopology local({required String regionId}) => MapTopology(
    nodes: [
      TopologyNode(
        id: kProvinceShortcutHostOldWorldLocalProvinceId,
        regionId: regionId,
        type: TopologyNodeType.province,
      ),
      if (includeSea)
        TopologyNode(
          id: kProvinceShortcutHostOldWorldLocalSeaId,
          regionId: regionId,
          type: TopologyNodeType.seaZone,
        ),
    ],
    edges: [
      if (includeSea)
        const TopologyEdge(
          id1: kProvinceShortcutHostOldWorldLocalProvinceId,
          id2: kProvinceShortcutHostOldWorldLocalSeaId,
        ),
    ],
  );
  return {
    'oldWorld': local(regionId: 'oldWorld'),
    if (includeNewWorld) 'newWorld': local(regionId: 'newWorld'),
  };
}

Map<String, TileMapResult> provinceShortcutHostTileMapByRegion({
  int width = 1,
  int height = 1,
  List<List<String>>? grid,
  List<List<TerrainType>>? terrainGrid,
  List<List<Resource?>>? resourceGrid,
  bool includeNewWorld = false,
}) {
  final resolvedGrid =
      grid ??
      List<List<String>>.generate(
        height,
        (_) => List<String>.filled(
          width,
          kProvinceShortcutHostOldWorldLocalProvinceId,
        ),
      );
  final resolvedTerrain =
      terrainGrid ??
      List<List<TerrainType>>.generate(
        height,
        (_) => List<TerrainType>.filled(width, TerrainType.plains),
      );
  final resolvedResources =
      resourceGrid ??
      List<List<Resource?>>.generate(
        height,
        (_) => List<Resource?>.filled(width, Resource.grain),
      );
  final oldWorld = TileMapResult(
    width: width,
    height: height,
    grid: resolvedGrid,
    terrainGrid: resolvedTerrain,
    resourceGrid: resolvedResources,
  );
  return {
    'oldWorld': oldWorld,
    if (includeNewWorld)
      'newWorld': TileMapResult(
        width: width,
        height: height,
        grid: resolvedGrid,
      ),
  };
}

/// 2×2 golden tile map used by Build port / road / fort / railroad hosts.
Map<String, TileMapResult> provinceShortcutHostGoldenCoastalTileMapByRegion({
  bool includeNewWorld = false,
}) => provinceShortcutHostTileMapByRegion(
  width: 2,
  height: 2,
  grid: const [
    ['p1', 's1'],
    ['s1', 's1'],
  ],
  terrainGrid: const [
    [TerrainType.plains, TerrainType.plains],
    [TerrainType.plains, TerrainType.plains],
  ],
  resourceGrid: const [
    [Resource.grain, Resource.meat],
    [Resource.meat, Resource.meat],
  ],
  includeNewWorld: includeNewWorld,
);

typedef ProvinceShortcutHostMaps = ({
  MapTopology combinedTopology,
  Map<String, MapTopology> topologyByRegion,
  Map<String, TileMapResult> tileMapByRegion,
});

ProvinceShortcutHostMaps provinceShortcutHostCoastalMaps() => (
  combinedTopology: provinceShortcutHostCombinedTopology(),
  topologyByRegion: provinceShortcutHostTopologyByRegion(),
  tileMapByRegion: provinceShortcutHostGoldenCoastalTileMapByRegion(),
);

ProvinceShortcutHostMaps provinceShortcutHostPlainMaps() => (
  combinedTopology: provinceShortcutHostCombinedTopology(),
  topologyByRegion: provinceShortcutHostTopologyByRegion(),
  tileMapByRegion: provinceShortcutHostTileMapByRegion(),
);

ProvinceShortcutHostMaps provinceShortcutHostTwoTileMaps({
  bool includeSea = false,
}) {
  final combinedTopology = provinceShortcutHostCombinedTopology(
    includeSea: includeSea,
  );
  return (
    combinedTopology: combinedTopology,
    topologyByRegion: provinceShortcutHostTopologyByRegion(
      includeSea: includeSea,
    ),
    tileMapByRegion: provinceShortcutHostTileMapByRegion(
      width: 2,
      height: 1,
      grid: const [
        ['p1', 'p1'],
      ],
      terrainGrid: const [
        [TerrainType.plains, TerrainType.plains],
      ],
      resourceGrid: const [
        [Resource.grain, Resource.grain],
      ],
    ),
  );
}
