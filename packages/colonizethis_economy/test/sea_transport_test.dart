import 'package:colonizethis_economy_test_support/colonizethis_economy_test_support.dart';

void main() {
  runLabeledScenarioGroup(
    'cargoHoldsForHomeFleet',
    cargoHoldsForHomeFleetScenarios(),
    runCargoHoldsForHomeFleetScenario,
  );

  runLabeledScenarioGroup(
    'SeaTransport allocateOverseasToStockpile',
    allocateOverseasToStockpileScenarios(),
    runAllocateOverseasToStockpileScenario,
  );
}
