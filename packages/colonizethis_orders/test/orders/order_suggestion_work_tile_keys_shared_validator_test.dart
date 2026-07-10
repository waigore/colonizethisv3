// Consolidated work-tile-keys shared-validator runner (Refs #3949 wave 3).

import 'package:colonizethis_test/test.dart';

import 'support/scenario_runner.dart';
import 'support/suggestion/order_suggestion_work_tile_keys_shared_validator_scenarios.dart';

void main() {
  suppressLogsForTests();

  runLabeledScenarioGroup(
    'getValidWorkOrderTileKeysWithVisibility shared validator',
    orderSuggestionWorkTileKeysSharedValidatorVisibilityScenarios(),
    runRunnableScenario,
  );

  runLabeledScenarioGroup(
    'getValidWorkOrderTileKeys PlayerView reuse',
    orderSuggestionWorkTileKeysSharedValidatorPlayerViewScenarios(),
    runRunnableScenario,
  );
}
