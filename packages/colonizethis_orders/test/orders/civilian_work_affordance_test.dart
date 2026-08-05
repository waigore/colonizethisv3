import 'support/civilian_work_affordance_scenarios.dart';
import 'support/scenario_runner.dart';

void main() {
  runLabeledScenarioGroup(
    'civilian_work_affordance',
    civilianWorkAffordanceScenarios(),
    runRunnableScenario,
  );
}
