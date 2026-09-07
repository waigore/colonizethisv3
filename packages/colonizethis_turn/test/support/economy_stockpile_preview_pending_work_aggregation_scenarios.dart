import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/game_test_fixtures.dart';
import 'package:colonizethis_test/test.dart';

import 'economy_stockpile_preview_test_support.dart';

Unit _previewUnit({required String id, required String type}) => Unit(
  id: id,
  type: type,
  ownerId: 'p1',
  locationProvinceId: 'ow|p1',
  tileKey: kEconomyPreviewWorkTileKey,
);

void runMixedWorkTargetAggregationScenario() {
  final game = TestFixtures.singlePlayerWorkPreviewGame(
    playerStockpile: const Stockpile()
        .applyDelta(CommodityCatalog.lumber.id, 30)
        .applyDelta(CommodityCatalog.castIron.id, 20)
        .applyDelta(CommodityCatalog.bronze.id, 10)
        .applyDelta(CommodityCatalog.steel.id, 10),
    units: [
      _previewUnit(id: 'b1', type: kUnitTypeBuilder),
      _previewUnit(id: 'b2', type: kUnitTypeBuilder),
      _previewUnit(id: 'e1', type: kUnitTypeEngineer),
      _previewUnit(id: 'e2', type: kUnitTypeEngineer),
      _previewUnit(id: 'e3', type: kUnitTypeEngineer),
      _previewUnit(id: 'r1', type: kUnitTypeRailBuilder),
    ],
    tileState: const TileMapState().setImprovement(
      kEconomyPreviewWorkTileKey,
      0,
    ),
  );
  const orders = Orders(
    workOrdersByPlayerId: {
      'p1': [
        WorkOrder(
          unitId: 'b1',
          target: kWorkTargetBuildImprovement,
          targetTileKey: kEconomyPreviewWorkTileKey,
        ),
        WorkOrder(
          unitId: 'b2',
          target: kWorkTargetUpgradeTown,
          targetTileKey: kEconomyPreviewWorkTileKey,
        ),
        WorkOrder(
          unitId: 'e1',
          target: kWorkTargetBuildRoad,
          targetTileKey: kEconomyPreviewWorkTileKey,
        ),
        WorkOrder(
          unitId: 'e2',
          target: kWorkTargetBuildPort,
          targetTileKey: kEconomyPreviewWorkTileKey,
        ),
        WorkOrder(
          unitId: 'e3',
          target: kWorkTargetBuildFort,
          targetTileKey: kEconomyPreviewWorkTileKey,
        ),
        WorkOrder(
          unitId: 'r1',
          target: kWorkTargetBuildRail,
          targetTileKey: kEconomyPreviewWorkTileKey,
        ),
      ],
    },
  );
  final pending = economyPreviewPendingBuildCosts(game: game, orders: orders);
  expect(pending[CommodityCatalog.lumber.id], -13);
  expect(pending[CommodityCatalog.castIron.id], -8);
  expect(pending[CommodityCatalog.bronze.id], -3);
  expect(pending[CommodityCatalog.steel.id], -2);
  expectPhaseDeltasSumToNet(game: game, playerId: 'p1', currentOrders: orders);
}

void runSequentialAffordabilityScenario() {
  final game = TestFixtures.singlePlayerWorkPreviewGame(
    playerStockpile: const Stockpile()
        .applyDelta(CommodityCatalog.lumber.id, 2)
        .applyDelta(CommodityCatalog.castIron.id, 2),
    units: [
      _previewUnit(id: 'e1', type: kUnitTypeEngineer),
      _previewUnit(id: 'e2', type: kUnitTypeEngineer),
      _previewUnit(id: 'b1', type: kUnitTypeBuilder),
    ],
    tileState: const TileMapState().setImprovement(
      kEconomyPreviewWorkTileKey,
      0,
    ),
  );
  const orders = Orders(
    workOrdersByPlayerId: {
      'p1': [
        WorkOrder(
          unitId: 'e1',
          target: kWorkTargetBuildRoad,
          targetTileKey: kEconomyPreviewWorkTileKey,
        ),
        WorkOrder(
          unitId: 'e2',
          target: kWorkTargetBuildPort,
          targetTileKey: kEconomyPreviewWorkTileKey,
        ),
        WorkOrder(
          unitId: 'b1',
          target: kWorkTargetUpgradeTown,
          targetTileKey: kEconomyPreviewWorkTileKey,
        ),
      ],
    },
  );
  final pending = economyPreviewPendingBuildCosts(game: game, orders: orders);
  expect(pending[CommodityCatalog.lumber.id], -2);
  expect(pending[CommodityCatalog.castIron.id], -2);
  expectPhaseDeltasSumToNet(game: game, playerId: 'p1', currentOrders: orders);
}
