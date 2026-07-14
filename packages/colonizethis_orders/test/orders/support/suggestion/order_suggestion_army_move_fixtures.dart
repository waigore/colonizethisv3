// Shared army-move suggestion fixtures (Refs #3949 / #3971 wave 4).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../common/game_graphs.dart';

const armyMoveGp = 'gp1';
const armyMoveCap = 'oldWorld|cap';
const armyMoveP1 = 'oldWorld|p1';
const armyMoveP2 = 'oldWorld|p2';
const armyMoveNw = 'newWorld|col';

const _armyMovePlayer = Player(
  id: armyMoveGp,
  displayName: 'T',
  isHuman: true,
  capitalProvinceId: armyMoveCap,
);

// dart format off
Province _armyMoveCap() => Province(id: armyMoveCap, regionId: 'oldWorld', ownerId: armyMoveGp, townTileKey: 'oldWorld|cap|0|0');
Province _armyMoveOwned(String id, {String regionId = 'oldWorld'}) => Province(id: id, regionId: regionId, ownerId: armyMoveGp);

Game armyMoveGame0({String? extraNeighborProvinceId}) {
  final provinces = <Province>[
    _armyMoveCap(),
    _armyMoveOwned(armyMoveP1),
    if (extraNeighborProvinceId != null) _armyMoveOwned(extraNeighborProvinceId),
  ];
  return ordersOwRegionGame(
    id: 'g_army_sug',
    turnNumber: 1,
    players: const [_armyMovePlayer],
    oldWorld: RegionData(
      provinces: provinces,
      units: [Unit(id: 'u1', type: 'musketeers', ownerId: armyMoveGp, locationProvinceId: armyMoveP1, tileKey: 'oldWorld|p1|0|0')],
    ),
    newWorld: RegionData(provinces: [_armyMoveOwned(armyMoveNw, regionId: 'newWorld')]),
    armies: [
      Army(id: homeArmyIdFor(armyMoveGp), ownerId: armyMoveGp, regionId: 'oldWorld', stationedProvinceId: armyMoveCap, regimentUnitIds: const [], isHomeArmy: true),
      Army(id: 'field_a', ownerId: armyMoveGp, regionId: 'oldWorld', stationedProvinceId: armyMoveP1, regimentUnitIds: const ['u1'], isHomeArmy: false),
    ],
    playerVisibilityByTile: const {
      armyMoveGp: {'oldWorld|cap|0|0': 'fullyVisible', 'oldWorld|p1|0|0': 'fullyVisible', 'newWorld|col|0|0': 'fullyVisible'},
    },
    tileKeysByRegionAndProvince: const {
      'oldWorld': {armyMoveCap: ['oldWorld|cap|0|0'], armyMoveP1: ['oldWorld|p1|0|0']},
      'newWorld': {armyMoveNw: ['newWorld|col|0|0']},
    },
  );
}

MapTopology armyMoveTopology0({bool includeP2 = false}) => MapTopology(
  nodes: [
    const TopologyNode(id: 'oldWorld|cap', regionId: 'oldWorld', type: TopologyNodeType.province),
    const TopologyNode(id: 'oldWorld|p1', regionId: 'oldWorld', type: TopologyNodeType.province),
    const TopologyNode(id: 'newWorld|col', regionId: 'newWorld', type: TopologyNodeType.province),
    if (includeP2) const TopologyNode(id: 'oldWorld|p2', regionId: 'oldWorld', type: TopologyNodeType.province),
  ],
  edges: [if (includeP2) const TopologyEdge(id1: 'oldWorld|p1', id2: 'oldWorld|p2')],
);

Game armyMoveGameWithPriorMoveToP2() {
  final game = armyMoveGame0(extraNeighborProvinceId: armyMoveP2);
  final tileKeys = Map<String, List<String>>.from(game.worldState.tileKeysByRegionAndProvince['oldWorld']!);
  tileKeys[armyMoveP2] = ['oldWorld|p2|0|0'];
  return game.copyWith(
    worldState: game.worldState.copyWith(
      tileKeysByRegionAndProvince: {...game.worldState.tileKeysByRegionAndProvince, 'oldWorld': tileKeys},
      playerVisibilityByTile: {
        armyMoveGp: {...game.worldState.playerVisibilityByTile[armyMoveGp]!, 'oldWorld|p2|0|0': 'fullyVisible'},
      },
    ),
  );
}

Army armyMoveFieldArmy(Game game) => game.worldState.armies.firstWhere((a) => a.id == 'field_a');

Game armyMoveDestIdsGame() => ordersOwRegionGame(
  id: 'g_army_dest_ids',
  turnNumber: 1,
  players: const [_armyMovePlayer],
  oldWorld: RegionData(provinces: [_armyMoveCap(), _armyMoveOwned(armyMoveP1), _armyMoveOwned(armyMoveP2)], units: const []),
  newWorld: RegionData(provinces: [_armyMoveOwned(armyMoveNw, regionId: 'newWorld')]),
  armies: [Army(id: 'field_a', ownerId: armyMoveGp, regionId: 'oldWorld', stationedProvinceId: armyMoveP1, regimentUnitIds: const [], isHomeArmy: false)],
);

MapTopology armyMoveDestIdsTopology() => const MapTopology(
  nodes: [
    TopologyNode(id: 'oldWorld|cap', regionId: 'oldWorld', type: TopologyNodeType.province),
    TopologyNode(id: 'oldWorld|p1', regionId: 'oldWorld', type: TopologyNodeType.province),
    TopologyNode(id: 'oldWorld|p2', regionId: 'oldWorld', type: TopologyNodeType.province),
    TopologyNode(id: 'newWorld|col', regionId: 'newWorld', type: TopologyNodeType.province),
  ],
  edges: [TopologyEdge(id1: 'oldWorld|p1', id2: 'oldWorld|p2')],
);
// dart format on
