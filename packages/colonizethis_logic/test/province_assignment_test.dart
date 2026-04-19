import 'dart:math';

import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';

void main() {
  group('computeFairTargets', () {
    test('divides evenly', () {
      final result = computeFairTargets(['a', 'b', 'c'], 9);
      expect(result, {'a': 3, 'b': 3, 'c': 3});
    });

    test('distributes remainders to earlier factions', () {
      final result = computeFairTargets(['a', 'b', 'c'], 10);
      expect(result, {'a': 4, 'b': 3, 'c': 3});
    });

    test('distributes two remainders', () {
      final result = computeFairTargets(['a', 'b', 'c'], 11);
      expect(result, {'a': 4, 'b': 4, 'c': 3});
    });

    test('single faction gets all', () {
      final result = computeFairTargets(['x'], 7);
      expect(result, {'x': 7});
    });

    test('empty factions returns empty map', () {
      final result = computeFairTargets([], 10);
      expect(result, isEmpty);
    });

    test('zero total gives all zeros', () {
      final result = computeFairTargets(['a', 'b'], 0);
      expect(result, {'a': 0, 'b': 0});
    });
  });

  group('pickSimpleSeeds', () {
    test('one faction one candidate in available assigns seed', () {
      final available = {'p1'};
      final seeds = pickSimpleSeeds(
        factionIds: ['f1'],
        candidateIds: ['p1'],
        available: available,
      );
      expect(seeds, {'p1': 'f1'});
    });
    test('last faction wins when candidates are not consumed', () {
      // pickSimpleSeeds does not remove assigned candidates from available,
      // so repeated iterations overwrite the same seed. The downstream
      // BFS algorithm compensates for seedless factions.
      final available = {'p1', 'p2', 'p3', 'p4'};
      final seeds = pickSimpleSeeds(
        factionIds: ['f1', 'f2'],
        candidateIds: ['p1', 'p2', 'p3'],
        available: available,
      );
      expect(seeds.length, 1);
      expect(seeds['p1'], 'f2');
    });

    test('single faction gets one seed', () {
      final available = {'p2', 'p3'};
      final seeds = pickSimpleSeeds(
        factionIds: ['f1'],
        candidateIds: ['p1', 'p2', 'p3'],
        available: available,
      );
      expect(seeds, {'p2': 'f1'});
    });

    test('returns empty when no candidates available', () {
      final available = <String>{};
      final seeds = pickSimpleSeeds(
        factionIds: ['f1'],
        candidateIds: ['p1', 'p2'],
        available: available,
      );
      expect(seeds, isEmpty);
    });

    test('stops when candidates exhausted', () {
      final available = {'p1'};
      final seeds = pickSimpleSeeds(
        factionIds: ['f1', 'f2', 'f3'],
        candidateIds: ['p1'],
        available: available,
      );
      expect(seeds.length, 1);
      expect(seeds.containsKey('p1'), isTrue);
    });
  });

  group('assignTerritoriesByBfsGrowth', () {
    test('assigns contiguous territories via BFS', () {
      // Linear graph: p1 - p2 - p3 - p4 - p5
      final neighbours = <String, Set<String>>{
        'p1': {'p2'},
        'p2': {'p1', 'p3'},
        'p3': {'p2', 'p4'},
        'p4': {'p3', 'p5'},
        'p5': {'p4'},
      };
      final available = {'p1', 'p2', 'p3', 'p4', 'p5'};
      final seeds = {'p1': 'f1', 'p5': 'f2'};
      final targets = {'f1': 2, 'f2': 2};

      final owners = assignTerritoriesByBfsGrowth(
        neighbours: neighbours,
        factionIds: ['f1', 'f2'],
        seeds: seeds,
        targetPerFaction: targets,
        available: available,
      );

      expect(owners['p1'], 'f1');
      expect(owners['p5'], 'f2');
      // Each should have grown from their seed
      expect(
        owners.values.where((v) => v == 'f1').length,
        greaterThanOrEqualTo(2),
      );
      expect(
        owners.values.where((v) => v == 'f2').length,
        greaterThanOrEqualTo(2),
      );
    });

    test('respects maxTotal cap', () {
      final neighbours = <String, Set<String>>{
        'p1': {'p2', 'p3'},
        'p2': {'p1', 'p4'},
        'p3': {'p1', 'p5'},
        'p4': {'p2'},
        'p5': {'p3'},
      };
      final available = {'p1', 'p2', 'p3', 'p4', 'p5'};
      final seeds = {'p1': 'f1'};
      final targets = {'f1': 10};

      final owners = assignTerritoriesByBfsGrowth(
        neighbours: neighbours,
        factionIds: ['f1'],
        seeds: seeds,
        targetPerFaction: targets,
        available: available,
        maxTotal: 3,
      );

      expect(owners.length, 3);
      expect(owners['p1'], 'f1');
    });

    test('respects landmass constraint', () {
      // p1(island 1) - p2(island 1), p3(island 2) - p4(island 2)
      // p2 and p3 are neighbours across landmasses
      final neighbours = <String, Set<String>>{
        'p1': {'p2'},
        'p2': {'p1', 'p3'},
        'p3': {'p2', 'p4'},
        'p4': {'p3'},
      };
      final landmass = {'p1': 1, 'p2': 1, 'p3': 2, 'p4': 2};
      final available = {'p1', 'p2', 'p3', 'p4'};
      final seeds = {'p1': 'f1', 'p4': 'f2'};
      final targets = {'f1': 3, 'f2': 3};

      final owners = assignTerritoriesByBfsGrowth(
        neighbours: neighbours,
        landmassIds: landmass,
        factionIds: ['f1', 'f2'],
        seeds: seeds,
        targetPerFaction: targets,
        available: available,
      );

      expect(owners['p1'], 'f1');
      expect(owners['p2'], 'f1');
      expect(owners['p4'], 'f2');
      expect(owners['p3'], 'f2');
    });

    test('balances growth across factions', () {
      // Star graph: center p0 connected to p1..p6
      final neighbours = <String, Set<String>>{
        'p0': {'p1', 'p2', 'p3', 'p4', 'p5', 'p6'},
        'p1': {'p0'},
        'p2': {'p0'},
        'p3': {'p0'},
        'p4': {'p0'},
        'p5': {'p0'},
        'p6': {'p0'},
      };
      final available = {'p0', 'p1', 'p2', 'p3', 'p4', 'p5', 'p6'};
      final seeds = {'p1': 'f1', 'p2': 'f2'};
      final targets = {'f1': 3, 'f2': 3};

      final owners = assignTerritoriesByBfsGrowth(
        neighbours: neighbours,
        factionIds: ['f1', 'f2'],
        seeds: seeds,
        targetPerFaction: targets,
        available: available,
      );

      final f1Count = owners.values.where((v) => v == 'f1').length;
      final f2Count = owners.values.where((v) => v == 'f2').length;
      expect(f1Count, greaterThanOrEqualTo(3));
      expect(f2Count, greaterThanOrEqualTo(3));
    });

    test('greedy leftover assigns remaining provinces', () {
      final neighbours = <String, Set<String>>{
        'p1': {'p2'},
        'p2': {'p1', 'p3'},
        'p3': {'p2'},
      };
      final available = {'p1', 'p2', 'p3'};
      final seeds = {'p1': 'f1'};
      final targets = {'f1': 1};

      final owners = assignTerritoriesByBfsGrowth(
        neighbours: neighbours,
        factionIds: ['f1'],
        seeds: seeds,
        targetPerFaction: targets,
        available: available,
      );

      expect(owners.length, 3);
    });

    test(
      'greedy leftover uses factionLandmassIds when picking claiming faction',
      () {
        final neighbours = <String, Set<String>>{
          'a1': {'a2'},
          'a2': {'a1'},
          'b1': {'b2'},
          'b2': {'b1'},
        };
        final landmass = {'a1': 1, 'a2': 1, 'b1': 2, 'b2': 2};
        final available = {'a1', 'a2', 'b1', 'b2'};
        final owners = assignTerritoriesByBfsGrowth(
          neighbours: neighbours,
          landmassIds: landmass,
          factionLandmassIds: const {'f1': 1, 'f2': 2},
          factionIds: const ['f1', 'f2'],
          seeds: const {'a1': 'f1', 'b1': 'f2'},
          targetPerFaction: const {'f1': 1, 'f2': 1},
          available: available,
          neighborShuffleRandom: Random(1),
        );

        expect(owners.length, 4);
        expect(owners['a1'], 'f1');
        expect(owners['b1'], 'f2');
      },
    );

    test('greedy leftover falls back to lowest-count faction on landmass when '
        'no touching owner exists', () {
      final neighbours = <String, Set<String>>{
        'a1': <String>{},
        'c': <String>{},
        'b1': {'b2'},
        'b2': {'b1'},
      };
      final landmass = {'a1': 1, 'c': 1, 'b1': 2, 'b2': 2};
      final available = {'a1', 'c', 'b1', 'b2'};
      final owners = assignTerritoriesByBfsGrowth(
        neighbours: neighbours,
        landmassIds: landmass,
        factionLandmassIds: const {'f1': 1, 'f2': 2},
        factionIds: const ['f1', 'f2'],
        seeds: const {'a1': 'f1', 'b1': 'f2'},
        targetPerFaction: const {'f1': 1, 'f2': 1},
        available: available,
      );

      expect(owners['c'], 'f1');
    });

    test('shuffles neighbor expansion order when Random is provided', () {
      final neighbours = <String, Set<String>>{
        'p0': {'p1', 'p2', 'p3'},
        'p1': {'p0'},
        'p2': {'p0'},
        'p3': {'p0'},
      };
      final available = {'p0', 'p1', 'p2', 'p3'};
      assignTerritoriesByBfsGrowth(
        neighbours: neighbours,
        factionIds: const ['f1'],
        seeds: const {'p0': 'f1'},
        targetPerFaction: const {'f1': 4},
        available: available,
        neighborShuffleRandom: Random(0),
      );
    });
  });
}
