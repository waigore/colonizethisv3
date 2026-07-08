// Table-driven matrix consolidation of the observer-phase GP-blocker /
// peace-target branch-pin suites (Refs #3749 / #3941).
//
// Single contract file: GP-blocker truths plus COLONIAL / EXPAND / DEVELOP /
// stalled-below-quota peace ladders. Shared fixture families, runners, and
// case tables live in
// `observer_goal_phase_gp_blocker_peace_matrix_support.dart`.
//
// Coverage is preserved 1:1 from the former part2/part3 shards — every row
// keeps the same fixture and the verbatim regression `reason`.

import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_ai/src/planning/observer_goal_phase.dart';

import 'observer_goal_phase_gp_blocker_peace_matrix_support.dart';
import 'observer_goal_phase_gp_blocker_peace_matrix_blocker_cases.dart';
import 'observer_goal_phase_gp_blocker_peace_matrix_colonial_expand_peace_cases.dart';
import 'observer_goal_phase_gp_blocker_peace_matrix_develop_stalled_peace_cases.dart';

void main() {
  runBlocker(
    'primaryColonialGpBlocker contract',
    primaryColonialGpBlocker,
    kPrimaryColonialGpBlockerContractCases,
  );
  runBlocker(
    'primaryInvadableOldWorldGpBlocker contract',
    primaryInvadableOldWorldGpBlocker,
    kPrimaryInvadableOldWorldGpBlockerContractCases,
  );
  runPeace(
    'colonialPhaseGpPeaceTargets guard branches',
    colonialPhaseGpPeaceTargets,
    kColonialPhaseGpPeaceTargetsGuardBranchesCases,
  );
  runPeace(
    'expandPhaseGpPeaceTargets guard branches',
    expandPhaseGpPeaceTargets,
    kExpandPhaseGpPeaceTargetsGuardBranchesCases,
  );
  runPeace(
    'developPhaseGpPeaceTargets guard branches',
    developPhaseGpPeaceTargets,
    kDevelopPhaseGpPeaceTargetsGuardBranchesCases,
  );
  runPeace(
    'stalledBelowQuotaGpLeadPeaceTargets branches',
    stalledBelowQuotaGpLeadPeaceTargets,
    kStalledBelowQuotaGpLeadPeaceTargetsBranchesCases,
  );
}
