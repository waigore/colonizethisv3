// Shared army-move heuristics suggestion fixtures (Refs #3949 / #3971).

import 'package:colonizethis_ai_contracts/colonizethis_ai_contracts.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../common/game_graphs.dart';

const armyMoveHeuristicsGp = 'gp_ai';
const armyMoveHeuristicsCap = 'oldWorld|cap';
const armyMoveHeuristicsP1 = 'oldWorld|p1';
const armyMoveHeuristicsNw = 'newWorld|col';

// dart format off
final armyMoveHeuristicsTopology = const MapTopology(
  nodes: [
    TopologyNode(id: 'oldWorld|cap', regionId: 'oldWorld', type: TopologyNodeType.province),
    TopologyNode(id: 'oldWorld|p1', regionId: 'oldWorld', type: TopologyNodeType.province),
    TopologyNode(id: 'newWorld|col', regionId: 'newWorld', type: TopologyNodeType.province),
  ],
  edges: [],
);
// dart format on

Game armyMoveHeuristicsGame() => ordersOwRegionGame(
  id: 'g_heur',
  turnNumber: 1,
  players: const [
    Player(
      id: armyMoveHeuristicsGp,
      displayName: 'AI',
      isHuman: false,
      capitalProvinceId: armyMoveHeuristicsCap,
    ),
  ],
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
  playerVisibilityByTile: const {
    armyMoveHeuristicsGp: {
      'oldWorld|cap|0|0': 'fullyVisible',
      'oldWorld|p1|0|0': 'fullyVisible',
      'newWorld|col|0|0': 'fullyVisible',
    },
  },
  tileKeysByRegionAndProvince: const {
    'oldWorld': {
      armyMoveHeuristicsCap: ['oldWorld|cap|0|0'],
      armyMoveHeuristicsP1: ['oldWorld|p1|0|0'],
    },
    'newWorld': {
      armyMoveHeuristicsNw: ['newWorld|col|0|0'],
    },
  },
).copyWith(globalGameSeed: 1, aiSeedByGpId: const {armyMoveHeuristicsGp: 42});

Orders armyMoveHeuristicsOrders() {
  final game = armyMoveHeuristicsGame();
  return generateOrdersWithSimpleHeuristics(
    game,
    armyMoveHeuristicsTopology,
    armyMoveHeuristicsGp,
    turnSeedForPlayer(game, armyMoveHeuristicsGp, 1),
  );
}
