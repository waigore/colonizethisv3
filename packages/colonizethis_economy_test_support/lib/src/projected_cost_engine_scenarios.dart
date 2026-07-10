// Table-driven projected cost engine scenarios (Refs #3939 phase 3 slice 35).

import 'projected_cost_engine_expectations.dart';
import 'scenario_runner.dart';

/// One row in [projectedCostEngineWorkMaterialScenarios].
class ProjectedCostEngineWorkMaterialScenario implements RefsScenario {
  const ProjectedCostEngineWorkMaterialScenario({
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

/// One row in [projectedCostEngineBuildScenarios].
class ProjectedCostEngineBuildScenario implements RefsScenario {
  const ProjectedCostEngineBuildScenario({
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
        label:
            'delegates applyBuildOrderCostDeduction to applyBuildCostDeduction',
      ),
    ];
