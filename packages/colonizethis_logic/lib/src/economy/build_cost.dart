import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

/// Shared build-order cost and eligibility. Single source of truth for validation
/// and application. SPEC/program/orders.md § Build orders.
/// Used by BuildOrderValidator and orders_application.

/// Result of checking whether a player can afford a build order.
({bool canAfford, String? reason}) canAffordBuild(
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
      if (econ == null) return (canAfford: false, reason: 'Insufficient resources');
      final unlockingTechId = unlockingTechByCivilianId[order.unitType];
      if (unlockingTechId != null &&
          (player.techUnlocked?[unlockingTechId] != true)) {
        return (canAfford: false, reason: 'Insufficient resources');
      }
      if (treasury < econ.buildTreasuryCost) {
        return (canAfford: false, reason: 'Insufficient treasury');
      }
      for (final e in econ.buildInputs.entries) {
        if (stockpile.quantityOf(e.key) < e.value) {
          return (canAfford: false, reason: 'Insufficient materials');
        }
      }
      return (canAfford: true, reason: null);

    case BuildUnitCategory.military:
      final econ = RegimentEconomyCatalog.byId[order.unitType];
      if (econ == null) return (canAfford: false, reason: 'Insufficient resources');
      final regimentUnlockTech = unlockingTechByRegimentId[order.unitType];
      if (regimentUnlockTech != null &&
          (player.techUnlocked?[regimentUnlockTech] != true)) {
        return (canAfford: false, reason: 'Insufficient resources');
      }
      if (workers.peasants <= 0) {
        return (canAfford: false, reason: 'Insufficient resources');
      }
      if (treasury < econ.buildTreasuryCost) {
        return (canAfford: false, reason: 'Insufficient treasury');
      }
      for (final e in econ.buildInputs.entries) {
        if (stockpile.quantityOf(e.key) < e.value) {
          return (canAfford: false, reason: 'Insufficient materials');
        }
      }
      return (canAfford: true, reason: null);

    case BuildUnitCategory.naval:
      final shipEcon = ShipEconomyCatalog.byId[order.unitType];
      if (shipEcon == null) return (canAfford: false, reason: 'Insufficient resources');
      final shipUnlockTech = unlockingTechByShipId[order.unitType];
      if (shipUnlockTech != null &&
          (player.techUnlocked?[shipUnlockTech] != true)) {
        return (canAfford: false, reason: 'Insufficient tech');
      }
      if (treasury < shipEcon.buildTreasuryCost) {
        return (canAfford: false, reason: 'Insufficient treasury');
      }
      for (final e in shipEcon.buildInputs.entries) {
        if (stockpile.quantityOf(e.key) < e.value) {
          return (canAfford: false, reason: 'Insufficient materials');
        }
      }
      return (canAfford: true, reason: null);

    case BuildUnitCategory.unknown:
      return (canAfford: false, reason: 'Insufficient resources');
  }
}

/// Applies cost deduction for [order]. Call only when [canAffordBuild] returned true.
/// Returns updated workers, stockpile, and treasury.
({WorkerPool workers, Stockpile stockpile, int treasury}) applyBuildCostDeduction(
  Player player,
  BuildUnitOrder order,
  WorkerPool workers,
  Stockpile stockpile,
  int treasury,
) {
  final category = buildUnitCategoryForUnitType(order.unitType);
  switch (category) {
    case BuildUnitCategory.civilian:
      final econ = CivilianEconomyCatalog.byId[order.unitType]!;
      treasury -= econ.buildTreasuryCost;
      for (final e in econ.buildInputs.entries) {
        stockpile = stockpile.applyDelta(e.key, -e.value);
      }
      return (workers: workers, stockpile: stockpile, treasury: treasury);

    case BuildUnitCategory.military:
      final econ = RegimentEconomyCatalog.byId[order.unitType]!;
      treasury -= econ.buildTreasuryCost;
      for (final e in econ.buildInputs.entries) {
        stockpile = stockpile.applyDelta(e.key, -e.value);
      }
      workers = workers.copyWith(peasants: workers.peasants - 1);
      return (workers: workers, stockpile: stockpile, treasury: treasury);

    case BuildUnitCategory.naval:
      final shipEcon = ShipEconomyCatalog.byId[order.unitType]!;
      treasury -= shipEcon.buildTreasuryCost;
      for (final e in shipEcon.buildInputs.entries) {
        stockpile = stockpile.applyDelta(e.key, -e.value);
      }
      return (workers: workers, stockpile: stockpile, treasury: treasury);

    case BuildUnitCategory.unknown:
      return (workers: workers, stockpile: stockpile, treasury: treasury);
  }
}
