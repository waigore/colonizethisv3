// Table-driven projected cost engine scenarios (Refs #3939 phase 3 slice 35).

import 'projected_cost_engine_expectations.dart';

/// One row in [projectedCostEngineWorkMaterialScenarios] (Refs #3939 slice 64).
typedef ProjectedCostEngineWorkMaterialScenario = ({
  String label,
  void Function() run,
  String? refs,
});

void runProjectedCostEngineWorkMaterialScenario(
  ProjectedCostEngineWorkMaterialScenario scenario,
) {
  scenario.run();
}

/// Canonical scenarios for ProjectedCostEngine work-material helpers.
List<ProjectedCostEngineWorkMaterialScenario>
projectedCostEngineWorkMaterialScenarios() => [
  workMaterialAffordScenario(
    label: 'canAffordWorkMaterialCost is false when any commodity is short',
    pins: (
      stockpileDeltas: {'lumber': 1},
      cost: {'lumber': 2},
      expectedAfford: false,
    ),
  ),
  workMaterialDeductScenario(
    label: 'deductWorkMaterialCost reduces quantities',
    pins: (
      stockpileDeltas: {'lumber': 5, 'cast_iron': 3},
      cost: {'lumber': 2, 'cast_iron': 1},
      expectedQuantities: {'lumber': 3, 'cast_iron': 2},
    ),
  ),
];

/// One row in [projectedCostEngineBuildScenarios] (Refs #3939 slice 64).
typedef ProjectedCostEngineBuildScenario = ({
  String label,
  void Function() run,
  String? refs,
});

void runProjectedCostEngineBuildScenario(
  ProjectedCostEngineBuildScenario scenario,
) {
  scenario.run();
}

/// Canonical scenarios for ProjectedCostEngine build delegation.
List<ProjectedCostEngineBuildScenario> projectedCostEngineBuildScenarios() => [
  buildAffordDelegationScenario(
    label: 'delegates canAffordBuildOrder to build_cost canAffordBuild',
  ),
  buildApplyDeductionDelegationScenario(
    label: 'delegates applyBuildOrderCostDeduction to applyBuildCostDeduction',
  ),
];
