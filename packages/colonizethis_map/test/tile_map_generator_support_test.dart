import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_map/colonizethis_map.dart';

void main() {
  group('TileMapParams.copyWith', () {
    test('overrides supported generation toggles and keeps other fields', () {
      final base = TileMapParams(
        width: 32,
        height: 24,
        seed: 7,
        seaFraction: 0.6,
        borderNoise: 0.1,
        skipFillLakes: false,
        joinContinents: true,
        seedBeforeAssignment: false,
      );

      final updated = base.copyWith(
        seed: 99,
        seaFraction: 0.55,
        borderNoise: 0.35,
        skipFillLakes: true,
        joinContinents: false,
        seedBeforeAssignment: true,
      );

      expect(updated.seed, 99);
      expect(updated.seaFraction, 0.55);
      expect(updated.borderNoise, 0.35);
      expect(updated.skipFillLakes, isTrue);
      expect(updated.joinContinents, isFalse);
      expect(updated.seedBeforeAssignment, isTrue);
      expect(updated.width, base.width);
      expect(updated.height, base.height);
      expect(updated.maxSeaZoneFraction, base.maxSeaZoneFraction);
    });
  });

  group('computeGridSizeFromParams', () {
    test(
      'derives grid size from MapGenerationParams: 60 provinces, sea 0.6, target 35',
      () {
        final params = MapGenerationParams(
          targetTilesPerProvince: 35,
          seaFraction: 0.6,
          numContinents: 3,
        );
        final size = computeGridSizeFromParams(60, params);
        final totalLandTiles = 60 * 35;
        expect(totalLandTiles, 2100);
        final totalTiles = (totalLandTiles / (1 - 0.6)).round();
        expect(totalTiles, 5250);
        expect(
          size.width * size.height,
          greaterThanOrEqualTo(totalTiles - size.height),
        );
        expect(
          size.width * size.height,
          lessThanOrEqualTo(totalTiles + size.height),
        );
        expect(size.width, greaterThanOrEqualTo(8));
        expect(size.height, greaterThanOrEqualTo(8));
      },
    );

    test('higher sea fraction yields larger total grid for same land', () {
      final sizeLowSea = computeGridSizeFromParams(
        20,
        MapGenerationParams(seaFraction: 0.5, targetTilesPerProvince: 35),
      );
      final sizeHighSea = computeGridSizeFromParams(
        20,
        MapGenerationParams(seaFraction: 0.6, targetTilesPerProvince: 35),
      );
      expect(
        sizeHighSea.width * sizeHighSea.height,
        greaterThan(sizeLowSea.width * sizeLowSea.height),
      );
    });

    test('zero provinces returns default dimensions', () {
      final size = computeGridSizeFromParams(0, const MapGenerationParams());
      expect(size.width, 32);
      expect(size.height, 24);
    });
  });

  group('buildProvinceToContinentMap', () {
    test('partitions provinces evenly across continents', () {
      final map = buildProvinceToContinentMap(6, 2);
      expect(map.length, 6);
      expect(map['p1'], 0);
      expect(map['p2'], 0);
      expect(map['p3'], 0);
      expect(map['p4'], 1);
      expect(map['p5'], 1);
      expect(map['p6'], 1);
    });

    test('distributes remainder to first continents', () {
      final map = buildProvinceToContinentMap(7, 3);
      expect(map.length, 7);
      expect(map['p1'], 0);
      expect(map['p2'], 0);
      expect(map['p3'], 0); // continent 0 gets 3
      expect(map['p4'], 1);
      expect(map['p5'], 1); // continent 1 gets 2
      expect(map['p6'], 2);
      expect(map['p7'], 2); // continent 2 gets 2
    });
  });

  group('buildProvinceToContinentMapFromCounts', () {
    test('maps explicit per-continent sizes (locked OW / NW buckets)', () {
      final map = buildProvinceToContinentMapFromCounts([13, 13, 17, 17]);
      expect(map.length, 60);
      expect(map['p1'], 0);
      expect(map['p13'], 0);
      expect(map['p14'], 1);
      expect(map['p26'], 1);
      expect(map['p27'], 2);
      expect(map['p43'], 2);
      expect(map['p44'], 3);
      expect(map['p60'], 3);
    });
  });

  group('computeContinentMembership', () {
    test('returns two components for 2 continents', () {
      final topology = generateTopology(
        TopologyGeneratorParams(
          numProvinces: 60,
          numContinents: 2,
          regionId: 'oldWorld',
          seed: 1,
        ),
      );
      final membership = computeContinentMembership(topology);
      expect(membership.length, 60);
      final indices = membership.values.toSet();
      expect(indices.length, 2);
      expect(membership['p1'], membership['p30']);
      expect(membership['p31'], membership['p60']);
      expect(membership['p1'], isNot(equals(membership['p31'])));
    });
  });

  group('validateTileMapTopology', () {
    test('grid missing required adjacency yields missing non-empty', () {
      final topology = MapTopology(
        nodes: [
          const TopologyNode(
            id: 'p1',
            regionId: 'r1',
            type: TopologyNodeType.province,
          ),
          const TopologyNode(
            id: 'p2',
            regionId: 'r1',
            type: TopologyNodeType.province,
          ),
          const TopologyNode(
            id: 's1',
            regionId: 'r1',
            type: TopologyNodeType.seaZone,
          ),
        ],
        edges: [
          const TopologyEdge(id1: 'p1', id2: 'p2'),
          const TopologyEdge(id1: 'p1', id2: 's1'),
          const TopologyEdge(id1: 'p2', id2: 's1'),
        ],
      );
      final grid = [
        ['p1', 'p1', 's1'],
        ['p1', 'p1', 's1'],
        ['s1', 's1', 's1'],
      ];
      final result = TileMapResult(width: 3, height: 3, grid: grid);
      final validation = validateTileMapTopology(topology, result);
      expect(validation.missing, contains('p1|p2'));
      expect(validation.hasIssues, isTrue);
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
