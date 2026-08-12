import 'package:colonizethis_data/colonizethis_data.dart';

import 'observer_goal_phase.dart';
import 'phase_filter_common.dart';
import 'phase_planner_dispatch.dart';
import 'planning_helpers.dart'
    show
        resolvePhaseExpandOrColonialLiteActive,
        resolvePhaseNewWorldAcquisitionWeight,
        resolvePhaseOldWorldConquestWeight,
        scaleWeightedBonus;

/// When `true`, `runConquestArmyMovePlanner` applies the colonial-pressure
/// minimum weight floor (`kConquestArmyMoveMinWeightWhenColonialPressure`).
///
/// Active only under [ObserverGoalPhase.colonial] — structural, mirroring
/// full-COLONIAL NW invasion army moves. EXPAND, COLONIAL-lite, and DEVELOP
/// suppress the floor the same way they suppress NW declare-war / invasion
/// scoring (issue #2509 § phase suppressions).
bool resolvePhaseConquestColonialPressureActive({
  required PhasePlanOutcome phasePlan,
}) => phaseColonialPressureActiveFromPlan(phasePlan: phasePlan);

/// When `true`, NW invadable army-move destinations score `0` in the
/// conquest destination scorer (legacy `shouldSuppressNewWorldDeclareWar
/// InvasionAndPurchase` contract).
///
/// Suppressed under EXPAND, COLONIAL-lite, and DEVELOP; allowed under
/// COLONIAL only.
bool resolvePhaseConquestSuppressNwInvasionScoring({
  required PhasePlanOutcome phasePlan,
}) => phasePlan.phase != ObserverGoalPhase.colonial;

/// When `true`, `runDomainPlannersWithOutcome` runs
/// [kStalledConquestArmyMovePasses] conquest passes and **skips** the
/// follow-up army-relocation pass for the active player turn. When
/// `false`, the orchestrator runs a single conquest pass and lets the
/// relocation pass run normally.
///
/// Active only under [ObserverGoalPhase.expand] and
/// [ObserverGoalPhase.colonialLite] — both phases require
/// `oldWorldProvincesOwned < kObserverConquestMinOwProvincesPerGp` (10)
/// at entry via [observerGoalPhaseFor], which is precisely the
/// condition the legacy compound `isStalledOldWorldExpansion(ow) ||
/// isBelowObserverConquestQuota(ow)` evaluated to (for integer `ow` the
/// two `colonizethis_data` predicates are equivalent: both reduce to
/// `ow <= 9`). The resolver therefore is field-equal to the legacy
/// compound across every [ObserverGoalPhase] value, preserving the
/// prior extra-passes / relocation-skip behaviour exactly on the
/// landed post-S5 dispatch path.
///
/// Two orchestrator decisions consume this signal:
///
/// 1. **Extra conquest passes** — `runDomainPlannersWithOutcome` runs
///    [kStalledConquestArmyMovePasses] passes through
///    `runConquestArmyMovePlanner` instead of one so a stalled / below-quota
///    GP gets multiple chances to commit invadable-frontier moves in the
///    same turn (issue #2509 § Repository context "stalled conquest army
///    move passes").
/// 2. **Relocation pass guard** — the orchestrator skips
///    `runArmyMovePlanner` (the relocation pass) for the active turn so
///    frontier marches committed by the conquest passes are not undone
///    by an opportunistic relocation back toward the capital. The skip
///    is the *negation* of this resolver: under COLONIAL / DEVELOP
///    (above quota) the relocation pass runs normally.
///
/// Structural separation with sibling resolvers in this file:
///
/// - [resolvePhaseConquestColonialPressureActive] is the *complement*
///   slice (active only under COLONIAL); the colonial-pressure
///   minimum weight floor never fires under EXPAND / COLONIAL-lite
///   while extra passes are active.
/// - [resolvePhaseConquestSuppressNwInvasionScoring] is the *parallel*
///   suppression slice (active under EXPAND, COLONIAL-lite, **and**
///   DEVELOP); NW invasion army-move scoring is suppressed under
///   DEVELOP as well, but extra passes are not — DEVELOP has reached
///   the OW quota and runs only one conquest pass alongside the
///   relocation pass for any standing wars.
/// - [resolvePhaseConquestInvadable] retains its own DEVELOP-skip
///   short-circuit (`skipConquestPass: true`); the extra-passes
///   resolver is *not* consulted in that branch because the conquest
///   pass itself is skipped.
///
/// Pure and deterministic — identical inputs always yield identical
/// resolutions (Refs #2509 Must-have #7). Performs no I/O, no logging,
/// no order emission.
bool resolvePhaseConquestExtraPassesActive({
  required PhasePlanOutcome phasePlan,
}) => resolvePhaseExpandOrColonialLiteActive(phasePlan.phase);

