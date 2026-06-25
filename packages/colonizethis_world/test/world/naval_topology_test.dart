import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_world/src/world/naval.dart';
import 'package:colonizethis_world/src/world/topology_helpers.dart';
import 'package:colonizethis_test/test.dart';

import '../test_fixtures.dart';

/// Coverage uplift for `colonizethis_world` (Refs #3290 Phase 1 follow-up).
///
/// Exercises naval topology helpers in `lib/src/world/naval.dart`.
/// SPEC/program/naval-movement-resolution.md and SPEC/game/ships-and-naval.md.
///
/// Two regions: `oldWorld` (province p1 + sea s1) and `newWorld` (province n1 +
/// sea s2). s1–s2 is a cross-region S–S warp edge.
MapTopology _topology() => const MapTopology(
  nodes: [
    TopologyNode(
      id: 'oldWorld|p1',
      regionId: 'oldWorld',
      type: TopologyNodeType.province,
    ),
    TopologyNode(
      id: 'oldWorld|s1',
      regionId: 'oldWorld',
      type: TopologyNodeType.seaZone,
    ),
    TopologyNode(
      id: 'newWorld|n1',
      regionId: 'newWorld',
      type: TopologyNodeType.province,
    ),
    TopologyNode(
      id: 'newWorld|s2',
      regionId: 'newWorld',
      type: TopologyNodeType.seaZone,
    ),
  ],
  edges: [
    TopologyEdge(id1: 'oldWorld|p1', id2: 'oldWorld|s1'),
    TopologyEdge(id1: 'oldWorld|s1', id2: 'newWorld|s2'),
    TopologyEdge(id1: 'newWorld|n1', id2: 'newWorld|s2'),
  ],
);

Game _gameWithCapital(String? capital) => TestFixtures.minimalGame(
  id: 'g-naval',
  players: [
    Player(
      id: 'p1',
      displayName: 'P1',
      isHuman: true,
      capitalProvinceId: capital,
    ),
  ],
);

