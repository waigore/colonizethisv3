// Shared fixtures for naval_behavior_scenarios_test (Refs #4342 Slice C).
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

Game navalBehaviorBaseGame({
  required List<Fleet> fleets,
  required List<DiplomacyRelation> relations,
  int globalGameSeed = 42,
}) {
  return Game(
    id: 'g_naval',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
      oldWorld: const RegionData(),
      newWorld: const RegionData(),
      fleets: fleets,
    ),
    players: const [
      Player(id: 'p1', displayName: 'A', isHuman: true),
      Player(id: 'p2', displayName: 'B', isHuman: true),
      Player(id: 'p3', displayName: 'C', isHuman: true),
    ],
    diplomacyRelations: relations,
    globalGameSeed: globalGameSeed,
  );
}

Fleet navalScenarioFleet({
  required String id,
  required String ownerId,
  required String seaZoneId,
  required List<String> shipTypeIds,
  required FleetMission mission,
}) => Fleet(
  id: id,
  ownerId: ownerId,
  seaZoneId: seaZoneId,
  regionId: 'oldWorld',
  shipTypeIds: shipTypeIds,
  mission: mission,
);

DiplomacyRelation navalAtWar(String a, String b) =>
    DiplomacyRelation(factionId1: a, factionId2: b, state: RelationState.atWar);

const navalSea1Topology = MapTopology(
  nodes: [
    TopologyNode(
      id: 'sea1',
      regionId: 'oldWorld',
      type: TopologyNodeType.seaZone,
    ),
  ],
  edges: [],
);

const navalSea123Topology = MapTopology(
  nodes: [
    TopologyNode(
      id: 'sea1',
      regionId: 'oldWorld',
      type: TopologyNodeType.seaZone,
    ),
    TopologyNode(
      id: 'sea2',
      regionId: 'oldWorld',
      type: TopologyNodeType.seaZone,
    ),
    TopologyNode(
      id: 'sea3',
      regionId: 'oldWorld',
      type: TopologyNodeType.seaZone,
    ),
  ],
  edges: [
    TopologyEdge(id1: 'sea1', id2: 'sea2'),
    TopologyEdge(id1: 'sea1', id2: 'sea3'),
  ],
);

const navalSea12Topology = MapTopology(
  nodes: [
    TopologyNode(
      id: 'sea1',
      regionId: 'oldWorld',
      type: TopologyNodeType.seaZone,
    ),
    TopologyNode(
      id: 'sea2',
      regionId: 'oldWorld',
      type: TopologyNodeType.seaZone,
    ),
  ],
  edges: [TopologyEdge(id1: 'sea1', id2: 'sea2')],
);
