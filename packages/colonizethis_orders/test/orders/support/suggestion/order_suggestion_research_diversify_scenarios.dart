// Table-driven research diversification scenarios (Refs #3949 wave 3).

import '../scenario_runner.dart';
import 'order_suggestion_research_diversify_expectations.dart';

/// One row in [orderSuggestionResearchDiversifyScenarios].
class OrderSuggestionResearchDiversifyScenario implements RefsScenario {
  const OrderSuggestionResearchDiversifyScenario({
    required this.label,
    required this.target,
    this.refs,
  });

  @override
  final String label;
  final OrderSuggestionResearchDiversifyTarget target;
  @override
  final String? refs;
}

void runOrderSuggestionResearchDiversifyScenario(
  OrderSuggestionResearchDiversifyScenario scenario,
) {
  runOrderSuggestionResearchDiversifyExpectation(scenario.target);
}

List<OrderSuggestionResearchDiversifyScenario>
    orderSuggestionResearchDiversifyScenarios() => const [
          OrderSuggestionResearchDiversifyScenario(
            label: 'slot 1 takes the highest-weight unrepresented bucket (AC9)',
            target: OrderSuggestionResearchDiversifyTarget
                .slot1TakesHighestWeightUnrepresentedBucket,
            refs: '#3472 AC9',
          ),
          OrderSuggestionResearchDiversifyScenario(
            label: 'weight 0 is identical to the greedy default (negative control)',
            target:
                OrderSuggestionResearchDiversifyTarget.weightZeroMatchesGreedyDefault,
            refs: '#3472',
          ),
        ];
