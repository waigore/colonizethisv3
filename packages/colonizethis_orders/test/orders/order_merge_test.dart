// Consolidated mergeOrderLists runner (Refs #3949 wave 3).
//
// Merges former order_merge_part{1,2}_test.dart into one ≤400-line family
// runner with scenarios in support/.


import 'support/merge/order_merge_scenarios.dart';
import 'support/scenario_runner.dart';

void main() {
  runLabeledScenarioGroup(
    'mergeOrderLists',
    orderMergeScenarios(),
    runRunnableScenario,
  );
}
