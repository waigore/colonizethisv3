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

/// Arm-eligibility flags from scanning invadable NW provinces (C0 diagnostic).
class ColonialC0ArmEligibilityScan {
  const ColonialC0ArmEligibilityScan({
    required this.arm1JoinEmpireEligible,
    required this.arm2PurchaseLandEligible,
    required this.arm3HasNonWarNonGpOwner,
  });

  final bool arm1JoinEmpireEligible;
  final bool arm2PurchaseLandEligible;
  final bool arm3HasNonWarNonGpOwner;
}

ColonialC0ArmEligibilityScan scanColonialArmEligibilityForInvadable({
  required Game game,
  required String gpId,
  required List<String> invadable,
  required Map<String, String?> provinceOwner,
  required int treasury,
  required Set<String> prospected,
  required Map<String, String> purchasedByTile,
}) {
  var arm1JoinEmpireEligible = false;
  var arm2PurchaseLandEligible = false;
  var arm3HasNonWarNonGpOwner = false;
  for (final provinceId in invadable) {
    final ownerId = provinceOwner[provinceId];
    if (ownerId == null) continue;
    if (game.playerById(ownerId) != null) continue;

    if (!arm1JoinEmpireEligible) {
      final overture = getOverture(game, gpId, ownerId);
      final relation = getRelation(game, gpId, ownerId);
      if (overture != null &&
          overture.stage == OvertureStage.nap &&
          relation != null &&
          relation.score >= relationScoreMinFriendly &&
          treasury >= joinEmpireCostForMinorOrTribe(game, ownerId)) {
        arm1JoinEmpireEligible = true;
      }
    }

    if (!arm2PurchaseLandEligible) {
      final relation = getRelation(game, gpId, ownerId);
      final overture = getOverture(game, gpId, ownerId);
      if ((relation == null || !relation.atWar) &&
          overture != null &&
          overture.hasEmbassy &&
          provinceHasValidPurchaseLandTileForC0Diagnostic(
            world: game.worldState,
            provinceId: provinceId,
            treasury: treasury,
            prospected: prospected,
            purchasedByTile: purchasedByTile,
          )) {
        arm2PurchaseLandEligible = true;
      }
    }

    if (!arm3HasNonWarNonGpOwner) {
      final relation = getRelation(game, gpId, ownerId);
      if (relation == null || !relation.atWar) {
        arm3HasNonWarNonGpOwner = true;
      }
    }
  }
  return ColonialC0ArmEligibilityScan(
    arm1JoinEmpireEligible: arm1JoinEmpireEligible,
    arm2PurchaseLandEligible: arm2PurchaseLandEligible,
    arm3HasNonWarNonGpOwner: arm3HasNonWarNonGpOwner,
  );
}
