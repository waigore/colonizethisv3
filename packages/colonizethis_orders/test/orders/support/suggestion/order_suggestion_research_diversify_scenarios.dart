// Table-driven research diversification scenarios (Refs #3949 wave 3).

import '../scenario_runner.dart';
import 'order_suggestion_research_diversify_run_rows.dart';

/// One row in [orderSuggestionResearchDiversifyScenarios].
class OrderSuggestionResearchDiversifyScenario implements RefsScenario {
  const OrderSuggestionResearchDiversifyScenario({
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

void runOrderSuggestionResearchDiversifyScenario(
  OrderSuggestionResearchDiversifyScenario scenario,
) {
  scenario.run();
}

List<OrderSuggestionResearchDiversifyScenario>
orderSuggestionResearchDiversifyScenarios() => const [
  OrderSuggestionResearchDiversifyScenario(
    label: 'slot 1 takes the highest-weight unrepresented bucket (AC9)',
    run: osrdRunSlot1TakesHighestWeightUnrepresentedBucket,
    refs: '#3472 AC9',
  ),
  OrderSuggestionResearchDiversifyScenario(
    label: 'weight 0 is identical to the greedy default (negative control)',
    run: osrdRunWeightZeroMatchesGreedyDefault,
    refs: '#3472',
  ),
];
