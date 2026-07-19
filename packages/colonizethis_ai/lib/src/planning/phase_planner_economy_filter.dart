/// Phase-planner economy directive resolvers for orchestrator wiring
/// (Refs #2509 S5 slice — companion to `phase_planner_conquest_filter.dart`,
/// `phase_planner_naval_filter.dart`, `phase_planner_diplomacy_filter.dart`,
/// and `phase_planner_work_order_filter.dart`).
///
/// Two pure phase resolvers feed the orchestrator's economy pass off the
/// dispatched [PhasePlanOutcome]:
///
/// - [resolvePhaseEconomyColonialPressureActive] — gates the COLONIAL
///   economy boost (lower civilian threshold, force
///   `runFullAiCivilianWork`, `BuildPickInput.colonialPressure` cargo
///   bonus). Active only under [ObserverGoalPhase.colonial].
/// - [resolvePhaseEconomyDevelopActive] — gates the DEVELOP economy
///   civilian-work decisions (lower threshold to
///   [kDevelopCivilianWorkThresholdCap], force
///   `runFullAiCivilianWork`). Active only under
///   [ObserverGoalPhase.develop].
/// - [resolvePhaseEconomyExpandQuotaPressureActive] — gates the
///   below-quota OW build-pass arms in `_appendEconomyBuildOrders`
///   (stalled build threshold, GP-blocker focus, quota peace rebuild
///   helpers). Active only under [ObserverGoalPhase.expand] and
///   [ObserverGoalPhase.colonialLite]; field-equal to
///   [resolvePhaseConquestExtraPassesActive].
///
/// Both resolvers read **only** `outcome.phase` and never inspect
/// sibling slots. The dispatcher already resolved
/// `observerGoalPhaseFor` once via `runPhasePlanners`, so each resolver
/// replaces a per-call recompute (`hasColonialAcquisitionTargets`
/// three-predicate compute for the colonial pressure;
/// `isObserverDevelopPhase` for the develop gate) with an O(1) phase
/// comparison. Phase-derived `true/false` is field-equal to the legacy
/// computes across every [ObserverGoalPhase] value, preserving the
/// orchestrator's economy-pass behaviour exactly on the landed
/// post-S5 dispatch path.
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

import 'package:colonizethis_data/colonizethis_data.dart'
    hide cheapestRegimentBuildTreasuryCost;

import '../perception/perception_snapshot.dart';
import 'observer_goal_phase.dart';
import 'phase_filter_common.dart';
import 'phase_planner_conquest_filter.dart';
import 'phase_planner_dispatch.dart';
import 'phase_priority_weights.dart';
import 'planning_helpers.dart'
    show
        clampPhaseWeightUpperUnit,
        resolvePhaseNewWorldAcquisitionWeight,
        resolvePhaseNewWorldCivilianWeight,
        resolvePhaseOldWorldCivilianWeight;
import 'phase_planner_economy_filter_expand.dart';

export 'phase_planner_economy_filter_expand.dart';

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
}) => phaseColonialPressureActiveFromPlan(phasePlan: phasePlan);

/// When `true`, `_runEconomyDomainPlanners` treats the active player as
/// in the DEVELOP phase for the economy-pass civilian-work decisions:
/// the work threshold is lowered to [kDevelopCivilianWorkThresholdCap]
/// and `runFullAiCivilianWork` is forced on (so DEVELOP improvement
/// planning runs even when domain weights would otherwise gate it out).
///
/// Active only under [ObserverGoalPhase.develop]. EXPAND, COLONIAL-lite,
/// and COLONIAL all return `false`:
///
/// - EXPAND: civilian work is OW-focused and gated by the EXPAND
///   structural NW suppression; DEVELOP threshold cap must not lower
///   the floor for the OW push.
/// - COLONIAL-lite: per issue #2509 § COLONIAL-lite scope summary, the
///   safeguard runs naval/overture work without weakening the OW push;
///   the DEVELOP improvement cap is suppressed structurally so the
///   EXPAND civilian threshold remains in effect.
/// - COLONIAL: civilian work is driven by `colonialCivilianWorkOrders`
///   (via `civilianWorkOrdersFromPhasePlan`) and the COLONIAL build
///   cap; the DEVELOP improvement cap is structurally inactive.
///
/// Mirrors the legacy `isObserverDevelopPhase(snapshot, game)` compute
/// — phase-derived `true/false` is field-equal across every
/// [ObserverGoalPhase] value (the dispatcher already resolved
/// `observerGoalPhaseFor` once via `runPhasePlanners`), so the
/// migration is behaviour-preserving for the orchestrator economy
/// civilian-work decisions. The resolver mirrors the partition matrix
/// established by
/// [resolvePhaseDiplomacyDeclareWarDevelopSuppressionActive]
/// (`phase_planner_diplomacy_filter.dart`): every DEVELOP-gated
/// orchestrator decision routes through one of these phase-derived
/// resolvers instead of recomputing `observerGoalPhaseFor` per call
/// site.
///
/// Pure and deterministic — identical inputs always yield identical
/// resolutions (Refs #2509 Must-have #7). Performs no I/O, no logging,
/// no order emission.
bool resolvePhaseEconomyDevelopActive({required PhasePlanOutcome phasePlan}) =>
    phasePlan.phase == ObserverGoalPhase.develop;

