// Shared fixtures for e2eFleetReachTurnLoop widget pins (#4598).
library;

import 'package:colonizethis_app_fixtures/config/ct_e2e_last_panel_snapshot.dart';
import 'package:colonizethis_data/colonizethis_data.dart' show MapTopology;
import 'package:colonizethis_models/colonizethis_models.dart';

const String fleetReachHuman = 'gp1';

const TurnState fleetReachOrderingTurn = TurnState(
  phase: TurnPhase.orders,
  turnNumber: 1,
);

const RegionData fleetReachEmptyRegion = RegionData();
const Orders fleetReachEmptyOrders = Orders();
const MapTopology fleetReachEmptyTopology = MapTopology();

Fleet fleetReachHomeFleet() => Fleet(
  id: 'fleet_$fleetReachHuman',
  ownerId: fleetReachHuman,
  regionId: 'oldWorld',
  inPortAtProvinceId: 'oldWorld|capital',
);

Fleet fleetReachSplitFleetInNw({String id = 'fleet_split'}) => Fleet(
  id: id,
  ownerId: fleetReachHuman,
  regionId: 'newWorld',
  seaZoneId: 'nwSea',
);

Game fleetReachGameWithFleets(List<Fleet> fleets) => Game(
  id: 'g1',
  worldState: WorldState(
    turnState: fleetReachOrderingTurn,
    oldWorld: fleetReachEmptyRegion,
    newWorld: fleetReachEmptyRegion,
    fleets: fleets,
  ),
  players: const [
    Player(id: fleetReachHuman, displayName: 'You', isHuman: true),
  ],
);

CtE2eNavalPanelSnapshot fleetReachSnapshot({required List<Fleet> fleets}) =>
    CtE2eNavalPanelSnapshot(
      game: fleetReachGameWithFleets(fleets),
      humanPlayerId: fleetReachHuman,
      topology: fleetReachEmptyTopology,
      draftOrders: fleetReachEmptyOrders,
    );

CtE2eNavalPanelSnapshot fleetReachReachedSnapshot() => fleetReachSnapshot(
  fleets: [fleetReachHomeFleet(), fleetReachSplitFleetInNw()],
);
