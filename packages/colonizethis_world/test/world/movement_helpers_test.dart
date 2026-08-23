import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_world/src/world/movement.dart';
import 'package:colonizethis_test/test.dart';

import '../world_test_support/world_test_support.dart';
import 'movement_helpers_apply_cases.dart';

/// Coverage uplift for `colonizethis_world` (Refs #3290 Phase 1 follow-up).
///
/// Exercises land-move adjacency validation and civilian tile-move application
/// in `lib/src/world/movement.dart`. SPEC/program/movement.md and
/// SPEC/game/world-model-identity.md.
void main() {
  group('neighborProvinceIdsInRegion / isValidLandMoveInRegion', () {
    final topology = threeProvincePartialChainTopology(regionId: 'oldWorld');

    test('returns adjacent local ids within the region', () {
      final neighbors = neighborProvinceIdsInRegion(
        topology,
        'oldWorld',
        'p1',
      ).toList();
      expect(neighbors, ['p2']);
    });

    test('returns nothing for a province not in the region', () {
      expect(
        neighborProvinceIdsInRegion(topology, 'oldWorld', 'unknown'),
        isEmpty,
      );
    });

    test('valid neighbor move is accepted, non-neighbor rejected', () {
      expect(isValidLandMoveInRegion(topology, 'oldWorld', 'p1', 'p2'), isTrue);
      expect(
        isValidLandMoveInRegion(topology, 'oldWorld', 'p1', 'p3'),
        isFalse,
      );
    });

    test('a move onto the same province is invalid', () {
      expect(
        isValidLandMoveInRegion(topology, 'oldWorld', 'p1', 'p1'),
        isFalse,
      );
    });

    test('duplicate local ids across regions stay region-scoped', () {
      final dual = topologyFromGraph(
        nodes: [
          TopologyNode(
            id: 'p1',
            regionId: 'oldWorld',
            type: TopologyNodeType.province,
          ),
          TopologyNode(
            id: 'p2',
            regionId: 'oldWorld',
            type: TopologyNodeType.province,
          ),
          TopologyNode(
            id: 'p1',
            regionId: 'newWorld',
            type: TopologyNodeType.province,
          ),
          TopologyNode(
            id: 'p2',
            regionId: 'newWorld',
            type: TopologyNodeType.province,
          ),
        ],
        edges: [TopologyEdge(id1: 'p1', id2: 'p2')],
      );
      expect(neighborProvinceIdsInRegion(dual, 'oldWorld', 'p1').toList(), [
        'p2',
      ]);
      expect(neighborProvinceIdsInRegion(dual, 'newWorld', 'p1').toList(), [
        'p2',
      ]);
      expect(isValidLandMoveInRegion(dual, 'oldWorld', 'p1', 'p2'), isTrue);
      expect(isValidLandMove(dual, 'p1', 'p2'), isFalse);
    });

    test('prefixed node ids resolve neighbors via local province id', () {
      final prefixed = topologyFromGraph(
        nodes: [
          TopologyNode(
            id: 'oldWorld|p1',
            regionId: 'oldWorld',
            type: TopologyNodeType.province,
          ),
          TopologyNode(
            id: 'oldWorld|p2',
            regionId: 'oldWorld',
            type: TopologyNodeType.province,
          ),
        ],
        edges: [TopologyEdge(id1: 'oldWorld|p1', id2: 'oldWorld|p2')],
      );
      expect(neighborProvinceIdsInRegion(prefixed, 'oldWorld', 'p1').toList(), [
        'p2',
      ]);
      expect(neighborProvinceIdsInRegion(prefixed, 'oldWorld', 'p2').toList(), [
        'p1',
      ]);
    });
  });

  group('isValidLandMove', () {
    final topology = threeProvincePartialChainTopology(regionId: 'oldWorld');

    test('accepts adjacent provinces resolved through a single node', () {
      expect(isValidLandMove(topology, 'p1', 'p2'), isTrue);
    });

    test('rejects identical from/to', () {
      expect(isValidLandMove(topology, 'p1', 'p1'), isFalse);
    });

    test('rejects when the from-province has no resolvable node', () {
      expect(isValidLandMove(topology, 'ghost', 'p2'), isFalse);
    });

    test('rejects a move onto an adjacent sea zone', () {
      final withSea = topologyFromGraph(
        nodes: [
          TopologyNode(
            id: 'A',
            regionId: 'oldWorld',
            type: TopologyNodeType.province,
          ),
          TopologyNode(
            id: 'Sea1',
            regionId: 'oldWorld',
            type: TopologyNodeType.seaZone,
          ),
        ],
        edges: [TopologyEdge(id1: 'A', id2: 'Sea1')],
      );
      expect(isValidLandMove(withSea, 'A', 'Sea1'), isFalse);
      expect(isValidLandMove(withSea, 'A', 'B'), isFalse);
    });
  });

  registerMovementHelpersApplyCases();
}
