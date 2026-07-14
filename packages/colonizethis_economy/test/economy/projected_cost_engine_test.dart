import 'package:colonizethis_economy_test_support/colonizethis_economy_test_support.dart';

void main() {
  runLabeledScenarioGroup(
    'ProjectedCostEngine work material',
    projectedCostEngineWorkMaterialScenarios(),
    runProjectedCostEngineWorkMaterialScenario,
    labelOf: (s) => s.label,
  );

  runLabeledScenarioGroup(
    'ProjectedCostEngine build',
    projectedCostEngineBuildScenarios(),
    runProjectedCostEngineBuildScenario,
    labelOf: (s) => s.label,
  );
}