/// Advisory `[0.0, 1.0]` multiplier for NW invasion scoring (declare-war
/// candidates against tribe/NW-owner targets, NW invasion army-move
/// destinations) sourced from
/// [PhasePriorityWeights.newWorldAcquisition] (Refs #2847 Phase 2
/// scaffolding).
///
/// Production NW invasion scoring multiplier for
/// `runConquestArmyMovePlanner` (Refs #2847 Phase 3). Replaces the
/// boolean [resolvePhaseConquestSuppressNwInvasionScoring] at the
/// conquest army-move scoring sites so the EXPAND→COLONIAL transition
/// is a continuous curve instead of a binary cliff
/// (`SPEC/ai/phase-planner-architecture.md` § Soft-phase priority
/// weights). The boolean remains for legacy call sites not yet migrated.
///
/// Pure and deterministic — identical `phasePlan.priorityWeights`
/// inputs always yield identical `double` results (Refs #2509
/// Must-have #7). Reads only `phasePlan.priorityWeights` and never
/// inspects sibling slots (the per-phase suppression matrix is encoded
/// in the [PhasePriorityWeights] curve + override floors that the
/// dispatcher computed once via [computePhasePriorityWeights]).
double resolvePhaseConquestNwInvasionWeight({
  required PhasePlanOutcome phasePlan,
}) => resolvePhaseNewWorldAcquisitionWeight(phasePlan);

/// Advisory `[0.0, 1.0]` multiplier for OW invasion scoring (declare-war
/// candidates against OW owners, OW invasion army-move destinations,
/// frontier-march pressure) sourced from
/// [PhasePriorityWeights.oldWorldConquest] (Refs #2847 Phase 2
/// scaffolding).
///
/// Companion to [resolvePhaseConquestNwInvasionWeight]; the two
/// resolvers form the OW/NW weight pair consumed by
/// `_scoreArmyMoveDestination` via [conquestOldWorldArmyMoveScaledBonus]
/// and [conquestNwInvadableArmyMoveBonus]. The booleans
/// [resolvePhaseConquestColonialPressureActive] and
/// [resolvePhaseConquestExtraPassesActive] remain the production
/// source of truth for extra-pass decisions until Phase 4 alignment.
///
/// Pure and deterministic (Refs #2509 Must-have #7). Reads only
/// `phasePlan.priorityWeights`.
double resolvePhaseConquestOldWorldInvasionWeight({
  required PhasePlanOutcome phasePlan,
}) => resolvePhaseOldWorldConquestWeight(phasePlan);

/// Advisory `[0.0, 1.0]` multiplier for the COLONIAL conquest
/// colonial-pressure minimum weight floor
/// (`kConquestArmyMoveMinWeightWhenColonialPressure` today) sourced
/// from [PhasePriorityWeights.newWorldAcquisition] (Refs #2847 Phase 2
/// scaffolding).
///
/// Companion to the boolean
/// [resolvePhaseConquestColonialPressureActive] which gates today's
/// hard "apply the floor" decision under COLONIAL only. The Phase 3
/// orchestrator-wiring slice will multiply the floor by this weight so
/// the colonial-pressure boost scales continuously with the active NW
/// acquisition priority instead of switching on/off at the
/// EXPAND→COLONIAL boundary.
///
/// Pure and deterministic (Refs #2509 Must-have #7). Reads only
/// `phasePlan.priorityWeights`.
double resolvePhaseConquestColonialPressureWeight({
  required PhasePlanOutcome phasePlan,
}) => resolvePhaseNewWorldAcquisitionWeight(phasePlan);

/// Returns the COLONIAL conquest army-move minimum weight floor scaled by
/// the soft-phase NW acquisition weight (Refs #2847 Phase 3 conquest
/// colonial-pressure floor wiring).
///
/// `runConquestArmyMovePlanner` consumes this helper as the production
/// source of truth for the colonial-pressure minimum-weight floor that
/// previously activated as a hard `weight = kConquestArmyMoveMinWeightWhenColonialPressure`
/// step under the boolean [resolvePhaseConquestColonialPressureActive].
/// The new helper scales that floor linearly with [colonialPressureWeight]
/// so the floor magnitude tracks the soft-phase NW acquisition priority:
///
/// - `colonialPressureWeight <= 0.0` returns `0` (no floor applied — legacy
///   `colonialPressure: false` equivalent; the conquest army-move pass
///   keeps whatever upstream weight the other floors produced).
/// - `colonialPressureWeight == 1.0` returns
///   [kConquestArmyMoveMinWeightWhenColonialPressure] exactly — identity-equal
///   to the legacy COLONIAL hard-phase floor.
/// - Intermediate `colonialPressureWeight` values return
///   `round(kConquestArmyMoveMinWeightWhenColonialPressure × colonialPressureWeight)`,
///   matching the continuous-scale contract used by the goal-score floors,
///   the economy build-pick cargo bonus, and the diplomacy declare-war
///   carve-out (`SPEC/ai/phase-planner-architecture.md` § Phase 3 consumer
///   wiring).
///
/// At the early-sprint default curve (`newWorldAcquisition = 0.05` for
/// `oldWorldProvincesOwned <= 7`) the floor collapses to
/// `round(45 × 0.05) = 2` — well below the
/// `kConquestArmyMoveMinWeightWhenStalled` / stalled-expansion floors so
/// the OW conquest sprint is not dominated by colonial-pressure pulls.
///
/// Pure and deterministic — identical [colonialPressureWeight] inputs
/// always yield identical `int` results (Refs #2509 Must-have #7).
/// Performs no I/O, no logging, no order emission. The function is a
/// projection of a single scalar input and never reads
/// `PhasePlanOutcome`, snapshot, or `Game` state.
int conquestColonialPressureMinWeightFloor({
  required double colonialPressureWeight,
}) => scaleWeightedBonus(
  colonialPressureWeight,
  kConquestArmyMoveMinWeightWhenColonialPressure,
);
