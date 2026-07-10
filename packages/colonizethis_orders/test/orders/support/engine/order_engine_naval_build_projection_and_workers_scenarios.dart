// Table-driven OrderEngine naval/build projection + worker scenarios (Refs #3949 wave 3).

import '../scenario_runner.dart';
import 'order_engine_naval_build_projection_and_workers_expectations.dart';

/// One row in [orderEngineNavalBuildProjectionAndWorkersScenarios].
class OrderEngineNavalBuildProjectionAndWorkersScenario
    implements RefsScenario {
  const OrderEngineNavalBuildProjectionAndWorkersScenario({
    required this.label,
    required this.target,
    this.refs,
  });

  @override
  final String label;
  final OrderEngineNavalBuildProjectionAndWorkersTarget target;
  @override
  final String? refs;
}

void runOrderEngineNavalBuildProjectionAndWorkersScenario(
  OrderEngineNavalBuildProjectionAndWorkersScenario scenario,
) {
  runOrderEngineNavalBuildProjectionAndWorkersExpectation(scenario.target);
}

/// Canonical scenarios for OrderEngine naval/build projection + worker family.
/// Labels must match wave-3 [DESCRIPTION_BASELINE.txt] entries and former
/// `order_engine_naval_build_projection_and_workers_test.dart` descriptions.
List<OrderEngineNavalBuildProjectionAndWorkersScenario>
orderEngineNavalBuildProjectionAndWorkersScenarios() => const [
  OrderEngineNavalBuildProjectionAndWorkersScenario(
    label: 'projectedEffects returns treasuryDelta when orders affect treasury',
    target: OrderEngineNavalBuildProjectionAndWorkersTarget
        .projectedEffectsTreasuryDelta,
  ),
  OrderEngineNavalBuildProjectionAndWorkersScenario(
    label: 'rejects naval build when peasants are zero',
    target: OrderEngineNavalBuildProjectionAndWorkersTarget
        .rejectsNavalBuildWhenPeasantsZero,
  ),
];
