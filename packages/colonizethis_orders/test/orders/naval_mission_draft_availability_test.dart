import 'support/scenario_runner.dart';
import 'support/validators/naval_mission_draft_scenarios.dart';

void main() {
  runLabeledScenarioGroup(
    'naval mission draft mutations',
    navalMissionDraftMutationScenarios(),
    runRunnableScenario,
  );
  runLabeledScenarioGroup(
    'navalMissionAvailabilityForFleet',
    navalMissionAvailabilityScenarios(),
    runRunnableScenario,
  );
}
