import 'package:colonizethis_economy_test_support/colonizethis_economy_test_support.dart';

void main() {
  runLabeledScenarioGroup(
    'overseasShippedTonnageFromExtractionTotals',
    overseasShippedTonnageScenarios(),
    runOverseasShippedTonnageScenario,
  );

  runLabeledScenarioGroup(
    'tradeCargoCapacityForGreatPower',
    tradeCargoCapacityForGreatPowerScenarios(),
    runTradeCargoCapacityForGreatPowerScenario,
  );

  runLabeledScenarioGroup(
    'extractionById bypass (Refs #3517 Cluster 4)',
    extractionByIdBypassScenarios(),
    runExtractionByIdBypassScenario,
  );
}
