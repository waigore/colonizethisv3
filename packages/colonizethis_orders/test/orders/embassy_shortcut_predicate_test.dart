// MAP20001 Political Embassy shortcut visibility predicate (Refs #4739).

import 'support/scenario_runner.dart';
import 'support/engine/embassy_shortcut_predicate_scenarios.dart';

void main() {
  runLabeledScenarioGroup(
    'embassyShortcutAppliesToMinorTribeProvince',
    embassyShortcutPredicateScenarios(),
    runRunnableScenario,
  );
}
