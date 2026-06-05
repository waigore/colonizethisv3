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
import 'package:colonizethis_models/colonizethis_models.dart';

import '../perception/perception_snapshot.dart';
import 'expand_phase_planner.dart'
    show ExpandEconomyPlan, cheapestRegimentBuildTreasuryCost;
import 'observer_goal_phase.dart';
import 'phase_planner_conquest_filter.dart';
import 'phase_planner_dispatch.dart';
import 'phase_priority_weights.dart';
import 'planning_helpers.dart' show resolvePhaseColonialPressureActive;

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
}) => resolvePhaseColonialPressureActive(phasePlan.phase);

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
bool resolvePhaseEconomyExpandQuotaPressureActive({
  required PhasePlanOutcome phasePlan,
}) => resolvePhaseConquestExtraPassesActive(phasePlan: phasePlan);

/// When `true`, `_appendEconomyBuildOrders` applies the GP-blocker-focus
/// build threshold cap (`min(buildThreshold, 8)`).
///
/// Field-equal to legacy `isStalledOldWorldGpBlockerFocus` when
/// [resolvePhaseEconomyExpandQuotaPressureActive] is already `true`:
/// EXPAND / COLONIAL-lite phase entry requires
/// `oldWorldProvincesOwned < kObserverConquestMinOwProvincesPerGp`, so
/// the below-quota arm of the legacy helper is satisfied structurally
/// and the remaining signal is
/// [PhasePlanOutcome.expandGpOnlyInvadableFrontierActive] (computed once
/// in [runPhasePlanners] via [expandIsOldWorldGpOnlyInvadableFrontier]).
///
/// Returns `false` under COLONIAL and DEVELOP even when the expand
/// frontier slots are populated.
bool resolvePhaseEconomyExpandGpBlockerFocusActive({
  required PhasePlanOutcome phasePlan,
}) =>
    resolvePhaseEconomyExpandQuotaPressureActive(phasePlan: phasePlan) &&
    phasePlan.expandGpOnlyInvadableFrontierActive;

/// Returns the primary OW invadable GP blocker faction id for economy
/// build-pass routing when [resolvePhaseEconomyExpandGpBlockerFocusActive]
/// is `true`, or `null` otherwise.
///
/// Replaces the per-build-pass `primaryInvadableOldWorldGpBlocker`
/// recompute in `_appendEconomyBuildOrders` when the dispatched phase
/// plan is set. Phase-derived `String?` is field-equal to the legacy
/// helper across every reachable `(ObserverGoalPhase, AIWorldSnapshot)`
/// pair because the dispatcher already computed the blocker once via
/// [expandPrimaryInvadableOldWorldGpBlocker].
String? expandPrimaryInvadableGpBlockerFromPhasePlan({
  required PhasePlanOutcome phasePlan,
}) {
  if (!resolvePhaseEconomyExpandGpBlockerFocusActive(phasePlan: phasePlan)) {
    return null;
  }
  return phasePlan.expandPrimaryInvadableGpBlockerFactionId;
}

