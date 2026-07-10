// Table-driven feedstock-priority build_improvement suggestion scenarios (Refs #3949).

import '../scenario_runner.dart';
import 'order_suggestion_work_feedstock_priority_run_rows.dart';

/// One row in [orderSuggestionWorkFeedstockPriorityExtractionScenarios].
class OrderSuggestionWorkFeedstockPriorityScenario implements RefsScenario {
  const OrderSuggestionWorkFeedstockPriorityScenario({
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

void runOrderSuggestionWorkFeedstockPriorityScenario(
  OrderSuggestionWorkFeedstockPriorityScenario scenario,
) {
  scenario.run();
}

/// Feedstock-extraction priority scenarios (Refs #2847 H8-extraction).
List<OrderSuggestionWorkFeedstockPriorityScenario>
orderSuggestionWorkFeedstockPriorityExtractionScenarios() => const [
  OrderSuggestionWorkFeedstockPriorityScenario(
    label:
        'supplier gate active: the emitted build_improvement suggestion targets the unimproved iron feedstock tile, not the lex-first grain tile',
    run: oswfpRunSupplierGateActiveIronNotLexFirstGrain,
    refs: '#2847',
  ),
  OrderSuggestionWorkFeedstockPriorityScenario(
    label:
        'supplier gate inactive (peer at quota): ordinary lexicographic ordering emits the grain tile (negative control)',
    run: oswfpRunSupplierGateInactivePeerAtQuotaLexGrain,
    refs: '#2847',
  ),
  OrderSuggestionWorkFeedstockPriorityScenario(
    label:
        'supplier with lumber only: feedstock build_improvement is accepted under castIron waiver',
    run: oswfpRunSupplierLumberOnlyCastIronWaiver,
    refs: '#2847',
  ),
  OrderSuggestionWorkFeedstockPriorityScenario(
    label: 'suggestion ordering is deterministic across repeated passes',
    run: oswfpRunSuggestionOrderingDeterministicRepeatedPasses,
    refs: '#2847',
  ),
];

/// Feedstock co-availability ordering scenarios (Refs #2847 H8-extraction).
List<OrderSuggestionWorkFeedstockPriorityScenario>
orderSuggestionWorkFeedstockCoAvailScenarios() => const [
  OrderSuggestionWorkFeedstockPriorityScenario(
    label:
        'supplier holds timber but no iron: the emitted build_improvement suggestion targets the least-held iron tile, not the lex-first timber tile',
    run: oswfpRunCoAvailSupplierHoldsTimberNotIronLeastHeldIron,
    refs: '#2847',
  ),
  OrderSuggestionWorkFeedstockPriorityScenario(
    label:
        'supplier holds equal feedstock (zero of each): lexicographic tie-break emits the timber tile (negative control)',
    run: oswfpRunCoAvailEqualFeedstockLexTimberNegativeControl,
    refs: '#2847',
  ),
  OrderSuggestionWorkFeedstockPriorityScenario(
    label: 'co-availability ordering is deterministic across repeated passes',
    run: oswfpRunCoAvailOrderingDeterministicRepeatedPasses,
    refs: '#2847',
  ),
];
