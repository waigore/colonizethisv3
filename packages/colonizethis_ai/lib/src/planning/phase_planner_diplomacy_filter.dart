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

import 'dart:math' as math;

import 'package:colonizethis_data/colonizethis_data.dart';

import 'observer_goal_phase.dart';
import 'phase_planner_dispatch.dart';
import 'phase_priority_weights.dart';
import 'planning_helpers.dart'
    show
        resolvePhaseColonialPressureActive,
        resolvePhaseNewWorldAcquisitionWeight,
        resolvePhaseOldWorldConquestWeight,
        scaleWeightedBonus;

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
}) => resolvePhaseColonialPressureActive(phasePlan.phase);

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

/// Returns the NW-tribe declare-war dominance bonus scaled by the soft-phase
/// NW acquisition weight (Refs #2847 Phase 3 diplomacy declare-war NW-tribe
/// bonus wiring).
///
/// `_declareWarColonialNwTribeBonuses`
/// (`diplomatic_candidate_scoring_declare_war_bonuses.dart`) consumes this
/// helper as the production source of truth for the
/// [kDeclareWarColonialNwTribeDominanceBonus] addend that previously applied
/// at its **full** magnitude whenever the binary `colonialPressure`
/// (`nwAcquisitionWeight > 0.0`) gate fired. Scaling the addend linearly with
/// [nwAcquisitionWeight] realises requirement clarification #1/#2/#6 — the
/// active phase biases the *magnitude* of the NW-acquisition module's score
/// contribution along the continuous weight curve instead of switching the
/// full bonus on/off at the EXPAND→COLONIAL boundary:
///
/// - `nwAcquisitionWeight <= 0.0` returns `0` (legacy `colonialPressure:
///   false` equivalent; the caller's `colonialPressure` guard already
///   short-circuits before this helper at zero weight).
/// - `nwAcquisitionWeight == 1.0` returns
///   [kDeclareWarColonialNwTribeDominanceBonus] exactly (identity-equal to the
///   legacy full-magnitude addend).
/// - Intermediate weights return
///   `round(kDeclareWarColonialNwTribeDominanceBonus × nwAcquisitionWeight)`,
///   matching the continuous-scale contract used by the conquest army-move
///   colonial-pressure floor, the goal-score colonial-pressure floors, the
///   economy build-pick cargo bonus, and the naval colonial-pressure bonus
///   (`SPEC/ai/phase-planner-architecture.md` § Phase 3 consumer wiring).
///
/// At the early-sprint default curve (`newWorldAcquisition = 0.05` for
/// `oldWorldProvincesOwned <= 7`) the dominance addend collapses to
/// `round(100 × 0.05) = 5`, keeping the early OW conquest sprint dominant so
/// the gp1/gp2 +6 OW baseline is preserved by construction; the § Resource-need
/// treasury-recovery (`0.60`) / zero-regiment (`0.30`) override floors keep a
/// proportionate NW-tribe bias for locked GPs.
///
/// Pure and deterministic — identical [nwAcquisitionWeight] inputs always
/// yield identical `int` results (Refs #2509 Must-have #7). The function is a
/// projection of a single scalar input and never reads `PhasePlanOutcome`,
/// snapshot, or `Game` state. Out-of-range weights clamp (`> 1.0 -> 1.0`,
/// `< 0.0 -> 0.0`) so callers do not need to clamp upstream.
int declareWarColonialNwTribeDominanceBonus({
  required double nwAcquisitionWeight,
}) => _scaleDeclareWarColonialNwTribeBonus(
  baseBonus: kDeclareWarColonialNwTribeDominanceBonus,
  nwAcquisitionWeight: nwAcquisitionWeight,
);