/// When `true`, `_appendEconomyBuildOrders` should treat the active
/// player as the seed-42 "EXPAND regiment-rebuild trap" case: a
/// below-quota EXPAND GP at peace with every other Great Power, holding
/// a small but non-zero standing regiment count
/// (`[1, kBelowQuotaPeaceMinRegimentsBeforeDeclareWar)`) and a non-empty
/// invadable OW frontier. The orchestrator routes this into both
/// `forceRegimentRebuild` and `militaryRebuildCrisis` so the next build
/// pass produces a cheapest-regiment order instead of stalling on
/// civilian work.
///
/// Replaces the per-build-pass `expandQuotaPressure &&
/// isBelowQuotaPeaceInsufficientRegiments(...)` compose in
/// `_appendEconomyBuildOrders` (`colonial_pressure.dart`). The phase
/// gate folded into the resolver is field-equal to the prior
/// `expandQuotaPressure` prefix because
/// [resolvePhaseEconomyExpandQuotaPressureActive] is itself field-equal
/// to `isBelowObserverConquestQuota(ow)` (both routes resolve to
/// `phase ∈ {EXPAND, COLONIAL-lite}`, which by [observerGoalPhaseFor]
/// is precisely `ow < kObserverConquestMinOwProvincesPerGp`). The legacy
/// helper's first guard (`isBelowObserverConquestQuota(ow)`) is therefore
/// satisfied structurally; the remaining
/// `!atWarWithAnyGreatPower &&
/// 0 < regimentCount < kBelowQuotaPeaceMinRegimentsBeforeDeclareWar &&
/// hasInvadableProvinces` arms are evaluated directly here so the
/// orchestrator never needs to import `colonial_pressure.dart` to make
/// this decision.
///
/// Structural suppression matrix (mirrors
/// [resolvePhaseEconomyExpandQuotaPressureActive]):
///
/// - [ObserverGoalPhase.expand]: routes legacy arms when the per-turn
///   peace/regiment/invadable inputs satisfy them; returns `false`
///   otherwise.
/// - [ObserverGoalPhase.colonialLite]: same routing as EXPAND — the
///   COLONIAL-lite safeguard explicitly preserves the EXPAND
///   regiment-rebuild crisis arm so the OW push is not weakened by NW
///   overture/naval work (issue #2509 § COLONIAL-lite "Begin NW
///   penetration without weakening OW push").
/// - [ObserverGoalPhase.colonial]: returns `false` regardless of
///   per-turn inputs (structural — at or above quota, the rebuild trap
///   does not apply).
/// - [ObserverGoalPhase.develop]: returns `false` regardless of
///   per-turn inputs (structural — DEVELOP drives improvement work,
///   not regiment rebuild).
///
/// Pure and deterministic — identical `(PhasePlanOutcome,
/// regimentCount, atWarWithAnyGreatPower, hasInvadableProvinces)`
/// inputs always yield identical resolutions (Refs #2509 Must-have #7).
/// Performs no I/O, no logging, no order emission.
bool resolvePhaseEconomyExpandBelowQuotaPeaceInsufficientRegimentsActive({
  required PhasePlanOutcome phasePlan,
  required int regimentCount,
  required bool atWarWithAnyGreatPower,
  required bool hasInvadableProvinces,
}) {
  if (!resolvePhaseEconomyExpandQuotaPressureActive(phasePlan: phasePlan)) {
    return false;
  }
  if (atWarWithAnyGreatPower) {
    return false;
  }
  if (regimentCount <= 0 ||
      regimentCount >= kBelowQuotaPeaceMinRegimentsBeforeDeclareWar) {
    return false;
  }
  return hasInvadableProvinces;
}

/// When `true`, `_appendEconomyBuildOrders` should treat the active
/// player as a below-quota EXPAND GP that has fallen to **zero**
/// regiments while still holding an invadable OW frontier. The
/// orchestrator routes this into `minRegimentFloor = 1`,
/// `forceRegimentRebuild`, and `militaryRebuildCrisis` so the next
/// build pass produces a cheapest-regiment order (this is the
/// strict-zero arm of the EXPAND regiment-rebuild trap and is the only
/// path that drops the regiment floor to a single regiment).
///
/// Replaces the per-build-pass `expandQuotaPressure &&
/// isBelowQuotaPeaceZeroRegimentsRebuild(...)` compose in
/// `_appendEconomyBuildOrders` (`colonial_pressure.dart`). The phase
/// gate folded into the resolver is field-equal to the prior
/// `expandQuotaPressure` prefix because
/// [resolvePhaseEconomyExpandQuotaPressureActive] is itself field-equal
/// to `isBelowObserverConquestQuota(ow)`. The legacy helper's first
/// guard is therefore satisfied structurally; the remaining
/// `regimentCount == 0 && hasInvadableProvinces` arms are evaluated
/// directly here so the orchestrator never needs to import
/// `colonial_pressure.dart` to make this decision.
///
/// Structural suppression matrix (mirrors
/// [resolvePhaseEconomyExpandQuotaPressureActive]):
///
/// - [ObserverGoalPhase.expand]: returns `regimentCount == 0 &&
///   hasInvadableProvinces`.
/// - [ObserverGoalPhase.colonialLite]: same routing as EXPAND — the
///   COLONIAL-lite safeguard preserves the EXPAND regiment-rebuild
///   crisis arm (issue #2509 § COLONIAL-lite).
/// - [ObserverGoalPhase.colonial]: returns `false` regardless of
///   per-turn inputs.
/// - [ObserverGoalPhase.develop]: returns `false` regardless of
///   per-turn inputs.
///
/// Pure and deterministic — identical `(PhasePlanOutcome,
/// regimentCount, hasInvadableProvinces)` inputs always yield
/// identical resolutions (Refs #2509 Must-have #7). Performs no I/O,
/// no logging, no order emission.
bool resolvePhaseEconomyExpandBelowQuotaPeaceZeroRegimentsRebuildActive({
  required PhasePlanOutcome phasePlan,
  required int regimentCount,
  required bool hasInvadableProvinces,
}) {
  if (!resolvePhaseEconomyExpandQuotaPressureActive(phasePlan: phasePlan)) {
    return false;
  }
  return regimentCount == 0 && hasInvadableProvinces;
}

