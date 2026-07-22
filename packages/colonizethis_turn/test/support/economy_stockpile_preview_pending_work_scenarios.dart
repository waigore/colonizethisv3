import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'package:colonizethis_test/game_test_fixtures.dart';
import 'economy_stockpile_preview_test_support.dart';

void runPendingWorkTargetSkipScenarios() {
  for (final t in kMaterialBackedWorkTargets) {
    expectEconomyPreviewPendingBuildCostsEmpty(
      game: TestFixtures.singlePlayerWorkPreviewGame(
        playerStockpile: validWorkPreviewStockpile(),
        units: [],
        tileState: const TileMapState().setImprovement(
          kEconomyPreviewWorkTileKey,
          0,
        ),
      ),
      orders: economyPreviewSingleWorkOrder(
        unitId: 'missing',
        target: t.target,
      ),
      reason: 'missing unit target=${t.target}',
    );

    expectEconomyPreviewPendingBuildCostsEmpty(
      game: economyPreviewWorkUnitGame(
        unitId: 'u1',
        unitType: t.unitType,
        status: UnitStatus.working,
        currentWork: const CurrentWork(
          workTarget: kWorkTargetBuildImprovement,
          tileKey: kEconomyPreviewWorkTileKey,
          totalTurns: 1,
          remainingTurns: 1,
        ),
      ),
      orders: economyPreviewSingleWorkOrder(unitId: 'u1', target: t.target),
      reason: 'busy unit target=${t.target}',
    );

    expectEconomyPreviewPendingBuildCostsEmpty(
      game: economyPreviewWorkUnitGame(
        unitId: 'u1',
        unitType: 'peasant_levies',
      ),
      orders: economyPreviewSingleWorkOrder(unitId: 'u1', target: t.target),
      reason: 'disallowed unit target=${t.target}',
    );

    expectEconomyPreviewPendingBuildCostsEmpty(
      game: economyPreviewWorkUnitGame(unitId: 'u1', unitType: t.unitType),
      orders: economyPreviewSingleWorkOrder(
        unitId: 'u1',
        target: t.target,
        targetTileKey: '',
      ),
      reason: 'invalid target key target=${t.target}',
    );

    final insufficientStockpile = t.cost.entries.fold<Stockpile>(
      const Stockpile(),
      (acc, e) {
        final amount = e.key == t.cost.keys.first ? e.value - 1 : e.value;
        return acc.applyDelta(e.key, amount);
      },
    );
    final insufficientGame = economyPreviewWorkUnitGame(
      unitId: 'u1',
      unitType: t.unitType,
      playerStockpile: insufficientStockpile,
    );
    final insufficientOrders = economyPreviewSingleWorkOrder(
      unitId: 'u1',
      target: t.target,
    );
    expectEconomyPreviewPendingBuildCostsEmpty(
      game: insufficientGame,
      orders: insufficientOrders,
      reason: 'insufficient stockpile target=${t.target}',
    );
    expectPhaseDeltasSumToNet(
      game: insufficientGame,
      playerId: 'p1',
      currentOrders: insufficientOrders,
    );
  }
}

void runMixedWorkTargetAggregationScenario() {
  final game = TestFixtures.singlePlayerWorkPreviewGame(
    playerStockpile: const Stockpile()
        .applyDelta(CommodityCatalog.lumber.id, 30)
        .applyDelta(CommodityCatalog.castIron.id, 20)
        .applyDelta(CommodityCatalog.bronze.id, 10)
        .applyDelta(CommodityCatalog.steel.id, 10),
    units: [
      Unit(
        id: 'b1',
        type: kUnitTypeBuilder,
        ownerId: 'p1',
        locationProvinceId: 'ow|p1',
        tileKey: kEconomyPreviewWorkTileKey,
      ),
      Unit(
        id: 'b2',
        type: kUnitTypeBuilder,
        ownerId: 'p1',
        locationProvinceId: 'ow|p1',
        tileKey: kEconomyPreviewWorkTileKey,
      ),
      Unit(
        id: 'e1',
        type: kUnitTypeEngineer,
        ownerId: 'p1',
        locationProvinceId: 'ow|p1',
        tileKey: kEconomyPreviewWorkTileKey,
      ),
      Unit(
        id: 'e2',
        type: kUnitTypeEngineer,
        ownerId: 'p1',
        locationProvinceId: 'ow|p1',
        tileKey: kEconomyPreviewWorkTileKey,
      ),
      Unit(
        id: 'e3',
        type: kUnitTypeEngineer,
        ownerId: 'p1',
        locationProvinceId: 'ow|p1',
        tileKey: kEconomyPreviewWorkTileKey,
      ),
      Unit(
        id: 'r1',
        type: kUnitTypeRailBuilder,
        ownerId: 'p1',
        locationProvinceId: 'ow|p1',
        tileKey: kEconomyPreviewWorkTileKey,
      ),
    ],
    tileState: const TileMapState().setImprovement(kEconomyPreviewWorkTileKey, 0),
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
  expectPhaseDeltasSumToNet(
    game: game,
    playerId: 'p1',
    currentOrders: orders,
  );
}

void runSequentialAffordabilityScenario() {
  final game = TestFixtures.singlePlayerWorkPreviewGame(
    playerStockpile: const Stockpile()
        .applyDelta(CommodityCatalog.lumber.id, 2)
        .applyDelta(CommodityCatalog.castIron.id, 2),
    units: [
      Unit(
        id: 'e1',
        type: kUnitTypeEngineer,
        ownerId: 'p1',
        locationProvinceId: 'ow|p1',
        tileKey: kEconomyPreviewWorkTileKey,
      ),
      Unit(
        id: 'e2',
        type: kUnitTypeEngineer,
        ownerId: 'p1',
        locationProvinceId: 'ow|p1',
        tileKey: kEconomyPreviewWorkTileKey,
      ),
      Unit(
        id: 'b1',
        type: kUnitTypeBuilder,
        ownerId: 'p1',
        locationProvinceId: 'ow|p1',
        tileKey: kEconomyPreviewWorkTileKey,
      ),
    ],
    tileState: const TileMapState().setImprovement(kEconomyPreviewWorkTileKey, 0),
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
  expectPhaseDeltasSumToNet(
    game: game,
    playerId: 'p1',
    currentOrders: orders,
  );
}
