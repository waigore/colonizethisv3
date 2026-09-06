// Fixtures for e2e_helpers barrel PR #2731 lifted pins (#4734 Slice J).

import 'package:colonizethis_app_fixtures/config/ct_e2e_last_panel_snapshot.dart'
    show CtE2eCivilianPanelSnapshot, CtE2eNavalPanelSnapshot;
import 'package:colonizethis_data/colonizethis_data.dart' show MapTopology;
import 'package:colonizethis_models/colonizethis_models.dart';

CtE2eNavalPanelSnapshot bundledExploreFailureNavalSnapshot() {
  const human = 'gp1';
  return CtE2eNavalPanelSnapshot(
    game: Game(
      id: 'barrel-smoke-bundled-explore-failure',
      worldState: WorldState(
        turnState: const TurnState(
          phase: TurnPhase.orders,
          turnNumber: 1,
        ),
        oldWorld: const RegionData(),
        newWorld: const RegionData(
          provinces: [Province(id: 'newWorld|nwA', regionId: 'newWorld')],
        ),
        playerVisibilityByTile: const {
          human: {'newWorld|nwA|0|0': 'fogged'},
        },
      ),
      players: const [
        Player(id: human, displayName: 'You', isHuman: true),
      ],
    ),
    humanPlayerId: human,
    topology: const MapTopology(),
    draftOrders: const Orders(),
  );
}

CtE2eNavalPanelSnapshot nwReachNavalSnapshot() {
  const human = 'gp1';
  return CtE2eNavalPanelSnapshot(
    game: Game(
      id: 'barrel-smoke-nw-reach',
      worldState: WorldState(
        turnState: TurnState(phase: TurnPhase.orders, turnNumber: 1),
        oldWorld: RegionData(),
        newWorld: RegionData(),
        fleets: [
          Fleet(
            id: 'fleet_$human',
            ownerId: human,
            regionId: 'oldWorld',
            inPortAtProvinceId: 'oldWorld|capital',
          ),
          Fleet(
            id: 'fleet_split',
            ownerId: human,
            regionId: 'newWorld',
            seaZoneId: 'nwSea',
          ),
        ],
      ),
      players: const [
        Player(id: human, displayName: 'You', isHuman: true),
      ],
    ),
    humanPlayerId: human,
    topology: const MapTopology(),
    draftOrders: const Orders(),
  );
}
