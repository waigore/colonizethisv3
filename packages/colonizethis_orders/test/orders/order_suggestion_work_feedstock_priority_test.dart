// Consolidated feedstock-priority build_improvement suggestion runner (Refs #3949).
//
// Migrated from imperative `test()` bodies to table-driven scenarios in support/.

import 'package:colonizethis_test/test.dart';

import 'support/scenario_runner.dart';
import 'support/suggestion/order_suggestion_work_feedstock_priority_scenarios.dart';

void main() {
  group('suggestWorkOrders feedstock-extraction build_improvement priority '
      '(Refs #2847 H8-extraction)', () {
    runLabeledScenarios(
      orderSuggestionWorkFeedstockPriorityExtractionScenarios(),
      runRunnableScenario,
    );
  });

  group('suggestWorkOrders feedstock co-availability ordering '
      '(Refs #2847 H8-extraction feedstock co-availability)', () {
    runLabeledScenarios(
      orderSuggestionWorkFeedstockCoAvailScenarios(),
      runRunnableScenario,
    );
  });
}
