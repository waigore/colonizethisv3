/// Phase-planner economy directive resolver for orchestrator wiring
/// (Refs #2509 S5 slice — companion to `phase_planner_conquest_filter.dart`,
/// `phase_planner_naval_filter.dart`, and `phase_planner_work_order_filter.dart`).
///
/// Resolves whether `_runEconomyDomainPlanners` should engage the colonial
/// economy boost this turn for the active player, given a single
/// [PhasePlanOutcome]. The boolean drives three economy-pass decisions
/// today:
///
/// 1. Civilian work threshold cap (`kColonialCivilianWorkThresholdCap`):
///    lowered when colonial economy pressure is active so civilian planning
///    triggers below the default 40-weight bar.
/// 2. `runFullAiCivilianWork` gate: forces the civilian planner to run
///    even when domain weights are below threshold so colonial builders
///    and merchants get a chance to act.
/// 3. `BuildPickInput.colonialPressure` (`pickBuildOrder` in
///    `build_planner.dart`): adds the cargo-ship build bonus
///    (`+2.5` cargo bonus when `cargoHold > 0`) so cargo capacity grows
///    while colonial pressure is active.
///
/// Suppression matrix (mirrors `SPEC/ai/phase-planner-dispatch.md` §
/// Adapter helpers, economy row, and § Orchestrator economy slice):
///
/// | Phase | Colonial economy pressure | Notes |
/// |---|---|---|
/// | [ObserverGoalPhase.expand] | `false` (structural) | EXPAND never weights economy toward NW activity; matches today's `shouldSuppressNewWorldColonialOrders` gate. |
/// | [ObserverGoalPhase.colonialLite] | `false` (structural) | COLONIAL-lite is the EXPAND safeguard: NW overture/naval is permitted, but the spec explicitly forbids weakening the OW quota push by biasing economy/build toward NW cargo or lowering civilian thresholds (issue #2509 § COLONIAL-lite "Begin NW penetration without weakening OW push"). |
/// | [ObserverGoalPhase.colonial] | `true` | Full COLONIAL drives every NW economic path — cargo bias, civilian threshold cap, full civilian planner run. |
/// | [ObserverGoalPhase.develop] | `false` (structural) | DEVELOP focuses on improvements (driven by `developCivilianWorkOrders`), not acquisition pressure. |
///
/// The active-phase signal for COLONIAL is **structural**: the resolver
/// does not re-check whether visible NW invadable is non-empty. The
/// phase-planner dispatcher already gated entry to COLONIAL on
/// `hasColonialAcquisitionTargets` (`observerGoalPhaseFor`). Re-checking
/// inside the economy pass would duplicate that gate and could drift from
/// the phase resolver. The structural exclusion of COLONIAL-lite mirrors
/// the conquest resolver `resolvePhaseConquestColonialPressureActive`
/// (active only under COLONIAL), preserving the architectural property
/// that COLONIAL-lite is a *safeguard*, not a full-COLONIAL substitute.
///
/// The resolver is pure and deterministic — identical inputs always
/// yield identical resolutions (Refs #2509 Must-have #7). It performs no
/// I/O, no logging, and no order emission.
library;

import 'observer_goal_phase.dart';
import 'phase_planner_dispatch.dart';

/// When `true`, `_runEconomyDomainPlanners` lowers the civilian work
/// threshold to `kColonialCivilianWorkThresholdCap`, forces the
/// civilian planner to run, and passes `colonialPressure: true` into
/// `BuildPickInput` so cargo-capable ships receive the colonial cargo
/// build bonus (`pickBuildOrder` in `build_planner.dart`).
///
/// Active only under [ObserverGoalPhase.colonial] — structural,
/// mirroring [resolvePhaseConquestColonialPressureActive]
/// (`phase_planner_conquest_filter.dart`). EXPAND, COLONIAL-lite, and
/// DEVELOP all return `false`:
///
/// - EXPAND: NW economy bias never applies (legacy
///   `shouldSuppressNewWorldColonialOrders` gate).
/// - COLONIAL-lite: spec safeguard — issue #2509 § COLONIAL-lite
///   "Begin NW penetration without weakening OW push" forbids biasing
///   economy/build toward NW cargo while still below the OW quota.
///   The COLONIAL-lite naval/overture safeguard runs independently of
///   the economy boost.
/// - DEVELOP: no acquisition pressure to weight economy toward; the
///   improvement push runs through `civilianWorkOrdersFromPhasePlan`
///   (`developCivilianWorkOrders`).
///
/// The tagalong `snapshot.colonial.newWorldProvincesOwned > 0`
/// condition at the orchestrator call sites still independently
/// lowers the civilian threshold and gates `runFullAiCivilianWork`,
/// so a GP that already owns at least one NW province continues to
/// receive the civilian-planner pass even under EXPAND or
/// COLONIAL-lite — only the *acquisition-pressure* boost is gated
/// by this resolver.
///
/// Pure and deterministic — identical inputs always yield identical
/// resolutions (Refs #2509 Must-have #7). Performs no I/O, no logging,
/// no order emission.
bool resolvePhaseEconomyColonialPressureActive({
  required PhasePlanOutcome phasePlan,
}) => phasePlan.phase == ObserverGoalPhase.colonial;
