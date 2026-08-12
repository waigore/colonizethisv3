import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_world/src/world/sea_reachable_provinces.dart';
import 'package:colonizethis_test/test.dart';

import '../world_test_support/world_test_support.dart';

/// Sea-reachability BFS pins (Refs #3290 / densify #4330 Slice C).
void main() {
  group('reachableNonOwnedProvinceIdsViaSeas', () {
    for (final case_ in seaReachableIdsCases) {
      test(case_.description, () {
        final result = reachableNonOwnedProvinceIdsViaSeas(
          case_.topology,
          case_.anchors,
          seaReachableViewOwning(case_.owners),
          regionIdFilter: case_.regionIdFilter,
        );
        expect(result, case_.expected);
      });
    }
  });

  group('reachableNonOwnedProvinceDistancesViaSeas', () {
    for (final case_ in seaReachableDistancesCases) {
      test(case_.description, () {
        final result = reachableNonOwnedProvinceDistancesViaSeas(
          case_.topology,
          case_.anchors,
          seaReachableViewOwning(case_.owners),
          regionIdFilter: case_.regionIdFilter,
        );
        expect(result, case_.expected);
      });
    }

    test('identical inputs produce identical distance maps', () {
      final topology = topologyFromGraph(
        nodes: [
          prefixedProvinceNode('oldWorld|own'),
          prefixedSeaZoneNode('oldWorld|owSea'),
          prefixedSeaZoneNode('newWorld|nwSea'),
          prefixedProvinceNode('newWorld|colonyA'),
          prefixedProvinceNode('newWorld|colonyB'),
        ],
        edges: const [
          TopologyEdge(id1: 'oldWorld|own', id2: 'oldWorld|owSea'),
          TopologyEdge(id1: 'oldWorld|owSea', id2: 'newWorld|nwSea'),
          TopologyEdge(id1: 'newWorld|nwSea', id2: 'newWorld|colonyA'),
          TopologyEdge(id1: 'newWorld|nwSea', id2: 'newWorld|colonyB'),
        ],
      );
      final view = seaReachableViewOwning(const {
        'oldWorld|own': 'p1',
        'newWorld|colonyA': 'p2',
        'newWorld|colonyB': 'p3',
      });
      final first = reachableNonOwnedProvinceDistancesViaSeas(
        topology,
        {'oldWorld|own'},
        view,
        regionIdFilter: kNewWorldRegionId,
      );
      final second = reachableNonOwnedProvinceDistancesViaSeas(
        topology,
        {'oldWorld|own'},
        view,
        regionIdFilter: kNewWorldRegionId,
      );
      expect(first, second);
      expect(first, {'newWorld|colonyA': 3, 'newWorld|colonyB': 3});
    });
  });
}
