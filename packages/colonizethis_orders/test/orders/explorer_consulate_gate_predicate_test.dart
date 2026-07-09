// Consolidated explorer Consulate-gate predicate runner (Refs #3949 wave 3).
//
// Migrated from imperative `test()` bodies to table-driven scenarios in support/.
// Refs #3753 R4/R4b: shared Explorer Consulate-gate predicate for order-engine
// submission gate and province-overlay disabled Explore/Prospect tooltip.

import 'support/scenario_runner.dart';
import 'support/engine/explorer_consulate_gate_predicate_scenarios.dart';

void main() {
  runLabeledScenarioGroup(
    'explorerConsulateGateBlocksMinorTribeProvince',
    explorerConsulateGatePredicateScenarios(),
    runExplorerConsulateGatePredicateScenario,
  );
}
