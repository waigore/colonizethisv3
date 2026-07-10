// Table-driven orders-domain logging scenarios (Refs #3949 wave 3).

import '../scenario_runner.dart';
import 'orders_logging_run_rows.dart';

/// One row in [ordersLoggingScenarios].
class OrdersLoggingScenario implements RefsScenario {
  const OrdersLoggingScenario({
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

void runOrdersLoggingScenario(OrdersLoggingScenario scenario) {
  scenario.run();
}

/// Canonical scenarios for orders_logging family tests.
List<OrdersLoggingScenario> ordersLoggingScenarios() => const [
      OrdersLoggingScenario(
        label: 'ordersLog is a CtLogger with the distinct `orders` prefix',
        run: olRunOrdersLogIsCtLogger,
      ),
      OrdersLoggingScenario(
        label: 'ordersLog is the single shared instance for the orders domain',
        run: olRunOrdersLogIsSharedInstance,
      ),
      OrdersLoggingScenario(
        label: 'ordersApplicationLog is an alias of the shared ordersLog',
        run: olRunOrdersApplicationLogAlias,
      ),
      OrdersLoggingScenario(
        label: 'orderSuggestionLog is rooted under the `orders` domain prefix',
        run: olRunOrderSuggestionLogPrefix,
      ),
      OrdersLoggingScenario(
        label: 'ordersLog emits messages with the `orders:` prefix',
        run: olRunOrdersLogEmitsPrefixedMessages,
      ),
      OrdersLoggingScenario(
        label: 'no lib/src/orders source consumes the core logicLog',
        run: olRunNoLibOrdersSourceConsumesLogicLog,
        refs: '#3290 C2',
      ),
    ];
