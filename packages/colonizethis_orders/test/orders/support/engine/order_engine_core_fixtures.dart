// Shared OrderEngine core scenario fixtures (Refs #3949 wave 3 / #3971).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../common/game_graphs.dart';

const oecOw = 'oldWorld';

MapTopology oecTwoProvinceTopology() => MapTopology(
  nodes: const [
    TopologyNode(id: 'P1', regionId: oecOw, type: TopologyNodeType.province),
    TopologyNode(id: 'P2', regionId: oecOw, type: TopologyNodeType.province),
  ],
  edges: const [TopologyEdge(id1: 'P1', id2: 'P2')],
);

MapTopology oecSingleProvinceTopology() => MapTopology(
  nodes: const [
    TopologyNode(id: 'P1', regionId: oecOw, type: TopologyNodeType.province),
  ],
  edges: const [],
);

const oecBothTilesVisible = {
  'p1': {'oldWorld|P1|0|0': 'fullyVisible', 'oldWorld|P2|0|0': 'fullyVisible'},
};

const oecP1VisibleP2Fogged = {
  'p1': {'oldWorld|P1|0|0': 'fullyVisible', 'oldWorld|P2|0|0': 'fogged'},
};

const _oecP1 = Player(id: 'p1', displayName: 'P1', isHuman: true);
const _oecP2 = Player(id: 'p2', displayName: 'P2', isHuman: true);

Game _oecTwoProvinceGame({
  required String unitType,
  Map<String, Map<String, String>>? playerVisibilityByTile,
  String p2OwnerId = 'p1',
  List<Player>? players,
  List<Tribe> tribes = const [],
  List<Army> armies = const [],
}) => ordersOwRegionGame(
  players: players ??
      (p2OwnerId == 'p2' ? const [_oecP1, _oecP2] : const [_oecP1]),
  oldWorld: RegionData(
    provinces: [
      Province(id: '$oecOw|P1', regionId: oecOw, ownerId: 'p1'),
      Province(id: '$oecOw|P2', regionId: oecOw, ownerId: p2OwnerId),
    ],
    units: [
      Unit(
        id: 'u1',
        type: unitType,
        ownerId: 'p1',
        locationProvinceId: '$oecOw|P1',
      ),
    ],
  ),
  armies: armies,
  tribes: tribes,
  playerVisibilityByTile: playerVisibilityByTile,
);

Game oecBuilderOnP1Game({
  Map<String, Map<String, String>>? playerVisibilityByTile,
  String p2OwnerId = 'p1',
}) => _oecTwoProvinceGame(
  unitType: kUnitTypeBuilder,
  playerVisibilityByTile: playerVisibilityByTile ?? oecBothTilesVisible,
  p2OwnerId: p2OwnerId,
);

Game oecExplorerOnP1Game({
  Map<String, Map<String, String>>? playerVisibilityByTile,
  String p2OwnerId = 'p1',
  List<Tribe> tribes = const [],
}) => _oecTwoProvinceGame(
  unitType: kUnitTypeExplorer,
  playerVisibilityByTile: playerVisibilityByTile ?? const {},
  p2OwnerId: p2OwnerId,
  players: const [_oecP1],
  tribes: tribes,
);

Game oecMilitaryOnP1Game() => _oecTwoProvinceGame(
  unitType: 'pikemen',
  p2OwnerId: 'p2',
  playerVisibilityByTile: oecP1VisibleP2Fogged,
  armies: [
    Army(
      id: fieldArmyIdFor('p1', '$oecOw|P1'),
      ownerId: 'p1',
      regionId: oecOw,
      stationedProvinceId: '$oecOw|P1',
      regimentUnitIds: const ['u1'],
      isHomeArmy: false,
    ),
  ],
);

Game oecEmptyUnitsP1Game() => ordersOwRegionGame(
  players: const [_oecP1],
  oldWorld: RegionData(
    provinces: [Province(id: '$oecOw|P1', regionId: oecOw, ownerId: 'p1')],
    units: const [],
  ),
);

OrderEngine oecProjectorEngine() => OrderEngine(projector: projectOrderEffects);
