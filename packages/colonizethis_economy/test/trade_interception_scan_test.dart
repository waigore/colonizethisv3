import 'package:colonizethis_test/test.dart';

import 'package:colonizethis_economy_test_support/colonizethis_economy_test_support.dart';

void main() {
  setUp(resetTradeInterceptionScanFleetSeq);

  runLabeledScenarioGroup(
    'scanTradeInterceptionInputs',
    tradeInterceptionScanScenarios(),
    runTradeInterceptionScanScenario,
  );
}