void main() {
  group('dockOrderTargetsPlayerCapital', () {
    test('matches a prefixed capital', () {
      final game = _gameWithCapital('oldWorld|p1');
      expect(dockOrderTargetsPlayerCapital(game, 'p1', 'oldWorld|p1'), isTrue);
      expect(dockOrderTargetsPlayerCapital(game, 'p1', 'oldWorld|p2'), isFalse);
    });

    test('matches a legacy local capital against a prefixed dock province', () {
      final game = _gameWithCapital('p1');
      expect(dockOrderTargetsPlayerCapital(game, 'p1', 'oldWorld|p1'), isTrue);
    });

    test('returns false when player or capital is missing', () {
      expect(
        dockOrderTargetsPlayerCapital(_gameWithCapital(null), 'p1', 'x|y'),
        isFalse,
      );
      expect(
        dockOrderTargetsPlayerCapital(_gameWithCapital('oldWorld|p1'), 'zz', 'x|y'),
        isFalse,
      );
    });
  });

  test('homeFleetIdFor uses the fleet_ convention', () {
    expect(homeFleetIdFor('p1'), 'fleet_p1');
  });

  group('regionAndLocalProvinceForFleetInPort', () {
    test('splits a prefixed in-port province id', () {
      final rl = regionAndLocalProvinceForFleetInPort('oldWorld|p1', 'newWorld');
      expect(rl.regionId, 'oldWorld');
      expect(rl.localId, 'p1');
    });

    test('falls back to the fleet region for a legacy id', () {
      final rl = regionAndLocalProvinceForFleetInPort('p1', 'oldWorld');
      expect(rl.regionId, 'oldWorld');
      expect(rl.localId, 'p1');
    });
  });

  test('indexTopologyNodesByRegion groups nodes by region', () {
    final byRegion = indexTopologyNodesByRegion(_topology());
    expect(byRegion.keys, containsAll(['oldWorld', 'newWorld']));
    expect(byRegion['oldWorld']!.containsKey('oldWorld|p1'), isTrue);
  });

  group('sea-zone adjacency predicates', () {
    final topology = _topology();

    test('isAdjacentSeaZone covers edge, same-zone, and non-edge', () {
      expect(isAdjacentSeaZone(topology, 'oldWorld|s1', 'newWorld|s2'), isTrue);
      expect(isAdjacentSeaZone(topology, 'oldWorld|s1', 'oldWorld|s1'), isFalse);
      expect(isAdjacentSeaZone(topology, 'oldWorld|s1', 'oldWorld|p1'), isTrue);
      expect(isAdjacentSeaZone(topology, 'oldWorld|p1', 'newWorld|s2'), isFalse);
    });

    test('isAdjacentSeaSeaZone requires both endpoints to be sea zones', () {
      expect(
        isAdjacentSeaSeaZone(topology, 'oldWorld|s1', 'newWorld|s2'),
        isTrue,
      );
      expect(
        isAdjacentSeaSeaZone(topology, 'oldWorld|s1', 'oldWorld|p1'),
        isFalse,
      );
      expect(
        isAdjacentSeaSeaZone(topology, 'oldWorld|s1', 'oldWorld|s1'),
        isFalse,
      );
    });

    test('adjacentSeaZoneIdsSeaOnly lists S–S neighbors only', () {
      expect(adjacentSeaZoneIdsSeaOnly(topology, 'oldWorld|s1'), [
        'newWorld|s2',
      ]);
      expect(adjacentSeaZoneIdsSeaOnly(topology, 'oldWorld|p1'), isEmpty);
    });

    test('isWarpZoneSeaZone detects cross-region S–S edges', () {
      expect(isWarpZoneSeaZone(topology, 'oldWorld|s1'), isTrue);
      expect(isWarpZoneSeaZone(topology, 'oldWorld|p1'), isFalse);
    });
  });

  group('provinceTopologyNodeId', () {
    final topology = _topology();

    test('resolves local and prefixed province ids', () {
      expect(
        provinceTopologyNodeId(topology, 'p1', 'oldWorld'),
        'oldWorld|p1',
      );
      expect(
        provinceTopologyNodeId(topology, 'oldWorld|p1', 'oldWorld'),
        'oldWorld|p1',
      );
    });

    test('returns null for sea nodes, missing nodes, and missing regions', () {
      expect(provinceTopologyNodeId(topology, 's1', 'oldWorld'), isNull);
      expect(provinceTopologyNodeId(topology, 'ghost', 'oldWorld'), isNull);
      expect(provinceTopologyNodeId(topology, 'p1', 'zzz'), isNull);
    });
  });

  group('navalMoveTopologyPicksForFleet', () {
    final topology = _topology();

    test('at-sea fleet picks adjacent seas and dockable provinces', () {
      final picks = navalMoveTopologyPicksForFleet(
        topology: topology,
        fleet: Fleet(
          id: 'f1',
          ownerId: 'p1',
          seaZoneId: 'oldWorld|s1',
          regionId: 'oldWorld',
        ),
      );
      expect(picks.adjacentSeaZoneIds, contains('newWorld|s2'));
      expect(picks.adjacentProvinceIdsForDock, contains('oldWorld|p1'));
      expect(picks.totalCount, greaterThan(0));
    });

    test('in-port fleet picks undock sea zones', () {
      final picks = navalMoveTopologyPicksForFleet(
        topology: topology,
        fleet: Fleet(
          id: 'f2',
          ownerId: 'p1',
          inPortAtProvinceId: 'oldWorld|p1',
          regionId: 'oldWorld',
        ),
      );
      expect(picks.adjacentSeaZoneIds, contains('oldWorld|s1'));
      expect(picks.adjacentProvinceIdsForDock, isEmpty);
    });

    test('in-port fleet with unknown province yields empty picks', () {
      final picks = navalMoveTopologyPicksForFleet(
        topology: topology,
        fleet: Fleet(
          id: 'f3',
          ownerId: 'p1',
          inPortAtProvinceId: 'oldWorld|ghost',
          regionId: 'oldWorld',
        ),
      );
      expect(picks.totalCount, 0);
    });

    test('fleet neither at sea nor in port yields empty picks', () {
      final picks = navalMoveTopologyPicksForFleet(
        topology: topology,
        fleet: Fleet(id: 'f4', ownerId: 'p1', regionId: 'oldWorld'),
      );
      expect(picks.totalCount, 0);
    });
  });

  group('province/sea-zone lookups', () {
    final topology = _topology();

    test('firstAdjacentSeaZone returns an endpoint or null', () {
      expect(firstAdjacentSeaZone(topology, 'oldWorld|s1'), isNotNull);
      expect(firstAdjacentSeaZone(topology, 'oldWorld|orphan'), isNull);
    });

    test('seaZoneIdForProvince resolves region-scoped and global', () {
      expect(
        seaZoneIdForProvince(topology, 'p1', regionId: 'oldWorld'),
        'oldWorld|s1',
      );
      expect(seaZoneIdForProvince(topology, 'oldWorld|p1'), 'oldWorld|s1');
      expect(
        seaZoneIdForProvince(topology, 'p1', regionId: 'zzz'),
        isNull,
      );
    });

    test('provinceIdsAdjacentToSeaZone lists coastal provinces', () {
      expect(
        provinceIdsAdjacentToSeaZone(topology, 'oldWorld|s1',
            regionId: 'oldWorld'),
        contains('oldWorld|p1'),
      );
    });

    test('regionIdForSeaZone resolves known and unknown sea zones', () {
      expect(regionIdForSeaZone(topology, 'oldWorld|s1'), 'oldWorld');
      expect(regionIdForSeaZone(topology, 'oldWorld|sX'), isNull);
    });

    test('seaZoneIdsAdjacentToProvince lists P–S neighbors', () {
      expect(
        seaZoneIdsAdjacentToProvince(topology, 'oldWorld|p1'),
        contains('oldWorld|s1'),
      );
    });
  });

  group('fleetsInPortAtProvince', () {
    test('finds fleets docked at a province (prefixed and legacy)', () {
      final worldState = TestFixtures.worldStateAtOrdersPhase(
        fleets: [
          Fleet(
            id: 'f1',
            ownerId: 'p1',
            inPortAtProvinceId: 'oldWorld|p1',
            regionId: 'oldWorld',
          ),
          Fleet(
            id: 'f2',
            ownerId: 'p1',
            seaZoneId: 'oldWorld|s1',
            regionId: 'oldWorld',
          ),
        ],
      );

      expect(fleetsInPortAtProvince(worldState, 'oldWorld|p1').length, 1);
      expect(fleetsInPortAtProvince(worldState, 'p1').length, 1);
      expect(fleetsInPortAtProvince(worldState, 'oldWorld|p9'), isEmpty);
    });
  });
}
