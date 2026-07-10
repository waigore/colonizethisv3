// Table-driven pending-riches build suggestion scenarios (Refs #3949 wave 3).

import '../scenario_runner.dart';
import 'order_suggestion_build_pending_riches_expectations.dart';

/// One row in pending-riches build suggestion scenario tables.
class OrderSuggestionBuildPendingRichesScenario implements RefsScenario {
  const OrderSuggestionBuildPendingRichesScenario({
    required this.label,
    required this.target,
    this.refs,
  });

  @override
  final String label;
  final OrderSuggestionBuildPendingRichesTarget target;
  @override
  final String? refs;
}

void runOrderSuggestionBuildPendingRichesScenario(
  OrderSuggestionBuildPendingRichesScenario scenario,
) {
  runOrderSuggestionBuildPendingRichesExpectation(scenario.target);
}

/// Scenarios for suggestBuildOrders pending riches treasury (Refs #2509).
List<OrderSuggestionBuildPendingRichesScenario>
    suggestBuildOrdersPendingRichesTreasuryScenarios() => const [
          OrderSuggestionBuildPendingRichesScenario(
            label: 'accepts peasant_levies when treasury is zero but stockpile has spices',
            target: OrderSuggestionBuildPendingRichesTarget
                .acceptsPeasantLeviesWithRichesStockpile,
            refs: '#2509',
          ),
          OrderSuggestionBuildPendingRichesScenario(
            label: 'incremental build probe matches full-pass when riches fund build',
            target:
                OrderSuggestionBuildPendingRichesTarget.incrementalProbeMatchesFullPass,
            refs: '#2509',
          ),
        ];
