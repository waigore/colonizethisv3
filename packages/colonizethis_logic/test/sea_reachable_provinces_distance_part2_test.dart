// Continuation of `sea_reachable_provinces_distance_test.dart`. Split to
// stay under the `repo.logic_test_file_size` 400-line cap
// (see SPEC/program/repo-lint.md, "logic test file size").
//
// These tests pin the remaining three contracts of
// `reachableNonOwnedProvinceDistancesViaSeas`:
//
//   1. Region filter restricts the returned distance map to the
//      requested region.
//   2. Foreign-province non-expansion (the BFS does not pass through
//      foreign provinces, mirroring the legacy
//      `reachableNonOwnedProvinceIdsViaSeas` contract).
//   3. Determinism (Refs #2509 Must-have #7): identical inputs yield
//      identical maps across repeated calls.

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/ai_api.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

const _gp1 = 'gp1';
const _tribe1 = 't1';
const _tribe2 = 't2';

Game _makeGame({
  required List<Province> oldWorldProvinces,
  required List<Province> newWorldProvinces,
}) {
  return Game(
    id: 'g-sea-reach-distance-part2',
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
  group('reachableNonOwnedProvinceDistancesViaSeas (part 2)', () {
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