/// Advisory `[0.0, 1.0]` multiplier for the economy-pass colonial
/// pressure boost (civilian threshold cap, `runFullAiCivilianWork`
/// force-on, `BuildPickInput.colonialPressure` cargo bonus) sourced
/// from [PhasePriorityWeights.newWorldAcquisition] (Refs #2847 Phase 2
/// scaffolding).
///
/// Weight-aware companion of the structural boolean
/// [resolvePhaseEconomyColonialPressureActive]; the boolean remains
/// the production source of truth in this scaffolding slice. Phase 3
/// orchestrator wiring will migrate the cargo / civilian-threshold
/// scoring sites to multiply candidate weights by this resolver so
/// the colonial cargo bias scales continuously with the active NW
/// acquisition priority instead of switching on/off at the
/// EXPAND→COLONIAL boundary.
///
/// Pure and deterministic — identical `phasePlan.priorityWeights`
/// inputs always yield identical `double` results (Refs #2509
/// Must-have #7). Reads only `phasePlan.priorityWeights`.
double resolvePhaseEconomyColonialPressureWeight({
  required PhasePlanOutcome phasePlan,
}) => phasePlan.priorityWeights.newWorldAcquisition;

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
  final clamped = colonialPressureWeight > 1.0 ? 1.0 : colonialPressureWeight;
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
  final clamped = colonialPressureWeight > 1.0 ? 1.0 : colonialPressureWeight;
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
}) => phasePlan.priorityWeights.oldWorldCivilian;

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
}) => phasePlan.priorityWeights.newWorldCivilian;

/// Resource-need override predicate (Refs #2847 § Resource-need overrides).
///
/// True when treasury recovery cargo is active, the GP owns no NW
/// provinces, and cash treasury is exactly zero — the same triple that
/// lifts `newWorldAcquisition` to [kPhasePriorityNwTreasuryRecoveryFloor].
bool resolvePhaseNwTreasuryRecoveryResourceNeedOverrideActive({
  required AIWorldSnapshot snapshot,
  required ExpandEconomyPlan expandEconomyPlan,
}) =>
    snapshot.economy.treasury == 0 &&
    snapshot.colonial.newWorldProvincesOwned == 0 &&
    expandEconomyPlan.boostTreasuryRecoveryCargo;

/// Returns `true` when [playerId] owns at least one naval hull with
/// `cargoHold > 0` in any fleet.
bool playerOwnsCargoCapableNavalUnit(Game game, String playerId) {
  for (final fleet in game.worldState.fleets) {
    if (fleet.ownerId != playerId) continue;
    for (final ship in fleet.ships) {
      if (NavalStatsCatalog.get(ship.typeId).cargoHold > 0) {
        return true;
      }
    }
  }
  return false;
}

/// First-naval-transport bootstrap (Refs #2847 Phase 3, #2924 Path F).
///
/// When active, `_appendEconomyBuildOrders` keeps cargo-capable ship
/// candidates in the build pick and suppresses the regiment-only
/// `militaryRebuildCrisis` short-circuit so the orchestrator can emit a
/// first NW-acquisition transport under the treasury-recovery override.
///
/// Active when treasury-recovery cargo is on, the GP owns no NW provinces
/// and no cargo-capable hull yet, and either:
/// - treasury is below `cheapestRegimentBuildTreasuryCost()` (partial Path F
///   credits must not flip back to regiment-only rebuild), or
/// - the GP is in the mid-below-quota zero-NW band (seed-42 gp3–gp6) so the
///   first build prioritises market cargo capacity **before** high starting
///   treasury is spent on regiments (gp6 Path F regression).
///
/// The build pipeline's own treasury/material affordability check is
/// unchanged — this relaxes only planner-level regiment bias.
bool resolvePhaseFirstNavalTransportBootstrapActive({
  required Game game,
  required AIWorldSnapshot snapshot,
  required ExpandEconomyPlan expandEconomyPlan,
  required String playerId,
}) {
  if (snapshot.colonial.newWorldProvincesOwned != 0) return false;
  if (playerOwnsCargoCapableNavalUnit(game, playerId)) return false;
  final ow = snapshot.conquest.oldWorldProvincesOwned;
  if (ow >= 2 && isBelowObserverConquestQuota(ow)) {
    return true;
  }
  return expandEconomyPlan.boostTreasuryRecoveryCargo &&
      snapshot.economy.treasury < cheapestRegimentBuildTreasuryCost();
}
