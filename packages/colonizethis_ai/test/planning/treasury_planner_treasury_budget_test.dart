// Thin contract for treasury-budget pin suite (Refs #3997 Phase 8).
// Case bodies live in sibling `*_cases.dart` modules.

import 'treasury_planner_treasury_budget_deficit_clamp_cases.dart';
import 'treasury_planner_treasury_budget_lock_recovery_speculative_cases.dart';

void main() {
  registerTreasuryPlannerTreasuryBudgetDeficitClampCases();
  registerTreasuryPlannerTreasuryBudgetLockRecoverySpeculativeCases();
}
