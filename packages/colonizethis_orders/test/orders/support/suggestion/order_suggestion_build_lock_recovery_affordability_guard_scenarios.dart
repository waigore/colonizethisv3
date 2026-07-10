// Table-driven lock-recovery affordability guard scenarios (Refs #3949 wave 3).

import '../scenario_runner.dart';
import 'order_suggestion_build_lock_recovery_affordability_guard_expectations.dart';

/// One row in [orderSuggestionBuildLockRecoveryAffordabilityGuardScenarios].
class OrderSuggestionBuildLockRecoveryAffordabilityGuardScenario
    implements LabeledScenario {
  const OrderSuggestionBuildLockRecoveryAffordabilityGuardScenario({
    required this.label,
    required this.target,
  });

  @override
  final String label;
  final OrderSuggestionBuildLockRecoveryAffordabilityGuardTarget target;
}

void runOrderSuggestionBuildLockRecoveryAffordabilityGuardScenario(
  OrderSuggestionBuildLockRecoveryAffordabilityGuardScenario scenario,
) {
  runOrderSuggestionBuildLockRecoveryAffordabilityGuardExpectation(
    scenario.target,
  );
}

List<OrderSuggestionBuildLockRecoveryAffordabilityGuardScenario>
    orderSuggestionBuildLockRecoveryAffordabilityGuardScenarios() => const [
          OrderSuggestionBuildLockRecoveryAffordabilityGuardScenario(
            label: 'positive control: a broke GP with riches CAN train the cheapest '
                'regiment (proves the negative guard is non-vacuous)',
            target: OrderSuggestionBuildLockRecoveryAffordabilityGuardTarget
                .positiveControlRichesFundRegiment,
          ),
          OrderSuggestionBuildLockRecoveryAffordabilityGuardScenario(
            label: 'affordability regression guard: AI GP at treasury 0 with no riches '
                'gets zero regiment build candidates (no AI bypass)',
            target:
                OrderSuggestionBuildLockRecoveryAffordabilityGuardTarget.aiNoBypass,
          ),
          OrderSuggestionBuildLockRecoveryAffordabilityGuardScenario(
            label: 'human-player guard: human at treasury 0 with no riches gets zero '
                'regiment suggestions (no human waiver)',
            target: OrderSuggestionBuildLockRecoveryAffordabilityGuardTarget
                .humanNoWaiverSuggestions,
          ),
          OrderSuggestionBuildLockRecoveryAffordabilityGuardScenario(
            label: 'human-player guard: the build-validation path rejects a human regiment '
                'build at treasury 0 (UI submission path, no waiver)',
            target: OrderSuggestionBuildLockRecoveryAffordabilityGuardTarget
                .humanNoWaiverValidationPath,
          ),
        ];
