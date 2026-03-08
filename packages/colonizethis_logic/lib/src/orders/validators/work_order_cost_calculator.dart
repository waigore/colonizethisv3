import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../../world/province_lookup.dart';

/// Calculates work order material costs. Reduces duplication between validation and projection.
/// SPEC/program/orders.md § Work orders. Used by OrderEngine for work-order cost validation and projection.
class WorkOrderCostCalculator {
  final Game game;

  const WorkOrderCostCalculator(this.game);

  /// Calculates cost for a work order at the given tile.
  /// Returns null if no cost applies (steal_tech, counter_spy, purchase_land).
  Map<String, int>? calculateCost(
    String target,
    String targetTileKey, {
    int improvementLevel = 0,
    int? fortLevel,
    int? roadLevel,
  }) {
    if (target == 'steal_tech' ||
        target == 'counter_spy' ||
        target == 'purchase_land') {
      return null;
    }

    final province = _targetProvince(targetTileKey);
    final fl = fortLevel ?? province?.fortLevel ?? 0;
    final rl = roadLevel ?? game.worldState.tileState.roadLevel(targetTileKey);

    return workOrderMaterialCost(
      target,
      improvementLevel: improvementLevel,
      fortLevel: fl,
      roadLevel: rl,
    );
  }

  Province? _targetProvince(String tileKey) {
    final provId = Unit.provinceIdFromTileKey(tileKey);
    if (provId == null) return null;
    return tryGetProvince(game.worldState, provId);
  }
}
