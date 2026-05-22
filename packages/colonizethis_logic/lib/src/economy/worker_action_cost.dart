/// Shared affordability and deduction for [RecruitWorkerOrder]. Single source
/// of truth used by [RecruitWorkerOrderValidator], the Build / work worker
/// pool phase, and the economy preview pipeline so submission, validation,
/// resolution, and projection share one cost table.
///
/// SPEC source of truth:
/// - `SPEC/game/workers-and-population.md` § Recruiting, Training, and
///   Disbanding (cost table, rejection reasons).
/// - `SPEC/program/orders.md` § RecruitWorkerOrder.
/// - `SPEC/program/turn-resolution-phase-details.md` § Build / work
///   (worker pool orders resolve before [BuildUnitOrder]).
library;

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

/// Rejection reason vocabulary (matches GDD § Order rejection reasons).
///
/// These strings are part of the user-visible UI contract; do not change
/// without updating both SPEC and downstream localization strings.
const String kRecruitWorkerInsufficientWorkers = 'Insufficient workers';
const String kRecruitWorkerInsufficientMaterials = 'Insufficient materials';
const String kRecruitWorkerInsufficientTreasury = 'Insufficient treasury';
const String kRecruitWorkerTechLocked = 'Required technology not unlocked';

/// Checks whether the player can pay for one [RecruitWorkerOrder] given the
/// running worker pool, stockpile, and treasury state for that player's order
/// chain (i.e. after deductions from prior accepted recruit / build orders).
///
/// Tech gates use the static catalog `WorkerActionEconomyCatalog.forTier` and
/// the player's `techUnlocked` map; both must be true for trained tiers.
///
/// Returns `canAfford: true` with `reason: null` when the action is allowed.
/// Otherwise returns the first failing reason in the canonical order:
/// tech → workers → treasury → materials.
({bool canAfford, String? reason}) canAffordRecruitWorker(
  Player player,
  RecruitWorkerOrder order,
  WorkerPool workers,
  Stockpile stockpile,
  int treasury,
) {
  final row = WorkerActionEconomyCatalog.forTier(order.targetTier);
  final tech = player.techUnlocked ?? const <String, bool>{};
  for (final techId in row.requiredTechIds) {
    if (tech[techId] != true) {
      return (canAfford: false, reason: kRecruitWorkerTechLocked);
    }
  }
  if (row.consumesPeasant && workers.peasants <= 0) {
    return (canAfford: false, reason: kRecruitWorkerInsufficientWorkers);
  }
  if (treasury < row.treasuryCost) {
    return (canAfford: false, reason: kRecruitWorkerInsufficientTreasury);
  }
  for (final entry in row.materialCosts.entries) {
    if (stockpile.quantityOf(entry.key) < entry.value) {
      return (canAfford: false, reason: kRecruitWorkerInsufficientMaterials);
    }
  }
  return (canAfford: true, reason: null);
}

/// Applies the cost deduction for one [RecruitWorkerOrder] and returns the
/// updated economy snapshot. Call only when [canAffordRecruitWorker] returned
/// `canAfford: true` for the same inputs.
///
/// Increments the [order.targetTier] count by 1; decrements `peasants` by 1
/// for non-peasant tiers (per the GDD cost row `consumesPeasant`).
({WorkerPool workers, Stockpile stockpile, int treasury})
applyRecruitWorkerCostDeduction(
  RecruitWorkerOrder order,
  WorkerPool workers,
  Stockpile stockpile,
  int treasury,
) {
  final row = WorkerActionEconomyCatalog.forTier(order.targetTier);
  var nextStockpile = stockpile;
  for (final entry in row.materialCosts.entries) {
    nextStockpile = nextStockpile.applyDelta(entry.key, -entry.value);
  }
  final nextWorkers = _applyTierDelta(
    workers,
    order.targetTier,
    increment: 1,
    decrementPeasant: row.consumesPeasant,
  );
  final nextTreasury = treasury - row.treasuryCost;
  return (
    workers: nextWorkers,
    stockpile: nextStockpile,
    treasury: nextTreasury,
  );
}

WorkerPool _applyTierDelta(
  WorkerPool pool,
  WorkerTier tier, {
  required int increment,
  required bool decrementPeasant,
}) {
  final peasantsAfter = decrementPeasant ? pool.peasants - 1 : pool.peasants;
  switch (tier) {
    case WorkerTier.peasant:
      return pool.copyWith(peasants: peasantsAfter + increment);
    case WorkerTier.apprentice:
      return pool.copyWith(
        peasants: peasantsAfter,
        apprentices: pool.apprentices + increment,
      );
    case WorkerTier.journeyman:
      return pool.copyWith(
        peasants: peasantsAfter,
        journeymen: pool.journeymen + increment,
      );
    case WorkerTier.master:
      return pool.copyWith(
        peasants: peasantsAfter,
        masters: pool.masters + increment,
      );
  }
}
