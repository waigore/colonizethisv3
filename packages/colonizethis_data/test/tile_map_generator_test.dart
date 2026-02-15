import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:test/test.dart';

void main() {
  group('TileMapGenerator', () {
    test('generates grid with correct dimensions', () {
      final topology = MapTopology(
        nodes: [
          const TopologyNode(id: 'p1', regionId: 'r1', type: TopologyNodeType.province),
        ],
        edges: [],
      );
      final params = TileMapParams(width: 20, height: 15, seed: 1);
      final result = TileMapGenerator(params: params).generate(topology);
      expect(result.width, 20);
      expect(result.height, 15);
      expect(result.grid.length, 15);
      for (final row in result.grid) {
        expect(row.length, 20);
        expect(row.every((id) => id == 'p1'), isTrue);
      }
    });

    test('two adjacent regions touch in grid', () {
      final topology = MapTopology(
        nodes: [
          const TopologyNode(id: 'p1', regionId: 'r1', type: TopologyNodeType.province),
          const TopologyNode(id: 'p2', regionId: 'r1', type: TopologyNodeType.province),
        ],
        edges: [const TopologyEdge(id1: 'p1', id2: 'p2')],
      );
      final params = TileMapParams(width: 30, height: 30, seed: 42, maxEnforceIterations: 5);
      final result = TileMapGenerator(params: params).generate(topology);
      final pairs = result.adjacentRegionPairs();
      expect(pairs.contains('p1|p2'), isTrue);
    });

    test('empty topology throws', () {
      final topology = MapTopology(nodes: [], edges: []);
      final gen = TileMapGenerator(params: TileMapParams(width: 10, height: 10));
      expect(() => gen.generate(topology), throwsArgumentError);
    });

    test('with resourceRules produces terrain and resource grids of same dimensions', () {
      final topology = MapTopology(
        nodes: [
          const TopologyNode(id: 'p1', regionId: 'oldWorld', type: TopologyNodeType.province),
        ],
        edges: [],
      );
      final params = TileMapParams(width: 20, height: 15, seed: 2);
      final result = TileMapGenerator(params: params)
          .generate(topology, resourceRules: ResourceRules.defaultRules);
      expect(result.terrainGrid, isNotNull);
      expect(result.resourceGrid, isNotNull);
      expect(result.terrainGrid!.length, result.height);
      expect(result.resourceGrid!.length, result.height);
      for (var i = 0; i < result.height; i++) {
        expect(result.terrainGrid![i].length, result.width);
        expect(result.resourceGrid![i].length, result.width);
      }
    });

    test('terrain and resource respect region and terrain rules', () {
      final topology = MapTopology(
        nodes: [
          const TopologyNode(id: 'p1', regionId: 'oldWorld', type: TopologyNodeType.province),
        ],
        edges: [],
      );
      final params = TileMapParams(width: 25, height: 25, seed: 3);
      final result = TileMapGenerator(params: params)
          .generate(topology, resourceRules: ResourceRules.defaultRules);
      final rules = ResourceRules.defaultRules;
      for (var y = 0; y < result.height; y++) {
        for (var x = 0; x < result.width; x++) {
          final t = result.terrainAt(x, y);
          final r = result.resourceAt(x, y);
          if (t != null && r != null) {
            expect(rules.isAllowedOnTerrain(r, t), isTrue);
            expect(rules.isAllowedInRegion(r, 'oldWorld'), isTrue);
          }
        }
      }
    });

    test('without resourceRules leaves terrain and resource grids null', () {
      final topology = MapTopology(
        nodes: [
          const TopologyNode(id: 'p1', regionId: 'r1', type: TopologyNodeType.province),
        ],
        edges: [],
      );
      final result = TileMapGenerator(
        params: TileMapParams(width: 10, height: 10, seed: 1),
      ).generate(topology);
      expect(result.terrainGrid, isNull);
      expect(result.resourceGrid, isNull);
    });
  });

  group('TileMapResult', () {
    test('adjacentRegionPairs returns normalized pairs', () {
      final grid = [
        ['a', 'b'],
        ['a', 'a'],
      ];
      final result = TileMapResult(width: 2, height: 2, grid: grid);
      final pairs = result.adjacentRegionPairs();
      expect(pairs, contains('a|b'));
      expect(pairs.length, 1);
    });
  });
}
