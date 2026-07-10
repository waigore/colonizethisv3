// Table-driven orderValidationPhasePlan scenarios (Refs #3949 wave 3).

import '../scenario_runner.dart';
import 'order_engine_validation_phase_plan_run_rows.dart';

/// One row in [orderEngineValidationPhasePlanScenarios].
class OrderEngineValidationPhasePlanScenario implements RefsScenario {
  const OrderEngineValidationPhasePlanScenario({
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

void runOrderEngineValidationPhasePlanScenario(
  OrderEngineValidationPhasePlanScenario scenario,
) {
  scenario.run();
}

/// Canonical scenarios for order_engine_validation_phase_plan family tests.
List<OrderEngineValidationPhasePlanScenario>
orderEngineValidationPhasePlanScenarios() => const [
  OrderEngineValidationPhasePlanScenario(
    label: 'declares the canonical per-category phase order',
    run: oevppRunDeclaresCanonicalPerCategoryPhaseOrder,
    refs: '#3543 AC2',
  ),
  OrderEngineValidationPhasePlanScenario(
    label: 'phase names are unique (no category runs twice)',
    run: oevppRunPhaseNamesAreUnique,
    refs: '#3543 AC2',
  ),
  OrderEngineValidationPhasePlanScenario(
    label:
        'move + army-move share the initial bundle; resource/diplomatic/naval phases refresh; trade reuses the advanced bundle',
    run: oevppRunMoveArmyMoveShareInitialBundleResourcePhasesRefreshTradeReuses,
    refs: '#2391 AC7',
  ),
];
