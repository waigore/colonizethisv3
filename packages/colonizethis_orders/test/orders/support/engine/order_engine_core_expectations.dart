// Compact OrderEngine core assertions (Refs #3949 wave 3).

import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'order_engine_core_fixtures.dart';

/// Pins for [orderEngineCoreScenarios] rows.
enum OrderEngineCoreTarget {
  addOrderAndValidate,
  removeMoveOrderAtIndex,
  removeBuildOrderAtIndex,
  addWorkOrderWithContextRejected,
  firstInvalidPlusSubsequentRejected,
  projectedEffectsWorkerCount,
  projectedEffectsUnitLocations,
  projectedEffectsNoGameMutation,
  addMoveOrderWithContextValidation,
  civilianCannotMoveIntoGpTerritory,
  militaryCannotMoveIntoGpWithoutWar,
  militaryMayMoveIntoGpWithDeclareWar,
  explorerMayMoveIntoTribalProvince,
  moveRejectedWhenSourceProvinceUnknown,
}

void runOrderEngineCoreExpectation(OrderEngineCoreTarget target) {
  switch (target) {
    case OrderEngineCoreTarget.addOrderAndValidate:
      final engine = OrderEngine();
      final result = engine.addMoveOrder(
        'p1',
        const MoveOrder(unitId: 'u1', destinationTileKey: 'oldWorld|P2|0|0'),
      );
      expect(result.status, OrderValidationStatus.accepted);
      expect(engine.orders.moveOrdersByPlayerId['p1']?.length, 1);

    case OrderEngineCoreTarget.removeMoveOrderAtIndex:
      final engine = OrderEngine();
      engine.addMoveOrder(
        'p1',
        const MoveOrder(unitId: 'u1', destinationTileKey: 'oldWorld|P2|0|0'),
      );
      engine.addMoveOrder(
        'p1',
        const MoveOrder(unitId: 'u2', destinationTileKey: 'oldWorld|P3|0|0'),
      );
      expect(engine.orders.moveOrdersByPlayerId['p1']!.length, 2);
      engine.removeMoveOrder('p1', 0);
      expect(engine.orders.moveOrdersByPlayerId['p1']!.length, 1);
      expect(engine.orders.moveOrdersByPlayerId['p1']!.first.unitId, 'u2');

    case OrderEngineCoreTarget.removeBuildOrderAtIndex:
      final engine = OrderEngine();
      engine.addBuildOrder(
        'p1',
        BuildUnitOrder(
          unitType: 'peasant_levies',
          isMilitary: true,
          spawnProvinceId: 'oldWorld|P1',
        ),
      );
      expect(engine.orders.buildUnitOrdersByPlayerId['p1']!.length, 1);
      engine.removeBuildOrder('p1', 0);
      expect(engine.orders.buildUnitOrdersByPlayerId['p1'], isEmpty);

    case OrderEngineCoreTarget.addWorkOrderWithContextRejected:
      final topology = oecSingleProvinceTopology();
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
          oldWorld: RegionData(
            provinces: [
              Province(id: '$oecOw|P1', regionId: oecOw, ownerId: 'p1'),
            ],
            units: [
              Unit(
                id: 'u1',
                type: kUnitTypeBuilder,
                ownerId: 'p1',
                locationProvinceId: '$oecOw|P1',
                tileKey: 'oldWorld|P1|0|0',
              ),
            ],
          ),
          newWorld: const RegionData(),
        ),
        players: const [Player(id: 'p1', displayName: 'P1', isHuman: true)],
      );
      final engine = OrderEngine();
      final result = engine.addWorkOrderWithContext(
        game,
        topology,
        'p1',
        const WorkOrder(
          unitId: 'u1',
          target: 'unknown_target',
          targetTileKey: 'oldWorld|P1|0|0',
        ),
      );
      expect(result.status, OrderValidationStatus.rejected);

    case OrderEngineCoreTarget.firstInvalidPlusSubsequentRejected:
      final topology = oecTwoProvinceTopology();
      final game = oecBuilderOnP1Game();
      final engine = OrderEngine();
      engine.addMoveOrder(
        'p1',
        const MoveOrder(unitId: 'u1', destinationTileKey: 'oldWorld|P2|0|0'),
      );
      engine.addMoveOrder(
        'p1',
        const MoveOrder(unitId: 'u999', destinationTileKey: 'oldWorld|P2|0|0'),
      );
      engine.addMoveOrder(
        'p1',
        const MoveOrder(unitId: 'u1', destinationTileKey: 'oldWorld|P3|0|0'),
      );
      final results = engine.validatePlayerOrdersWithContext(
        game,
        topology,
        'p1',
      );
      expect(results.length, 3);
      expect(results[0].status, OrderValidationStatus.accepted);
      expect(results[1].status, OrderValidationStatus.rejected);
      expect(results[2].status, OrderValidationStatus.rejected);

    case OrderEngineCoreTarget.projectedEffectsWorkerCount:
      final topology = oecSingleProvinceTopology();
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
          oldWorld: RegionData(
            provinces: [
              Province(id: '$oecOw|P1', regionId: oecOw, ownerId: 'p1'),
            ],
            units: [],
          ),
          newWorld: const RegionData(),
        ),
        players: const [Player(id: 'p1', displayName: 'P1', isHuman: true)],
      );
      final engine = oecProjectorEngine();
      final effects = engine.projectedEffects(game, topology, 'p1');
      expect(effects.workerCount, isNotNull);

    case OrderEngineCoreTarget.projectedEffectsUnitLocations:
      final topology = oecTwoProvinceTopology();
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
          oldWorld: RegionData(
            provinces: [
              Province(id: '$oecOw|P1', regionId: oecOw, ownerId: 'p1'),
              Province(id: '$oecOw|P2', regionId: oecOw, ownerId: 'p1'),
            ],
            units: [
              Unit(
                id: 'u1',
                type: kUnitTypeMerchant,
                ownerId: 'p1',
                locationProvinceId: '$oecOw|P1',
                tileKey: '$oecOw|P1|0|0',
              ),
            ],
          ),
          newWorld: const RegionData(),
          playerVisibilityByTile: oecBothTilesVisible,
        ),
        players: const [Player(id: 'p1', displayName: 'P1', isHuman: true)],
      );
      final engine = oecProjectorEngine();
      engine.addMoveOrder(
        'p1',
        const MoveOrder(unitId: 'u1', destinationTileKey: '$oecOw|P2|0|0'),
      );
      final effects = engine.projectedEffects(game, topology, 'p1');
      expect(effects.unitLocations, isNotNull);
      expect(effects.unitLocations!['u1'], '$oecOw|P2');

    case OrderEngineCoreTarget.projectedEffectsNoGameMutation:
      final topology = oecSingleProvinceTopology();
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
          oldWorld: RegionData(
            provinces: [
              Province(id: '$oecOw|P1', regionId: oecOw, ownerId: 'p1'),
            ],
            units: [],
          ),
          newWorld: const RegionData(),
        ),
        players: const [Player(id: 'p1', displayName: 'P1', isHuman: true)],
      );
      final turnBefore = game.worldState.turnState.turnNumber;
      final engine = oecProjectorEngine();
      engine.projectedEffects(game, topology, 'p1');
      expect(game.worldState.turnState.turnNumber, turnBefore);

    case OrderEngineCoreTarget.addMoveOrderWithContextValidation:
      final topology = oecTwoProvinceTopology();
      final game = oecBuilderOnP1Game();
      final engine = OrderEngine();
      final ok = engine.addMoveOrderWithContext(
        game,
        topology,
        'p1',
        const MoveOrder(unitId: 'u1', destinationTileKey: 'oldWorld|P2|0|0'),
      );
      final bad = engine.addMoveOrderWithContext(
        game,
        topology,
        'p1',
        const MoveOrder(unitId: 'u999', destinationTileKey: 'oldWorld|P2|0|0'),
      );
      expect(ok.status, OrderValidationStatus.accepted);
      expect(bad.status, OrderValidationStatus.rejected);

    case OrderEngineCoreTarget.civilianCannotMoveIntoGpTerritory:
      final topology = oecTwoProvinceTopology();
      final game = oecBuilderOnP1Game(
        p2OwnerId: 'p2',
        playerVisibilityByTile: oecP1VisibleP2Fogged,
      );
      final engine = OrderEngine();
      engine.addMoveOrder(
        'p1',
        const MoveOrder(unitId: 'u1', destinationTileKey: 'oldWorld|P2|0|0'),
      );
      final results = engine.validatePlayerOrdersWithContext(
        game,
        topology,
        'p1',
      );
      expect(results.single.status, OrderValidationStatus.rejected);

    case OrderEngineCoreTarget.militaryCannotMoveIntoGpWithoutWar:
      final topology = oecTwoProvinceTopology();
      final game = oecMilitaryOnP1Game();
      final engine = OrderEngine();
      engine.addArmyMoveOrder(
        'p1',
        ArmyMoveOrder(
          armyId: fieldArmyIdFor('p1', '$oecOw|P1'),
          destinationProvinceId: '$oecOw|P2',
        ),
      );
      final results = engine.validatePlayerOrdersWithContext(
        game,
        topology,
        'p1',
      );
      expect(results.single.status, OrderValidationStatus.rejected);
      expect(results.single.reason, contains('declare war'));

    case OrderEngineCoreTarget.militaryMayMoveIntoGpWithDeclareWar:
      final topology = oecTwoProvinceTopology();
      final game = oecMilitaryOnP1Game();
      final engine = OrderEngine()
        ..addDiplomaticOrder(
          'p1',
          const DiplomaticOrder(
            type: DiplomaticOrderType.declareWar,
            targetFactionId: 'p2',
          ),
        )
        ..addArmyMoveOrder(
          'p1',
          ArmyMoveOrder(
            armyId: fieldArmyIdFor('p1', '$oecOw|P1'),
            destinationProvinceId: '$oecOw|P2',
          ),
        );
      final results = engine.validatePlayerOrdersWithContext(
        game,
        topology,
        'p1',
      );
      expect(results.length, 2);
      expect(
        results.every((r) => r.status == OrderValidationStatus.accepted),
        isTrue,
      );

    case OrderEngineCoreTarget.explorerMayMoveIntoTribalProvince:
      final topology = oecTwoProvinceTopology();
      final game = oecExplorerOnP1Game(
        p2OwnerId: 'tribe1',
        playerVisibilityByTile: oecP1VisibleP2Fogged,
        tribes: const [Tribe(id: 'tribe1', displayName: 'Tribe 1')],
      );
      final engine = OrderEngine();
      engine.addMoveOrder(
        'p1',
        const MoveOrder(unitId: 'u1', destinationTileKey: 'oldWorld|P2|0|0'),
      );
      final results = engine.validatePlayerOrdersWithContext(
        game,
        topology,
        'p1',
      );
      expect(results.single.status, OrderValidationStatus.accepted);

    case OrderEngineCoreTarget.moveRejectedWhenSourceProvinceUnknown:
      final topology = oecTwoProvinceTopology();
      final game = oecExplorerOnP1Game();
      final engine = OrderEngine();
      engine.addMoveOrder(
        'p1',
        const MoveOrder(unitId: 'u1', destinationTileKey: 'oldWorld|P2|0|0'),
      );
      final results = engine.validatePlayerOrdersWithContext(
        game,
        topology,
        'p1',
      );
      expect(results.length, 1);
      expect(results[0].status, OrderValidationStatus.rejected);
      expect(results[0].reason, contains('visible'));
  }
}
