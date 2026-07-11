// Simple-AI validator-reuse fixtures (Refs #2394, #3949 wave 3, #3971 wave 4).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../common/game_graphs.dart';

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
  final game = ordersTwoProvinceOwnedGame(
    id: 'g_simple_ai_validator_reuse',
    p1Local: 'P1',
    p2Local: 'P2',
    players: const [
      Player(id: 'gp1', displayName: 'AI1', isHuman: false),
      Player(id: 'gp2', displayName: 'AI2', isHuman: false),
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
    includeDefaultDiplomacy: true,
    state: RelationState.atWar,
  );
  return game.copyWith(
    globalGameSeed: 0,
    aiSeedByGpId: const {'gp1': 11, 'gp2': 22},
  );
}
