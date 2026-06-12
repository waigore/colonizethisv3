import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

/// Shared build-order cost and eligibility. Single source of truth for validation
/// and application. SPEC/program/orders.md § Build orders.
/// Used by BuildOrderValidator and orders_application.

typedef _BuildDeductionPlan = ({
  int treasuryCost,
  Map<CommodityId, int> materialCosts,
  bool subtractOnePeasant,
});

/// Resolves whether the player can pay for [order] and, if so, the exact deduction.
({String? failReason, _BuildDeductionPlan? plan}) _resolveBuildDeductionPlan(
  Player player,
  BuildUnitOrder order,
  WorkerPool workers,
  Stockpile stockpile,
  int treasury,
) {
  final category = buildUnitCategoryForUnitType(order.unitType);
  switch (category) {
    case BuildUnitCategory.civilian:
      final econ = CivilianEconomyCatalog.byId[order.unitType];
      if (econ == null) {
        return (failReason: 'Insufficient resources', plan: null);
      }
      return _resolveBuildPlanForCatalog(
        player: player,
        workers: workers,
        stockpile: stockpile,
        treasury: treasury,
        buildTreasuryCost: econ.buildTreasuryCost,
        buildInputs: econ.buildInputs,
        unlockingTechId: unlockingTechByCivilianId[order.unitType],
        requiresPeasant: false,
        subtractOnePeasant: false,
      );

    case BuildUnitCategory.military:
      final econ = RegimentEconomyCatalog.byId[order.unitType];
      if (econ == null) {
        return (failReason: 'Insufficient resources', plan: null);
      }
      return _resolveBuildPlanForCatalog(
        player: player,
        workers: workers,
        stockpile: stockpile,
        treasury: treasury,
        buildTreasuryCost: econ.buildTreasuryCost,
        buildInputs: econ.buildInputs,
        unlockingTechId: unlockingTechByRegimentId[order.unitType],
        requiresPeasant: true,
        subtractOnePeasant: true,
      );

    case BuildUnitCategory.naval:
      final shipEcon = ShipEconomyCatalog.byId[order.unitType];
      if (shipEcon == null) {
        return (failReason: 'Insufficient resources', plan: null);
      }
      return _resolveBuildPlanForCatalog(
        player: player,
        workers: workers,
        stockpile: stockpile,
        treasury: treasury,
        buildTreasuryCost: shipEcon.buildTreasuryCost,
        buildInputs: shipEcon.buildInputs,
        unlockingTechId: unlockingTechByShipId[order.unitType],
        requiresPeasant: true,
        subtractOnePeasant: true,
      );

    case BuildUnitCategory.unknown:
      return (failReason: 'Insufficient resources', plan: null);
  }
}

/// Generic per-catalog affordability check shared by the civilian, military,
/// and naval branches of [_resolveBuildDeductionPlan]. Each branch resolves its
/// own economy-catalog entry (the only per-category difference besides the
/// peasant requirement and peasant deduction) and delegates the common
/// tech / worker / treasury / material gating here so the validation order and
/// failure reasons stay identical across branches.
///
/// Check order is preserved from the original per-branch code: unlock tech →
/// peasant (when [requiresPeasant]) → treasury → materials.
({String? failReason, _BuildDeductionPlan? plan}) _resolveBuildPlanForCatalog({
  required Player player,
  required WorkerPool workers,
  required Stockpile stockpile,
  required int treasury,
  required int buildTreasuryCost,
  required Map<CommodityId, int> buildInputs,
  required String? unlockingTechId,
  required bool requiresPeasant,
  required bool subtractOnePeasant,
}) {
  if (unlockingTechId != null &&
      (player.techUnlocked?[unlockingTechId] != true)) {
    return (failReason: 'Required technology not unlocked', plan: null);
  }
  if (requiresPeasant && workers.peasants <= 0) {
    return (failReason: 'Insufficient workers', plan: null);
  }
  if (treasury < buildTreasuryCost) {
    return (failReason: 'Insufficient treasury', plan: null);
  }
  for (final e in buildInputs.entries) {
    if (stockpile.quantityOf(e.key) < e.value) {
      return (failReason: 'Insufficient materials', plan: null);
    }
  }
  return (
    failReason: null,
    plan: (
      treasuryCost: buildTreasuryCost,
      materialCosts: buildInputs,
      subtractOnePeasant: subtractOnePeasant,
    ),
  );
}

/// Result of checking whether a player can afford a build order.
({bool canAfford, String? reason}) canAffordBuild(
  Player player,
  BuildUnitOrder order,
  WorkerPool workers,
  Stockpile stockpile,
  int treasury,
) {
  final r = _resolveBuildDeductionPlan(
    player,
    order,
    workers,
    stockpile,
    treasury,
  );
  if (r.failReason != null) {
    return (canAfford: false, reason: r.failReason);
  }
  return (canAfford: true, reason: null);
}

/// Applies cost deduction for [order]. Call only when [canAffordBuild] returned true.
/// Returns updated workers, stockpile, and treasury.
({WorkerPool workers, Stockpile stockpile, int treasury})
applyBuildCostDeduction(
  Player player,
  BuildUnitOrder order,
  WorkerPool workers,
  Stockpile stockpile,
  int treasury,
) {
  final r = _resolveBuildDeductionPlan(
    player,
    order,
    workers,
    stockpile,
    treasury,
  );
  final plan = r.plan;
  if (plan == null) {
    return (workers: workers, stockpile: stockpile, treasury: treasury);
  }
  var t = treasury - plan.treasuryCost;
  var s = stockpile;
  for (final e in plan.materialCosts.entries) {
    s = s.applyDelta(e.key, -e.value);
  }
  var w = workers;
  if (plan.subtractOnePeasant) {
    w = w.copyWith(peasants: w.peasants - 1);
  }
  return (workers: w, stockpile: s, treasury: t);
}
