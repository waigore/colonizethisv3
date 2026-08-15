// Shared MAP20001 army-move overlay fixtures (Refs #4350, #4407).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

const kArmyMoveActionHumanId = 'gp1';
const kArmyMoveActionRivalId = 'gp2';
const kArmyMoveActionOwnedId = 'oldWorld|p_owned';
const kArmyMoveActionForeignId = 'oldWorld|p_foreign';
const kArmyMoveActionOtherId = 'oldWorld|p_other';

MapTopology armyMoveActionTopology() => const MapTopology(
  nodes: [
    TopologyNode(
      id: kArmyMoveActionOwnedId,
      regionId: 'oldWorld',
      type: TopologyNodeType.province,
    ),
    TopologyNode(
      id: kArmyMoveActionForeignId,
      regionId: 'oldWorld',
      type: TopologyNodeType.province,
    ),
    TopologyNode(
      id: kArmyMoveActionOtherId,
      regionId: 'oldWorld',
      type: TopologyNodeType.province,
    ),
  ],
  edges: [
    TopologyEdge(id1: kArmyMoveActionOwnedId, id2: kArmyMoveActionForeignId),
    TopologyEdge(id1: kArmyMoveActionForeignId, id2: kArmyMoveActionOtherId),
  ],
);

Game armyMoveActionGameWithArmies({
  required List<Army> armies,
  String foreignOwner = kArmyMoveActionRivalId,
}) {
  return Game(
    id: 'g_army_move_action',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
      oldWorld: RegionData(
        provinces: [
          const Province(
            id: kArmyMoveActionOwnedId,
            regionId: 'oldWorld',
            ownerId: kArmyMoveActionHumanId,
            displayName: 'Owned',
          ),
          Province(
            id: kArmyMoveActionForeignId,
            regionId: 'oldWorld',
            ownerId: foreignOwner,
            displayName: 'Foreign',
          ),
          const Province(
            id: kArmyMoveActionOtherId,
            regionId: 'oldWorld',
            ownerId: kArmyMoveActionHumanId,
            displayName: 'Other',
          ),
        ],
      ),
      newWorld: const RegionData(),
      armies: armies,
    ),
    players: const [
      Player(id: kArmyMoveActionHumanId, displayName: 'Human', isHuman: true),
      Player(id: kArmyMoveActionRivalId, displayName: 'Rival', isHuman: false),
    ],
  );
}
