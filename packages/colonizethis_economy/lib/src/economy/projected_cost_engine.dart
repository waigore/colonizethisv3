import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'build_cost.dart';

/// Shared afford/deduct paths for work material costs and build orders so
/// validation, application, and economy preview stay aligned.
/// SPEC/program/orders.md § Work orders; § Build orders.
abstract final class ProjectedCostEngine {
  /// Whether [stockpile] has every commodity in [cost] at required quantities.
  static bool canAffordWorkMaterialCost(
    Stockpile stockpile,
    WorkOrderCost cost,
  ) {
    for (final e in cost.entries) {
      if (stockpile.quantityOf(e.key) < e.value) return false;
    }
    return true;
  }

  /// Deducts [cost] from [stockpile]. Call only when
  /// [canAffordWorkMaterialCost] is true for the same inputs.
  static Stockpile deductWorkMaterialCost(
    Stockpile stockpile,
    WorkOrderCost cost,
  ) {
    var s = stockpile;
    for (final e in cost.entries) {
      s = s.applyDelta(e.key, -e.value);
    }
    return s;
  }

  /// Same contract as [canAffordBuild] in [build_cost.dart].
  static ({bool canAfford, String? reason}) canAffordBuildOrder(
    Player player,
    BuildUnitOrder order,
    WorkerPool workers,
    Stockpile stockpile,
    int treasury,
  ) => canAffordBuild(player, order, workers, stockpile, treasury);

  /// Same contract as [applyBuildCostDeduction] in [build_cost.dart].
  static ({WorkerPool workers, Stockpile stockpile, int treasury})
  applyBuildOrderCostDeduction(
    Player player,
    BuildUnitOrder order,
    WorkerPool workers,
    Stockpile stockpile,
    int treasury,
  ) => applyBuildCostDeduction(player, order, workers, stockpile, treasury);
}
