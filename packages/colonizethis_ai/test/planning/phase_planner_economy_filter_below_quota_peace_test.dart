// Thin contract for EXPAND below-quota peace rebuild-trap resolver pins
// (Refs #4104 Phase-10 Slice C).
// Unit tests for the EXPAND below-quota peace rebuild-trap resolvers
// in `phase_planner_economy_filter.dart` (Refs #2509 S5 — split out of
// `phase_planner_economy_filter_test.dart` to keep both files under the
// repo-lint `dart_file_non_comment_line_size` 1000-line cap; see
// `SPEC/program/repo-lint.md` § Dart files must stay at or below 1000
// non-comment lines).
//
// Pins the structural contract of
// `resolvePhaseEconomyExpandBelowQuotaPeaceInsufficientRegimentsActive`
// and `resolvePhaseEconomyExpandBelowQuotaPeaceZeroRegimentsRebuildActive`:
//
//   - Returns `true` only when phase ∈ {EXPAND, COLONIAL-lite} AND the
//     legacy `isBelowQuotaPeace*` arms hold for the per-turn inputs.
//   - Returns `false` under COLONIAL and DEVELOP regardless of
//     per-turn inputs (structural — at or above quota the rebuild
//     trap does not apply).
//   - Field-equal to the legacy `colonial_pressure.dart` helpers
//     under EXPAND / COLONIAL-lite where
//     `isBelowObserverConquestQuota(ow)` is already satisfied
//     structurally by the phase-entry guard.
//   - Reads only the documented inputs — sibling slots on
//     [PhasePlanOutcome] (COLONIAL acquisition, DEVELOP civilian
//     work, EXPAND frontier, ...) have no effect.
//   - Pure and deterministic across repeated calls (Refs #2509
//     Must-have #7).
//
// These resolvers replace the orchestrator's last two direct calls
// into `colonial_pressure.dart` from `_appendEconomyBuildOrders`
// (`expandQuotaPressure && isBelowQuotaPeaceInsufficientRegiments`
// and `expandQuotaPressure && isBelowQuotaPeaceZeroRegimentsRebuild`)
// and let the orchestrator drop the `colonial_pressure.dart` import
// entirely. Legacy parity tests below pin the field-equal contract
// across the matrix the legacy helpers actually answered for the
// orchestrator (the `isBelowObserverConquestQuota` first guard
// collapses into the phase gate because EXPAND / COLONIAL-lite phase
// entry requires `ow < kObserverConquestMinOwProvincesPerGp` by
// `observerGoalPhaseFor`).
//
// Case bodies live in sibling `*_cases.dart` modules.

import 'phase_planner_economy_filter_below_quota_peace_insufficient_regiments_cases.dart';
import 'phase_planner_economy_filter_below_quota_peace_zero_regiments_cases.dart';
import 'phase_planner_economy_filter_below_quota_peace_zero_regiments_matrix_cases.dart';

void main() {
  registerPhasePlannerEconomyFilterBelowQuotaPeaceInsufficientRegimentsCases();
  registerPhasePlannerEconomyFilterBelowQuotaPeaceZeroRegimentsCases();
  registerPhasePlannerEconomyFilterBelowQuotaPeaceZeroRegimentsMatrixCases();
}
