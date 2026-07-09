// Table-driven order-effects projector seam scenarios (Refs #3949 wave 3).

import '../scenario_runner.dart';
import 'order_effects_projector_seam_expectations.dart';

/// One row in [orderEffectsProjectorSeamScenarios].
class OrderEffectsProjectorSeamScenario implements RefsScenario {
  const OrderEffectsProjectorSeamScenario({
    required this.label,
    required this.target,
    this.refs,
  });

  @override
  final String label;
  final OrderEffectsProjectorSeamTarget target;
  @override
  final String? refs;
}

void runOrderEffectsProjectorSeamScenario(
  OrderEffectsProjectorSeamScenario scenario,
) {
  runOrderEffectsProjectorSeamExpectation(scenario.target);
}

/// Canonical scenarios for order_effects_projector_seam family tests.
List<OrderEffectsProjectorSeamScenario> orderEffectsProjectorSeamScenarios() =>
    const [
      OrderEffectsProjectorSeamScenario(
        label: 'uses the injected projector output',
        target: OrderEffectsProjectorSeamTarget.usesInjectedProjectorOutput,
        refs: '#3290 C2',
      ),
      OrderEffectsProjectorSeamScenario(
        label: 'throws StateError when no projector was injected',
        target: OrderEffectsProjectorSeamTarget.throwsWhenNoProjectorInjected,
        refs: '#3290 C2',
      ),
      OrderEffectsProjectorSeamScenario(
        label: 'throws StateError when a trade order is validated without a projector',
        target: OrderEffectsProjectorSeamTarget
            .throwsWhenTradeOrderValidatedWithoutProjector,
        refs: '#3290 C2',
      ),
      OrderEffectsProjectorSeamScenario(
        label: 'uses the injected projector and accepts a valid offer',
        target:
            OrderEffectsProjectorSeamTarget.usesInjectedProjectorAndAcceptsValidOffer,
        refs: '#3290 C2',
      ),
      OrderEffectsProjectorSeamScenario(
        label: 'does not invoke the projector when no trade order is staged',
        target: OrderEffectsProjectorSeamTarget
            .doesNotInvokeProjectorWhenNoTradeOrderStaged,
        refs: '#3290 C2',
      ),
    ];
