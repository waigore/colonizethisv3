// Table-driven suggestWorkOrders logging scenarios (Refs #3949 wave 3).

import '../scenario_runner.dart';
import 'order_suggestion_work_logging_run_rows.dart';

/// One row in [orderSuggestionWorkLoggingScenarios].
class OrderSuggestionWorkLoggingScenario implements RefsScenario {
  const OrderSuggestionWorkLoggingScenario({
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

void runOrderSuggestionWorkLoggingScenario(
  OrderSuggestionWorkLoggingScenario scenario,
) {
  scenario.run();
}

List<OrderSuggestionWorkLoggingScenario>
orderSuggestionWorkLoggingScenarios() => const [
  OrderSuggestionWorkLoggingScenario(
    label: 'emits suggest_work summaries for Explorer/Builder/Spy/Merchant',
    run: oswlRunEmitsSummariesForCivilianTypes,
  ),
  OrderSuggestionWorkLoggingScenario(
    label:
        'suggestWorkOrders logger lines never emit unbounded full list payload',
    run: oswlRunLoggerLinesNeverEmitUnboundedFullListPayload,
    refs: '#2133',
  ),
  OrderSuggestionWorkLoggingScenario(
    label:
        'explorer multiple prospect tiles emit one suggest_work with includedCount',
    run: oswlRunMultipleProspectTilesEmitIncludedCount,
  ),
  OrderSuggestionWorkLoggingScenario(
    label: 'explorer pending targets preserve duplicate check and log ordering',
    run: oswlRunPendingTargetsPreserveDuplicateCheckAndLogOrdering,
  ),
];
