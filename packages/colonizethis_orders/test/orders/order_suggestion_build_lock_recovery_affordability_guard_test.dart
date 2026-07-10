// Consolidated lock-recovery affordability guard runner (Refs #3949 wave 3 slice 95).
//
// Migrated from imperative `test()` bodies to table-driven scenarios in support/.

import 'support/scenario_runner.dart';
import 'support/suggestion/order_suggestion_build_lock_recovery_affordability_guard_scenarios.dart';

void main() {
  runLabeledScenarioGroup(
    'suggestBuildOrders lock-recovery affordability guard (Refs #2924)',
    orderSuggestionBuildLockRecoveryAffordabilityGuardScenarios(),
    runRunnableScenario,
  );
}
