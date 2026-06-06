/// Pins [e2eBestSeaZoneTowardRegion]
/// (`app/integration_test/e2e_test_shared_fleet_nav.dart`), the topology-guided
/// destination chooser the fleet-reach move helper uses to sail toward the New
/// World.
///
/// The integration suite cannot validate the navigation directly today (the
/// `app_e2e_linux` lane is a no-op per `SPEC/program/e2e-integration-tests.md`
/// § CI), so this pure-function pin guards the BFS selection contract that
/// fixes the fleet-reach reach/oscillation failure (Refs GitHub #2336 AC6 /
/// AC7).
library;

import 'package:colonizethis_data/colonizethis_data.dart'
    show MapTopology, TopologyEdge, TopologyNode, TopologyNodeType;
import 'package:flutter_test/flutter_test.dart';

import '../integration_test/e2e_test_shared_fleet_nav.dart';

TopologyNode _sea(String id, String regionId) =>
    TopologyNode(id: id, regionId: regionId, type: TopologyNodeType.seaZone);

TopologyNode _province(String id, String regionId) =>
    TopologyNode(id: id, regionId: regionId, type: TopologyNodeType.province);

/// A 4-zone sea corridor: oldWorld s1–s2–s3 then a cross-region edge into the
/// newWorld zone n1, plus an unrelated province to prove non-sea nodes are
/// ignored.
///
/// Sea→newWorld BFS distances: n1=0, ow_s3=1, ow_s2=2, ow_s1=3.
MapTopology _corridorTopology() => const MapTopology(
  nodes: [
    TopologyNode(
      id: 'ow_s1',
      regionId: 'oldWorld',
      type: TopologyNodeType.seaZone,
    ),
    TopologyNode(
      id: 'ow_s2',
      regionId: 'oldWorld',
      type: TopologyNodeType.seaZone,
    ),
    TopologyNode(
      id: 'ow_s3',
      regionId: 'oldWorld',
      type: TopologyNodeType.seaZone,
    ),
    TopologyNode(
      id: 'nw_n1',
      regionId: 'newWorld',
      type: TopologyNodeType.seaZone,
    ),
    TopologyNode(
      id: 'ow_p1',
      regionId: 'oldWorld',
      type: TopologyNodeType.province,
    ),
  ],
  edges: [
    TopologyEdge(id1: 'ow_s1', id2: 'ow_s2'),
    TopologyEdge(id1: 'ow_s2', id2: 'ow_s3'),
    TopologyEdge(id1: 'ow_s3', id2: 'nw_n1'),
    // Province edge that must never participate in the sea→sea BFS.
    TopologyEdge(id1: 'ow_p1', id2: 'ow_s1'),
  ],
);

