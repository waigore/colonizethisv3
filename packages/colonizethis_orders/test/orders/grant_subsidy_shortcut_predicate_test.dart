// MAP20001 Political Grant Aid / Set Subsidy visibility predicate (Refs #4761).

import 'support/scenario_runner.dart';
import 'support/engine/grant_subsidy_shortcut_predicate_scenarios.dart';

void main() {
  runLabeledScenarioGroup(
    'grantSubsidyShortcutAppliesToMinorTribeProvince',
    grantSubsidyShortcutPredicateScenarios(),
    runRunnableScenario,
  );
}
