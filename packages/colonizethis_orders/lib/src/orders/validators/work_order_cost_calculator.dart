import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../order_work_constants.dart';
import '../feedstock_bootstrap_cost.dart';
import 'package:colonizethis_world/colonizethis_world.dart';

/// Calculates work order material costs. Reduces duplication between validation and projection.
/// SPEC/program/orders.md § Work orders. Used by OrderEngine for work-order cost validation and projection.
class WorkOrderCostCalculator {
  final Game game;
  final String? playerId;

  const WorkOrderCostCalculator(this.game, {this.playerId});

  /// Calculates cost for a work order at the given tile.
  /// Returns null if no cost applies (steal_tech, counter_spy, purchase_land).
  Map<String, int>? calculateCost(
    String target,
    String targetTileKey, {
    int improvementLevel = 0,
    int? fortLevel,
    int? roadLevel,
  }) {
    if (target == kWorkTargetStealTech ||
        target == kWorkTargetCounterSpy ||
        target == kWorkTargetPurchaseLand) {
      return null;
    }

    final province = _targetProvince(targetTileKey);
    final fl = fortLevel ?? province?.fortLevel ?? 0;
    final rl = roadLevel ?? game.worldState.tileState.roadLevel(targetTileKey);

    final base = workOrderMaterialCost(
      target,
      improvementLevel: improvementLevel,
      fortLevel: fl,
      roadLevel: rl,
    );
    if (base == null || playerId == null) return base;
    return _applyFeedstockBootstrapWaivers(
      target: target,
      targetTileKey: targetTileKey,
      improvementLevel: improvementLevel,
      baseCost: base,
    );
  }

  Map<String, int>? _applyFeedstockBootstrapWaivers({
    required String target,
    required String targetTileKey,
    required int improvementLevel,
    required Map<String, int> baseCost,
  }) {
    if (target != kWorkTargetBuildImprovement || improvementLevel != 0) {
      return baseCost;
    }
    final effective = feedstockBootstrapBuildImprovementEffectiveCost(
      game,
      playerId!,
      targetTileKey,
    );
    if (effective.length == baseCost.length) return baseCost;
    return effective;
  }

  Province? _targetProvince(String tileKey) {
    final provId = Unit.provinceIdFromTileKey(tileKey);
    if (provId == null) return null;
    return game.worldState.tryGetProvince(provId);
  }
}
