// Tile-map / topology / resource-visibility map fixtures for advanced-start
// unit tests. SPEC/game/advanced-starts.md (Refs #4086 Slice D).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_world/colonizethis_world.dart';

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

const advancedStartWorldKnowledgeNwTiles = <String, List<String>>{
  'newWorld|p1': ['newWorld|p1|0|0', 'newWorld|p1|1|0'],
  'newWorld|p2': ['newWorld|p2|0|0'],
  'newWorld|p3': ['newWorld|p3|0|0'],
  'newWorld|s1': ['newWorld|s1|0|0'],
  'newWorld|s2': ['newWorld|s2|0|0'],
  'newWorld|s3': ['newWorld|s3|0|0'],
};

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
