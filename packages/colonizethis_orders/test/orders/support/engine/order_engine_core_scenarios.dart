// Table-driven OrderEngine core scenarios (Refs #3949 wave 3).

import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';
import '../scenario_runner.dart';
import 'order_engine_core_fixtures.dart';

void oecRunAddOrderAndValidate() {
  final engine = OrderEngine();
  final result = engine.addMoveOrder(
    'p1',
    const MoveOrder(unitId: 'u1', destinationTileKey: 'oldWorld|P2|0|0'),
  );
  expect(result.status, OrderValidationStatus.accepted);
  expect(engine.orders.moveOrdersByPlayerId['p1']?.length, 1);
}

void oecRunRemoveMoveOrderAtIndex() {
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
}

void oecRunRemoveBuildOrderAtIndex() {
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
}

void oecRunAddWorkOrderWithContextRejected() {
  final topology = oecSingleProvinceTopology();
  final game = Game(
    id: 'g1',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
      oldWorld: RegionData(
        provinces: [Province(id: '$oecOw|P1', regionId: oecOw, ownerId: 'p1')],
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
}

void oecRunFirstInvalidPlusSubsequentRejected() {
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
  final results = engine.validatePlayerOrdersWithContext(game, topology, 'p1');
  expect(results.length, 3);
  expect(results[0].status, OrderValidationStatus.accepted);
  expect(results[1].status, OrderValidationStatus.rejected);
  expect(results[2].status, OrderValidationStatus.rejected);
}

void oecRunProjectedEffectsWorkerCount() {
  final effects = oecProjectorEngine().projectedEffects(
    oecEmptyUnitsP1Game(),
    oecSingleProvinceTopology(),
    'p1',
  );
  expect(effects.workerCount, isNotNull);
}

void oecRunProjectedEffectsUnitLocations() {
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
}

void oecRunProjectedEffectsNoGameMutation() {
  final game = oecEmptyUnitsP1Game();
  final turnBefore = game.worldState.turnState.turnNumber;
  oecProjectorEngine().projectedEffects(
    game,
    oecSingleProvinceTopology(),
    'p1',
  );
  expect(game.worldState.turnState.turnNumber, turnBefore);
}

void oecRunAddMoveOrderWithContextValidation() {
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
}

void oecRunCivilianCannotMoveIntoGpTerritory() {
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
  final results = engine.validatePlayerOrdersWithContext(game, topology, 'p1');
  expect(results.single.status, OrderValidationStatus.rejected);
}

void oecRunMilitaryCannotMoveIntoGpWithoutWar() {
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
  final results = engine.validatePlayerOrdersWithContext(game, topology, 'p1');
  expect(results.single.status, OrderValidationStatus.rejected);
  expect(results.single.reason, contains('declare war'));
}

void oecRunMilitaryMayMoveIntoGpWithDeclareWar() {
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
  final results = engine.validatePlayerOrdersWithContext(game, topology, 'p1');
  expect(results.length, 2);
  expect(
    results.every((r) => r.status == OrderValidationStatus.accepted),
    isTrue,
  );
}

void oecRunExplorerMayMoveIntoTribalProvince() {
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
  final results = engine.validatePlayerOrdersWithContext(game, topology, 'p1');
  expect(results.single.status, OrderValidationStatus.accepted);
}

void oecRunMoveRejectedWhenSourceProvinceUnknown() {
  final topology = oecTwoProvinceTopology();
  final game = oecExplorerOnP1Game();
  final engine = OrderEngine();
  engine.addMoveOrder(
    'p1',
    const MoveOrder(unitId: 'u1', destinationTileKey: 'oldWorld|P2|0|0'),
  );
  final results = engine.validatePlayerOrdersWithContext(game, topology, 'p1');
  expect(results.length, 1);
  expect(results[0].status, OrderValidationStatus.rejected);
  expect(results[0].reason, contains('visible'));
}

List<RunnableScenario> orderEngineCoreScenarios() => [
  RunnableScenario(
    label: 'add order and validate',
    run: oecRunAddOrderAndValidate,
  ),
  RunnableScenario(
    label: 'removeMoveOrder removes order at index',
    run: oecRunRemoveMoveOrderAtIndex,
  ),
  RunnableScenario(
    label: 'removeBuildOrder removes order at index',
    run: oecRunRemoveBuildOrderAtIndex,
  ),
  RunnableScenario(
    label: 'addWorkOrderWithContext returns rejected when order invalid',
    run: oecRunAddWorkOrderWithContextRejected,
  ),
  RunnableScenario(
    label: 'first invalid order plus subsequent rejected',
    run: oecRunFirstInvalidPlusSubsequentRejected,
  ),
  RunnableScenario(
    label: 'projected effects returns worker count',
    run: oecRunProjectedEffectsWorkerCount,
  ),
  RunnableScenario(
    label: 'projectedEffects returns unitLocations when engine has move order',
    run: oecRunProjectedEffectsUnitLocations,
  ),
  RunnableScenario(
    label: 'projectedEffects does not mutate passed-in game',
    run: oecRunProjectedEffectsNoGameMutation,
  ),
  RunnableScenario(
    label: 'addMoveOrderWithContext uses world-state validation',
    run: oecRunAddMoveOrderWithContextValidation,
  ),
  RunnableScenario(
    label: 'civilian cannot move into other GP territory',
    run: oecRunCivilianCannotMoveIntoGpTerritory,
  ),
  RunnableScenario(
    label: 'military cannot move into other GP province without war',
    run: oecRunMilitaryCannotMoveIntoGpWithoutWar,
    refs: '#943',
  ),
  RunnableScenario(
    label: 'military may move into other GP province with same-turn declareWar',
    run: oecRunMilitaryMayMoveIntoGpWithDeclareWar,
  ),
  RunnableScenario(
    label: 'explorer may move into tribal province',
    run: oecRunExplorerMayMoveIntoTribalProvince,
  ),
  RunnableScenario(
    label: 'move order rejected when source province unknown',
    run: oecRunMoveRejectedWhenSourceProvinceUnknown,
  ),
];
