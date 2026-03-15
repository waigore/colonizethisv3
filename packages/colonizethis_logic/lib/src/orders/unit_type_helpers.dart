import 'package:colonizethis_models/colonizethis_models.dart' show WorldState;

import '../world/unit_lookup.dart' show allUnitsFromWorld;

/// Shared unit-type and work-target predicates for orders. SPEC/program/orders.md § Work orders.
/// Used by WorkOrderValidator and OrderEngine for dev-exclusive tile tracking.

/// True for Builder, Engineer, Merchant: at most one work order per tile per player.
bool isDevExclusiveUnitType(String type) =>
    type == 'Builder' || type == 'Engineer' || type == 'Merchant';

/// True for work targets that participate in per-tile exclusivity (one order per tile per player).
/// Used with [isDevExclusiveUnitType] to enforce Builder/Engineer/Merchant tile exclusivity.
bool isDevExclusiveWorkTarget(String target) =>
    target == 'build_improvement' ||
    target == 'upgrade_town' ||
    target == 'build_road' ||
    target == 'build_port' ||
    target == 'build_fort' ||
    target == 'purchase_land';

/// Tile keys already reserved by [playerId]'s Builder/Engineer/Merchant currentWork.
/// Used for per-player tile exclusivity (SPEC/game/civilian-units.md, SPEC/program/orders.md).
Set<String> devExclusiveTilesFromWorld(WorldState world, String playerId) {
  final tiles = <String>{};
  for (final u in allUnitsFromWorld(world)) {
    final w = u.currentWork;
    if (u.ownerId == playerId &&
        isDevExclusiveUnitType(u.type) &&
        w != null &&
        w.tileKey.isNotEmpty) {
      tiles.add(w.tileKey);
    }
  }
  return tiles;
}
