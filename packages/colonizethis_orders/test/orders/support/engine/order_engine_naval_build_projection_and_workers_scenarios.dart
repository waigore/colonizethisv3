// Table-driven OrderEngine naval/build projection + worker scenarios (Refs #3949 wave 3).

import '../scenario_runner.dart';
import 'order_engine_naval_build_projection_and_workers_run_rows.dart';

/// One row in [orderEngineNavalBuildProjectionAndWorkersScenarios].
class OrderEngineNavalBuildProjectionAndWorkersScenario
    implements RefsScenario {
  const OrderEngineNavalBuildProjectionAndWorkersScenario({
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

void runOrderEngineNavalBuildProjectionAndWorkersScenario(
  OrderEngineNavalBuildProjectionAndWorkersScenario scenario,
) {
  scenario.run();
}

/// Canonical scenarios for OrderEngine naval/build projection + worker family.
/// Labels must match wave-3 [DESCRIPTION_BASELINE.txt] entries and former
/// `order_engine_naval_build_projection_and_workers_test.dart` descriptions.
List<OrderEngineNavalBuildProjectionAndWorkersScenario>
orderEngineNavalBuildProjectionAndWorkersScenarios() => const [
  OrderEngineNavalBuildProjectionAndWorkersScenario(
    label: 'projectedEffects returns treasuryDelta when orders affect treasury',
    run: oenbpaRunProjectedEffectsTreasuryDelta,
  ),
  OrderEngineNavalBuildProjectionAndWorkersScenario(
    label: 'rejects naval build when peasants are zero',
    run: oenbpaRunRejectsNavalBuildWhenPeasantsZero,
  ),
];
