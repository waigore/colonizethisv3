// Fixtures for e2eHandleBundledExploreFailure pins (#4598).
library;

import 'package:colonizethis_app_fixtures/config/ct_e2e_last_panel_snapshot.dart';
import 'package:colonizethis_data/colonizethis_data.dart' show MapTopology;
import 'package:colonizethis_models/colonizethis_models.dart';

const String bundledExploreHuman = 'gp1';

const TurnState bundledExploreOrderingTurn = TurnState(
  phase: TurnPhase.orders,
  turnNumber: 1,
);

const MapTopology bundledExploreEmptyTopology = MapTopology();

const Orders bundledExploreEmptyOrders = Orders();

CtE2eNavalPanelSnapshot bundledExploreNavalSnapshot({
  RegionData newWorld = const RegionData(),
  Map<String, Map<String, String>> playerVisibilityByTile = const {},
}) => CtE2eNavalPanelSnapshot(
  game: Game(
    id: 'g1',
    worldState: WorldState(
      turnState: bundledExploreOrderingTurn,
      oldWorld: const RegionData(),
      newWorld: newWorld,
      playerVisibilityByTile: playerVisibilityByTile,
    ),
    players: const [
      Player(id: bundledExploreHuman, displayName: 'You', isHuman: true),
    ],
  ),
  humanPlayerId: bundledExploreHuman,
  topology: bundledExploreEmptyTopology,
  draftOrders: bundledExploreEmptyOrders,
);

CtE2eCivilianPanelSnapshot bundledExploreCivilianSnapshot({
  Map<String, List<String>> availableWorkTargets = const {},
}) => CtE2eCivilianPanelSnapshot(
  game: Game(
    id: 'g1',
    worldState: WorldState(
      turnState: bundledExploreOrderingTurn,
      oldWorld: const RegionData(),
      newWorld: const RegionData(),
    ),
    players: const [
      Player(id: bundledExploreHuman, displayName: 'You', isHuman: true),
    ],
  ),
  humanPlayerId: bundledExploreHuman,
  currentOrders: bundledExploreEmptyOrders,
  availableWorkTargets: availableWorkTargets,
);

/// Naval snapshot with one fogged NW tile so the topology skip arm does
/// NOT fire — used by the regression-fail-arm tests.
CtE2eNavalPanelSnapshot bundledExploreNavalWithFoggedNwTile() =>
    bundledExploreNavalSnapshot(
      newWorld: const RegionData(
        provinces: [Province(id: 'newWorld|nwA', regionId: 'newWorld')],
      ),
      playerVisibilityByTile: const {
        bundledExploreHuman: {'newWorld|nwA|0|0': 'fogged'},
      },
    );
