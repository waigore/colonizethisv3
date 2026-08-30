/// Phase-planner economy directive resolvers for orchestrator wiring
/// (Refs #2509 S5; #4602 Slice A).
///
/// Cite `SPEC/ai/phase-planner-dispatch.md` (adapter helpers / economy row)
/// rather than restating the colonial-pressure matrix here.
library;

import 'package:colonizethis_data/colonizethis_data.dart'
    hide cheapestRegimentBuildTreasuryCost;

import '../perception/perception_snapshot.dart';
import 'observer_goal_phase.dart';
import 'phase_filter_common.dart';
import 'phase_planner_conquest_filter.dart';
import 'phase_planner_dispatch.dart';
import 'planning_helpers.dart' show resolvePhaseNewWorldAcquisitionWeight;
import 'phase_planner_economy_filter_caps.dart';

export 'phase_planner_economy_filter_caps.dart';
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
