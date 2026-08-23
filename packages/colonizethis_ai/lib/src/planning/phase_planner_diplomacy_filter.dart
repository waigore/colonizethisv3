/// Phase-planner diplomacy directive resolvers for declare-war scoring
/// (Refs #2509 S5; #4602 Slice A).
///
/// Cite `SPEC/ai/phase-planner-dispatch.md` (adapter helpers / declare-war
/// scoring) and `SPEC/ai/ai-architecture.md` § Observer goal phases rather
/// than restating the suppression matrix here.
library;

import 'observer_goal_phase.dart';
import 'phase_filter_common.dart';
import 'phase_planner_dispatch.dart';
import 'phase_priority_weights.dart';
import 'planning_helpers.dart'
    show
        resolvePhaseNewWorldAcquisitionWeight,
        resolvePhaseOldWorldConquestWeight;

export 'phase_planner_diplomacy_filter_bonuses.dart';

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
}) => phaseColonialPressureActiveFromPlan(phasePlan: phasePlan);

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

/// Advisory `[0.0, 1.0]` multiplier for the declare-war scoring NW
/// colonial-pressure exception sourced from
/// [PhasePriorityWeights.newWorldAcquisition] (Refs #2847 Phase 2
/// scaffolding).
///
/// Weight-aware companion of the structural boolean
/// [resolvePhaseDiplomacyDeclareWarColonialPressureActive]; the
/// boolean remains the production source of truth in this
/// scaffolding slice — `_declareWarSuppressedWarConcentrationScore`
/// still flags `colonialPressure` from the boolean. Phase 3
/// orchestrator wiring will multiply the colonial-pressure exception
/// branch's score adjustment by this weight so the `ownsInvadableNw`
/// keep-scorable carve-out scales continuously with the active NW
/// acquisition priority instead of switching on/off at the
/// EXPAND→COLONIAL boundary.
///
/// Pure and deterministic — identical `phasePlan.priorityWeights`
/// inputs always yield identical `double` results (Refs #2509
/// Must-have #7). Reads only `phasePlan.priorityWeights`.
double resolvePhaseDiplomacyDeclareWarColonialPressureWeight({
  required PhasePlanOutcome phasePlan,
}) => resolvePhaseNewWorldAcquisitionWeight(phasePlan);

/// Production `[0.0, 1.0]` multiplier for OW declare-war scoring bias
/// sourced from [PhasePriorityWeights.oldWorldConquest] (Refs #2847
/// Phase 3 diplomacy declare-war OW scoring).
///
/// Pairs with [resolvePhaseDiplomacyDeclareWarColonialPressureWeight]
/// to form the OW/NW weight pair consumed by `_scoreDeclareWarBonuses`
/// via [declareWarOldWorldConquestScaledBonus]. Structural booleans
/// continue to gate the suppression matrix
/// (`resolvePhaseDiplomacyDeclareWarDevelopSuppressionActive`, etc.)
/// unchanged.
///
/// Pure and deterministic (Refs #2509 Must-have #7). Reads only
/// `phasePlan.priorityWeights`.
double resolvePhaseDiplomacyDeclareWarOldWorldConquestWeight({
  required PhasePlanOutcome phasePlan,
}) => resolvePhaseOldWorldConquestWeight(phasePlan);
