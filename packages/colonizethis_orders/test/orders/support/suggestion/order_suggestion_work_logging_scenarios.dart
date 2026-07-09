// Table-driven suggestWorkOrders logging scenarios (Refs #3949 wave 3).

import '../scenario_runner.dart';
import 'order_suggestion_work_logging_expectations.dart';

/// One row in [orderSuggestionWorkLoggingScenarios].
class OrderSuggestionWorkLoggingScenario implements RefsScenario {
  const OrderSuggestionWorkLoggingScenario({
    required this.label,
    required this.target,
    this.refs,
  });

  @override
  final String label;
  final OrderSuggestionWorkLoggingTarget target;
  @override
  final String? refs;
}

void runOrderSuggestionWorkLoggingScenario(
  OrderSuggestionWorkLoggingScenario scenario,
) {
  runOrderSuggestionWorkLoggingExpectation(scenario.target);
}

List<OrderSuggestionWorkLoggingScenario> orderSuggestionWorkLoggingScenarios() =>
    const [
      OrderSuggestionWorkLoggingScenario(
        label: 'emits suggest_work summaries for Explorer/Builder/Spy/Merchant',
        target: OrderSuggestionWorkLoggingTarget.emitsSummariesForCivilianTypes,
      ),
      OrderSuggestionWorkLoggingScenario(
        label: 'suggestWorkOrders logger lines never emit unbounded full list payload',
        target: OrderSuggestionWorkLoggingTarget
            .loggerLinesNeverEmitUnboundedFullListPayload,
        refs: '#2133',
      ),
    ];
