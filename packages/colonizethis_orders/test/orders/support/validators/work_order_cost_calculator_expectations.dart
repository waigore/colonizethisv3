// Compact WorkOrderCostCalculator assertions (Refs #3949 wave 3).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_orders/src/orders/validators/work_order_cost_calculator.dart';
import 'package:colonizethis_test/test.dart';

/// Pins for [workOrderCostCalculatorScenarios] rows.
enum WorkOrderCostCalculatorTarget {
  nullCostForCounterSpyAndPurchaseLand,
  buildImprovementCostMap,
  buildFortUsesProvinceFortLevel,
}

void runWorkOrderCostCalculatorExpectation(
  WorkOrderCostCalculatorTarget target,
) {
  switch (target) {
    case WorkOrderCostCalculatorTarget.nullCostForCounterSpyAndPurchaseLand:
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
          oldWorld: const RegionData(),
          newWorld: const RegionData(),
        ),
        players: const [],
      );
      final calc = WorkOrderCostCalculator(game);
      expect(
        calc.calculateCost(kWorkTargetCounterSpy, 'oldWorld|P1|0|0'),
        isNull,
      );
      expect(
        calc.calculateCost(kWorkTargetPurchaseLand, 'oldWorld|P1|0|0'),
        isNull,
      );

    case WorkOrderCostCalculatorTarget.buildImprovementCostMap:
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
          oldWorld: RegionData(
            provinces: [
              Province(id: 'oldWorld|P1', regionId: 'oldWorld', ownerId: 'p1'),
            ],
            units: [],
          ),
          newWorld: const RegionData(),
        ),
        players: const [Player(id: 'p1', displayName: 'P1', isHuman: true)],
      );
      final calc = WorkOrderCostCalculator(game);
      final cost = calc.calculateCost(
        kWorkTargetBuildImprovement,
        'oldWorld|P1|0|0',
        improvementLevel: 0,
      );
      expect(cost, isNotNull);
      expect(cost!.length, 2);
      expect(cost[CommodityCatalog.lumber.id], 1);
      expect(cost[CommodityCatalog.castIron.id], 1);

    case WorkOrderCostCalculatorTarget.buildFortUsesProvinceFortLevel:
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
          oldWorld: RegionData(
            provinces: [
              Province(
                id: 'oldWorld|P1',
                regionId: 'oldWorld',
                ownerId: 'p1',
                fortLevel: 1,
              ),
            ],
            units: [],
          ),
          newWorld: const RegionData(),
        ),
        players: const [Player(id: 'p1', displayName: 'P1', isHuman: true)],
      );
      final calc = WorkOrderCostCalculator(game);
      final cost = calc.calculateCost(kWorkTargetBuildFort, 'oldWorld|P1|0|0');
      expect(cost, isNotNull);
      expect(cost![CommodityCatalog.lumber.id], 4);
      expect(cost[CommodityCatalog.bronze.id], 4);
  }
}