/// Returns the NW-tribe "priority over OW minor" declare-war bonus scaled by
/// the soft-phase NW acquisition weight (Refs #2847 Phase 3 diplomacy
/// declare-war NW-tribe bonus wiring).
///
/// Companion to [declareWarColonialNwTribeDominanceBonus] for the
/// [kDeclareWarColonialNwTribePriorityOverOwMinorBonus] addend, which
/// `_declareWarColonialNwTribeBonuses` applies on top of the dominance bonus
/// when colonial pressure is active **and** Old World expansion is stalled so
/// NW tribe targets out-rank stacked OW-minor declare-war bonuses. This addend
/// is the literal OW-vs-NW candidate-selection lever requirement clarification
/// #6 describes ("NW declare-war candidates score normally and compete against
/// OW candidates"); scaling it by the weight makes that competition
/// proportional to the active NW acquisition priority rather than a binary
/// override. Because the addend is gated on `stalledOwExpansion` (below the OW
/// quota) it never fires for above-quota GPs, so scaling it cannot weaken the
/// OW push of GPs that have already cleared the conquest gate.
///
/// Scaling, clamping, identity (`1.0`), zero (`<= 0.0`), and determinism
/// semantics match [declareWarColonialNwTribeDominanceBonus]; at the
/// early-sprint default curve the addend collapses to `round(360 × 0.05) = 18`.
int declareWarColonialNwTribePriorityOverOwMinorBonus({
  required double nwAcquisitionWeight,
}) => _scaleDeclareWarColonialNwTribeBonus(
  baseBonus: kDeclareWarColonialNwTribePriorityOverOwMinorBonus,
  nwAcquisitionWeight: nwAcquisitionWeight,
);

int _scaleDeclareWarColonialNwTribeBonus({
  required int baseBonus,
  required double nwAcquisitionWeight,
}) => scaleWeightedBonus(nwAcquisitionWeight, baseBonus);

/// Returns an OW declare-war additive bonus scaled by the soft-phase
/// OW conquest weight (Refs #2847 Phase 3 diplomacy declare-war OW
/// scoring).
///
/// `_declareWarAdjacencyAndStalledBonuses` and related OW-expansion
/// paths consume this helper as the production source of truth for
/// OW-minor / stalled-OW / invadable-blocker addends that previously
/// applied at full magnitude every turn. Scaling mirrors
/// [conquestOldWorldArmyMoveScaledBonus] on the army-move path:
///
/// - `oldWorldConquestWeight <= 0.0` returns `0` (legacy
///   hard-suppress equivalent).
/// - `oldWorldConquestWeight == 1.0` returns [baseBonus] exactly.
/// - Intermediate weights return `round(baseBonus × weight)` with
///   clamping to `[0.0, 1.0]`.
///
/// At the early-sprint default curve (`oldWorldConquest = 0.95` for
/// OW ≤ 7) OW declare-war bonuses retain `95%` of their legacy
/// magnitudes so the gp1/gp2 +6 OW baseline is preserved. The §
/// Resource-need override never weakens `oldWorldConquest`.
///
/// Pure and deterministic (Refs #2509 Must-have #7).
int declareWarOldWorldConquestScaledBonus({
  required int baseBonus,
  required double oldWorldConquestWeight,
}) => scaleWeightedBonus(oldWorldConquestWeight, baseBonus);

/// Raises [currentScore] to the OW-conquest-scaled [floorBonus] floor, never
/// lowering it (Refs #3717 declare-war OW-conquest scoring-skeleton dedup).
///
/// Single source of truth for the repeated declare-war "raise the running
/// score to at least this OW-expansion floor" skeleton that previously inlined
/// `math.max(s, declareWarOldWorldConquestScaledBonus(baseBonus: floor,
/// oldWorldConquestWeight: ...))` across `_declareWarAdjacencyAndStalledBonuses`
/// and `_declareWarFinalizeBonuses` in
/// `diplomatic_candidate_scoring_declare_war_bonuses.dart`. The floor bonus is
/// scaled by [declareWarOldWorldConquestScaledBonus] (so it follows the same
/// soft-phase OW-conquest weight curve as additive OW bonuses) and the result
/// is taken as `max(currentScore, scaledFloor)` — byte-identical to the inline
/// form it replaces.
///
/// Pure and deterministic (Refs #2509 Must-have #7).
int raiseToDeclareWarOldWorldConquestFloor({
  required int currentScore,
  required int floorBonus,
  required double oldWorldConquestWeight,
}) => math.max(
  currentScore,
  declareWarOldWorldConquestScaledBonus(
    baseBonus: floorBonus,
    oldWorldConquestWeight: oldWorldConquestWeight,
  ),
);
