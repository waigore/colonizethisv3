// Table-driven OrderEngine core scenarios (Refs #3949 wave 3).

import '../scenario_runner.dart';
import 'order_engine_core_expectations.dart';

/// One row in [orderEngineCoreScenarios].
class OrderEngineCoreScenario implements RefsScenario {
  const OrderEngineCoreScenario({
    required this.label,
    required this.target,
    this.refs,
  });

  @override
  final String label;
  final OrderEngineCoreTarget target;
  @override
  final String? refs;
}

void runOrderEngineCoreScenario(OrderEngineCoreScenario scenario) {
  runOrderEngineCoreExpectation(scenario.target);
}

/// Canonical scenarios for OrderEngine core family tests.
/// Labels must match wave-3 [DESCRIPTION_BASELINE.txt] entries and former
/// `order_engine_core_part*_test.dart` descriptions (single-line `label:` for CI).
List<OrderEngineCoreScenario> orderEngineCoreScenarios() => const [
      OrderEngineCoreScenario(
        label: 'add order and validate',
        target: OrderEngineCoreTarget.addOrderAndValidate,
      ),
      OrderEngineCoreScenario(
        label: 'removeMoveOrder removes order at index',
        target: OrderEngineCoreTarget.removeMoveOrderAtIndex,
      ),
      OrderEngineCoreScenario(
        label: 'removeBuildOrder removes order at index',
        target: OrderEngineCoreTarget.removeBuildOrderAtIndex,
      ),
      OrderEngineCoreScenario(
        label: 'addWorkOrderWithContext returns rejected when order invalid',
        target: OrderEngineCoreTarget.addWorkOrderWithContextRejected,
      ),
      OrderEngineCoreScenario(
        label: 'first invalid order plus subsequent rejected',
        target: OrderEngineCoreTarget.firstInvalidPlusSubsequentRejected,
      ),
      OrderEngineCoreScenario(
        label: 'projected effects returns worker count',
        target: OrderEngineCoreTarget.projectedEffectsWorkerCount,
      ),
      OrderEngineCoreScenario(
        label:
            'projectedEffects returns unitLocations when engine has move order',
        target: OrderEngineCoreTarget.projectedEffectsUnitLocations,
      ),
      OrderEngineCoreScenario(
        label: 'projectedEffects does not mutate passed-in game',
        target: OrderEngineCoreTarget.projectedEffectsNoGameMutation,
      ),
      OrderEngineCoreScenario(
        label: 'addMoveOrderWithContext uses world-state validation',
        target: OrderEngineCoreTarget.addMoveOrderWithContextValidation,
      ),
      OrderEngineCoreScenario(
        label: 'civilian cannot move into other GP territory',
        target: OrderEngineCoreTarget.civilianCannotMoveIntoGpTerritory,
      ),
      OrderEngineCoreScenario(
        label: 'military cannot move into other GP province without war',
        target: OrderEngineCoreTarget.militaryCannotMoveIntoGpWithoutWar,
        refs: '#943',
      ),
      OrderEngineCoreScenario(
        label:
            'military may move into other GP province with same-turn declareWar',
        target: OrderEngineCoreTarget.militaryMayMoveIntoGpWithDeclareWar,
      ),
      OrderEngineCoreScenario(
        label: 'explorer may move into tribal province',
        target: OrderEngineCoreTarget.explorerMayMoveIntoTribalProvince,
      ),
      OrderEngineCoreScenario(
        label: 'move order rejected when source province unknown',
        target: OrderEngineCoreTarget.moveRejectedWhenSourceProvinceUnknown,
      ),
    ];
