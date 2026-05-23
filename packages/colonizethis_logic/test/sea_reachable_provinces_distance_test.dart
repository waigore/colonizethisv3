// Unit tests for `reachableNonOwnedProvinceDistancesViaSeas` in
// `packages/colonizethis_logic/lib/src/world/sea_reachable_provinces.dart`.
//
// The helper feeds the adjacency-distance iteration order in
// `planColonialAcquisition` (Refs #2509 § COLONIAL phase planner §
// planColonialAcquisition -- "sorted by adjacency distance to owned
// territory"). The distance key is BFS topology hop count from the
// nearest owned anchor: a foreign province sharing a direct
// province-province border with an owned anchor reads as distance 1,
// and an NW province reached via the canonical owned-anchor -> OW sea
// -> NW sea -> NW colony chain reads as distance 3.
//
// These tests pin:
//
//   1. Direct province-province border -> distance 1.
//   2. Province -> seaZone -> province path -> distance 2.
//   3. Canonical NW route (owned OW -> OW sea -> NW sea -> NW colony)
//      -> distance 3.
//   4. Two paths to the same foreign province -> shortest distance
//      wins.
//   5. Region filter restricts the returned distance map to the
//      requested region.
//   6. Foreign-province non-expansion (the BFS does not pass through
//      foreign provinces, mirroring the legacy
//      `reachableNonOwnedProvinceIdsViaSeas` contract).
//   7. Determinism (Refs #2509 Must-have #7): identical inputs yield
//      identical maps across repeated calls.

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/ai_api.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:test/test.dart';

const _gp1 = 'gp1';
const _tribe1 = 't1';
const _tribe2 = 't2';

Game _makeGame({
  required List<Province> oldWorldProvinces,
  required List<Province> newWorldProvinces,
}) {
  return Game(
    id: 'g-sea-reach-distance',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
      oldWorld: RegionData(provinces: oldWorldProvinces),
      newWorld: RegionData(provinces: newWorldProvinces),
    ),
    players: const [Player(id: _gp1, displayName: 'GP1', isHuman: false)],
    tribes: const [
      Tribe(id: _tribe1, displayName: 'T1'),
      Tribe(id: _tribe2, displayName: 'T2'),
    ],
  );
}

