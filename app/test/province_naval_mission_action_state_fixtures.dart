// Fixtures for MAP20001 Naval Blockade/Beachhead action-state pins (Refs #4413).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

const human = 'gp1';
const rival = 'gp2';
const foreign = 'oldWorld|p_foreign';
const owned = 'oldWorld|p_owned';
const inland = 'oldWorld|p_inland';
const wild = 'oldWorld|p_wild';
const sea = 'sea1';

MapTopology coastalTopology() => const MapTopology(
  nodes: [
    TopologyNode(
      id: foreign,
      regionId: 'oldWorld',
      type: TopologyNodeType.province,
    ),
    TopologyNode(
      id: owned,
      regionId: 'oldWorld',
      type: TopologyNodeType.province,
    ),
    TopologyNode(
      id: inland,
      regionId: 'oldWorld',
      type: TopologyNodeType.province,
    ),
    TopologyNode(
      id: wild,
      regionId: 'oldWorld',
      type: TopologyNodeType.province,
    ),
    TopologyNode(id: sea, regionId: 'oldWorld', type: TopologyNodeType.seaZone),
  ],
  edges: [
    TopologyEdge(id1: sea, id2: foreign),
    TopologyEdge(id1: sea, id2: wild),
    TopologyEdge(id1: owned, id2: inland),
  ],
);

Game gameWith({
  required List<Fleet> fleets,
  String foreignOwner = rival,
  RelationState relation = RelationState.atWar,
}) {
  return Game(
    id: 'g_naval_overlay',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
      oldWorld: RegionData(
        provinces: [
          const Province(
            id: owned,
            regionId: 'oldWorld',
            ownerId: human,
            displayName: 'Owned',
          ),
          Province(
            id: foreign,
            regionId: 'oldWorld',
            ownerId: foreignOwner,
            displayName: 'Foreign',
          ),
          const Province(
            id: inland,
            regionId: 'oldWorld',
            ownerId: rival,
            displayName: 'Inland',
          ),
          const Province(id: wild, regionId: 'oldWorld', displayName: 'Wild'),
        ],
      ),
      newWorld: const RegionData(),
      fleets: fleets,
    ),
    players: const [
      Player(id: human, displayName: 'Human', isHuman: true),
      Player(id: rival, displayName: 'Rival', isHuman: false),
    ],
    diplomacyRelations: [
      DiplomacyRelation(factionId1: human, factionId2: rival, state: relation),
    ],
  );
}

Fleet atSeaFleet({String id = 'f_sea', String seaZoneId = sea}) => Fleet(
  id: id,
  ownerId: human,
  seaZoneId: seaZoneId,
  regionId: 'oldWorld',
  shipTypeIds: const ['carrack'],
);
