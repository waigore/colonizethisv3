import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

/// Standard carrack [Fleet] for naval integration scenarios.
Fleet turnTestCarrackFleet({
  String id = 'f1',
  String ownerId = 'p1',
  String? seaZoneId = 'sea1',
  String? inPortAtProvinceId,
  String regionId = kRegionOldWorld,
  FleetMission mission = FleetMission.none,
  List<String> shipTypeIds = const ['carrack'],
}) {
  return Fleet(
    id: id,
    ownerId: ownerId,
    seaZoneId: seaZoneId,
    inPortAtProvinceId: inPortAtProvinceId,
    regionId: regionId,
    shipTypeIds: shipTypeIds,
    mission: mission,
  );
}

/// OW sea zone plus one province; optionally linked by a topology edge.
MapTopology turnTestOwSeaProvinceTopology({
  String seaZoneId = 'sea1',
  String provinceLocalId = 'P1',
  bool linkSeaToProvince = true,
}) {
  return MapTopology(
    nodes: [
      TopologyNode(
        id: seaZoneId,
        regionId: kRegionOldWorld,
        type: TopologyNodeType.seaZone,
      ),
      TopologyNode(
        id: provinceLocalId,
        regionId: kRegionOldWorld,
        type: TopologyNodeType.province,
      ),
    ],
    edges: linkSeaToProvince
        ? [TopologyEdge(id1: seaZoneId, id2: provinceLocalId)]
        : const <TopologyEdge>[],
  );
}

/// OW sea zone only (no provinces).
MapTopology turnTestOwSeaZoneTopology({String seaZoneId = 'sea1'}) {
  return MapTopology(
    nodes: [
      TopologyNode(
        id: seaZoneId,
        regionId: kRegionOldWorld,
        type: TopologyNodeType.seaZone,
      ),
    ],
    edges: const [],
  );
}

/// Two linked OW sea zones (default `sea1`–`sea2`).
MapTopology turnTestOwTwoLinkedSeaZonesTopology({
  String seaZone1 = 'sea1',
  String seaZone2 = 'sea2',
}) {
  return MapTopology(
    nodes: [
      TopologyNode(
        id: seaZone1,
        regionId: kRegionOldWorld,
        type: TopologyNodeType.seaZone,
      ),
      TopologyNode(
        id: seaZone2,
        regionId: kRegionOldWorld,
        type: TopologyNodeType.seaZone,
      ),
    ],
    edges: [TopologyEdge(id1: seaZone1, id2: seaZone2)],
  );
}

/// [Game] with fleets only (empty province data).
Game turnTestFleetsOnlyGame({
  required List<Fleet> fleets,
  List<Player>? players,
}) {
  return Game(
    id: 'g1',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
      oldWorld: const RegionData(),
      newWorld: const RegionData(),
      fleets: fleets,
    ),
    players:
        players ?? const [Player(id: 'p1', displayName: 'A', isHuman: true)],
  );
}
