// Shared army-move heuristics suggestion fixtures (Refs #3949 wave 3).

import 'package:colonizethis_ai_contracts/colonizethis_ai_contracts.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

const armyMoveHeuristicsGp = 'gp_ai';
const armyMoveHeuristicsCap = 'oldWorld|cap';
const armyMoveHeuristicsP1 = 'oldWorld|p1';
const armyMoveHeuristicsNw = 'newWorld|col';

final armyMoveHeuristicsTopology = MapTopology(
  nodes: const [
    TopologyNode(
      id: 'oldWorld|cap',
      regionId: 'oldWorld',
      type: TopologyNodeType.province,
    ),
    TopologyNode(
      id: 'oldWorld|p1',
      regionId: 'oldWorld',
      type: TopologyNodeType.province,
    ),
    TopologyNode(
      id: 'newWorld|col',
      regionId: 'newWorld',
      type: TopologyNodeType.province,
    ),
  ],
  edges: const [],
);

Game armyMoveHeuristicsGame() => Game(
  id: 'g_heur',
  worldState: WorldState(
    turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
    oldWorld: RegionData(
      provinces: [
        Province(
          id: armyMoveHeuristicsCap,
          regionId: 'oldWorld',
          ownerId: armyMoveHeuristicsGp,
          townTileKey: 'oldWorld|cap|0|0',
        ),
        Province(
          id: armyMoveHeuristicsP1,
          regionId: 'oldWorld',
          ownerId: armyMoveHeuristicsGp,
        ),
      ],
      units: [
        Unit(
          id: 'u1',
          type: 'musketeers',
          ownerId: armyMoveHeuristicsGp,
          locationProvinceId: armyMoveHeuristicsP1,
          tileKey: 'oldWorld|p1|0|0',
        ),
      ],
    ),
    newWorld: RegionData(
      provinces: [
        Province(
          id: armyMoveHeuristicsNw,
          regionId: 'newWorld',
          ownerId: armyMoveHeuristicsGp,
        ),
      ],
    ),
    armies: [
      Army(
        id: homeArmyIdFor(armyMoveHeuristicsGp),
        ownerId: armyMoveHeuristicsGp,
        regionId: 'oldWorld',
        stationedProvinceId: armyMoveHeuristicsCap,
        regimentUnitIds: const [],
        isHomeArmy: true,
      ),
      Army(
        id: 'field_a',
        ownerId: armyMoveHeuristicsGp,
        regionId: 'oldWorld',
        stationedProvinceId: armyMoveHeuristicsP1,
        regimentUnitIds: const ['u1'],
        isHomeArmy: false,
      ),
    ],
    playerVisibilityByTile: {
      armyMoveHeuristicsGp: {
        'oldWorld|cap|0|0': 'fullyVisible',
        'oldWorld|p1|0|0': 'fullyVisible',
        'newWorld|col|0|0': 'fullyVisible',
      },
    },
    tileKeysByRegionAndProvince: {
      'oldWorld': {
        armyMoveHeuristicsCap: ['oldWorld|cap|0|0'],
        armyMoveHeuristicsP1: ['oldWorld|p1|0|0'],
      },
      'newWorld': {
        armyMoveHeuristicsNw: ['newWorld|col|0|0'],
      },
    },
  ),
  players: [
    Player(
      id: armyMoveHeuristicsGp,
      displayName: 'AI',
      isHuman: false,
      capitalProvinceId: armyMoveHeuristicsCap,
    ),
  ],
  globalGameSeed: 1,
  aiSeedByGpId: const {armyMoveHeuristicsGp: 42},
);

Orders armyMoveHeuristicsOrders() {
  final game = armyMoveHeuristicsGame();
  return generateOrdersWithSimpleHeuristics(
    game,
    armyMoveHeuristicsTopology,
    armyMoveHeuristicsGp,
    turnSeedForPlayer(game, armyMoveHeuristicsGp, 1),
  );
}
