// Thin contract for quota-met peace decider pins (Refs #4104 Phase-10 Slice C).
// Pins the canonical `quotaMetBelowQuotaAtWarPeaceTargets` and
// `quotaMetFutileBelowQuotaGpPeaceTargets` peace deciders in
// `expand_phase_planner.dart` (Refs #2509 S1).
//
// Both deciders were relocated from `colonial_pressure.dart` so they
// survive the now-completed S1 deletion of that file. The canonical
// implementations live in `expand_phase_planner.dart`.
//
// Live consumers (post-relocation):
//   * `quotaMetBelowQuotaAtWarPeaceTargets` is the broad quota-met
//     futile-war exit. Once the active player has crossed the
//     observer OW quota, every below-quota Great Power still at war
//     surfaces in the result so the planner stops dragging on mop-up
//     wars after the OW frontier is cleared. The decider is composed
//     directly via `diplomacy_planner_peace_targets.dart` and the
//     offer-peace scoring layer
//     `diplomatic_candidate_scoring_offer_peace.dart` for the
//     futile-bullying signal.
//   * `quotaMetFutileBelowQuotaGpPeaceTargets` is the narrower
//     quota-met companion. It additionally requires the active
//     player to still hold an invadable OW frontier and excludes any
//     below-quota enemy GP that owns one of those invadable OW
//     provinces (peace there would forfeit the residual OW
//     acquisition path) plus the primary invadable OW blocker
//     (`primaryInvadableOldWorldGpBlocker`; defensive backstop).
//     `diplomatic_candidate_scoring_offer_peace.dart` applies a
//     stronger offer-peace score bonus to this narrower set.
//
// Behavioral invariants pinned here (all deterministic — Must-have #7):
//
//   1. `quotaMetBelowQuotaAtWarPeaceTargets` short-circuits to
//      `const []` when `isBelowObserverConquestQuota` is `true` for the
//      active player. Both boundaries are pinned at the
//      `kObserverConquestMinOwProvincesPerGp` seam (own == quota - 1
//      empty; own == quota fires).
//   2. `quotaMetBelowQuotaAtWarPeaceTargets` filters non-Great-Power
//      factions (minors / tribes) and Great Power enemies at or above
//      the observer quota. The remaining below-quota Great Powers
//      are returned sorted ascending so the offer-peace consumer sees
//      a stable order.
//   3. `quotaMetFutileBelowQuotaGpPeaceTargets` short-circuits to
//      `const []` for two outer guards: (a) `isBelowObserverConquestQuota`
//      is `true` for the active player; (b)
//      `invadableProvinceIdsSorted` is empty.
//   4. `quotaMetFutileBelowQuotaGpPeaceTargets` filters non-Great-Power
//      factions (minors / tribes), Great Power enemies at or above the
//      observer quota, Great Power enemies that own one of the active
//      player's invadable OW provinces, and the primary invadable OW
//      blocker (defensive backstop). The remaining below-quota
//      non-blocker non-invadable-owner Great Powers are returned
//      sorted ascending.
//
// Case bodies live in sibling `*_cases.dart` modules.

import 'expand_phase_planner_quota_met_peace_deciders_below_quota_cases.dart';
import 'expand_phase_planner_quota_met_peace_deciders_futile_cases.dart';

void main() {
  registerExpandPhasePlannerQuotaMetPeaceDecidersBelowQuotaCases();
  registerExpandPhasePlannerQuotaMetPeaceDecidersFutileCases();
}
