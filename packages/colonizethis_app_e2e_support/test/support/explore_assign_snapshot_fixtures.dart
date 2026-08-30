// Shared civilian-panel snapshot builder for explore-assign pin groups (#4598).
library;

import 'package:colonizethis_app_fixtures/config/ct_e2e_last_panel_snapshot.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

const String kExploreAssignSnapshotHumanId = 'gp1';

const TurnState _orderingTurn = TurnState(
  phase: TurnPhase.orders,
  turnNumber: 1,
);

const Orders _emptyOrders = Orders();

WorldState _world() => const WorldState(
  turnState: _orderingTurn,
  oldWorld: RegionData(),
  newWorld: RegionData(),
);

Game _game() => Game(
  id: 'g1',
  worldState: _world(),
  players: const [
    Player(
      id: kExploreAssignSnapshotHumanId,
      displayName: 'You',
      isHuman: true,
    ),
  ],
);

CtE2eCivilianPanelSnapshot exploreAssignSnapshotForTest({
  Map<String, List<String>> availableWorkTargets = const {},
}) => CtE2eCivilianPanelSnapshot(
  game: _game(),
  humanPlayerId: kExploreAssignSnapshotHumanId,
  currentOrders: _emptyOrders,
  availableWorkTargets: availableWorkTargets,
);
