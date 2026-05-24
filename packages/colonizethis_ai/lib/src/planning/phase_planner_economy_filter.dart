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
/// orchestrator's economy-pass behaviour exactly during the S5
/// migration.
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

import 'package:colonizethis_data/colonizethis_data.dart';

import '../perception/perception_snapshot.dart';
import 'observer_goal_phase.dart';
import 'phase_planner_conquest_filter.dart';
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

/// Returns the build-order threshold cap that
/// `_appendEconomyBuildOrders` should clamp `buildThreshold` to when
/// the active player is operating under full COLONIAL acquisition
/// pressure and already owns at least one New World province, or
/// `null` when no cap applies for the current phase / NW-ownership
/// combination.
///
/// Replaces the per-call `colonialBuildOrderThresholdCap` invocation
/// in `_appendEconomyBuildOrders` (`colonial_pressure.dart`). The
/// legacy helper had two arms keyed on
/// `hasColonialAcquisitionTargets(colonial)`:
///
/// - `hasColonialAcquisitionTargets && newWorldProvincesOwned > 0`
///   -> [kColonialBuildOrderThresholdWhenOwnedNwUnderPressure]
/// - `newWorldProvincesOwned > 0` (no acquisition targets)
///   -> [kColonialBuildOrderThresholdWhenOwnedNw]
/// - otherwise -> `null`
///
/// The orchestrator only invoked the helper inside an outer
/// `if (colonialPressure)` guard, where `colonialPressure` is the
/// dispatched [resolvePhaseEconomyColonialPressureActive] (active
/// only under [ObserverGoalPhase.colonial]). COLONIAL phase entry is
/// itself gated on `hasColonialAcquisitionTargets` via
/// [observerGoalPhaseFor], so the first legacy arm is the *only*
/// reachable arm under the orchestrator call site — the second
/// `kColonialBuildOrderThresholdWhenOwnedNw` arm requires
/// `!hasColonialAcquisitionTargets`, which is structurally
/// unreachable inside the orchestrator's COLONIAL-pressure branch.
///
/// This resolver therefore collapses the helper's reachable behaviour
/// to a single phase-derived path: when phase is
/// [ObserverGoalPhase.colonial] and `newWorldProvincesOwned > 0`,
/// return [kColonialBuildOrderThresholdWhenOwnedNwUnderPressure];
/// otherwise return `null`. Phase-derived `int?` is field-equal to
/// the legacy `colonialBuildOrderThresholdCap` compute at the
/// orchestrator's only call site across every reachable
/// `(ObserverGoalPhase, ColonialSummary)` pair, preserving the
/// prior build-threshold cap behaviour exactly during the S5
/// migration.
///
/// Structural suppression matrix (mirrors
/// [resolvePhaseEconomyColonialPressureActive]):
///
/// - [ObserverGoalPhase.expand]: returns `null` (NW economy bias is
///   structurally suppressed under EXPAND).
/// - [ObserverGoalPhase.colonialLite]: returns `null` (issue #2509
///   § COLONIAL-lite "Begin NW penetration without weakening OW
///   push" forbids biasing economy/build toward NW cargo under the
///   safeguard).
/// - [ObserverGoalPhase.colonial]: returns
///   [kColonialBuildOrderThresholdWhenOwnedNwUnderPressure] when
///   `colonial.newWorldProvincesOwned > 0`; returns `null` otherwise
///   (no NW provinces yet -> no cap).
/// - [ObserverGoalPhase.develop]: returns `null` (DEVELOP drives
///   improvement work through `civilianWorkOrdersFromPhasePlan`, not
///   the colonial build cap).
///
/// Pure and deterministic — identical
/// `(PhasePlanOutcome, ColonialSummary)` inputs always yield
/// identical `int?` resolutions (Refs #2509 Must-have #7). Performs
/// no I/O, no logging, no order emission.
int? resolvePhaseEconomyColonialBuildOrderThresholdCap({
  required PhasePlanOutcome phasePlan,
  required ColonialSummary colonial,
}) {
  if (!resolvePhaseEconomyColonialPressureActive(phasePlan: phasePlan)) {
    return null;
  }
  if (colonial.newWorldProvincesOwned <= 0) {
    return null;
  }
  return kColonialBuildOrderThresholdWhenOwnedNwUnderPressure;
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
