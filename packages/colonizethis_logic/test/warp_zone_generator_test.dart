// Warp zone generator. SPEC/game/map-topology.md § Warp zones.

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_test/test.dart';

void main() {
  group('WarpZoneGenerator', () {
    test('seaZonesOnEdge returns sea zones that touch grid boundary', () {
      final grid = [
        ['p1', 'sea1', 'sea1'],
        ['p1', 'p1', 'sea1'],
      ];
      final tileMap = TileMapResult(width: 3, height: 2, grid: grid);
      final topology = MapTopology(
        nodes: const [
          TopologyNode(id: 'p1', regionId: 'r', type: TopologyNodeType.province),
          TopologyNode(id: 'sea1', regionId: 'r', type: TopologyNodeType.seaZone),
        ],
        edges: const [TopologyEdge(id1: 'p1', id2: 'sea1')],
      );
      final onEdge = seaZonesOnEdge(tileMap, topology);
      expect(onEdge, {'sea1'});
    });

    test('seaZonesOnEdge returns empty when no sea on boundary', () {
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
      expect(seaZonesOnEdge(tileMap, topology), isEmpty);
    });

    test('generateWarpZones produces 1:1 links when both maps have edge sea', () {
      final owGrid = [
        ['p1', 'sea1'],
        ['p1', 'p1'],
      ];
      final nwGrid = [
        ['p2', 'sea2'],
        ['p2', 'p2'],
      ];
      final tileMapOW = TileMapResult(width: 2, height: 2, grid: owGrid);
      final tileMapNW = TileMapResult(width: 2, height: 2, grid: nwGrid);
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
      expect(links.length, 1);
      expect(links[0].regionId, 'oldWorld');
      expect(links[0].seaZoneId, 'sea1');
      expect(links[0].otherRegionId, 'newWorld');
      expect(links[0].otherSeaZoneId, 'sea2');
    });

    test('generateWarpZones returns empty when one map has no edge sea', () {
      final owGrid = [
        ['p1', 'sea1'],
        ['p1', 'p1'],
      ];
      final nwGrid = [
        ['p2', 'p2'],
        ['p2', 'p2'],
      ];
      final tileMapOW = TileMapResult(width: 2, height: 2, grid: owGrid);
      final tileMapNW = TileMapResult(width: 2, height: 2, grid: nwGrid);
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
      expect(links, isEmpty);
    });
  });
}
