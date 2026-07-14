import 'package:colonizethis_economy_test_support/colonizethis_economy_test_support.dart';

void main() {
  runLabeledScenarioGroup(
    'overseasShippedTonnageFromExtractionTotals',
    overseasShippedTonnageScenarios(),
    runOverseasShippedTonnageScenario,
    labelOf: (s) => s.label,
  );

  runLabeledScenarioGroup(
    'tradeCargoCapacityForGreatPower',
    tradeCargoCapacityForGreatPowerScenarios(),
    runTradeCargoCapacityForGreatPowerScenario,
    labelOf: (s) => s.label,
  );

  runLabeledScenarioGroup(
    'extractionById bypass (Refs #3517 Cluster 4)',
    extractionByIdBypassScenarios(),
    runExtractionByIdBypassScenario,
    labelOf: (s) => s.label,
  );
}
