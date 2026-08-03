import 'package:colonizethis_data/colonizethis_data.dart'
    as regiment_catalog
    show cheapestRegimentBuildTreasuryCost;

import 'planning_imports.dart';

/// Minimum [RegimentEconomyCatalog] build treasury cost (deterministic
/// catalog scan).
///
/// Canonical home (Refs #2509 S1) for the EXPAND-trap treasury affordability
/// gate used by [planExpandDeclareWar] (treasury floor before declaring),
/// [planExpandEconomy] (arms B/C threshold for force-build and treasury
/// recovery cargo), and the [planColonialAcquisition] declare-war arm in
/// `colonial_phase_planner.dart`. `colonial_pressure.dart` retains a
/// thin delegating stub for legacy import sites so the planned S1
/// deletion of that file leaves no orphan callers.
///
/// Linear in the catalog size, matching the budget-rule note in
/// `colonizethis-turn-resolution-budget.mdc`.
int cheapestRegimentBuildTreasuryCost() =>
    regiment_catalog.cheapestRegimentBuildTreasuryCost();

/// Below-quota EXPAND GP with zero standing regiments and a non-empty
/// invadable Old World frontier.
///
/// Canonical home (Refs #2509 S1) for the legacy
/// `isBelowQuotaPeaceZeroRegimentsRebuild` predicate previously hosted in
/// `colonial_pressure.dart` (Arm A of the legacy below-quota treasury-recovery
/// composite). The function captures the EXPAND-trap "zero regiments with
/// frontier to expand into" arm shared by:
///
///   - [planExpandEconomy] Arm A (`regimentCount == 0 && hasInvadable` →
///     `forceCheapestRegimentBuild: true`), which signals the orchestrator
///     to force a regiment build attempt regardless of treasury (cargo
///     boost in Arm C handles the funding side).
///   - The `isBelowQuotaPeaceTreasuryRecovery` composite (composed with the
///     `isBelowQuotaPeaceInsufficientRegiments` arm) so the cargo-delivery
///     trigger and the planner directive cannot drift apart now that the
///     S5 orchestrator wire-up is in place. The composite was canonical in
///     the now-deleted `colonial_pressure.dart` (#2509 S1) and is hosted
///     here alongside this predicate.
///
/// `colonial_pressure.dart` previously retained a thin delegating stub for legacy
/// import sites (the `colonial_pressure_below_quota_peace_*` tests and
/// `phase_planner_economy_filter.dart`) so the now-completed S1 deletion of
/// that file leaves no orphan callers.
///
/// Pure and deterministic — identical inputs always yield identical
/// results (Refs #2509 Must-have #7). Constant-time (no catalog or
/// game-state scan).
bool isBelowQuotaPeaceZeroRegimentsRebuild({
  required int oldWorldProvincesOwned,
  required int regimentCount,
  required bool hasInvadableProvinces,
}) =>
    isBelowObserverConquestQuota(oldWorldProvincesOwned) &&
    regimentCount == 0 &&
    hasInvadableProvinces;

