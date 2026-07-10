// Simple-AI validator-reuse fixtures (Refs #2394, #3949 wave 3).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

const simpleAiValidatorReuseTopology = MapTopology(
  nodes: [
    TopologyNode(
      id: 'P1',
      regionId: 'oldWorld',
      type: TopologyNodeType.province,
    ),
    TopologyNode(
      id: 'P2',
      regionId: 'oldWorld',
      type: TopologyNodeType.province,
    ),
  ],
  edges: [TopologyEdge(id1: 'P1', id2: 'P2')],
);

Game simpleAiValidatorReuseTwoGpWarGame() {
  return Game(
    id: 'g_simple_ai_validator_reuse',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
      oldWorld: RegionData(
        provinces: const [
          Province(id: 'oldWorld|P1', regionId: 'oldWorld', ownerId: 'gp1'),
          Province(id: 'oldWorld|P2', regionId: 'oldWorld', ownerId: 'gp2'),
        ],
        units: [
          Unit(
            id: 'u1',
            type: 'grenadiers',
            ownerId: 'gp1',
            locationProvinceId: 'oldWorld|P1',
          ),
          Unit(
            id: 'u2',
            type: 'grenadiers',
            ownerId: 'gp2',
            locationProvinceId: 'oldWorld|P2',
          ),
        ],
      ),
      newWorld: const RegionData(),
      playerVisibilityByTile: const {
        'gp1': {
          'oldWorld|P1|0|0': 'fullyVisible',
          'oldWorld|P2|0|0': 'fullyVisible',
        },
        'gp2': {
          'oldWorld|P1|0|0': 'fullyVisible',
          'oldWorld|P2|0|0': 'fullyVisible',
        },
      },
    ),
    players: const [
      Player(id: 'gp1', displayName: 'AI1', isHuman: false),
      Player(id: 'gp2', displayName: 'AI2', isHuman: false),
    ],
    diplomacyRelations: const [
      DiplomacyRelation(
        factionId1: 'gp1',
        factionId2: 'gp2',
        state: RelationState.atWar,
      ),
    ],
    globalGameSeed: 0,
    aiSeedByGpId: {'gp1': 11, 'gp2': 22},
  );
}
