import 'package:colonizethis_economy_test_support/colonizethis_economy_test_support.dart';

void main() {
  runLabeledScenarioGroup(
    'cargoHoldsForHomeFleet',
    cargoHoldsForHomeFleetScenarios(),
    runCargoHoldsForHomeFleetScenario,
    labelOf: (s) => s.label,
  );

  runLabeledScenarioGroup(
    'SeaTransport allocateOverseasToStockpile',
    allocateOverseasToStockpileScenarios(),
    runAllocateOverseasToStockpileScenario,
    labelOf: (s) => s.label,
  );
}
