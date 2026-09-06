// Map-backed GameService for Development panel golden/layout tests (Refs #4734 Slice G).

import 'package:colonizethis_data/colonizethis_data.dart';

import 'package:colonizethis_app/core/services/game_service/game_service.dart';

const String kDevelopmentPanelMapTestGameId = 'development-panel-golden-test';

final MapTopology developmentPanelMapCombinedTopology = MapTopology(
  nodes: const [
    TopologyNode(
      id: 'oldWorld|p1',
      regionId: 'oldWorld',
      type: TopologyNodeType.province,
    ),
    TopologyNode(
      id: 'oldWorld|p2',
      regionId: 'oldWorld',
      type: TopologyNodeType.province,
    ),
  ],
  edges: const [
    TopologyEdge(id1: 'oldWorld|p1', id2: 'oldWorld|p2'),
  ],
);

class DevelopmentPanelMapGameService extends GameService {
  DevelopmentPanelMapGameService(super.box, super.adapter);

  static final Map<String, MapTopology> _topologyByRegion = {
    'oldWorld': MapTopology(
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
    ),
    'newWorld': const MapTopology(nodes: [], edges: []),
  };

  static final Map<String, TileMapResult> _tileMapByRegion = {
    'oldWorld': TileMapResult(
      width: 2,
      height: 2,
      grid: const [
        ['p1', 'p1'],
        ['p2', 'p2'],
      ],
      terrainGrid: const [
        [TerrainType.plains, TerrainType.plains],
        [TerrainType.plains, TerrainType.plains],
      ],
      resourceGrid: [
        [Resource.grain, Resource.grain],
        [null, null],
      ],
    ),
    'newWorld': TileMapResult(
      width: 1,
      height: 1,
      grid: const [
        ['nw1'],
      ],
      terrainGrid: const [
        [TerrainType.plains],
      ],
    ),
  };

  static ({
    MapTopology combinedTopology,
    Map<String, TileMapResult> tileMapByRegion,
    Map<String, MapTopology> topologyByRegion,
    List<WarpLink>? warpLinks,
  })
  goldenMapData() {
    return (
      combinedTopology: developmentPanelMapCombinedTopology,
      tileMapByRegion: _tileMapByRegion,
      topologyByRegion: _topologyByRegion,
      warpLinks: null,
    );
  }

  @override
  ({
    MapTopology combinedTopology,
    Map<String, TileMapResult> tileMapByRegion,
    Map<String, MapTopology> topologyByRegion,
    List<WarpLink>? warpLinks,
  })?
  getMapData(String gameId) {
    if (gameId != kDevelopmentPanelMapTestGameId) return null;
    return goldenMapData();
  }
}
