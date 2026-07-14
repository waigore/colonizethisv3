// Table-driven projected cost engine scenarios (Refs #3939 phase 3 slice 35, #3979).
import 'projected_cost_engine_expectations.dart';
/// One row in [projectedCostEngineWorkMaterialScenarios] (Refs #3979).
typedef ProjectedCostEngineWorkMaterialScenario = ({
  String label,
  ProjectedCostWorkMaterialKind kind,
  WorkMaterialAffordPins? affordPins,
  WorkMaterialDeductPins? deductPins,
  String? refs,
});
void runProjectedCostEngineWorkMaterialScenario(
  ProjectedCostEngineWorkMaterialScenario scenario,
) {
  switch (scenario.kind) {
    case ProjectedCostWorkMaterialKind.afford:
      runWorkMaterialAffordExpectation(scenario.affordPins!);
    case ProjectedCostWorkMaterialKind.deduct:
      runWorkMaterialDeductExpectation(scenario.deductPins!);
  }
}
/// Canonical scenarios for ProjectedCostEngine work-material helpers.
// dart format off
List<ProjectedCostEngineWorkMaterialScenario> projectedCostEngineWorkMaterialScenarios() => [
  workMaterialAffordScenario(label: 'canAffordWorkMaterialCost is false when any commodity is short', pins: (stockpileDeltas: {'lumber': 1}, cost: {'lumber': 2}, expectedAfford: false)),
  workMaterialDeductScenario(
    label: 'deductWorkMaterialCost reduces quantities',
    pins: (stockpileDeltas: {'lumber': 5, 'cast_iron': 3}, cost: {'lumber': 2, 'cast_iron': 1}, expectedQuantities: {'lumber': 3, 'cast_iron': 2}),
  ),
];
/// One row in [projectedCostEngineBuildScenarios] (Refs #3979).
typedef ProjectedCostEngineBuildScenario = ({String label, ProjectedCostBuildTarget target, String? refs});
void runProjectedCostEngineBuildScenario(ProjectedCostEngineBuildScenario scenario) {
  runProjectedCostBuildExpectation(scenario.target);
}
/// Canonical scenarios for ProjectedCostEngine build delegation.
List<ProjectedCostEngineBuildScenario> projectedCostEngineBuildScenarios() => [
  buildAffordDelegationScenario(label: 'delegates canAffordBuildOrder to build_cost canAffordBuild'),
  buildApplyDeductionDelegationScenario(label: 'delegates applyBuildOrderCostDeduction to applyBuildCostDeduction'),
];
// dart format on
