import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'package:colonizethis_test/game_test_fixtures.dart';
import '../economy_stockpile_preview_test_support.dart';

void runPendingWorkTargetSkipScenarios() {
  for (final t in kMaterialBackedWorkTargets) {
    final validBaseStockpile = const Stockpile()
        .applyDelta(CommodityCatalog.lumber.id, 20)
        .applyDelta(CommodityCatalog.castIron.id, 20)
        .applyDelta(CommodityCatalog.bronze.id, 20)
        .applyDelta(CommodityCatalog.steel.id, 20);

    final missingUnitGame = TestFixtures.singlePlayerWorkPreviewGame(
      playerStockpile: validBaseStockpile,
      units: [],
      tileState: const TileMapState().setImprovement(kEconomyPreviewWorkTileKey, 0),
    );
    final missingUnitOrders = Orders(
      workOrdersByPlayerId: {
        'p1': [
          WorkOrder(
            unitId: 'missing',
            target: t.target,
            targetTileKey: kEconomyPreviewWorkTileKey,
          ),
        ],
      },
    );
    expect(
      previewStockpilePhaseDeltasByCommodityForPlayer(
        game: missingUnitGame,
        topology: const MapTopology(),
        playerId: 'p1',
        inputs: economyPreviewInputs(currentOrders: missingUnitOrders),
      )[EconomyPreviewStockpilePhase.pendingBuildCosts],
      isEmpty,
      reason: 'missing unit target=${t.target}',
    );

    final busyUnitGame = TestFixtures.singlePlayerWorkPreviewGame(
      playerStockpile: validBaseStockpile,
      units: [
        Unit(
          id: 'u1',
          type: t.unitType,
          ownerId: 'p1',
          locationProvinceId: 'ow|p1',
          tileKey: kEconomyPreviewWorkTileKey,
          status: UnitStatus.working,
          currentWork: const CurrentWork(
            workTarget: kWorkTargetBuildImprovement,
            tileKey: kEconomyPreviewWorkTileKey,
            totalTurns: 1,
            remainingTurns: 1,
          ),
        ),
      ],
      tileState: const TileMapState().setImprovement(kEconomyPreviewWorkTileKey, 0),
    );
    final busyOrders = Orders(
      workOrdersByPlayerId: {
        'p1': [
          WorkOrder(
            unitId: 'u1',
            target: t.target,
            targetTileKey: kEconomyPreviewWorkTileKey,
          ),
        ],
      },
    );
    expect(
      previewStockpilePhaseDeltasByCommodityForPlayer(
        game: busyUnitGame,
        topology: const MapTopology(),
        playerId: 'p1',
        inputs: economyPreviewInputs(currentOrders: busyOrders),
      )[EconomyPreviewStockpilePhase.pendingBuildCosts],
      isEmpty,
      reason: 'busy unit target=${t.target}',
    );

    final disallowedUnitGame = TestFixtures.singlePlayerWorkPreviewGame(
      playerStockpile: validBaseStockpile,
      units: [
        Unit(
          id: 'u1',
          type: 'peasant_levies',
          ownerId: 'p1',
          locationProvinceId: 'ow|p1',
          tileKey: kEconomyPreviewWorkTileKey,
        ),
      ],
      tileState: const TileMapState().setImprovement(kEconomyPreviewWorkTileKey, 0),
    );
    final disallowedOrders = Orders(
      workOrdersByPlayerId: {
        'p1': [
          WorkOrder(
            unitId: 'u1',
            target: t.target,
            targetTileKey: kEconomyPreviewWorkTileKey,
          ),
        ],
      },
    );
    expect(
      previewStockpilePhaseDeltasByCommodityForPlayer(
        game: disallowedUnitGame,
        topology: const MapTopology(),
        playerId: 'p1',
        inputs: economyPreviewInputs(currentOrders: disallowedOrders),
      )[EconomyPreviewStockpilePhase.pendingBuildCosts],
      isEmpty,
      reason: 'disallowed unit target=${t.target}',
    );

    final invalidTileGame = TestFixtures.singlePlayerWorkPreviewGame(
      playerStockpile: validBaseStockpile,
      units: [
        Unit(
          id: 'u1',
          type: t.unitType,
          ownerId: 'p1',
          locationProvinceId: 'ow|p1',
          tileKey: kEconomyPreviewWorkTileKey,
        ),
      ],
      tileState: const TileMapState().setImprovement(kEconomyPreviewWorkTileKey, 0),
    );
    final invalidTileOrders = Orders(
      workOrdersByPlayerId: {
        'p1': [
          WorkOrder(unitId: 'u1', target: t.target, targetTileKey: ''),
        ],
      },
    );
    expect(
      previewStockpilePhaseDeltasByCommodityForPlayer(
        game: invalidTileGame,
        topology: const MapTopology(),
        playerId: 'p1',
        inputs: economyPreviewInputs(currentOrders: invalidTileOrders),
      )[EconomyPreviewStockpilePhase.pendingBuildCosts],
      isEmpty,
      reason: 'invalid target key target=${t.target}',
    );

    final insufficientStockpile = t.cost.entries.fold<Stockpile>(
      const Stockpile(),
      (acc, e) {
        final amount = e.key == t.cost.keys.first ? e.value - 1 : e.value;
        return acc.applyDelta(e.key, amount);
      },
    );
    final insufficientGame = TestFixtures.singlePlayerWorkPreviewGame(
      playerStockpile: insufficientStockpile,
      units: [
        Unit(
          id: 'u1',
          type: t.unitType,
          ownerId: 'p1',
          locationProvinceId: 'ow|p1',
          tileKey: kEconomyPreviewWorkTileKey,
        ),
      ],
      tileState: const TileMapState().setImprovement(kEconomyPreviewWorkTileKey, 0),
    );
    final insufficientOrders = Orders(
      workOrdersByPlayerId: {
        'p1': [
          WorkOrder(
            unitId: 'u1',
            target: t.target,
            targetTileKey: kEconomyPreviewWorkTileKey,
          ),
        ],
      },
    );
    expect(
      previewStockpilePhaseDeltasByCommodityForPlayer(
        game: insufficientGame,
        topology: const MapTopology(),
        playerId: 'p1',
        inputs: economyPreviewInputs(currentOrders: insufficientOrders),
      )[EconomyPreviewStockpilePhase.pendingBuildCosts],
      isEmpty,
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
  final phases = previewStockpilePhaseDeltasByCommodityForPlayer(
    game: game,
    topology: const MapTopology(),
    playerId: 'p1',
    inputs: economyPreviewInputs(currentOrders: orders),
  );
  final pending = phases[EconomyPreviewStockpilePhase.pendingBuildCosts]!;
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
  final phases = previewStockpilePhaseDeltasByCommodityForPlayer(
    game: game,
    topology: const MapTopology(),
    playerId: 'p1',
    inputs: economyPreviewInputs(currentOrders: orders),
  );
  final pending = phases[EconomyPreviewStockpilePhase.pendingBuildCosts]!;
  expect(pending[CommodityCatalog.lumber.id], -2);
  expect(pending[CommodityCatalog.castIron.id], -2);
  expectPhaseDeltasSumToNet(
    game: game,
    playerId: 'p1',
    currentOrders: orders,
  );
}
