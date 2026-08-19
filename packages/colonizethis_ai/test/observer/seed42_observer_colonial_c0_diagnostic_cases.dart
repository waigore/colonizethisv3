import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

/// Idle-Merchant scan matching the production planner gate (C0 diagnostic).
bool hasIdleMerchantForC0Diagnostic(WorldState world, String playerId) {
  for (final unit in allUnitsFromWorld(world)) {
    if (unit.ownerId == playerId &&
        unit.type == kUnitTypeMerchant &&
        unit.status == UnitStatus.idle) {
      return true;
    }
  }
  return false;
}

/// Per-tile `purchase_land` gates matching `precheckPurchaseLand` (C0).
bool provinceHasValidPurchaseLandTileForC0Diagnostic({
  required WorldState world,
  required String provinceId,
  required int treasury,
  required Set<String> prospected,
  required Map<String, String> purchasedByTile,
}) {
  for (final entry in world.resourceByTileKey.entries) {
    final tileKey = entry.key;
    if (Unit.provinceIdFromTileKey(tileKey) != provinceId) continue;
    final resourceId = entry.value;
    if (resourceId.isEmpty) continue;
    if (purchasedByTile.containsKey(tileKey)) continue;
    if (kMineralResourceIds.contains(resourceId) &&
        !prospected.contains(tileKey)) {
      continue;
    }
    if (treasury < purchaseLandCost(resourceId)) continue;
    return true;
  }
  return false;
}
