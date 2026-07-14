// Shared army-move picker destination fixtures (Refs #3949 / #3971 wave 4).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../common/game_graphs.dart';

const armyMovePickerGp = 'gp1';
const armyMovePickerCap = 'oldWorld|cap';
const armyMovePickerP1 = 'oldWorld|p1';
const armyMovePickerP2 = 'oldWorld|p2';
const armyMovePickerNw = 'newWorld|col';

const _pickerPlayer = Player(
  id: armyMovePickerGp,
  displayName: 'T',
  isHuman: true,
  capitalProvinceId: armyMovePickerCap,
);

Province _pickerCap() => Province(
  id: armyMovePickerCap,
  regionId: 'oldWorld',
  ownerId: armyMovePickerGp,
  townTileKey: 'oldWorld|cap|0|0',
);

Province _pickerOwned(String id, {String regionId = 'oldWorld'}) =>
    Province(id: id, regionId: regionId, ownerId: armyMovePickerGp);

Army _pickerFieldOnP1() => Army(
  id: 'field_a',
  ownerId: armyMovePickerGp,
  regionId: 'oldWorld',
  stationedProvinceId: armyMovePickerP1,
  regimentUnitIds: const [],
  isHomeArmy: false,
);

Game _pickerGame({
  required String id,
  required List<Province> owProvinces,
  RegionData newWorld = const RegionData(),
}) => ordersOwRegionGame(
  id: id,
  turnNumber: 1,
  players: const [_pickerPlayer],
  oldWorld: RegionData(provinces: owProvinces, units: const []),
  newWorld: newWorld,
  armies: [_pickerFieldOnP1()],
);

Game armyMovePickerGameTwoNeighborsWithNw({required String id}) => _pickerGame(
  id: id,
  owProvinces: [
    _pickerCap(),
    _pickerOwned(armyMovePickerP1),
    _pickerOwned(armyMovePickerP2),
  ],
  newWorld: RegionData(
    provinces: [_pickerOwned(armyMovePickerNw, regionId: 'newWorld')],
  ),
);

Game armyMovePickerGameMinimal({required String id}) => _pickerGame(
  id: id,
  owProvinces: [_pickerCap(), _pickerOwned(armyMovePickerP1)],
);

Game armyMovePickerGameTwoNeighborsOnly({required String id}) => _pickerGame(
  id: id,
  owProvinces: [
    _pickerCap(),
    _pickerOwned(armyMovePickerP1),
    _pickerOwned(armyMovePickerP2),
  ],
);

// dart format off
MapTopology armyMovePickerTopologyFourProvinces() => const MapTopology(
  nodes: [
    TopologyNode(id: 'oldWorld|cap', regionId: 'oldWorld', type: TopologyNodeType.province),
    TopologyNode(id: 'oldWorld|p1', regionId: 'oldWorld', type: TopologyNodeType.province),
    TopologyNode(id: 'oldWorld|p2', regionId: 'oldWorld', type: TopologyNodeType.province),
    TopologyNode(id: 'newWorld|col', regionId: 'newWorld', type: TopologyNodeType.province),
  ],
  edges: [TopologyEdge(id1: 'oldWorld|p1', id2: 'oldWorld|p2')],
);

MapTopology armyMovePickerTopologyThreeProvinces() => const MapTopology(
  nodes: [
    TopologyNode(id: 'oldWorld|cap', regionId: 'oldWorld', type: TopologyNodeType.province),
    TopologyNode(id: 'oldWorld|p1', regionId: 'oldWorld', type: TopologyNodeType.province),
    TopologyNode(id: 'oldWorld|p2', regionId: 'oldWorld', type: TopologyNodeType.province),
  ],
  edges: [TopologyEdge(id1: 'oldWorld|p1', id2: 'oldWorld|p2')],
);
// dart format on

const armyMovePickerEmptyTopology = MapTopology(nodes: [], edges: []);

Army armyMovePickerFieldArmy(Game game) => game.worldState.armies.first;
