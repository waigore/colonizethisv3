// Table-driven OrderEngine core scenarios (Refs #3949 wave 3).

import '../scenario_runner.dart';
import 'order_engine_core_run_rows.dart';

/// Canonical scenarios for OrderEngine core family tests.
/// Labels must match wave-3 [DESCRIPTION_BASELINE.txt] entries and former
/// `order_engine_core_part*_test.dart` descriptions (single-line `label:` for CI).
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
