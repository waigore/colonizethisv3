import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_world/colonizethis_world.dart';

Game distantSeaVisibilityGame({
  List<Province> oldWorldProvinces = const [],
  List<Province> newWorldProvinces = const [],
  required Map<String, Map<String, List<String>>> tileKeysByRegionAndProvince,
  required List<Player> players,
  List<Fleet> fleets = const [],
  Map<String, Map<String, String>> playerVisibilityByTile = const {},
  int turnNumber = 0,
  String id = 'g1',
}) {
  return Game(
    id: id,
    worldState: WorldState(
      turnState: TurnState(phase: TurnPhase.endOfTurn, turnNumber: turnNumber),
      oldWorld: RegionData(provinces: oldWorldProvinces),
      newWorld: RegionData(provinces: newWorldProvinces),
      tileKeysByRegionAndProvince: tileKeysByRegionAndProvince,
      fleets: fleets,
      playerVisibilityByTile: playerVisibilityByTile,
    ),
    players: players,
  );
}

MapTopology provinceSeaZoneTopology({
  required String regionId,
  required String provinceLocalId,
  required String seaZoneId,
}) {
  return MapTopology(
    nodes: [
      TopologyNode(
        id: provinceLocalId,
        regionId: regionId,
        type: TopologyNodeType.province,
      ),
      TopologyNode(
        id: seaZoneId,
        regionId: regionId,
        type: TopologyNodeType.seaZone,
      ),
    ],
    edges: [TopologyEdge(id1: seaZoneId, id2: provinceLocalId)],
  );
}

MapTopology provinceSeaChainTopology(String regionId) {
  return MapTopology(
    nodes: [
      TopologyNode(
        id: 'p1',
        regionId: regionId,
        type: TopologyNodeType.province,
      ),
      TopologyNode(
        id: 's1',
        regionId: regionId,
        type: TopologyNodeType.seaZone,
      ),
      TopologyNode(
        id: 's2',
        regionId: regionId,
        type: TopologyNodeType.seaZone,
      ),
    ],
    edges: const [
      TopologyEdge(id1: 'p1', id2: 's1'),
      TopologyEdge(id1: 's1', id2: 's2'),
    ],
  );
}

MapTopology dualRegionLandOnlyTopology() {
  return const MapTopology(
    nodes: [
      TopologyNode(
        id: 'p1',
        regionId: kRegionOldWorld,
        type: TopologyNodeType.province,
      ),
      TopologyNode(
        id: 'P2',
        regionId: kRegionNewWorld,
        type: TopologyNodeType.province,
      ),
    ],
  );
}

({MapTopology combined, MapTopology ow, MapTopology nw})
owSeaChainWithIsolatedNwSea() {
  final ow = provinceSeaChainTopology(kRegionOldWorld);
  const nw = MapTopology(
    nodes: [
      TopologyNode(
        id: 'nwSea',
        regionId: kRegionNewWorld,
        type: TopologyNodeType.seaZone,
      ),
    ],
  );
  return (
    combined: MapTopology(
      nodes: [...ow.nodes, ...nw.nodes],
      edges: [...ow.edges, ...nw.edges],
    ),
    ow: ow,
    nw: nw,
  );
}