/// Below-quota EXPAND GP at peace with all other Great Powers, with an
/// invadable Old World frontier and a positive but small standing regiment
/// count.
///
/// Canonical home (Refs #2509 S1) for the legacy
/// `isBelowQuotaPeaceInsufficientRegiments` predicate previously hosted in
/// `colonial_pressure.dart`. Captures the seed-42 turn-100 trap where a GP
/// that exited an early war with few standing regiments and zero treasury is
/// no longer "broke" (`regimentCount > 0`) and so neither
/// `needRegimentsToExpand` nor `brokeBelowQuotaAtPeace` triggers force
/// regiment rebuild — yet the GP also has too few regiments to mount a
/// credible EXPAND declare-war on the remaining GP-only frontier (Refs
/// #2509 § Observer goal phases (Full AI) "EXPAND regiment-rebuild trap").
///
/// Returns `true` only while OW holdings are below
/// [kObserverConquestMinOwProvincesPerGp], no Great Power is in the at-war
/// set, `invadableProvinceIdsSorted` is non-empty, and the standing
/// regiment count is in the half-open range
/// `[1, kBelowQuotaPeaceMinRegimentsBeforeDeclareWar)`. Arm B of the
/// EXPAND-trap below-quota treasury-recovery composite, paired with
/// [isBelowQuotaPeaceZeroRegimentsRebuild] (Arm A) inside
/// [isBelowQuotaPeaceTreasuryRecovery].
///
/// `colonial_pressure.dart` previously retained a thin delegating stub for legacy
/// import sites (the `colonial_pressure_below_quota_peace_insufficient_regiments`
/// tests, `economy_planner.dart`, and `phase_planner_economy_filter.dart`)
/// so the now-completed S1 deletion of that file leaves no orphan callers.
///
/// Pure and deterministic — identical inputs always yield identical
/// results (Refs #2509 Must-have #7). Constant-time (no catalog or
/// game-state scan).
bool isBelowQuotaPeaceInsufficientRegiments({
  required int oldWorldProvincesOwned,
  required int regimentCount,
  required bool atWarWithAnyGreatPower,
  required bool hasInvadableProvinces,
}) {
  if (!isBelowObserverConquestQuota(oldWorldProvincesOwned)) {
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

/// Below-quota EXPAND GP at peace with insufficient regiments and effective
/// treasury (cash plus same-turn pending riches) below cheapest regiment
/// build.
///
/// Triggers the overseas cargo-recovery preference so auto-transport can
/// deliver riches to the stockpile before the next build pass (Refs #2509).
///
/// Canonical home (Refs #2509 S1) for the legacy
/// `isBelowQuotaPeaceTreasuryRecovery` composite previously hosted in
/// `colonial_pressure.dart`. The composite short-circuits to `true` when the
/// Arm A zero-regiments rebuild trigger ([isBelowQuotaPeaceZeroRegimentsRebuild])
/// fires; otherwise it requires the Arm B insufficient-regiments gate
/// ([isBelowQuotaPeaceInsufficientRegiments]) AND an effective treasury
/// (`treasury + pendingRichesTreasuryDelta(stockpile)`) strictly below
/// [cheapestRegimentBuildTreasuryCost]. Mirrors the legacy three-arm
/// EXPAND-trap decision tree without the cargo-boost wiring at the same
/// function boundary the orchestrator and `economy_planner.dart` consume.
///
/// `colonial_pressure.dart` previously retained a thin delegating stub for legacy
/// import sites (the `colonial_pressure_below_quota_peace_treasury_recovery_branches`
/// tests, `economy_planner.dart`, and `phase_planner_economy_filter.dart`)
/// so the now-completed S1 deletion of that file leaves no orphan callers.
///
/// Pure and deterministic — identical inputs always yield identical
/// results (Refs #2509 Must-have #7). Linear in the [RegimentEconomyCatalog]
/// only via [cheapestRegimentBuildTreasuryCost]; otherwise constant-time.
bool isBelowQuotaPeaceTreasuryRecovery({
  required int oldWorldProvincesOwned,
  required int regimentCount,
  required bool atWarWithAnyGreatPower,
  required bool hasInvadableProvinces,
  required int treasury,
  required Stockpile stockpile,
}) {
  if (isBelowQuotaPeaceZeroRegimentsRebuild(
    oldWorldProvincesOwned: oldWorldProvincesOwned,
    regimentCount: regimentCount,
    hasInvadableProvinces: hasInvadableProvinces,
  )) {
    return true;
  }
  if (!isBelowQuotaPeaceInsufficientRegiments(
    oldWorldProvincesOwned: oldWorldProvincesOwned,
    regimentCount: regimentCount,
    atWarWithAnyGreatPower: atWarWithAnyGreatPower,
    hasInvadableProvinces: hasInvadableProvinces,
  )) {
    return false;
  }
  final effectiveTreasury =
      treasury + pendingRichesTreasuryDelta(stockpile: stockpile);
  return effectiveTreasury < cheapestRegimentBuildTreasuryCost();
}