/// Returns the build-order threshold cap that `_appendEconomyBuildOrders`
/// should clamp `buildThreshold` to when the active player already owns
/// at least one New World province and the soft-phase NW acquisition
/// weight is positive, or `null` when no cap applies.
///
/// Applies the `newWorldProvincesOwned > 0` tagalong, then delegates
/// the cap magnitude to [economyColonialPressureBuildOrderThresholdCap]
/// (Refs #2847 Phase 3 economy build-order threshold cap wiring).
///
/// Pure and deterministic — identical
/// `(PhasePlanOutcome, ColonialSummary)` inputs always yield
/// identical `int?` resolutions (Refs #2509 Must-have #7). Performs
/// no I/O, no logging, no order emission.
int? resolvePhaseEconomyColonialBuildOrderThresholdCap({
  required PhasePlanOutcome phasePlan,
  required ColonialSummary colonial,
}) {
  if (phasePlan.phase == ObserverGoalPhase.colonialLite ||
      phasePlan.phase == ObserverGoalPhase.develop) {
    return null;
  }
  if (colonial.newWorldProvincesOwned <= 0) {
    return null;
  }
  return economyColonialPressureBuildOrderThresholdCap(
    colonialPressureWeight: resolvePhaseEconomyColonialPressureWeight(
      phasePlan: phasePlan,
    ),
  );
}

/// When `true`, `_appendEconomyBuildOrders` applies the below-quota OW
/// build-pass arms (stalled build threshold cap, GP-blocker focus,
/// `isBelowQuotaPeace*` regiment-rebuild helpers, and the
/// `forceRegimentRebuild` stalled-expansion arm) for the active player.
///
/// Active only under [ObserverGoalPhase.expand] and
/// [ObserverGoalPhase.colonialLite] — field-equal to
/// [resolvePhaseConquestExtraPassesActive] because both phases require
/// `oldWorldProvincesOwned < kObserverConquestMinOwProvincesPerGp` at
/// entry via [observerGoalPhaseFor], which is precisely the condition
/// the legacy `isStalledOldWorldExpansion(ow)` /
/// `isBelowObserverConquestQuota(ow)` pair evaluated to.
///
/// COLONIAL and DEVELOP return `false` even when EXPAND slots on
/// [PhasePlanOutcome] are populated (structural phase separation).
///
/// Pure and deterministic — identical inputs always yield identical
/// resolutions (Refs #2509 Must-have #7).
double resolvePhaseEconomyColonialPressureWeight({
  required PhasePlanOutcome phasePlan,
}) => resolvePhaseNewWorldAcquisitionWeight(phasePlan);

/// Returns the economy-pass civilian-work threshold cap scaled by the
/// soft-phase NW acquisition weight (Refs #2847 Phase 3 economy
/// civilian-work threshold cap wiring).
///
/// `_runEconomyDomainPlanners` consumes this helper as the production
/// source of truth for the colonial-pressure civilian-work threshold
/// cap that previously activated as a hard
/// `workThreshold = min(workThreshold, kColonialCivilianWorkThresholdCap)`
/// step under the boolean [resolvePhaseEconomyColonialPressureActive].
/// The new helper interpolates the cap linearly from the uncapped
/// threshold (no cap) down to [kColonialCivilianWorkThresholdCap] as
/// [colonialPressureWeight] rises, so the civilian-work bar tracks the
/// soft-phase NW acquisition priority instead of stepping on/off at the
/// EXPAND→COLONIAL boundary:
///
/// - `colonialPressureWeight <= 0.0` returns [uncappedThreshold] (no cap
///   applied — legacy `colonialPressure: false` equivalent; the civilian
///   work bar keeps whatever value the spy-modifier base produced).
/// - `colonialPressureWeight == 1.0` returns
///   [kColonialCivilianWorkThresholdCap] exactly — identity-equal to the
///   legacy COLONIAL hard-phase cap.
/// - Intermediate `colonialPressureWeight` values return
///   `round(uncappedThreshold - (uncappedThreshold -
///   kColonialCivilianWorkThresholdCap) × colonialPressureWeight)`,
///   matching the continuous-scale contract used by the conquest
///   army-move floor, the naval colonial-pressure bonus/floor, the
///   goal-score floors, and the economy build-pick cargo bonus
///   (`SPEC/ai/phase-planner-architecture.md` § Phase 3 consumer
///   wiring).
///
/// At the early-sprint default curve (`newWorldAcquisition = 0.05` for
/// `oldWorldProvincesOwned <= 7`) with the default `uncappedThreshold`
/// of `40`, the cap collapses to `round(40 - 28 × 0.05) = 39` — a
/// one-point relaxation that leaves the OW conquest sprint civilian/build
/// balance essentially unchanged. At the resource-need override floor
/// (`newWorldAcquisition = 0.60`, the EXPAND geographic peer-war lock
/// recovery weight per § Resource-need overrides) the cap reaches
/// `round(40 - 28 × 0.60) = 23`, lowering the civilian-work bar so
/// colonial Builder / Merchant work can engage while a locked GP is still
/// in EXPAND.
///
/// The orchestrator applies `math.min(workThreshold, <result>)` so a base
/// threshold already at or below [kColonialCivilianWorkThresholdCap]
/// (after a large spy modifier) is never raised by this helper.
///
/// Pure and deterministic — identical
/// `(colonialPressureWeight, uncappedThreshold)` inputs always yield
/// identical `int` results (Refs #2509 Must-have #7). Performs no I/O,
/// no logging, no order emission. The function is a projection of two
/// scalar inputs and never reads `PhasePlanOutcome`, snapshot, or `Game`
/// state.
int economyColonialPressureCivilianWorkThresholdCap({
  required double colonialPressureWeight,
  required int uncappedThreshold,
}) {
  if (colonialPressureWeight <= 0.0) {
    return uncappedThreshold;
  }
  final clamped = clampPhaseWeightUpperUnit(colonialPressureWeight);
  final span = uncappedThreshold - kColonialCivilianWorkThresholdCap;
  return (uncappedThreshold - span * clamped).round();
}

