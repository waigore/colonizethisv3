// Table-driven orderValidationPhasePlan scenarios (Refs #3949 wave 3).

import '../scenario_runner.dart';
import 'order_engine_validation_phase_plan_expectations.dart';

/// One row in [orderEngineValidationPhasePlanScenarios].
class OrderEngineValidationPhasePlanScenario implements RefsScenario {
  const OrderEngineValidationPhasePlanScenario({
    required this.label,
    required this.target,
    this.refs,
  });

  @override
  final String label;
  final OrderEngineValidationPhasePlanTarget target;
  @override
  final String? refs;
}

void runOrderEngineValidationPhasePlanScenario(
  OrderEngineValidationPhasePlanScenario scenario,
) {
  runOrderEngineValidationPhasePlanExpectation(scenario.target);
}

/// Canonical scenarios for order_engine_validation_phase_plan family tests.
List<OrderEngineValidationPhasePlanScenario>
    orderEngineValidationPhasePlanScenarios() => const [
          OrderEngineValidationPhasePlanScenario(
            label: 'declares the canonical per-category phase order',
            target: OrderEngineValidationPhasePlanTarget
                .declaresCanonicalPerCategoryPhaseOrder,
            refs: '#3543 AC2',
          ),
          OrderEngineValidationPhasePlanScenario(
            label: 'phase names are unique (no category runs twice)',
            target: OrderEngineValidationPhasePlanTarget.phaseNamesAreUnique,
            refs: '#3543 AC2',
          ),
          OrderEngineValidationPhasePlanScenario(
            label:
                'move + army-move share the initial bundle; resource/diplomatic/naval phases refresh; trade reuses the advanced bundle',
            target: OrderEngineValidationPhasePlanTarget
                .moveArmyMoveShareInitialBundleResourcePhasesRefreshTradeReuses,
            refs: '#2391 AC7',
          ),
        ];
