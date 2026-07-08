import 'package:colonizethis_economy_test_support/colonizethis_economy_test_support.dart';

void main() {
  runLabeledScenarioGroup(
    'ProjectedCostEngine work material',
    projectedCostEngineWorkMaterialScenarios(),
    runProjectedCostEngineWorkMaterialScenario,
  );

  runLabeledScenarioGroup(
    'ProjectedCostEngine build',
    projectedCostEngineBuildScenarios(),
    runProjectedCostEngineBuildScenario,
  );
}
