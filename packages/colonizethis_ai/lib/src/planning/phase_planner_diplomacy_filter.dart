/// Phase-planner diplomacy directive resolver for declare-war scoring
/// (Refs #2509 S5 slice — companion to `phase_planner_conquest_filter.dart`,
/// `phase_planner_economy_filter.dart`, `phase_planner_naval_filter.dart`,
/// and `phase_planner_work_order_filter.dart`).
///
/// Resolves whether `_DeclareWarTargetContext.build` (consumed by
/// `_scoreDeclareWarDiplomaticOrder` in `diplomatic_candidate_scoring_declare_war.dart`)
/// should treat colonial acquisition pressure as active when scoring a
/// candidate `declareWar` order. The boolean drives a single
/// scoring decision today:
///
/// - `_declareWarSuppressedWarConcentrationScore` allows a tribe target
///   declare-war candidate (which would otherwise collapse under
///   stalled-OW + behind-victory-pace + invadable-OW-minor preconditions)
///   when `colonialPressure && ownsInvadableNw` — i.e. the tribe owns an
///   invadable NW province and the active player is in the COLONIAL phase
///   pursuing acquisition. Phase-derived `colonialPressure` keeps the
///   exception structurally limited to COLONIAL, where NW invasion is
///   the SPEC-authorized acquisition route, and excludes EXPAND /
///   COLONIAL-lite / DEVELOP where NW `declareWar` is structurally
///   suppressed by other branches before this scoring path runs.
///
/// Suppression matrix (mirrors `SPEC/ai/phase-planner-dispatch.md` §
/// Adapter helpers, declare-war scoring row, and § Orchestrator
/// declare-war scoring slice):
///
/// | Phase | Declare-war colonial pressure | Notes |
/// |---|---|---|
/// | [ObserverGoalPhase.expand] | `false` (structural) | EXPAND never scores NW `declareWar` against tribes — `_declareWarSuppressedExpandColonialScore` collapses NW colonial targets to `kDeclareWarNonAdjacentSuppressedScore` before war-concentration scoring runs. The `colonialPressure && ownsInvadableNw` exception is therefore unreachable under EXPAND, and the resolver returns `false` to make that structural fact explicit. |
/// | [ObserverGoalPhase.colonialLite] | `false` (structural) | COLONIAL-lite explicitly suppresses NW `declareWar` per issue #2509 § COLONIAL-lite scope summary ("Suppressed: NW declareWar, NW invasion army moves, purchase_land in NW"). `_declareWarSuppressedColonialLiteScore` collapses NW colonial targets in COLONIAL-lite the same way EXPAND does, so colonial pressure is structurally inactive in this scoring path under the safeguard. |
/// | [ObserverGoalPhase.colonial] | `true` | Full COLONIAL is the only phase that allows NW `declareWar` (issue #2509 § COLONIAL `planColonialAcquisition` step 3 "declareWar + invade"). The exception in `_declareWarSuppressedWarConcentrationScore` is the SPEC-authorized exit ramp for the stalled-OW-frontier suppression when the tribe owns an invadable NW province. |
/// | [ObserverGoalPhase.develop] | `false` (structural) | DEVELOP forbids new wars (issue #2509 § DEVELOP suppressions). `_declareWarSuppressedDevelopPhaseScore` collapses every declare-war candidate to `kDeclareWarNonAdjacentSuppressedScore` regardless of target type, so the resolver returns `false` to make the suppression contract explicit at the colonial-pressure layer. |
///
/// The active-phase signal for COLONIAL is **structural**: the resolver
/// does not re-check whether visible NW invadable is non-empty. The
/// phase-planner dispatcher already gated entry to COLONIAL on
/// `hasColonialAcquisitionTargets` (`observerGoalPhaseFor`). Re-checking
/// inside the declare-war scoring path would duplicate that gate and
/// could drift from the phase resolver. The structural exclusion of
/// COLONIAL-lite mirrors `resolvePhaseConquestColonialPressureActive`
/// and `resolvePhaseEconomyColonialPressureActive` — every COLONIAL-only
/// adapter under #2509 S5 routes to the same single-COLONIAL-phase
/// gate, preserving the architectural property that COLONIAL-lite is a
/// *safeguard*, not a full-COLONIAL substitute.
///
/// The resolver is pure and deterministic — identical inputs always
/// yield identical resolutions (Refs #2509 Must-have #7). It performs
/// no I/O, no logging, and no order emission.
library;

import 'observer_goal_phase.dart';
import 'phase_planner_dispatch.dart';

/// When `true`, `_DeclareWarTargetContext.build` flags the candidate's
/// `colonialPressure` slot for `_declareWarSuppressedWarConcentrationScore`
/// so the `colonialPressure && ownsInvadableNw` exception keeps the
/// tribe declare-war candidate scorable under stalled-OW + behind-victory
/// pace preconditions.
///
/// Active only under [ObserverGoalPhase.colonial] — structural,
/// mirroring [resolvePhaseConquestColonialPressureActive] and
/// [resolvePhaseEconomyColonialPressureActive]. EXPAND, COLONIAL-lite,
/// and DEVELOP all return `false`:
///
/// - EXPAND: NW `declareWar` candidates already collapse via
///   `_declareWarSuppressedExpandColonialScore` before reaching the
///   war-concentration scoring branch, so the exception is unreachable.
/// - COLONIAL-lite: spec safeguard explicitly forbids NW `declareWar`
///   (issue #2509 § COLONIAL-lite scope summary). The COLONIAL-lite
///   naval/overture safeguard runs independently of declare-war scoring.
/// - DEVELOP: every declare-war candidate is collapsed by
///   `_declareWarSuppressedDevelopPhaseScore`, so colonial pressure
///   has no effect.
///
/// Pure and deterministic — identical inputs always yield identical
/// resolutions (Refs #2509 Must-have #7). Performs no I/O, no logging,
/// no order emission.
bool resolvePhaseDiplomacyDeclareWarColonialPressureActive({
  required PhasePlanOutcome phasePlan,
}) => phasePlan.phase == ObserverGoalPhase.colonial;
