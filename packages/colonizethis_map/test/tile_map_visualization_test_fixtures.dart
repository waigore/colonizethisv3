import 'package:colonizethis_data/colonizethis_data.dart';

/// Shared fixtures for the `tile_map_visualization` test suites.
///
/// These were split out of the former single `tile_map_visualization_test.dart`
/// so that the render and helper test files each stay under the 500-line
/// guideline without duplicating the topology/result fixtures. Refs #3588.
final MapTopology visualizationTopology = MapTopology(
  nodes: [
    const TopologyNode(
      id: 'p1',
      regionId: 'oldWorld',
      type: TopologyNodeType.province,
    ),
    const TopologyNode(
      id: 'p2',
      regionId: 'oldWorld',
      type: TopologyNodeType.province,
    ),
    const TopologyNode(
      id: 's1',
      regionId: 'oldWorld',
      type: TopologyNodeType.seaZone,
    ),
  ],
  edges: [
    const TopologyEdge(id1: 'p1', id2: 'p2'),
    const TopologyEdge(id1: 'p1', id2: 's1'),
  ],
);

final TileMapResult visualizationSmallResult = TileMapResult(
  width: 4,
  height: 3,
  grid: [
    ['p1', 'p1', 'p2', 'p2'],
    ['p1', 's1', 's1', 'p2'],
    ['p1', 'p1', 'p2', 'p2'],
  ],
);

/// Result with terrain: p1/p2 land, s1 sea; at least one horizontal and one
/// vertical border.
final TileMapResult visualizationResultWithTerrain = TileMapResult(
  width: 4,
  height: 3,
  grid: [
    ['p1', 'p1', 'p2', 'p2'],
    ['p1', 's1', 's1', 'p2'],
    ['p1', 'p1', 'p2', 'p2'],
  ],
  terrainGrid: [
    [
      TerrainType.plains,
      TerrainType.plains,
      TerrainType.hills,
      TerrainType.hills,
    ],
    [TerrainType.plains, null, null, TerrainType.hills],
    [
      TerrainType.plains,
      TerrainType.plains,
      TerrainType.hills,
      TerrainType.hills,
    ],
  ],
);

/// Like [visualizationResultWithTerrain] with resourceGrid:
/// (0,0)=grain, (2,0)=timber, (0,2)=iron; others null.
final TileMapResult visualizationResultWithTerrainAndResources = TileMapResult(
  width: 4,
  height: 3,
  grid: visualizationResultWithTerrain.grid,
  terrainGrid: visualizationResultWithTerrain.terrainGrid,
  resourceGrid: [
    [Resource.grain, null, Resource.timber, null],
    [null, null, null, null],
    [Resource.iron, null, null, null],
  ],
);