void main() {
  group('reachableNonOwnedProvinceDistancesViaSeas', () {
    test('direct province-province border -> distance 1', () {
      const topology = MapTopology(
        nodes: [
          TopologyNode(
            id: 'oldWorld|home',
            regionId: 'oldWorld',
            type: TopologyNodeType.province,
          ),
          TopologyNode(
            id: 'oldWorld|foreign',
            regionId: 'oldWorld',
            type: TopologyNodeType.province,
          ),
        ],
        edges: [TopologyEdge(id1: 'oldWorld|home', id2: 'oldWorld|foreign')],
      );
      final game = _makeGame(
        oldWorldProvinces: const [
          Province(id: 'oldWorld|home', regionId: 'oldWorld', ownerId: _gp1),
          Province(
            id: 'oldWorld|foreign',
            regionId: 'oldWorld',
            ownerId: _tribe1,
          ),
        ],
        newWorldProvinces: const [],
      );
      final view = buildPlayerView(game, topology, _gp1);

      final distances = reachableNonOwnedProvinceDistancesViaSeas(topology, {
        'oldWorld|home',
      }, view);

      expect(distances, {'oldWorld|foreign': 1});
    });

    test('province -> seaZone -> province path -> distance 2', () {
      const topology = MapTopology(
        nodes: [
          TopologyNode(
            id: 'oldWorld|home',
            regionId: 'oldWorld',
            type: TopologyNodeType.province,
          ),
          TopologyNode(
            id: 'oldWorld|owSea',
            regionId: 'oldWorld',
            type: TopologyNodeType.seaZone,
          ),
          TopologyNode(
            id: 'oldWorld|foreign',
            regionId: 'oldWorld',
            type: TopologyNodeType.province,
          ),
        ],
        edges: [
          TopologyEdge(id1: 'oldWorld|home', id2: 'oldWorld|owSea'),
          TopologyEdge(id1: 'oldWorld|owSea', id2: 'oldWorld|foreign'),
        ],
      );
      final game = _makeGame(
        oldWorldProvinces: const [
          Province(id: 'oldWorld|home', regionId: 'oldWorld', ownerId: _gp1),
          Province(
            id: 'oldWorld|foreign',
            regionId: 'oldWorld',
            ownerId: _tribe1,
          ),
        ],
        newWorldProvinces: const [],
      );
      final view = buildPlayerView(game, topology, _gp1);

      final distances = reachableNonOwnedProvinceDistancesViaSeas(topology, {
        'oldWorld|home',
      }, view);

      expect(distances, {'oldWorld|foreign': 2});
    });

    test('canonical NW route via owned -> OW sea -> NW sea -> NW colony', () {
      const topology = MapTopology(
        nodes: [
          TopologyNode(
            id: 'oldWorld|home',
            regionId: 'oldWorld',
            type: TopologyNodeType.province,
          ),
          TopologyNode(
            id: 'oldWorld|owSea',
            regionId: 'oldWorld',
            type: TopologyNodeType.seaZone,
          ),
          TopologyNode(
            id: 'newWorld|nwSea',
            regionId: 'newWorld',
            type: TopologyNodeType.seaZone,
          ),
          TopologyNode(
            id: 'newWorld|colony',
            regionId: 'newWorld',
            type: TopologyNodeType.province,
          ),
        ],
        edges: [
          TopologyEdge(id1: 'oldWorld|home', id2: 'oldWorld|owSea'),
          TopologyEdge(id1: 'oldWorld|owSea', id2: 'newWorld|nwSea'),
          TopologyEdge(id1: 'newWorld|nwSea', id2: 'newWorld|colony'),
        ],
      );
      final game = _makeGame(
        oldWorldProvinces: const [
          Province(id: 'oldWorld|home', regionId: 'oldWorld', ownerId: _gp1),
        ],
        newWorldProvinces: const [
          Province(
            id: 'newWorld|colony',
            regionId: 'newWorld',
            ownerId: _tribe1,
          ),
        ],
      );
      final view = buildPlayerView(game, topology, _gp1);

      final distances = reachableNonOwnedProvinceDistancesViaSeas(
        topology,
        {'oldWorld|home'},
        view,
        regionIdFilter: kNewWorldRegionId,
      );

      expect(distances, {'newWorld|colony': 3});
    });

    test('two paths -> shortest distance wins', () {
      // Foreign province `oldWorld|foreign` is reachable two ways:
      //   short: home -> foreign (direct border, distance 1)
      //   long:  home -> owSea -> foreign (distance 2)
      // The shortest wins.
      const topology = MapTopology(
        nodes: [
          TopologyNode(
            id: 'oldWorld|home',
            regionId: 'oldWorld',
            type: TopologyNodeType.province,
          ),
          TopologyNode(
            id: 'oldWorld|owSea',
            regionId: 'oldWorld',
            type: TopologyNodeType.seaZone,
          ),
          TopologyNode(
            id: 'oldWorld|foreign',
            regionId: 'oldWorld',
            type: TopologyNodeType.province,
          ),
        ],
        edges: [
          TopologyEdge(id1: 'oldWorld|home', id2: 'oldWorld|owSea'),
          TopologyEdge(id1: 'oldWorld|home', id2: 'oldWorld|foreign'),
          TopologyEdge(id1: 'oldWorld|owSea', id2: 'oldWorld|foreign'),
        ],
      );
      final game = _makeGame(
        oldWorldProvinces: const [
          Province(id: 'oldWorld|home', regionId: 'oldWorld', ownerId: _gp1),
          Province(
            id: 'oldWorld|foreign',
            regionId: 'oldWorld',
            ownerId: _tribe1,
          ),
        ],
        newWorldProvinces: const [],
      );
      final view = buildPlayerView(game, topology, _gp1);

      final distances = reachableNonOwnedProvinceDistancesViaSeas(topology, {
        'oldWorld|home',
      }, view);

      expect(distances['oldWorld|foreign'], 1);
    });

    test('region filter restricts returned distance map', () {
      // Both NW and OW foreign provinces are reachable; filtering to NW
      // returns only the NW entry.
      const topology = MapTopology(
        nodes: [
          TopologyNode(
            id: 'oldWorld|home',
            regionId: 'oldWorld',
            type: TopologyNodeType.province,
          ),
          TopologyNode(
            id: 'oldWorld|owForeign',
            regionId: 'oldWorld',
            type: TopologyNodeType.province,
          ),
          TopologyNode(
            id: 'oldWorld|owSea',
            regionId: 'oldWorld',
            type: TopologyNodeType.seaZone,
          ),
          TopologyNode(
            id: 'newWorld|nwSea',
            regionId: 'newWorld',
            type: TopologyNodeType.seaZone,
          ),
          TopologyNode(
            id: 'newWorld|colony',
            regionId: 'newWorld',
            type: TopologyNodeType.province,
          ),
        ],
        edges: [
          TopologyEdge(id1: 'oldWorld|home', id2: 'oldWorld|owForeign'),
          TopologyEdge(id1: 'oldWorld|home', id2: 'oldWorld|owSea'),
          TopologyEdge(id1: 'oldWorld|owSea', id2: 'newWorld|nwSea'),
          TopologyEdge(id1: 'newWorld|nwSea', id2: 'newWorld|colony'),
        ],
      );
      final game = _makeGame(
        oldWorldProvinces: const [
          Province(id: 'oldWorld|home', regionId: 'oldWorld', ownerId: _gp1),
          Province(
            id: 'oldWorld|owForeign',
            regionId: 'oldWorld',
            ownerId: _tribe1,
          ),
        ],
        newWorldProvinces: const [
          Province(
            id: 'newWorld|colony',
            regionId: 'newWorld',
            ownerId: _tribe2,
          ),
        ],
      );
      final view = buildPlayerView(game, topology, _gp1);

      final distances = reachableNonOwnedProvinceDistancesViaSeas(
        topology,
        {'oldWorld|home'},
        view,
        regionIdFilter: kNewWorldRegionId,
      );

      expect(distances, {'newWorld|colony': 3});
      expect(distances.containsKey('oldWorld|owForeign'), isFalse);
    });

    test('BFS does not expand through foreign provinces (legacy contract)', () {
      // The legacy reachable helper terminates at foreign provinces:
      // a chain of foreign provinces beyond the first is NOT
      // reachable. The distance variant must preserve that contract
      // so callers can rely on identical reachability semantics for
      // both the lex-sorted and distance-sorted invadable lists.
      const topology = MapTopology(
        nodes: [
          TopologyNode(
            id: 'oldWorld|home',
            regionId: 'oldWorld',
            type: TopologyNodeType.province,
          ),
          TopologyNode(
            id: 'newWorld|nwSea',
            regionId: 'newWorld',
            type: TopologyNodeType.seaZone,
          ),
          TopologyNode(
            id: 'newWorld|colony',
            regionId: 'newWorld',
            type: TopologyNodeType.province,
          ),
          TopologyNode(
            id: 'newWorld|far',
            regionId: 'newWorld',
            type: TopologyNodeType.province,
          ),
        ],
        edges: [
          TopologyEdge(id1: 'oldWorld|home', id2: 'newWorld|nwSea'),
          TopologyEdge(id1: 'newWorld|nwSea', id2: 'newWorld|colony'),
          TopologyEdge(id1: 'newWorld|colony', id2: 'newWorld|far'),
        ],
      );
      final game = _makeGame(
        oldWorldProvinces: const [
          Province(id: 'oldWorld|home', regionId: 'oldWorld', ownerId: _gp1),
        ],
        newWorldProvinces: const [
          Province(
            id: 'newWorld|colony',
            regionId: 'newWorld',
            ownerId: _tribe1,
          ),
          Province(id: 'newWorld|far', regionId: 'newWorld', ownerId: _tribe2),
        ],
      );
      final view = buildPlayerView(game, topology, _gp1);

      final distances = reachableNonOwnedProvinceDistancesViaSeas(
        topology,
        {'oldWorld|home'},
        view,
        regionIdFilter: kNewWorldRegionId,
      );

      expect(distances.containsKey('newWorld|colony'), isTrue);
      expect(
        distances.containsKey('newWorld|far'),
        isFalse,
        reason:
            'BFS does not expand through foreign provinces, so '
            'newWorld|far (one hop beyond newWorld|colony) is NOT '
            'discoverable.',
      );
    });

    test('determinism: identical inputs produce identical maps', () {
      const topology = MapTopology(
        nodes: [
          TopologyNode(
            id: 'oldWorld|home',
            regionId: 'oldWorld',
            type: TopologyNodeType.province,
          ),
          TopologyNode(
            id: 'oldWorld|owSea',
            regionId: 'oldWorld',
            type: TopologyNodeType.seaZone,
          ),
          TopologyNode(
            id: 'newWorld|nwSea',
            regionId: 'newWorld',
            type: TopologyNodeType.seaZone,
          ),
          TopologyNode(
            id: 'newWorld|colonyA',
            regionId: 'newWorld',
            type: TopologyNodeType.province,
          ),
          TopologyNode(
            id: 'newWorld|colonyB',
            regionId: 'newWorld',
            type: TopologyNodeType.province,
          ),
        ],
        edges: [
          TopologyEdge(id1: 'oldWorld|home', id2: 'oldWorld|owSea'),
          TopologyEdge(id1: 'oldWorld|owSea', id2: 'newWorld|nwSea'),
          TopologyEdge(id1: 'newWorld|nwSea', id2: 'newWorld|colonyA'),
          TopologyEdge(id1: 'newWorld|nwSea', id2: 'newWorld|colonyB'),
        ],
      );
      final game = _makeGame(
        oldWorldProvinces: const [
          Province(id: 'oldWorld|home', regionId: 'oldWorld', ownerId: _gp1),
        ],
        newWorldProvinces: const [
          Province(
            id: 'newWorld|colonyA',
            regionId: 'newWorld',
            ownerId: _tribe1,
          ),
          Province(
            id: 'newWorld|colonyB',
            regionId: 'newWorld',
            ownerId: _tribe2,
          ),
        ],
      );
      final view = buildPlayerView(game, topology, _gp1);

      final first = reachableNonOwnedProvinceDistancesViaSeas(
        topology,
        {'oldWorld|home'},
        view,
        regionIdFilter: kNewWorldRegionId,
      );
      final second = reachableNonOwnedProvinceDistancesViaSeas(
        topology,
        {'oldWorld|home'},
        view,
        regionIdFilter: kNewWorldRegionId,
      );

      expect(first, second);
      expect(first, {'newWorld|colonyA': 3, 'newWorld|colonyB': 3});
    });
  });
}
