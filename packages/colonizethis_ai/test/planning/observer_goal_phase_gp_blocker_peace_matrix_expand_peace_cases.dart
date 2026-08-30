// Case-table barrel for EXPAND-phase GP peace targets (Refs #3941).

import 'observer_goal_phase_gp_blocker_peace_matrix_expand_peace_guard_cases.dart';
import 'observer_goal_phase_gp_blocker_peace_matrix_expand_peace_multi_gp_cases.dart';
import 'observer_goal_phase_gp_blocker_peace_matrix_support.dart';

final List<PeaceCase> kExpandPhaseGpPeaceTargetsGuardBranchesCases =
    <PeaceCase>[
      ...kExpandPhaseGpPeaceTargetsGuardEarlyCases,
      ...kExpandPhaseGpPeaceTargetsMultiGpCases,
    ];
