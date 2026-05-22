import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

/// Shared recruit/train worker cost and eligibility. Single source of truth
/// for [RecruitWorkerOrder] validation and application; mirrors the
/// build-cost pattern in [build_cost.dart] so the Build / work phase resolver
/// and the order engine validator stay aligned.
///
/// SPEC/game/workers-and-population.md § Recruiting, Training, and
/// Disbanding (authoritative cost table and rejection vocabulary).
/// SPEC/program/orders.md § Order Types.
/// SPEC/program/turn-resolution-phase-details.md § Build / work
/// (RecruitWorkerOrder resolves before BuildUnitOrder).

typedef _RecruitDeductionPlan = ({
  int treasuryCost,
  Map<CommodityId, int> materialCosts,
  bool consumesPeasant,
  WorkerTier targetTier,
});

/// Order rejection reasons — vocabulary fixed by
/// `SPEC/game/workers-and-population.md` § Order rejection reasons (validation).
const String kRecruitWorkerInsufficientWorkers = 'Insufficient workers';
const String kRecruitWorkerInsufficientMaterials = 'Insufficient materials';
const String kRecruitWorkerInsufficientTreasury = 'Insufficient treasury';
const String kRecruitWorkerTechLocked = 'Required technology not unlocked';

bool _playerHasAllTechs(Player player, List<String> requiredTechIds) {
  if (requiredTechIds.isEmpty) return true;
  final unlocked = player.techUnlocked ?? const <String, bool>{};
  for (final techId in requiredTechIds) {
    if (unlocked[techId] != true) return false;
  }
  return true;
}

({String? failReason, _RecruitDeductionPlan? plan}) _resolveRecruitPlan(
  Player player,
  RecruitWorkerOrder order,
  WorkerPool workers,
  Stockpile stockpile,
  int treasury,
) {
  final row = WorkerActionEconomyCatalog.forTier(order.targetTier);
  if (!_playerHasAllTechs(player, row.requiredTechIds)) {
    return (failReason: kRecruitWorkerTechLocked, plan: null);
  }
  if (row.consumesPeasant && workers.peasants <= 0) {
    return (failReason: kRecruitWorkerInsufficientWorkers, plan: null);
  }
  if (treasury < row.treasuryCost) {
    return (failReason: kRecruitWorkerInsufficientTreasury, plan: null);
  }
  for (final entry in row.materialCosts.entries) {
    if (stockpile.quantityOf(entry.key) < entry.value) {
      return (failReason: kRecruitWorkerInsufficientMaterials, plan: null);
    }
  }
  return (
    failReason: null,
    plan: (
      treasuryCost: row.treasuryCost,
      materialCosts: row.materialCosts,
      consumesPeasant: row.consumesPeasant,
      targetTier: row.targetTier,
    ),
  );
}

/// Whether [player] can pay for [order] given the projected economy state.
({bool canAfford, String? reason}) canAffordRecruitWorker(
  Player player,
  RecruitWorkerOrder order,
  WorkerPool workers,
  Stockpile stockpile,
  int treasury,
) {
  final r = _resolveRecruitPlan(player, order, workers, stockpile, treasury);
  if (r.failReason != null) {
    return (canAfford: false, reason: r.failReason);
  }
  return (canAfford: true, reason: null);
}

/// Deducts the recruit/train cost for [order] and applies the worker pool
/// delta (peasant consumed when applicable + target tier incremented by 1).
///
/// Call only when [canAffordRecruitWorker] returned `canAfford: true` for the
/// same inputs.
({WorkerPool workers, Stockpile stockpile, int treasury})
applyRecruitWorkerCostDeduction(
  Player player,
  RecruitWorkerOrder order,
  WorkerPool workers,
  Stockpile stockpile,
  int treasury,
) {
  final r = _resolveRecruitPlan(player, order, workers, stockpile, treasury);
  final plan = r.plan;
  if (plan == null) {
    return (workers: workers, stockpile: stockpile, treasury: treasury);
  }
  final nextTreasury = treasury - plan.treasuryCost;
  var nextStockpile = stockpile;
  for (final entry in plan.materialCosts.entries) {
    nextStockpile = nextStockpile.applyDelta(entry.key, -entry.value);
  }
  var nextWorkers = workers;
  final consumedPeasants = plan.consumesPeasant
      ? nextWorkers.peasants - 1
      : nextWorkers.peasants;
  switch (plan.targetTier) {
    case WorkerTier.peasant:
      nextWorkers = nextWorkers.copyWith(peasants: nextWorkers.peasants + 1);
    case WorkerTier.apprentice:
      nextWorkers = nextWorkers.copyWith(
        peasants: consumedPeasants,
        apprentices: nextWorkers.apprentices + 1,
      );
    case WorkerTier.journeyman:
      nextWorkers = nextWorkers.copyWith(
        peasants: consumedPeasants,
        journeymen: nextWorkers.journeymen + 1,
      );
    case WorkerTier.master:
      nextWorkers = nextWorkers.copyWith(
        peasants: consumedPeasants,
        masters: nextWorkers.masters + 1,
      );
  }
  return (
    workers: nextWorkers,
    stockpile: nextStockpile,
    treasury: nextTreasury,
  );
}
