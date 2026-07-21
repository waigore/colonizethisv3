// Table-driven projected cost engine scenarios (Refs #3939 phase 3 slice 35, #3979).

/// Discriminator for work-material scenario rows (Refs #3979).
enum ProjectedCostWorkMaterialKind { afford, deduct }

/// Pins for work-material affordability rows.
typedef WorkMaterialAffordPins = ({Map<String, int> stockpileDeltas, Map<String, int> cost, bool expectedAfford});

ProjectedCostEngineWorkMaterialScenario workMaterialAffordScenario({required String label, required WorkMaterialAffordPins pins}) => (label: label, kind: ProjectedCostWorkMaterialKind.afford, affordPins: pins, deductPins: null, refs: null);

/// Pins for work-material deduction rows.
typedef WorkMaterialDeductPins = ({Map<String, int> stockpileDeltas, Map<String, int> cost, Map<String, int> expectedQuantities});

ProjectedCostEngineWorkMaterialScenario workMaterialDeductScenario({required String label, required WorkMaterialDeductPins pins}) => (label: label, kind: ProjectedCostWorkMaterialKind.deduct, affordPins: null, deductPins: pins, refs: null);

/// One row in [projectedCostEngineWorkMaterialScenarios] (Refs #3979).
typedef ProjectedCostEngineWorkMaterialScenario = ({
  String label,
  ProjectedCostWorkMaterialKind kind,
  WorkMaterialAffordPins? affordPins,
  WorkMaterialDeductPins? deductPins,
  String? refs,
});

/// Canonical scenarios for ProjectedCostEngine work-material helpers.
// dart format off
List<ProjectedCostEngineWorkMaterialScenario> projectedCostEngineWorkMaterialScenarios() => [
  workMaterialAffordScenario(label: 'canAffordWorkMaterialCost is false when any commodity is short', pins: (stockpileDeltas: {'lumber': 1}, cost: {'lumber': 2}, expectedAfford: false)),
  workMaterialDeductScenario(
    label: 'deductWorkMaterialCost reduces quantities',
    pins: (stockpileDeltas: {'lumber': 5, 'cast_iron': 3}, cost: {'lumber': 2, 'cast_iron': 1}, expectedQuantities: {'lumber': 3, 'cast_iron': 2}),
  ),
];

/// Discriminator for build-delegation scenario rows (Refs #3979).
enum ProjectedCostBuildTarget { affordDelegation, applyDeductionDelegation }

ProjectedCostEngineBuildScenario buildAffordDelegationScenario({required String label}) => (label: label, target: ProjectedCostBuildTarget.affordDelegation, refs: null);

ProjectedCostEngineBuildScenario buildApplyDeductionDelegationScenario({required String label}) => (label: label, target: ProjectedCostBuildTarget.applyDeductionDelegation, refs: null);

/// One row in [projectedCostEngineBuildScenarios] (Refs #3979).
typedef ProjectedCostEngineBuildScenario = ({String label, ProjectedCostBuildTarget target, String? refs});

/// Canonical scenarios for ProjectedCostEngine build delegation.
List<ProjectedCostEngineBuildScenario> projectedCostEngineBuildScenarios() => [
  buildAffordDelegationScenario(label: 'delegates canAffordBuildOrder to build_cost canAffordBuild'),
  buildApplyDeductionDelegationScenario(label: 'delegates applyBuildOrderCostDeduction to applyBuildCostDeduction'),
];
// dart format on
