import 'package:colonizethis_economy_test_support/colonizethis_economy_test_support.dart';

void main() {
  runLabeledScenarioGroup(
    'applyTradeInterception',
    applyTradeInterceptionScenarios(),
    runApplyTradeInterceptionScenario,
  );
}
