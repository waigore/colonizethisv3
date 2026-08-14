// Shared fixtures for economy_stockpile_preview_work_orders_test
// (Refs #4342 Slice C).
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/game_test_fixtures.dart';

import 'support/economy_stockpile_preview_test_support.dart';

Stockpile workOrdersLumberIronStockpile(int quantity) => const Stockpile()
    .applyDelta(CommodityCatalog.lumber.id, quantity)
    .applyDelta(CommodityCatalog.castIron.id, quantity);

Game workOrdersPreviewGame({
  required int improvementLevel,
  required Stockpile stockpile,
  String unitId = 'b1',
  String unitType = kUnitTypeBuilder,
}) {
  return TestFixtures.singlePlayerWorkPreviewGame(
    playerStockpile: stockpile,
    units: [
      Unit(
        id: unitId,
        type: unitType,
        ownerId: 'p1',
        locationProvinceId: 'ow|p1',
        tileKey: kEconomyPreviewWorkTileKey,
      ),
    ],
    tileState: const TileMapState().setImprovement(
      kEconomyPreviewWorkTileKey,
      improvementLevel,
    ),
  );
}

Game workOrdersBusyBuilderGame() {
  final tileKey = kEconomyPreviewWorkTileKey;
  final busyUnit = Unit(
    id: 'b1',
    type: kUnitTypeBuilder,
    ownerId: 'p1',
    locationProvinceId: 'ow|p1',
    tileKey: tileKey,
    status: UnitStatus.working,
    currentWork: CurrentWork(
      workTarget: kWorkTargetBuildImprovement,
      tileKey: tileKey,
      totalTurns: 2,
      remainingTurns: 2,
    ),
  );
  return TestFixtures.minimalGame(
    id: 't',
    players: const [
      Player(id: 'p1', displayName: 'A', isHuman: true, stockpile: Stockpile()),
    ],
    oldWorld: RegionData(units: [busyUnit]),
    tileState: const TileMapState(),
  );
}

Game workOrdersUnaffordableUpgradeGame() {
  final tileKey = kEconomyPreviewWorkTileKey;
  return TestFixtures.minimalGame(
    id: 't2',
    players: [
      Player(
        id: 'p1',
        displayName: 'A',
        isHuman: true,
        stockpile: const Stockpile()
            .applyDelta(CommodityCatalog.lumber.id, 1)
            .applyDelta(CommodityCatalog.castIron.id, 1),
      ),
    ],
    oldWorld: RegionData(
      units: [
        Unit(
          id: 'b2',
          type: kUnitTypeBuilder,
          ownerId: 'p1',
          locationProvinceId: 'ow|p1',
          tileKey: tileKey,
        ),
      ],
    ),
    tileState: const TileMapState().setImprovement(tileKey, 1),
  );
}

Game workOrdersDisallowedUnitTypeGame() {
  return TestFixtures.minimalGame(
    id: 't',
    players: [
      Player(
        id: 'p1',
        displayName: 'A',
        isHuman: true,
        stockpile: const Stockpile()
            .applyDelta(CommodityCatalog.lumber.id, 10)
            .applyDelta(CommodityCatalog.castIron.id, 10),
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
