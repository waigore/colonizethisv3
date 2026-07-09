// Table-driven order-resolution context scenarios (Refs #3949 wave 3).

import '../scenario_runner.dart';
import 'order_resolution_context_expectations.dart';

/// One row in [orderResolutionContextScenarios].
class OrderResolutionContextScenario implements RefsScenario {
  const OrderResolutionContextScenario({
    required this.label,
    required this.target,
    this.refs,
  });

  @override
  final String label;
  final OrderResolutionContextTarget target;
  @override
  final String? refs;
}

void runOrderResolutionContextScenario(OrderResolutionContextScenario scenario) {
  runOrderResolutionContextExpectation(scenario.target);
}

/// Canonical scenarios for order_resolution_context family tests.
List<OrderResolutionContextScenario> orderResolutionContextScenarios() =>
    const [
      OrderResolutionContextScenario(
        label: 'buildOrderResolutionContext reuses view and cached units (Refs #2836)',
        target: OrderResolutionContextTarget.buildContextReusesViewAndCachedUnits,
        refs: '#2836',
      ),
      OrderResolutionContextScenario(
        label: 'orderResolutionContextFromView aliases provincesById',
        target: OrderResolutionContextTarget.fromViewAliasesProvincesById,
      ),
    ];