/// Returns the economy-pass build-order threshold cap scaled by the
/// soft-phase NW acquisition weight (Refs #2847 Phase 3 economy
/// build-order threshold cap wiring).
///
/// `_appendEconomyBuildOrders` consumes this helper (via
/// [resolvePhaseEconomyColonialBuildOrderThresholdCap]) as the
/// production source of truth for the colonial build-order threshold
/// cap that previously activated as a hard
/// `buildThreshold = min(buildThreshold,
/// kColonialBuildOrderThresholdWhenOwnedNwUnderPressure)` step only
/// under the boolean [resolvePhaseEconomyColonialPressureActive]:
///
/// - `colonialPressureWeight <= 0.0` returns `null` (no cap applied —
///   legacy hard-suppress / EXPAND equivalent).
/// - `colonialPressureWeight == 1.0` returns
///   [kColonialBuildOrderThresholdWhenOwnedNwUnderPressure] exactly —
///   identity-equal to the legacy COLONIAL hard cap.
/// - Intermediate weights return
///   `round(kColonialBuildOrderThresholdWhenOwnedNwUnderPressure ×
///   colonialPressureWeight)` with the weight clamped to `[0.0, 1.0]`.
///
/// The orchestrator applies the result only when
/// `colonial.newWorldProvincesOwned > 0` (tagalong unchanged).
///
/// Pure and deterministic (Refs #2509 Must-have #7). Performs no I/O,
/// no logging, no order emission.
int? economyColonialPressureBuildOrderThresholdCap({
  required double colonialPressureWeight,
}) {
  if (colonialPressureWeight <= 0.0) {
    return null;
  }
  final clamped = clampPhaseWeightUpperUnit(colonialPressureWeight);
  return (kColonialBuildOrderThresholdWhenOwnedNwUnderPressure * clamped)
      .round();
}

/// Advisory `[0.0, 1.0]` multiplier for the OW civilian-work bias
/// (build / improvement / population orders on OW-owned land)
/// sourced from [PhasePriorityWeights.oldWorldCivilian] (Refs #2847
/// Phase 2 scaffolding).
///
/// Pairs with [resolvePhaseEconomyNewWorldCivilianWeight] to form the
/// OW/NW civilian weight pair that future Phase 3 consumer wiring
/// will multiply into the build-pipeline scoring. The boolean
/// [resolvePhaseEconomyDevelopActive] remains the production source
/// of truth for the DEVELOP threshold-cap / force-on civilian
/// decisions in this slice.
///
/// Pure and deterministic (Refs #2509 Must-have #7). Reads only
/// `phasePlan.priorityWeights`.
double resolvePhaseEconomyOldWorldCivilianWeight({
  required PhasePlanOutcome phasePlan,
}) => resolvePhaseOldWorldCivilianWeight(phasePlan);

/// Advisory `[0.0, 1.0]` multiplier for the NW civilian-work bias
/// (build / improvement / population orders on NW-owned land)
/// sourced from [PhasePriorityWeights.newWorldCivilian] (Refs #2847
/// Phase 2 scaffolding).
///
/// Companion of [resolvePhaseEconomyOldWorldCivilianWeight]. The
/// existing tag-along condition `snapshot.colonial.newWorldProvincesOwned > 0`
/// at the orchestrator call sites remains the structural gate in
/// this slice — Phase 3 wiring will fold the NW civilian weight into
/// the build-pipeline weighting where appropriate.
///
/// Pure and deterministic (Refs #2509 Must-have #7).
double resolvePhaseEconomyNewWorldCivilianWeight({
  required PhasePlanOutcome phasePlan,
}) => resolvePhaseNewWorldCivilianWeight(phasePlan);

/// Resource-need override predicate (Refs #2847 § Resource-need overrides).
///
/// True when treasury recovery cargo is active, the GP owns no NW
/// provinces, and cash treasury is exactly zero — the same triple that
/// lifts `newWorldAcquisition` to [kPhasePriorityNwTreasuryRecoveryFloor].
