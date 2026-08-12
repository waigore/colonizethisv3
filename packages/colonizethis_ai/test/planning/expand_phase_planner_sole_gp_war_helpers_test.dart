// Pins the canonical `soleAtWarGreatPowerId` and
// `canPivotFromSoleGpWarAfterPeace` sole-GP-war helpers in
// `expand_phase_planner.dart` (Refs #2509 S1).
//
// Both helpers were relocated from `colonial_pressure.dart` so they survive
// the now-completed S1 deletion of that file. The canonical implementations
// live in `expand_phase_planner.dart`.
//
// Live consumers (post-relocation):
//   * `soleAtWarGreatPowerId` is consumed inside `expand_phase_planner.dart`
//     by `belowQuotaPeerGpPeaceTargets` (peer-stalled peace pivot fork),
//     `unwinnableSoleGpFrontierPeaceTarget` (below-quota outgunned sole-GP
//     peace), and `consolidateGainsSoleGpPeaceTarget` (quota-met
//     consolidate peace). All three short-circuit to the default
//     no-peace path when the helper returns `null`.
//   * `canPivotFromSoleGpWarAfterPeace` is consumed by
//     `unwinnableSoleGpFrontierPeaceTarget` as the pivot-availability gate
//     before returning a peace target id — peace is only worthwhile if
//     the active GP can immediately resume EXPAND against a minor rather
//     than idle while the lone GP rebuilds.
//
// Behavioral invariants pinned here (all deterministic — Must-have #7):
//
//   1. `soleAtWarGreatPowerId` returns `null` for an empty at-war list,
//      a minor-only at-war list, an unknown-faction-only at-war list, or
//      any list resolving to more than one Great Power after the
//      `playerById` filter.
//   2. `soleAtWarGreatPowerId` returns the lone Great Power id when
//      exactly one current Great Power remains after filtering; minor
//      and tribe ids in the same `atWarWith` list do not contribute to
//      the length count.
//   3. `canPivotFromSoleGpWarAfterPeace` returns `true` via the leading
//      `>=` short-circuit when the active player is at or above
//      [kObserverConquestMinOwProvincesPerGp] OW provinces (no longer
//      EXPAND territory).
//   4. `canPivotFromSoleGpWarAfterPeace` returns `true` via the
//      `minorsOnMap` arm when any OW province has a minor owner — even
//      when that minor is already in the active player's at-war set
//      (the helper does NOT filter by `snapshot.threats.atWarWith`; the
//      at-war filtering lives in higher-level peace collectors).
//   5. `canPivotFromSoleGpWarAfterPeace` returns `true` via the trailing
//      `any` arm when no OW minor exists but the invadable list contains
//      a province whose current owner is a minor (cross-region pivot —
//      typical of NW colonial minor frontiers when the active GP has
//      lost all OW minor neighbours).
//   6. `canPivotFromSoleGpWarAfterPeace` returns `false` only when the
//      active player is strictly below quota AND no minor owns any OW
//      province AND the invadable list contains no minor-owned
//      province. This is the EXPAND-trap deadlock the helper exists to
//      report.

import 'expand_phase_planner_sole_gp_war_helpers_pivot_cases.dart';
import 'expand_phase_planner_sole_gp_war_helpers_sole_at_war_cases.dart';

void main() {
  registerExpandPhasePlannerSoleGpWarHelpersSoleAtWarCases();
  registerExpandPhasePlannerSoleGpWarHelpersPivotCases();
}
