import 'package:colonizethis_models/colonizethis_models.dart' as ct_models;

/// Pure-ish helpers for `GameMapArea` state translation.
class GameMapAreaStateLogic {
  static int regionIndexFromWorldRegionId(String regionId) {
    if (regionId == 'newWorld') return 1;
    return 0; // oldWorld (default)
  }

  static bool isWorkTargetTileProvinceBased(String workTarget) {
    return workTarget == 'explore' ||
        workTarget == 'steal_tech' ||
        workTarget == 'counter_spy';
  }

  /// For province-based work targets, translate the tile key to a canonical tile
  /// key within that province (x=0,y=0).
  static String translateWorkTargetTileKey({
    required String tileKey,
    required String workTarget,
  }) {
    if (!isWorkTargetTileProvinceBased(workTarget)) return tileKey;
    final parts = tileKey.split('|');
    if (parts.length < 2) return tileKey;
    return '${parts[0]}|${parts[1]}|0|0';
  }

  static ct_models.Orders addHumanWorkOrder({
    required ct_models.Orders orders,
    required String humanPlayerId,
    required ct_models.WorkOrder workOrder,
  }) {
    final list = <ct_models.WorkOrder>[
      ...(orders.workOrdersByPlayerId[humanPlayerId] ?? const []),
      workOrder,
    ];
    return orders.copyWith(
      workOrdersByPlayerId: {
        ...orders.workOrdersByPlayerId,
        humanPlayerId: list,
      },
    );
  }
}

