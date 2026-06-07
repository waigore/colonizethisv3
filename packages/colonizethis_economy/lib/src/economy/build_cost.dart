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
      final unlockingTechId = unlockingTechByCivilianId[order.unitType];
      if (unlockingTechId != null &&
          (player.techUnlocked?[unlockingTechId] != true)) {
        return (failReason: 'Required technology not unlocked', plan: null);
      }
      if (treasury < econ.buildTreasuryCost) {
        return (failReason: 'Insufficient treasury', plan: null);
      }
      for (final e in econ.buildInputs.entries) {
        if (stockpile.quantityOf(e.key) < e.value) {
          return (failReason: 'Insufficient materials', plan: null);
        }
      }
      return (
        failReason: null,
        plan: (
          treasuryCost: econ.buildTreasuryCost,
          materialCosts: econ.buildInputs,
          subtractOnePeasant: false,
        ),
      );

    case BuildUnitCategory.military:
      final econ = RegimentEconomyCatalog.byId[order.unitType];
      if (econ == null) {
        return (failReason: 'Insufficient resources', plan: null);
      }
      final regimentUnlockTech = unlockingTechByRegimentId[order.unitType];
      if (regimentUnlockTech != null &&
          (player.techUnlocked?[regimentUnlockTech] != true)) {
        return (failReason: 'Required technology not unlocked', plan: null);
      }
      if (workers.peasants <= 0) {
        return (failReason: 'Insufficient workers', plan: null);
      }
      if (treasury < econ.buildTreasuryCost) {
        return (failReason: 'Insufficient treasury', plan: null);
      }
      for (final e in econ.buildInputs.entries) {
        if (stockpile.quantityOf(e.key) < e.value) {
          return (failReason: 'Insufficient materials', plan: null);
        }
      }
      return (
        failReason: null,
        plan: (
          treasuryCost: econ.buildTreasuryCost,
          materialCosts: econ.buildInputs,
          subtractOnePeasant: true,
        ),
      );

    case BuildUnitCategory.naval:
      final shipEcon = ShipEconomyCatalog.byId[order.unitType];
      if (shipEcon == null) {
        return (failReason: 'Insufficient resources', plan: null);
      }
      final shipUnlockTech = unlockingTechByShipId[order.unitType];
      if (shipUnlockTech != null &&
          (player.techUnlocked?[shipUnlockTech] != true)) {
        return (failReason: 'Required technology not unlocked', plan: null);
      }
      if (workers.peasants <= 0) {
        return (failReason: 'Insufficient workers', plan: null);
      }
      if (treasury < shipEcon.buildTreasuryCost) {
        return (failReason: 'Insufficient treasury', plan: null);
      }
      for (final e in shipEcon.buildInputs.entries) {
        if (stockpile.quantityOf(e.key) < e.value) {
          return (failReason: 'Insufficient materials', plan: null);
        }
      }
      return (
        failReason: null,
        plan: (
          treasuryCost: shipEcon.buildTreasuryCost,
          materialCosts: shipEcon.buildInputs,
          subtractOnePeasant: true,
        ),
      );

    case BuildUnitCategory.unknown:
      return (failReason: 'Insufficient resources', plan: null);
  }
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