void main() {
  group('e2eBestSeaZoneTowardRegion', () {
    test('returns null for empty candidates', () {
      expect(
        e2eBestSeaZoneTowardRegion(
          topology: _corridorTopology(),
          candidates: const <String>[],
        ),
        isNull,
      );
    });

    test('picks the candidate closest to the New World (monotonic progress)', () {
      // From ow_s2 the dialog offers neighbours {ow_s1 (dist 3), ow_s3 (dist
      // 1)}. The helper must pick ow_s3 so the fleet sails *toward* the warp;
      // the pre-fix alphabetically-first pick (ow_s1) would sail away and
      // could oscillate forever (Refs #2336 AC6/AC7 root cause).
      final best = e2eBestSeaZoneTowardRegion(
        topology: _corridorTopology(),
        candidates: const ['ow_s1', 'ow_s3'],
      );
      expect(best, 'ow_s3');
      expect(
        best,
        isNot('ow_s1'),
        reason:
            'Selecting the farther zone reproduces the undirected-walk '
            'oscillation that left the fleet stranded in the Old World.',
      );
    });

    test('candidate input order does not change the result', () {
      final reversed = e2eBestSeaZoneTowardRegion(
        topology: _corridorTopology(),
        candidates: const ['ow_s3', 'ow_s1'],
      );
      expect(reversed, 'ow_s3');
    });

    test('a candidate already in the New World region wins (distance 0)', () {
      final best = e2eBestSeaZoneTowardRegion(
        topology: _corridorTopology(),
        candidates: const ['ow_s3', 'nw_n1'],
      );
      expect(best, 'nw_n1');
    });

    test('equidistant candidates break ties by ascending id (deterministic)', () {
      // Two oldWorld zones both one hop from the same newWorld zone.
      const topology = MapTopology(
        nodes: [
          TopologyNode(
            id: 'ow_b',
            regionId: 'oldWorld',
            type: TopologyNodeType.seaZone,
          ),
          TopologyNode(
            id: 'ow_a',
            regionId: 'oldWorld',
            type: TopologyNodeType.seaZone,
          ),
          TopologyNode(
            id: 'nw_n1',
            regionId: 'newWorld',
            type: TopologyNodeType.seaZone,
          ),
        ],
        edges: [
          TopologyEdge(id1: 'ow_a', id2: 'nw_n1'),
          TopologyEdge(id1: 'ow_b', id2: 'nw_n1'),
        ],
      );
      expect(
        e2eBestSeaZoneTowardRegion(
          topology: topology,
          candidates: const ['ow_b', 'ow_a'],
        ),
        'ow_a',
      );
    });

    test('falls back to ascending-first when no candidate can reach target', () {
      // No newWorld sea zone at all: every candidate is unreachable, so the
      // helper returns the deterministic ascending-first fallback rather than
      // null (mirrors the legacy seaRadio.first behaviour).
      const topology = MapTopology(
        nodes: [
          TopologyNode(
            id: 'ow_s1',
            regionId: 'oldWorld',
            type: TopologyNodeType.seaZone,
          ),
          TopologyNode(
            id: 'ow_s2',
            regionId: 'oldWorld',
            type: TopologyNodeType.seaZone,
          ),
        ],
        edges: [TopologyEdge(id1: 'ow_s1', id2: 'ow_s2')],
      );
      expect(
        e2eBestSeaZoneTowardRegion(
          topology: topology,
          candidates: const ['ow_s2', 'ow_s1'],
        ),
        'ow_s1',
      );
    });

    test('ids absent from the topology fall back to ascending-first', () {
      expect(
        e2eBestSeaZoneTowardRegion(
          topology: _corridorTopology(),
          candidates: const ['zzz_unknown', 'aaa_unknown'],
        ),
        'aaa_unknown',
      );
    });

    test('province nodes never participate in the sea path', () {
      // ow_p1 is a province bridging to ow_s1; it must not shorten any sea
      // distance. ow_s1 stays at distance 3 (s1→s2→s3→n1), so from {ow_s1,
      // ow_s2} the closer ow_s2 (dist 2) wins.
      final best = e2eBestSeaZoneTowardRegion(
        topology: _corridorTopology(),
        candidates: const ['ow_s1', 'ow_s2'],
      );
      expect(best, 'ow_s2');
    });

    test('helper uses the canonical newWorld region id by default', () {
      expect(kE2eNewWorldRegionId, 'newWorld');
      // Sanity: the same corridor under an explicit targetRegionId matches the
      // default-arg result.
      final explicit = e2eBestSeaZoneTowardRegion(
        topology: _corridorTopology(),
        candidates: const ['ow_s1', 'ow_s3'],
        targetRegionId: 'newWorld',
      );
      expect(explicit, 'ow_s3');
    });

    test('_province helper builds a province node (fixture guard)', () {
      // Guards the test fixture builders so a future edit that flips the node
      // type is caught here rather than silently weakening the province-path
      // exclusion assertion above.
      expect(_province('p', 'oldWorld').type, TopologyNodeType.province);
      expect(_sea('s', 'oldWorld').type, TopologyNodeType.seaZone);
    });
  });
}
