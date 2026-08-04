// Connectivity dev target ordering fixtures (Refs #4246 Slice E).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_orders/src/orders/connectivity_dev_snapshot.dart';

import '../common/game_graphs.dart';

const connectivityDevOw = 'oldWorld';

const connectivityDevGp1Player = Player(
  id: 'gp1',
  displayName: 'GP',
  isHuman: false,
  capitalProvinceId: 'oldWorld|ow1',
  capitalTile: CapitalTile(
    regionId: connectivityDevOw,
    provinceId: 'oldWorld|ow1',
    x: 0,
    y: 0,
  ),
);

ConnectivityDevSnapshot connectivityDevSnapshot({
  Set<String> connected = const {},
  Set<String> frontier = const {},
  Set<String> adjacent = const {},
  Set<String> bottleneck = const {},
  Map<String, int> extensionDistance = const {},
  Set<String> seaZonesReachableFromCapital = const {},
  Set<String> provincesWithUnconnectedDevTargets = const {},
  bool hasTargets = true,
}) {
  return ConnectivityDevSnapshot(
    connected: connected,
    pathTransportCap: const {},
    extensionDistanceByTile: extensionDistance,
    seaZonesReachableFromCapital: seaZonesReachableFromCapital,
    provincesWithUnconnectedDevTargets: provincesWithUnconnectedDevTargets,
    hasUnconnectedDevTargets: hasTargets,
    frontierExtensionTiles: frontier,
    bottleneckRailTiles: bottleneck,
    adjacentToConnectedTiles: adjacent,
  );
}

/// Port prioritization scenario for overseas resource-province promotion (AC-D1).
({ConnectivityDevSnapshot snapshot, Game game, MapTopology topology, List<String> visible, String expectedFirst})
connectivityDevOverseasResourcePortCase() {
  const resourceProvince = 'oldWorld|nw1';
  const plainPort = 'oldWorld|ow1|0|0';
  const linkedPort = '$resourceProvince|0|0';
  return (
    snapshot: connectivityDevSnapshot(
      seaZonesReachableFromCapital: {'$connectivityDevOw|sea1'},
      provincesWithUnconnectedDevTargets: {resourceProvince},
    ),
    game: ordersOwRegionGame(
      players: const [connectivityDevGp1Player],
      oldWorld: RegionData(
        provinces: [
          ordersProvince(localId: 'ow1', ownerId: 'gp1'),
          ordersProvince(localId: 'nw1', ownerId: 'gp1'),
        ],
      ),
    ),
    topology: const MapTopology(
      nodes: [
        TopologyNode(id: 'oldWorld|ow1', regionId: connectivityDevOw, type: TopologyNodeType.province),
        TopologyNode(id: resourceProvince, regionId: connectivityDevOw, type: TopologyNodeType.province),
        TopologyNode(id: '$connectivityDevOw|sea1', regionId: connectivityDevOw, type: TopologyNodeType.seaZone),
      ],
      edges: [
        TopologyEdge(id1: 'oldWorld|ow1', id2: '$connectivityDevOw|sea1'),
        TopologyEdge(id1: resourceProvince, id2: '$connectivityDevOw|sea1'),
      ],
    ),
    visible: [plainPort, linkedPort],
    expectedFirst: linkedPort,
  );
}

/// Port prioritization scenario for sea-unreachable demotion (AC-D2).
({ConnectivityDevSnapshot snapshot, Game game, MapTopology topology, List<String> visible, String expectedFirst})
connectivityDevSeaUnreachablePortCase() {
  const reachableProvince = '$connectivityDevOw|nwReach';
  const unreachableProvince = '$connectivityDevOw|nwBlock';
  const reachablePort = '$reachableProvince|0|0';
  const unreachablePort = '$unreachableProvince|0|0';
  return (
    snapshot: connectivityDevSnapshot(
      seaZonesReachableFromCapital: {'$connectivityDevOw|seaReach'},
      provincesWithUnconnectedDevTargets: {reachableProvince, unreachableProvince},
    ),
    game: ordersOwRegionGame(
      players: const [connectivityDevGp1Player],
      oldWorld: RegionData(
        provinces: [
          ordersProvince(localId: 'ow1', ownerId: 'gp1'),
          ordersProvince(localId: 'nwReach', ownerId: 'gp1'),
          ordersProvince(localId: 'nwBlock', ownerId: 'gp1'),
        ],
      ),
    ),
    topology: const MapTopology(
      nodes: [
        TopologyNode(id: 'oldWorld|ow1', regionId: connectivityDevOw, type: TopologyNodeType.province),
        TopologyNode(id: reachableProvince, regionId: connectivityDevOw, type: TopologyNodeType.province),
        TopologyNode(id: unreachableProvince, regionId: connectivityDevOw, type: TopologyNodeType.province),
        TopologyNode(id: '$connectivityDevOw|seaReach', regionId: connectivityDevOw, type: TopologyNodeType.seaZone),
        TopologyNode(id: '$connectivityDevOw|seaBlock', regionId: connectivityDevOw, type: TopologyNodeType.seaZone),
      ],
      edges: [
        TopologyEdge(id1: 'oldWorld|ow1', id2: '$connectivityDevOw|seaReach'),
        TopologyEdge(id1: reachableProvince, id2: '$connectivityDevOw|seaReach'),
        TopologyEdge(id1: unreachableProvince, id2: '$connectivityDevOw|seaBlock'),
      ],
    ),
    visible: [unreachablePort, reachablePort],
    expectedFirst: reachablePort,
  );
}

Game connectivityDevEmptyGame() => ordersOwRegionGame(
  id: 'g',
  turnNumber: 1,
  players: const [],
  oldWorld: const RegionData(),
);
