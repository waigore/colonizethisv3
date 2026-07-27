// Shared fixtures for economy_stockpile_preview_test (Refs #4168 slice B).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/game_test_fixtures.dart';

Player economyPreviewSinglePlayer({
  Stockpile stockpile = const Stockpile(),
  WorkerPool workerPool = const WorkerPool(),
  int treasury = 0,
}) {
  return Player(
    id: 'p1',
    displayName: 'A',
    isHuman: true,
    stockpile: stockpile,
    workerPool: workerPool,
    treasury: treasury,
  );
}

Game economyPreviewSinglePlayerGame(Player player) {
  return TestFixtures.singlePlayerGame(player);
}

Game economyPreviewMilitaryConsumptionGame() {
  return TestFixtures.minimalGame(
    id: 't',
    players: [
      economyPreviewSinglePlayer(
        stockpile: const Stockpile().applyDelta(CommodityCatalog.grain.id, 10),
      ),
    ],
    oldWorld: RegionData(
      units: [
        Unit(
          id: 'u1',
          type: 'peasant_levies',
          ownerId: 'p1',
          locationProvinceId: 'ow|p1',
        ),
      ],
    ),
  );
}

Game economyPreviewProductionGame() {
  final stockpile = const Stockpile()
      .applyDelta(CommodityCatalog.grain.id, 50)
      .applyDelta(CommodityCatalog.meat.id, 50)
      .applyDelta(CommodityCatalog.timber.id, 20);
  return economyPreviewSinglePlayerGame(
    economyPreviewSinglePlayer(
      stockpile: stockpile,
      workerPool: const WorkerPool(peasants: 10),
    ),
  );
}

Game economyPreviewCombinedScenarioGame() {
  final stockpile = const Stockpile()
      .applyDelta(CommodityCatalog.grain.id, 100)
      .applyDelta(CommodityCatalog.meat.id, 100)
      .applyDelta(CommodityCatalog.timber.id, 20)
      .applyDelta(CommodityCatalog.gems.id, 1);
  return TestFixtures.minimalGame(
    id: 't',
    players: [
      economyPreviewSinglePlayer(
        stockpile: stockpile,
        workerPool: const WorkerPool(peasants: 2),
      ),
    ],
    oldWorld: RegionData(
      units: [
        Unit(
          id: 'u1',
          type: 'peasant_levies',
          ownerId: 'p1',
          locationProvinceId: 'ow|p1',
        ),
      ],
    ),
  );
}
