// Thin contract for treasury_planner pin suite (Refs #3997 Phase 8).
// Case bodies live in sibling `*_cases.dart` modules.
// Partial-fill forecasting lives in treasury_planner_forecasting_test.dart.

import 'treasury_planner_core_cases.dart';
import 'treasury_planner_lock_recovery_seller_cases.dart';

void main() {
  registerTreasuryPlannerCoreCases();
  registerTreasuryPlannerLockRecoverySellerCases();
}
