import 'package:colonizethis_models/colonizethis_models.dart';

import 'package:colonizethis_app_fixtures/demo/production_panel_demo_data.dart';

/// Players and games for production panel widget tests without debug game init.
Player productionPanelTestFullPlayer() {
  return Player(
    id: 'test_gp_full',
    displayName: 'Full test',
    isHuman: true,
    stockpile: productionPanelTestFullStockpile,
    workerPool: productionPanelTestFullWorkerPool,
  );
}

Player productionPanelTestPartialPlayer() {
  return Player(
    id: 'test_gp_partial',
    displayName: 'Partial test',
    isHuman: true,
    stockpile: productionPanelTestPartialStockpile,
    workerPool: productionPanelTestPartialWorkerPool,
  );
}

Game productionPanelTestGameFor(Player player) {
  return Game(
    id: 'production-widget-test',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
      oldWorld: const RegionData(),
      newWorld: const RegionData(),
    ),
    players: [player],
  );
}
