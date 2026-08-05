// Consolidated order suggestion pass context runner (Refs #3949 wave 3).
//
// Migrated from imperative `test()` bodies to table-driven scenarios in support/.

import 'support/scenario_runner.dart';
import 'support/suggestion/order_suggestion_pass_context_scenarios.dart';

void main() {
  runLabeledScenarioGroup(
    'indexExistingTargetsByEntityId',
    indexExistingTargetsByEntityIdScenarios(),
    runRunnableScenario,
  );
  runLabeledScenarioGroup(
    'emitAcceptedCandidates',
    emitAcceptedCandidatesScenarios(),
    runRunnableScenario,
  );
  runLabeledScenarioGroup(
    'runCappedSuggestionProbeLoop',
    runCappedSuggestionProbeLoopScenarios(),
    runRunnableScenario,
  );
  runLabeledScenarioGroup(
    'ownedProvinceIdsFromView',
    ownedProvinceIdsFromViewScenarios(),
    runRunnableScenario,
  );
  runLabeledScenarioGroup(
    'ownedProvinceIdsForPlayer',
    ownedProvinceIdsForPlayerScenarios(),
    runRunnableScenario,
  );
}
