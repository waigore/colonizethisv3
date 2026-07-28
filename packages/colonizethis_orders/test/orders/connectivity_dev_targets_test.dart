import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_orders/src/orders/connectivity_dev_snapshot.dart';
import 'package:colonizethis_orders/src/orders/connectivity_dev_targets.dart';
import 'package:colonizethis_orders/src/orders/order_work_constants.dart';
import 'package:test/test.dart';

ConnectivityDevSnapshot _snapshot({
  Set<String> connected = const {},
  Set<String> frontier = const {},
  Set<String> adjacent = const {},
  Set<String> bottleneck = const {},
  Map<String, int> extensionDistance = const {},
  bool hasTargets = true,
}) {
  return ConnectivityDevSnapshot(
    connected: connected,
    pathTransportCap: const {},
    extensionDistanceByTile: extensionDistance,
    seaZonesReachableFromCapital: const {},
    provincesWithUnconnectedDevTargets: const {},
    hasUnconnectedDevTargets: hasTargets,
    frontierExtensionTiles: frontier,
    bottleneckRailTiles: bottleneck,
    adjacentToConnectedTiles: adjacent,
  );
}

void main() {
  group('prioritizeBuildRoadCandidatesByConnectivity', () {
    test('AC-A2 frontier hard demotion', () {
      final snapshot = _snapshot(
        frontier: {'oldWorld|p1|0|1'},
        extensionDistance: {'oldWorld|p1|0|1': 2},
      );
      final ordered = prioritizeBuildRoadCandidatesByConnectivity(
        snapshot: snapshot,
        sortedVisible: ['oldWorld|p1|9|9', 'oldWorld|p1|0|1'],
      );
      expect(ordered.first, 'oldWorld|p1|0|1');
    });

    test('AC-A3 nearest-target-first within frontier', () {
      final snapshot = _snapshot(
        frontier: {'oldWorld|p1|0|1', 'oldWorld|p1|0|3'},
        extensionDistance: {'oldWorld|p1|0|1': 1, 'oldWorld|p1|0|3': 3},
      );
      final ordered = prioritizeBuildRoadCandidatesByConnectivity(
        snapshot: snapshot,
        sortedVisible: ['oldWorld|p1|0|3', 'oldWorld|p1|0|1'],
      );
      expect(ordered, ['oldWorld|p1|0|1', 'oldWorld|p1|0|3']);
    });

    test('AC-A4 baseline when no unconnected targets', () {
      final snapshot = _snapshot(hasTargets: false);
      const input = ['oldWorld|p1|9|9', 'oldWorld|p1|0|1'];
      expect(
        prioritizeBuildRoadCandidatesByConnectivity(
          snapshot: snapshot,
          sortedVisible: input,
        ),
        input,
      );
    });
  });

  group('prioritizeBuildImprovementCandidatesByConnectivity', () {
    test('AC-C1 connected > adjacent > far', () {
      final snapshot = _snapshot(
        connected: {'c'},
        adjacent: {'a'},
      );
      final ordered = prioritizeBuildImprovementCandidatesByConnectivity(
        snapshot: snapshot,
        sortedVisible: ['f', 'a', 'c'],
      );
      expect(ordered, ['c', 'a', 'f']);
    });
  });

  group('stablePartitionByConnectivityTier', () {
    test('preserves relative order within tier', () {
      final ordered = stablePartitionByConnectivityTier(
        ['b2', 'a2', 'b1', 'a1'],
        (k) => k.endsWith('1') ? 0 : 1,
      );
      expect(ordered, ['b1', 'a1', 'b2', 'a2']);
    });
  });

  group('applyConnectivityDevTargetOrdering', () {
    test('unknown target unchanged', () {
      final snapshot = _snapshot();
      const input = ['t1', 't2'];
      expect(
        applyConnectivityDevTargetOrdering(
          workTarget: kWorkTargetExplore,
          sortedVisible: input,
          snapshot: snapshot,
          game: Game(
            id: 'g',
            worldState: WorldState(
              turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
              oldWorld: const RegionData(),
              newWorld: const RegionData(),
            ),
            players: const [],
          ),
          topology: const MapTopology(nodes: [], edges: []),
          tileMapByRegion: const {},
        ),
        input,
      );
    });
  });
}
