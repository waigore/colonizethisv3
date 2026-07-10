// Consolidated army-move picker destination runner (Refs #3949 wave 3).

import 'package:colonizethis_test/test.dart';

import 'support/scenario_runner.dart';
import 'support/suggestion/order_suggestion_army_move_picker_scenarios.dart';

void main() {
  suppressLogsForTests();
  runLabeledScenarioGroup(
    'armyMovePickerDestinations',
    orderSuggestionArmyMovePickerScenarios(),
    runRunnableScenario,
  );
}
