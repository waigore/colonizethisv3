// Thin contract for critical expand-peace decider pins (Refs #4104 Phase-10 Slice C).
// Pins canonical homes in `expand_phase_planner.dart` for
// `criticalWeakGpSurvivalPeaceTargets` and
// `criticalMultiFrontGpPeaceTargets` (Refs #2509 S1).
//
// Both deciders were relocated from
// `diplomacy_planner_peace_targets.dart` so they survive the planned
// S1 deletion of that file. The canonical implementations live in
// `expand_phase_planner.dart` (part file
// `expand_phase_planner_peer_peace.dart`);
// `diplomacy_planner_peace_targets.dart` previously retained thin delegating
// stubs for the legacy
// `diplomacy_planner_mutual_exhausted_peace_test.dart`,
// `diplomacy_planner_below_quota_peace_part3_test.dart`, and
// `diplomacy_planner_stalled_peace_test.dart` fixtures and the in-file
// `_survivalGreatPowerPeaceTargets` /
// `_expandRatchetGreatPowerPeaceTargets` /
// `stalledOwExpansionNeedsPeacePass` consumer chains until the
// planned deletion.
//
// Behavioral invariants pinned at the canonical entry points:
//
// `criticalWeakGpSurvivalPeaceTargets`:
//   1. Returns `const []` when `oldWorldProvincesOwned >
//      kFewOldWorldProvincesDefendThreshold` (today: 6) — outside the
//      critical OW-defend band the broader `criticalOwHoldPeaceTargets`
//      and the band-specific deciders take over.
//   2. When the outer guard passes, every Great Power foe in
//      `threats.atWarWith` (filtered via `Game.playerById`) whose
//      own province count satisfies a band-dependent minimum-lead
//      threshold is peaced:
//      a. `ownOw <= kObserverDefaultStartOldWorldProvincesPerGp + 1`
//         (today: 8) — default-start critical row: lead `>= 1` is
//         enough.
//      b. Else `isBelowObserverConquestQuota(ownOw)` — below-quota
//         critical row: lead `>= kUnwinnableSoleGpMinProvinceDeficit`
//         (today: 2).
//      c. Else (above-quota critical-band shape, defensive) —
//         lead `>=
//         kDeclareWarAggressorSuppressWeakGpLeadThreshold`
//         (today: 4).
//   3. Tribes and minors are dropped silently
//      (`Game.playerById` returns `null` for them); the GP-foe scan
//      is the only path into the returned list.
//   4. Result sorted ascending by `factionId` for downstream
//      offer-peace determinism (Refs #2509 Must-have #7).
//
// `criticalMultiFrontGpPeaceTargets`:
//   1. Returns `const []` when both
//      `isObserverConquestExpansionPressure` and
//      `isAtObserverConquestQuotaBand` are `false` for the active
//      player's `oldWorldProvincesOwned` — outside the EXPAND band
//      the quota-met deciders own the decision.
//   2. Returns `const []` when fewer than two Great Powers remain in
//      `threats.atWarWith` after the `Game.playerById` filter — the
//      "multi-front" precondition does not hold.
//   3. When both guards pass, delegates to
//      `multiFrontNonBlockerGpPeaceTargets` for the deterministic
//      non-blocker selection: the primary OW frontier blocker is
//      held open; every other GP foe is peaced sorted ascending.
//
// Delegation parity:
//   * The delegating stubs in
//     `diplomacy_planner_peace_targets.dart` return the same values
//     as the canonical helpers for every representative input —
//     required so the legacy fixtures and the in-file consumer
//     chains agree on both deciders.
//
// Case bodies live in sibling `*_cases.dart` modules.

import 'expand_phase_planner_critical_multi_front_peace_cases.dart';
import 'expand_phase_planner_critical_weak_survival_peace_cases.dart';

void main() {
  registerExpandPhasePlannerCriticalWeakSurvivalPeaceCases();
  registerExpandPhasePlannerCriticalMultiFrontPeaceCases();
}
