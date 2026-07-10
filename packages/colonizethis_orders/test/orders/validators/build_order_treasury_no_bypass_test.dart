// Consolidated build-order treasury no-bypass guard runner (Refs #3949 wave 3).
//
// Affordability regression guard + human-player guard (Refs #2924).
// Migrated from imperative `test()` bodies to table-driven scenarios in support/.

import 'package:colonizethis_test/test.dart';

import '../support/scenario_runner.dart';
import '../support/validators/build_order_treasury_no_bypass_scenarios.dart';

void main() {
  suppressLogsForTests();

  runLabeledScenarioGroup(
    'Refs #2924 regiment build affordability no-bypass guard',
    buildOrderTreasuryNoBypassScenarios(),
    runRunnableScenario,
  );
}
