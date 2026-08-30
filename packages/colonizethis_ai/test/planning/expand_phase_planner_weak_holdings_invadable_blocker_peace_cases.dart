// Case-library barrel (Refs #4602 Slice B).

import 'expand_phase_planner_weak_holdings_invadable_blocker_peace_guard_cases.dart';
import 'expand_phase_planner_weak_holdings_invadable_blocker_peace_tail_cases.dart';
import 'expand_phase_planner_weak_holdings_invadable_blocker_peace_determinism_cases.dart';
import 'expand_phase_planner_weak_holdings_invadable_blocker_peace_delegation_cases.dart';

void registerWeakHoldingsInvadableBlockerPeace() {
  registerWeakHoldingsInvadableBlockerPeaceGuardCases();
  registerWeakHoldingsInvadableBlockerPeaceTailCases();
  registerWeakHoldingsInvadableBlockerPeaceDeterminismCases();
  registerWeakHoldingsInvadableBlockerPeaceDelegationCases();
}
