// Table-driven orders-domain logging scenarios (Refs #3949 wave 3).

import '../scenario_runner.dart';
import 'orders_logging_expectations.dart';

/// One row in [ordersLoggingScenarios].
class OrdersLoggingScenario implements RefsScenario {
  const OrdersLoggingScenario({
    required this.label,
    required this.target,
    this.refs,
  });

  @override
  final String label;
  final OrdersLoggingTarget target;
  @override
  final String? refs;
}

void runOrdersLoggingScenario(OrdersLoggingScenario scenario) {
  runOrdersLoggingExpectation(scenario.target);
}

/// Canonical scenarios for orders_logging family tests.
List<OrdersLoggingScenario> ordersLoggingScenarios() => const [
      OrdersLoggingScenario(
        label: 'ordersLog is a CtLogger with the distinct `orders` prefix',
        target: OrdersLoggingTarget.ordersLogIsCtLogger,
      ),
      OrdersLoggingScenario(
        label: 'ordersLog is the single shared instance for the orders domain',
        target: OrdersLoggingTarget.ordersLogIsSharedInstance,
      ),
      OrdersLoggingScenario(
        label: 'ordersApplicationLog is an alias of the shared ordersLog',
        target: OrdersLoggingTarget.ordersApplicationLogAlias,
      ),
      OrdersLoggingScenario(
        label: 'orderSuggestionLog is rooted under the `orders` domain prefix',
        target: OrdersLoggingTarget.orderSuggestionLogPrefix,
      ),
      OrdersLoggingScenario(
        label: 'ordersLog emits messages with the `orders:` prefix',
        target: OrdersLoggingTarget.ordersLogEmitsPrefixedMessages,
      ),
      OrdersLoggingScenario(
        label: 'no lib/src/orders source consumes the core logicLog',
        target: OrdersLoggingTarget.noLibOrdersSourceConsumesLogicLog,
        refs: '#3290 C2',
      ),
    ];
