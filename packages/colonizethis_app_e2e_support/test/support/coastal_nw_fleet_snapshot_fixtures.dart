// Shared fixtures for coastal NW fleet snapshot predicate pins (Slice D / #4195).
library;

import 'package:colonizethis_app_fixtures/config/ct_e2e_last_panel_snapshot.dart';
import 'package:colonizethis_data/colonizethis_data.dart'
    show MapTopology, TopologyEdge, TopologyNode, TopologyNodeType;
import 'package:colonizethis_models/colonizethis_models.dart';

const String coastalNwHumanPlayerId = 'gp1';
const String coastalNwOtherGpId = 'gp2';

const TurnState coastalNwOrderingTurn = TurnState(
  phase: TurnPhase.orders,
  turnNumber: 1,
);

const RegionData coastalNwEmptyRegion = RegionData();
const Orders coastalNwEmptyOrders = Orders();
const MapTopology coastalNwEmptyTopology = MapTopology();

MapTopology coastalNwCoastalTopology({
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

Game coastalNwGameWithFleets(List<Fleet> fleets) => Game(
  id: 'g1',
  worldState: WorldState(
    turnState: coastalNwOrderingTurn,
    oldWorld: coastalNwEmptyRegion,
    newWorld: coastalNwEmptyRegion,
    fleets: fleets,
  ),
  players: const [
    Player(id: coastalNwHumanPlayerId, displayName: 'You', isHuman: true),
  ],
);

CtE2eNavalPanelSnapshot coastalNwSnapshot({
  required List<Fleet> fleets,
  MapTopology topology = coastalNwEmptyTopology,
}) => CtE2eNavalPanelSnapshot(
  game: coastalNwGameWithFleets(fleets),
  humanPlayerId: coastalNwHumanPlayerId,
  topology: topology,
  draftOrders: coastalNwEmptyOrders,
);

Fleet coastalNwHomeFleet({
  String regionId = 'oldWorld',
  String? inPortAtProvinceId = 'oldWorld|capital',
}) => Fleet(
  id: 'fleet_$coastalNwHumanPlayerId',
  ownerId: coastalNwHumanPlayerId,
  regionId: regionId,
  inPortAtProvinceId: inPortAtProvinceId,
);
