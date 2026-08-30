// Shared fixtures for `phase_planner_expand_economy_test.dart` (Refs #4669 Slice D).

import 'package:colonizethis_ai/src/planning/expand_phase_planner.dart'
    show ExpandEconomyPlan;

const ExpandEconomyPlan kExpandEconomyRebuildOnly = ExpandEconomyPlan(
  forceCheapestRegimentBuild: true,
  boostTreasuryRecoveryCargo: false,
);

const ExpandEconomyPlan kExpandEconomyBoostOnly = ExpandEconomyPlan(
  forceCheapestRegimentBuild: false,
  boostTreasuryRecoveryCargo: true,
);

const ExpandEconomyPlan kExpandEconomyRebuildAndBoost = ExpandEconomyPlan(
  forceCheapestRegimentBuild: true,
  boostTreasuryRecoveryCargo: true,
);
