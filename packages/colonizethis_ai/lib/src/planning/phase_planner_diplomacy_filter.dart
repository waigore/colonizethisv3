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

/// When `true`, `_declareWarSuppressedDevelopPhaseScore`
/// (`diplomatic_candidate_scoring_declare_war.dart`) returns
/// `kDeclareWarNonAdjacentSuppressedScore` for every declare-war
/// candidate this turn, structurally collapsing every declare-war
/// candidate before any scoring branch runs (issue #2509 § DEVELOP
/// suppressions "No `declareWar` on anyone").
///
/// Active only under [ObserverGoalPhase.develop]. EXPAND, COLONIAL-lite,
/// and COLONIAL all return `false`:
///
/// - EXPAND: declare-war candidates are scored normally; NW colonial
///   targets fall through to [resolvePhaseDiplomacyDeclareWarExpandColonialSuppressionActive].
/// - COLONIAL-lite: declare-war candidates are scored normally; NW
///   colonial targets fall through to [resolvePhaseDiplomacyDeclareWarColonialLiteSuppressionActive]
///   (NW `declareWar` collapses, OW remains scorable).
/// - COLONIAL: declare-war candidates are scored normally; the
///   `colonialPressure && ownsInvadableNw` exception in
///   `_declareWarSuppressedWarConcentrationScore` keeps tribe targets
///   scorable.
///
/// Pure and deterministic — identical inputs always yield identical
/// resolutions (Refs #2509 Must-have #7). Performs no I/O, no logging,
/// no order emission.
bool resolvePhaseDiplomacyDeclareWarDevelopSuppressionActive({
  required PhasePlanOutcome phasePlan,
}) => phasePlan.phase == ObserverGoalPhase.develop;

/// When `true`, `_declareWarSuppressedColonialLiteScore`
/// (`diplomatic_candidate_scoring_declare_war.dart`) collapses NW
/// colonial declare-war targets (tribes, NW invadable owners,
/// colonial-adjacent owners) to
/// `kDeclareWarNonAdjacentSuppressedScore`, while leaving OW declare-war
/// candidates scorable (issue #2509 § COLONIAL-lite scope summary
/// "Suppressed: NW declareWar, NW invasion army moves, purchase_land in
/// NW" combined with the OW push remaining active during the safeguard).
///
/// Active only under [ObserverGoalPhase.colonialLite]. EXPAND, COLONIAL,
/// and DEVELOP all return `false`:
///
/// - EXPAND: NW collapse happens via
///   [resolvePhaseDiplomacyDeclareWarExpandColonialSuppressionActive]
///   instead — the EXPAND branch runs separately.
/// - COLONIAL: NW `declareWar` is the SPEC-authorized acquisition route
///   (issue #2509 § COLONIAL `planColonialAcquisition` step 3), so no
///   colonial-lite collapse fires.
/// - DEVELOP: every declare-war candidate already collapses via
///   [resolvePhaseDiplomacyDeclareWarDevelopSuppressionActive] before
///   the colonial-lite branch runs; the resolver returning `false`
///   keeps the structural ordering explicit.
///
/// Pure and deterministic — identical inputs always yield identical
/// resolutions (Refs #2509 Must-have #7). Performs no I/O, no logging,
/// no order emission.
bool resolvePhaseDiplomacyDeclareWarColonialLiteSuppressionActive({
  required PhasePlanOutcome phasePlan,
}) => phasePlan.phase == ObserverGoalPhase.colonialLite;

/// When `true`, `_declareWarSuppressedExpandColonialScore`
/// (`diplomatic_candidate_scoring_declare_war.dart`) collapses NW
/// colonial declare-war targets (tribes, NW invadable owners,
/// colonial-adjacent owners) to
/// `kDeclareWarNonAdjacentSuppressedScore`, while leaving OW declare-war
/// candidates scorable (issue #2509 § EXPAND NW suppression "structural
/// suppression — never imports or calls colonial modules").
///
/// Active only under [ObserverGoalPhase.expand]. COLONIAL-lite,
/// COLONIAL, and DEVELOP all return `false`:
///
/// - COLONIAL-lite: NW collapse happens via
///   [resolvePhaseDiplomacyDeclareWarColonialLiteSuppressionActive]
///   instead.
/// - COLONIAL: NW `declareWar` is the SPEC-authorized acquisition route.
/// - DEVELOP: every declare-war candidate already collapses via
///   [resolvePhaseDiplomacyDeclareWarDevelopSuppressionActive] before
///   the EXPAND branch runs; the resolver returning `false` keeps the
///   structural ordering explicit.
///
/// Mirrors the legacy `shouldSuppressNewWorldColonialOrders`
/// (`observer_goal_phase.dart`) which returned `phase == EXPAND` —
/// phase-derived `true/false` is field-equal across every
/// [ObserverGoalPhase] value, so the migration is behaviour-preserving
/// for the EXPAND-collapse scoring branch.
///
/// Pure and deterministic — identical inputs always yield identical
/// resolutions (Refs #2509 Must-have #7). Performs no I/O, no logging,
/// no order emission.
bool resolvePhaseDiplomacyDeclareWarExpandColonialSuppressionActive({
  required PhasePlanOutcome phasePlan,
}) => phasePlan.phase == ObserverGoalPhase.expand;
