// Fixtures for e2eAwaitNwCoastalOrVisibleLandForBundledExplore pins (#4598).
library;

import 'package:colonizethis_app_fixtures/config/ct_e2e_last_panel_snapshot.dart';
import 'package:colonizethis_data/colonizethis_data.dart'
    show MapTopology, TopologyEdge, TopologyNode, TopologyNodeType;
import 'package:colonizethis_models/colonizethis_models.dart';

const String awaitNwHuman = 'gp1';

const TurnState awaitNwOrderingTurn = TurnState(
  phase: TurnPhase.orders,
  turnNumber: 1,
);

const RegionData awaitNwEmptyRegion = RegionData();
const Orders awaitNwEmptyOrders = Orders();
const MapTopology awaitNwEmptyTopology = MapTopology();

Province awaitNwProvince(String localId) =>
    Province(id: ProvinceId.full('newWorld', localId), regionId: 'newWorld');

Fleet awaitNwHomeFleet() => Fleet(
  id: 'fleet_$awaitNwHuman',
  ownerId: awaitNwHuman,
  regionId: 'oldWorld',
  inPortAtProvinceId: 'oldWorld|capital',
);

MapTopology awaitNwCoastalTopology({
  required String seaId,
  required List<String> adjacentProvinceIds,
}) => MapTopology(
  nodes: [
    TopologyNode(
      id: seaId,
      regionId: 'newWorld',
      type: TopologyNodeType.seaZone,
    ),
    for (final pid in adjacentProvinceIds)
      TopologyNode(
        id: pid,
        regionId: 'newWorld',
        type: TopologyNodeType.province,
      ),
  ],
  edges: [
    for (final pid in adjacentProvinceIds) TopologyEdge(id1: pid, id2: seaId),
  ],
);

Game awaitNwGameWithFleets({
  List<Fleet> fleets = const [],
  RegionData newWorld = awaitNwEmptyRegion,
  Map<String, Map<String, String>> playerVisibilityByTile = const {},
}) => Game(
  id: 'g1',
  worldState: WorldState(
    turnState: awaitNwOrderingTurn,
    oldWorld: awaitNwEmptyRegion,
    newWorld: newWorld,
    fleets: fleets,
    playerVisibilityByTile: playerVisibilityByTile,
  ),
  players: const [Player(id: awaitNwHuman, displayName: 'You', isHuman: true)],
);

CtE2eNavalPanelSnapshot awaitNwSnapshot({
  List<Fleet> fleets = const [],
  MapTopology topology = awaitNwEmptyTopology,
  RegionData newWorld = awaitNwEmptyRegion,
  Map<String, Map<String, String>> playerVisibilityByTile = const {},
}) => CtE2eNavalPanelSnapshot(
  game: awaitNwGameWithFleets(
    fleets: fleets,
    newWorld: newWorld,
    playerVisibilityByTile: playerVisibilityByTile,
  ),
  humanPlayerId: awaitNwHuman,
  topology: topology,
  draftOrders: awaitNwEmptyOrders,
);

CtE2eNavalPanelSnapshot awaitNwCoastalArrivalSnapshot() => awaitNwSnapshot(
  fleets: [
    awaitNwHomeFleet(),
    Fleet(
      id: 'fleetawaitNwHuman_split',
      ownerId: awaitNwHuman,
      regionId: 'newWorld',
      seaZoneId: 'sea_nw_1',
    ),
  ],
  topology: awaitNwCoastalTopology(
    seaId: 'sea_nw_1',
    adjacentProvinceIds: const ['newWorld|p1'],
  ),
);

CtE2eNavalPanelSnapshot awaitNwFoggedSnapshot() => awaitNwSnapshot(
  newWorld: RegionData(provinces: [awaitNwProvince('p1')]),
  playerVisibilityByTile: const {
    awaitNwHuman: {'newWorld|p1|0|0': 'fogged'},
  },
);
