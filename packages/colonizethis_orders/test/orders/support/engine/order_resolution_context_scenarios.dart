// Table-driven order-resolution context scenarios (Refs #3949 wave 3).

import '../scenario_runner.dart';
import 'order_resolution_context_run_rows.dart';

/// One row in [orderResolutionContextScenarios].
class OrderResolutionContextScenario implements RefsScenario {
  const OrderResolutionContextScenario({
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

void runOrderResolutionContextScenario(
  OrderResolutionContextScenario scenario,
) {
  scenario.run();
}

/// Canonical scenarios for order_resolution_context family tests.
List<OrderResolutionContextScenario>
orderResolutionContextScenarios() => const [
  OrderResolutionContextScenario(
    label:
        'buildOrderResolutionContext reuses view and cached units (Refs #2836)',
    run: orcRunBuildContextReusesViewAndCachedUnits,
    refs: '#2836',
  ),
  OrderResolutionContextScenario(
    label: 'orderResolutionContextFromView aliases provincesById',
    run: orcRunFromViewAliasesProvincesById,
  ),
];
