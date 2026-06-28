/// Shared phase-filter helpers and suppression-matrix contract
/// (Refs #3749 step 4 — phase-filter family dedup).
///
/// Canonical home for the small pure helpers shared by the per-domain phase
/// filters (`phase_planner_{conquest,diplomacy,economy,naval,goal,work_order}
/// _filter.dart`). Each filter previously repeated the
/// `{required PhasePlanOutcome phasePlan} =>
/// resolvePhaseColonialPressureActive(phasePlan.phase)` colonial-pressure
/// wrapper inline; the [PhasePlanOutcome] → COLONIAL-only projection now lives
/// once here. Per-family files keep only their domain-specific resolvers and
/// delegate the shared `phasePlan.phase` unwrap to this module so the
/// structural contract is expressed in a single place.
///
/// ## Colonial-pressure suppression matrix
///
/// [phaseColonialPressureActiveFromPlan] is the single source of truth for the
/// "is colonial-acquisition pressure structurally active for this phase plan?"
/// projection consumed by the conquest, diplomacy, and economy filters. It is
/// `true` **only** under [ObserverGoalPhase.colonial] and `false` for every
/// other phase (mirrors `SPEC/ai/phase-planner-dispatch.md` § Adapter helpers):
///
/// | Phase | Colonial pressure | Rationale |
/// |---|---|---|
/// | [ObserverGoalPhase.expand] | `false` (structural) | EXPAND never advances NW acquisition. |
/// | [ObserverGoalPhase.colonialLite] | `false` (structural) | COLONIAL-lite is the EXPAND safeguard, not a full-COLONIAL substitute. |
/// | [ObserverGoalPhase.colonial] | `true` | Full COLONIAL is the only SPEC-authorized NW acquisition phase. |
/// | [ObserverGoalPhase.develop] | `false` (structural) | DEVELOP suppresses new acquisition objectives. |
///
/// The active-phase signal is **structural**: callers do not re-check whether
/// visible NW invadable is non-empty. The phase-planner dispatcher already
/// gated entry to COLONIAL on `hasColonialAcquisitionTargets`
/// (`observerGoalPhaseFor`); re-checking inside a filter would duplicate that
/// gate and could drift from the phase resolver. Each per-family filter wraps
/// this helper under its own documented name so the existing orchestrator /
/// filter test pins stay stable.
///
/// Pure and deterministic — identical inputs always yield identical results
/// (Refs #2509 Must-have #7). Performs no I/O, no logging, no order emission.
library;

import 'observer_goal_phase.dart';
import 'phase_planner_dispatch.dart';
import 'planning_helpers.dart' show resolvePhaseColonialPressureActive;

/// Whether colonial-acquisition pressure is structurally active for
/// [phasePlan] (`true` only under [ObserverGoalPhase.colonial]).
///
/// Single source of truth for the `resolvePhaseColonialPressureActive
/// (phasePlan.phase)` filter wrapper duplicated across
/// `phase_planner_conquest_filter.dart`,
/// `phase_planner_diplomacy_filter.dart`, and
/// `phase_planner_economy_filter.dart`. Unwraps [PhasePlanOutcome.phase] and
/// delegates to the bare-phase structural predicate
/// [resolvePhaseColonialPressureActive] in `planning_helpers.dart`, so the
/// `PhasePlanOutcome` → `phase` projection lives once. See the library doc
/// above for the full suppression matrix.
///
/// Pure and deterministic — identical inputs always yield identical results
/// (Refs #2509 Must-have #7).
bool phaseColonialPressureActiveFromPlan({
  required PhasePlanOutcome phasePlan,
}) => resolvePhaseColonialPressureActive(phasePlan.phase);
