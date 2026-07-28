import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_orders/src/orders/connectivity_dev_snapshot.dart';
import 'package:colonizethis_orders/src/orders/connectivity_dev_targets.dart';
import 'package:colonizethis_orders/src/orders/feedstock_extraction_targets.dart';
import 'package:colonizethis_orders/src/orders/order_work_constants.dart';
import 'package:colonizethis_test/test.dart';

import 'support/suggestion/order_suggestion_work_feedstock_priority_fixtures.dart';

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

  group('applyBuildImprovementConnectivityPreservingFeedstock', () {
    test('AC-C3 feedstock tile precedes connected non-feedstock tile', () {
      final game = feedstockPriorityGame();
      expect(
        feedstockExtractionResourceIdsForPlayer(
          game,
          feedstockPrioritySupplierId,
        ),
        contains('iron'),
      );
      final snapshot = _snapshot(
        connected: {feedstockPrioritySupplierGrainTile},
        adjacent: const {},
      );
      final ordered = applyBuildImprovementConnectivityPreservingFeedstock(
        game: game,
        playerId: feedstockPrioritySupplierId,
        sortedVisible: [
          feedstockPrioritySupplierGrainTile,
          feedstockPrioritySupplierIronTile,
        ],
        snapshot: snapshot,
      );
      expect(ordered.first, feedstockPrioritySupplierIronTile);
    });
  });

  group('prioritizeBuildRailCandidatesByConnectivity', () {
    test('AC-B1 bottleneck promotion', () {
      final snapshot = _snapshot(
        connected: {'bottleneck', 'plain'},
        bottleneck: {'bottleneck'},
      );
      final ordered = prioritizeBuildRailCandidatesByConnectivity(
        snapshot: snapshot,
        sortedVisible: ['plain', 'bottleneck'],
      );
      expect(ordered.first, 'bottleneck');
    });

    test('AC-B2 no-yield-gain demotion', () {
      final snapshot = _snapshot(
        connected: {'bottleneck', 'satisfied'},
        bottleneck: {'bottleneck'},
      );
      final ordered = prioritizeBuildRailCandidatesByConnectivity(
        snapshot: snapshot,
        sortedVisible: ['satisfied', 'bottleneck'],
      );
      expect(ordered.first, 'bottleneck');
    });
  });

  group('prioritizeBuildPortCandidatesByConnectivity', () {
    test('AC-D1 overseas resource province promotion', () {
      const ow = 'oldWorld';
      const provinceId = '$ow|nw1';
      const linkedPort = '$provinceId|0|0';
      const plainPort = 'oldWorld|ow1|0|0';
      final snapshot = ConnectivityDevSnapshot(
        connected: const {},
        pathTransportCap: const {},
        extensionDistanceByTile: const {},
        seaZonesReachableFromCapital: {'$ow|sea1'},
        provincesWithUnconnectedDevTargets: {provinceId},
        hasUnconnectedDevTargets: true,
        frontierExtensionTiles: const {},
        bottleneckRailTiles: const {},
        adjacentToConnectedTiles: const {},
      );
      final game = Game(
        id: 'g',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(
            provinces: [
              Province(id: 'oldWorld|ow1', regionId: ow, ownerId: 'gp1'),
              Province(id: provinceId, regionId: ow, ownerId: 'gp1'),
            ],
          ),
          newWorld: const RegionData(),
        ),
        players: [
          Player(
            id: 'gp1',
            displayName: 'GP',
            isHuman: false,
            capitalProvinceId: 'oldWorld|ow1',
            capitalTile: CapitalTile(
              regionId: ow,
              provinceId: 'oldWorld|ow1',
              x: 0,
              y: 0,
            ),
          ),
        ],
      );
      const topology = MapTopology(
        nodes: [
          TopologyNode(
            id: 'oldWorld|ow1',
            regionId: ow,
            type: TopologyNodeType.province,
          ),
          TopologyNode(
            id: provinceId,
            regionId: ow,
            type: TopologyNodeType.province,
          ),
          TopologyNode(
            id: '$ow|sea1',
            regionId: ow,
            type: TopologyNodeType.seaZone,
          ),
        ],
        edges: [
          TopologyEdge(
            id1: 'oldWorld|ow1',
            id2: '$ow|sea1',
          ),
          TopologyEdge(
            id1: provinceId,
            id2: '$ow|sea1',
          ),
        ],
      );
      final ordered = prioritizeBuildPortCandidatesByConnectivity(
        snapshot: snapshot,
        sortedVisible: [plainPort, linkedPort],
        game: game,
        topology: topology,
      );
      expect(ordered.first, linkedPort);
    });

    test('AC-D2 sea-unreachable demotion', () {
      const ow = 'oldWorld';
      const reachableProvince = '$ow|nwReach';
      const unreachableProvince = '$ow|nwBlock';
      const reachablePort = '$reachableProvince|0|0';
      const unreachablePort = '$unreachableProvince|0|0';
      final snapshot = ConnectivityDevSnapshot(
        connected: const {},
        pathTransportCap: const {},
        extensionDistanceByTile: const {},
        seaZonesReachableFromCapital: {'$ow|seaReach'},
        provincesWithUnconnectedDevTargets: {
          reachableProvince,
          unreachableProvince,
        },
        hasUnconnectedDevTargets: true,
        frontierExtensionTiles: const {},
        bottleneckRailTiles: const {},
        adjacentToConnectedTiles: const {},
      );
      final game = Game(
        id: 'g',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(
            provinces: [
              Province(
                id: 'oldWorld|ow1',
                regionId: ow,
                ownerId: 'gp1',
              ),
              Province(id: reachableProvince, regionId: ow, ownerId: 'gp1'),
              Province(id: unreachableProvince, regionId: ow, ownerId: 'gp1'),
            ],
          ),
          newWorld: const RegionData(),
        ),
        players: [
          Player(
            id: 'gp1',
            displayName: 'GP',
            isHuman: false,
            capitalProvinceId: 'oldWorld|ow1',
            capitalTile: CapitalTile(
              regionId: ow,
              provinceId: 'oldWorld|ow1',
              x: 0,
              y: 0,
            ),
          ),
        ],
      );
      const topology = MapTopology(
        nodes: [
          TopologyNode(
            id: 'oldWorld|ow1',
            regionId: ow,
            type: TopologyNodeType.province,
          ),
          TopologyNode(
            id: reachableProvince,
            regionId: ow,
            type: TopologyNodeType.province,
          ),
          TopologyNode(
            id: unreachableProvince,
            regionId: ow,
            type: TopologyNodeType.province,
          ),
          TopologyNode(
            id: '$ow|seaReach',
            regionId: ow,
            type: TopologyNodeType.seaZone,
          ),
          TopologyNode(
            id: '$ow|seaBlock',
            regionId: ow,
            type: TopologyNodeType.seaZone,
          ),
        ],
        edges: [
          TopologyEdge(id1: 'oldWorld|ow1', id2: '$ow|seaReach'),
          TopologyEdge(id1: reachableProvince, id2: '$ow|seaReach'),
          TopologyEdge(id1: unreachableProvince, id2: '$ow|seaBlock'),
        ],
      );
      final ordered = prioritizeBuildPortCandidatesByConnectivity(
        snapshot: snapshot,
        sortedVisible: [unreachablePort, reachablePort],
        game: game,
        topology: topology,
      );
      expect(ordered.first, reachablePort);
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
