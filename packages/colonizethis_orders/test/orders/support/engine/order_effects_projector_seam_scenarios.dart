// Table-driven order-effects projector seam scenarios (Refs #3949 wave 3).

import '../scenario_runner.dart';
import 'order_effects_projector_seam_run_rows.dart';

/// One row in [orderEffectsProjectorSeamScenarios].
class OrderEffectsProjectorSeamScenario implements RefsScenario {
  const OrderEffectsProjectorSeamScenario({
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

void runOrderEffectsProjectorSeamScenario(
  OrderEffectsProjectorSeamScenario scenario,
) {
  scenario.run();
}

/// Canonical scenarios for order_effects_projector_seam family tests.
List<OrderEffectsProjectorSeamScenario>
orderEffectsProjectorSeamScenarios() => const [
  OrderEffectsProjectorSeamScenario(
    label: 'uses the injected projector output',
    run: oepsRunUsesInjectedProjectorOutput,
    refs: '#3290 C2',
  ),
  OrderEffectsProjectorSeamScenario(
    label: 'throws StateError when no projector was injected',
    run: oepsRunThrowsWhenNoProjectorInjected,
    refs: '#3290 C2',
  ),
  OrderEffectsProjectorSeamScenario(
    label: 'throws StateError when a trade order is validated without a projector',
    run: oepsRunThrowsWhenTradeOrderValidatedWithoutProjector,
    refs: '#3290 C2',
  ),
  OrderEffectsProjectorSeamScenario(
    label: 'uses the injected projector and accepts a valid offer',
    run: oepsRunUsesInjectedProjectorAndAcceptsValidOffer,
    refs: '#3290 C2',
  ),
  OrderEffectsProjectorSeamScenario(
    label: 'does not invoke the projector when no trade order is staged',
    run: oepsRunDoesNotInvokeProjectorWhenNoTradeOrderStaged,
    refs: '#3290 C2',
  ),
];
