// Table-driven pending-riches build suggestion scenarios (Refs #3949 wave 3).

import '../scenario_runner.dart';
import 'order_suggestion_build_pending_riches_run_rows.dart';

/// One row in pending-riches build suggestion scenario tables.
class OrderSuggestionBuildPendingRichesScenario implements RefsScenario {
  const OrderSuggestionBuildPendingRichesScenario({
    required this.label,
    required this.run,
    this.refs,
  });

  @override
  final String label;
  final void Function() run;
  @override
  final String? refs;
}

void runOrderSuggestionBuildPendingRichesScenario(
  OrderSuggestionBuildPendingRichesScenario scenario,
) {
  scenario.run();
}

/// Scenarios for suggestBuildOrders pending riches treasury (Refs #2509).
List<OrderSuggestionBuildPendingRichesScenario>
suggestBuildOrdersPendingRichesTreasuryScenarios() => const [
  OrderSuggestionBuildPendingRichesScenario(
    label:
        'accepts peasant_levies when treasury is zero but stockpile has spices',
    run: osbprRunAcceptsPeasantLeviesWithRichesStockpile,
    refs: '#2509',
  ),
  OrderSuggestionBuildPendingRichesScenario(
    label: 'incremental build probe matches full-pass when riches fund build',
    run: osbprRunIncrementalProbeMatchesFullPass,
    refs: '#2509',
  ),
];
