// Table-driven OrderEngine core scenarios (Refs #3949 wave 3).

import '../scenario_runner.dart';
import 'order_engine_core_run_rows.dart';

/// One row in [orderEngineCoreScenarios].
class OrderEngineCoreScenario implements RefsScenario {
  const OrderEngineCoreScenario({
    required this.label,
    required this.run,
    this.refs,
  });

  @override
  final String label;
  final void Function() run;
  @override
  final String? refs;
}

void runOrderEngineCoreScenario(OrderEngineCoreScenario scenario) =>
    scenario.run();

/// Canonical scenarios for OrderEngine core family tests.
/// Labels must match wave-3 [DESCRIPTION_BASELINE.txt] entries and former
/// `order_engine_core_part*_test.dart` descriptions (single-line `label:` for CI).
List<OrderEngineCoreScenario> orderEngineCoreScenarios() => [
      OrderEngineCoreScenario(
        label: 'add order and validate',
        run: oecRunAddOrderAndValidate,
      ),
      OrderEngineCoreScenario(
        label: 'removeMoveOrder removes order at index',
        run: oecRunRemoveMoveOrderAtIndex,
      ),
      OrderEngineCoreScenario(
        label: 'removeBuildOrder removes order at index',
        run: oecRunRemoveBuildOrderAtIndex,
      ),
      OrderEngineCoreScenario(
        label: 'addWorkOrderWithContext returns rejected when order invalid',
        run: oecRunAddWorkOrderWithContextRejected,
      ),
      OrderEngineCoreScenario(
        label: 'first invalid order plus subsequent rejected',
        run: oecRunFirstInvalidPlusSubsequentRejected,
      ),
      OrderEngineCoreScenario(
        label: 'projected effects returns worker count',
        run: oecRunProjectedEffectsWorkerCount,
      ),
      OrderEngineCoreScenario(
        label:
            'projectedEffects returns unitLocations when engine has move order',
        run: oecRunProjectedEffectsUnitLocations,
      ),
      OrderEngineCoreScenario(
        label: 'projectedEffects does not mutate passed-in game',
        run: oecRunProjectedEffectsNoGameMutation,
      ),
      OrderEngineCoreScenario(
        label: 'addMoveOrderWithContext uses world-state validation',
        run: oecRunAddMoveOrderWithContextValidation,
      ),
      OrderEngineCoreScenario(
        label: 'civilian cannot move into other GP territory',
        run: oecRunCivilianCannotMoveIntoGpTerritory,
      ),
      OrderEngineCoreScenario(
        label: 'military cannot move into other GP province without war',
        run: oecRunMilitaryCannotMoveIntoGpWithoutWar,
        refs: '#943',
      ),
      OrderEngineCoreScenario(
        label:
            'military may move into other GP province with same-turn declareWar',
        run: oecRunMilitaryMayMoveIntoGpWithDeclareWar,
      ),
      OrderEngineCoreScenario(
        label: 'explorer may move into tribal province',
        run: oecRunExplorerMayMoveIntoTribalProvince,
      ),
      OrderEngineCoreScenario(
        label: 'move order rejected when source province unknown',
        run: oecRunMoveRejectedWhenSourceProvinceUnknown,
      ),
    ];
