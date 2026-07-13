// Shared fixtures for phase_planner_conquest_wiring pin cases (Refs #3997 Phase 8).
library;

import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_ai/src/planning/colonial_phase_planner.dart';
import 'package:colonizethis_ai/src/planning/expand_phase_planner.dart';
const ExpandMilitaryPlan kConquestWiringExpandOwOnly = ExpandMilitaryPlan(
  priorityDestinationProvinceIdsSorted: <String>['oldWorld|minor1_a'],
  priorityTargetOwnerFactionIdsSorted: <String>['minor1'],
);

const ColonialMilitaryPlan kConquestWiringColonialNwOnly = ColonialMilitaryPlan(
  priorityDestinationProvinceIdsSorted: <String>['newWorld|tribe1_a'],
  priorityTargetOwnerFactionIdsSorted: <String>['tribe1'],
);

const ExpandEconomyPlan kConquestWiringNwTreasuryRecoveryOverridePlan = ExpandEconomyPlan(
  forceCheapestRegimentBuild: true,
  boostTreasuryRecoveryCargo: true,
);

AIWorldSnapshot conquestWiringLockRecoverySnapshot() {
  return AIWorldSnapshot(
    playerId: 'gp1',
    threats: const ThreatSummary(atWarWith: ['tribe1']),
    opportunities: const OpportunitySummary(),
    conquest: ConquestSummary(
      oldWorldProvincesOwned: 7,
      provincesToVictory: 31,
      invadableProvinceIdsSorted: const ['oldWorld|minor1_a'],
    ),
    colonial: ColonialSummary(
      invadableNewWorldProvinceIdsSorted: const ['newWorld|tribe1_a'],
      newWorldProvincesOwned: 0,
    ),
    economy: const EconomySummary(treasury: 0),
    relations: const {},
  );
}
