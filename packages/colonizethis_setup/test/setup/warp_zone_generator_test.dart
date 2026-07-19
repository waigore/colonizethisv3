// Warp zone generator. SPEC/game/map-topology.md § Warp zones.
// Ported from colonizethis_logic (Refs #4090 Slice C).

import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_setup/colonizethis_setup.dart';

void main() {
  group('WarpZoneGenerator', () {
    test('seaZonesPerEdge returns one sea zone per edge', () {
      final grid = [
        ['sea1', 'sea1', 'sea2'], // top edge: sea1, sea2
        ['p1', 'p1', 'sea2'],
        ['sea3', 'p1', 'sea2'], // bottom edge: sea3
      ];
      final tileMap = TileMapResult(width: 3, height: 3, grid: grid);
      final topology = MapTopology(
        nodes: const [
          TopologyNode(id: 'p1', regionId: 'r', type: TopologyNodeType.province),
          TopologyNode(id: 'sea1', regionId: 'r', type: TopologyNodeType.seaZone),
          TopologyNode(id: 'sea2', regionId: 'r', type: TopologyNodeType.seaZone),
          TopologyNode(id: 'sea3', regionId: 'r', type: TopologyNodeType.seaZone),
        ],
        edges: const [],
      );
      final perEdge = seaZonesPerEdge(tileMap, topology, 42);
      // Should pick one per edge (top has sea1/sea2, right has sea2, bottom has sea3, left has sea3)
      expect(perEdge.length, lessThanOrEqualTo(4));
      expect(perEdge.containsKey('top'), isTrue);
      expect(perEdge.containsKey('bottom'), isTrue);
    });

    test('seaZonesPerEdge returns empty when no sea on boundary', () {
      final grid = [
        ['p1', 'p1'],
        ['p1', 'p1'],
      ];
      final tileMap = TileMapResult(width: 2, height: 2, grid: grid);
      final topology = MapTopology(
        nodes: const [
          TopologyNode(id: 'p1', regionId: 'r', type: TopologyNodeType.province),
        ],
        edges: const [],
      );
      expect(seaZonesPerEdge(tileMap, topology, 42), isEmpty);
    });

    test('generateWarpZones produces at most one link per edge', () {
      // Use 4x4 grids where sea zones are strictly on one edge (not corners)
      final owGrid = [
        ['p1',   'sea1', 'sea1', 'p1'  ], // sea1 on top edge (middle positions)
        ['p1',   'sea1', 'sea1', 'p1'  ],
        ['p1',   'p1',   'p1',   'p1'  ],
        ['p1',   'p1',   'p1',   'p1'  ],
      ];
      final nwGrid = [
        ['p2',   'sea2', 'sea2', 'p2'  ], // sea2 on top edge (middle positions)
        ['p2',   'sea2', 'sea2', 'p2'  ],
        ['p2',   'p2',   'p2',   'p2'  ],
        ['p2',   'p2',   'p2',   'p2'  ],
      ];
      final tileMapOW = TileMapResult(width: 4, height: 4, grid: owGrid);
      final tileMapNW = TileMapResult(width: 4, height: 4, grid: nwGrid);
      final topoOW = MapTopology(
        nodes: const [
          TopologyNode(id: 'p1', regionId: 'oldWorld', type: TopologyNodeType.province),
          TopologyNode(id: 'sea1', regionId: 'oldWorld', type: TopologyNodeType.seaZone),
        ],
        edges: const [TopologyEdge(id1: 'p1', id2: 'sea1')],
      );
      final topoNW = MapTopology(
        nodes: const [
          TopologyNode(id: 'p2', regionId: 'newWorld', type: TopologyNodeType.province),
          TopologyNode(id: 'sea2', regionId: 'newWorld', type: TopologyNodeType.seaZone),
        ],
        edges: const [TopologyEdge(id1: 'p2', id2: 'sea2')],
      );
      final links = generateWarpZones(
        tileMapOldWorld: tileMapOW,
        topologyOldWorld: topoOW,
        tileMapNewWorld: tileMapNW,
        topologyNewWorld: topoNW,
        regionIdOld: 'oldWorld',
        regionIdNew: 'newWorld',
        seed: 42,
      );
      // Should have exactly 1 link (both have top edge sea only)
      expect(links.length, 1);
      expect(links[0].regionId, 'oldWorld');
      expect(links[0].otherRegionId, 'newWorld');
    });

    test('generateWarpZones limits to 4 links max (one per edge)', () {
      // Create a grid where multiple sea zones touch each edge
      final owGrid = [
        ['sea1', 'sea2', 'sea3'], // top edge: 3 sea zones
        ['sea4', 'p1', 'sea5'], // left/right edges
        ['sea6', 'sea7', 'sea8'], // bottom edge: 3 sea zones
      ];
      final nwGrid = [
        ['seaA', 'seaB', 'seaC'], // top edge: 3 sea zones
        ['seaD', 'p2', 'seaE'], // left/right edges
        ['seaF', 'seaG', 'seaH'], // bottom edge: 3 sea zones
      ];
      final tileMapOW = TileMapResult(width: 3, height: 3, grid: owGrid);
      final tileMapNW = TileMapResult(width: 3, height: 3, grid: nwGrid);
      final topoOW = MapTopology(
        nodes: [
          const TopologyNode(id: 'p1', regionId: 'oldWorld', type: TopologyNodeType.province),
          for (final id in ['sea1', 'sea2', 'sea3', 'sea4', 'sea5', 'sea6', 'sea7', 'sea8'])
            TopologyNode(id: id, regionId: 'oldWorld', type: TopologyNodeType.seaZone),
        ],
        edges: const [],
      );
      final topoNW = MapTopology(
        nodes: [
          const TopologyNode(id: 'p2', regionId: 'newWorld', type: TopologyNodeType.province),
          for (final id in ['seaA', 'seaB', 'seaC', 'seaD', 'seaE', 'seaF', 'seaG', 'seaH'])
            TopologyNode(id: id, regionId: 'newWorld', type: TopologyNodeType.seaZone),
        ],
        edges: const [],
      );
      final links = generateWarpZones(
        tileMapOldWorld: tileMapOW,
        topologyOldWorld: topoOW,
        tileMapNewWorld: tileMapNW,
        topologyNewWorld: topoNW,
        regionIdOld: 'oldWorld',
        regionIdNew: 'newWorld',
        seed: 42,
      );
      // Should have at most 4 links (one per edge)
      expect(links.length, lessThanOrEqualTo(4));
    });

    test('generateWarpZones returns empty when no common edges', () {
      // OW has sea on top edge (middle only), NW has sea on bottom edge (middle only)
      // Using 5x5 grids with padding to avoid corners
      final owGrid = [
        ['p1',   'p1',   'p1',   'p1',   'p1'  ],
        ['p1',   'sea1', 'sea1', 'sea1', 'p1'  ], // sea1 below top edge
        ['p1',   'sea1', 'sea1', 'sea1', 'p1'  ],
        ['p1',   'p1',   'p1',   'p1',   'p1'  ],
        ['p1',   'p1',   'p1',   'p1',   'p1'  ],
      ];
      final nwGrid = [
        ['p2',   'p2',   'p2',   'p2',   'p2'  ],
        ['p2',   'p2',   'p2',   'p2',   'p2'  ],
        ['p2',   'p2',   'p2',   'p2',   'p2'  ],
        ['p2',   'sea2', 'sea2', 'sea2', 'p2'  ], // sea2 above bottom edge
        ['p2',   'p2',   'p2',   'p2',   'p2'  ],
      ];
      final tileMapOW = TileMapResult(width: 5, height: 5, grid: owGrid);
      final tileMapNW = TileMapResult(width: 5, height: 5, grid: nwGrid);
      final topoOW = MapTopology(
        nodes: const [
          TopologyNode(id: 'p1', regionId: 'oldWorld', type: TopologyNodeType.province),
          TopologyNode(id: 'sea1', regionId: 'oldWorld', type: TopologyNodeType.seaZone),
        ],
        edges: const [TopologyEdge(id1: 'p1', id2: 'sea1')],
      );
      final topoNW = MapTopology(
        nodes: const [
          TopologyNode(id: 'p2', regionId: 'newWorld', type: TopologyNodeType.province),
          TopologyNode(id: 'sea2', regionId: 'newWorld', type: TopologyNodeType.seaZone),
        ],
        edges: const [TopologyEdge(id1: 'p2', id2: 'sea2')],
      );
      final links = generateWarpZones(
        tileMapOldWorld: tileMapOW,
        topologyOldWorld: topoOW,
        tileMapNewWorld: tileMapNW,
        topologyNewWorld: topoNW,
        regionIdOld: 'oldWorld',
        regionIdNew: 'newWorld',
        seed: 42,
      );
      expect(links, isEmpty);
    });
  });
}
