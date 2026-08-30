// Fixtures for e2eAwaitExploreEnabledFromCivilianPanel pins (#4598).
library;

import 'package:colonizethis_app_fixtures/config/ct_e2e_last_panel_snapshot.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

const String awaitExploreHuman = 'gp1';

const TurnState awaitExploreOrderingTurn = TurnState(
  phase: TurnPhase.orders,
  turnNumber: 1,
);

const Orders awaitExploreEmptyOrders = Orders();

Game awaitExploreGame() => const Game(
  id: 'g1',
  worldState: WorldState(
    turnState: awaitExploreOrderingTurn,
    oldWorld: RegionData(),
    newWorld: RegionData(),
  ),
  players: [Player(id: awaitExploreHuman, displayName: 'You', isHuman: true)],
);

CtE2eCivilianPanelSnapshot awaitExploreCivilianSnapshot({
  Map<String, List<String>> availableWorkTargets = const {},
}) => CtE2eCivilianPanelSnapshot(
  game: awaitExploreGame(),
  humanPlayerId: awaitExploreHuman,
  currentOrders: awaitExploreEmptyOrders,
  availableWorkTargets: availableWorkTargets,
);
