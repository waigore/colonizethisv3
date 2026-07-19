/// EXPAND / NW economy filter resolvers (Refs #4079 Slice C).
library;

import 'package:colonizethis_data/colonizethis_data.dart'
    hide cheapestRegimentBuildTreasuryCost;
import 'package:colonizethis_models/colonizethis_models.dart';

import '../perception/perception_snapshot.dart';
import 'expand_phase_planner.dart'
    show ExpandEconomyPlan, cheapestRegimentBuildTreasuryCost;
import 'phase_planner_conquest_filter.dart';
import 'phase_planner_dispatch.dart';
import 'phase_priority_weights.dart';

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
/// in [runPhasePlanners] via [isOldWorldGpOnlyInvadableFrontier]).
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
/// [primaryInvadableOldWorldGpBlocker].
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
