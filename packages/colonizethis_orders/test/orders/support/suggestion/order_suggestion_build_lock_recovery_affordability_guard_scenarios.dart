// Table-driven lock-recovery affordability guard scenarios (Refs #3949 wave 3).

import '../scenario_runner.dart';
import 'order_suggestion_build_lock_recovery_affordability_guard_run_rows.dart';

/// One row in [orderSuggestionBuildLockRecoveryAffordabilityGuardScenarios].
class OrderSuggestionBuildLockRecoveryAffordabilityGuardScenario
    implements LabeledScenario {
  const OrderSuggestionBuildLockRecoveryAffordabilityGuardScenario({
    required this.label,
    required this.run,
  });

  @override
  final String label;
  final void Function() run;
}

void runOrderSuggestionBuildLockRecoveryAffordabilityGuardScenario(
  OrderSuggestionBuildLockRecoveryAffordabilityGuardScenario scenario,
) {
  scenario.run();
}

List<OrderSuggestionBuildLockRecoveryAffordabilityGuardScenario>
orderSuggestionBuildLockRecoveryAffordabilityGuardScenarios() => const [
  OrderSuggestionBuildLockRecoveryAffordabilityGuardScenario(
    label:
        'positive control: a broke GP with riches CAN train the cheapest '
        'regiment (proves the negative guard is non-vacuous)',
    run: osblragRunPositiveControlRichesFundRegiment,
  ),
  OrderSuggestionBuildLockRecoveryAffordabilityGuardScenario(
    label:
        'affordability regression guard: AI GP at treasury 0 with no riches '
        'gets zero regiment build candidates (no AI bypass)',
    run: osblragRunAiNoBypass,
  ),
  OrderSuggestionBuildLockRecoveryAffordabilityGuardScenario(
    label:
        'human-player guard: human at treasury 0 with no riches gets zero '
        'regiment suggestions (no human waiver)',
    run: osblragRunHumanNoWaiverSuggestions,
  ),
  OrderSuggestionBuildLockRecoveryAffordabilityGuardScenario(
    label:
        'human-player guard: the build-validation path rejects a human regiment '
        'build at treasury 0 (UI submission path, no waiver)',
    run: osblragRunHumanNoWaiverValidationPath,
  ),
];
