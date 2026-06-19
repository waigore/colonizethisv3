import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../order_work_constants.dart';
import '../diplomatic_access_helpers.dart';
import 'package:colonizethis_world/colonizethis_world.dart';
import 'package:colonizethis_diplomacy/colonizethis_diplomacy.dart';
import '../order_validation_result.dart';

/// Shared inputs for per-target work order validation steps that run before
/// generic territory and cost checks. [civilianEmbassyWorkAllowed] mirrors
/// [WorkOrderValidator] embassy/minor rules for Builder/Engineer/Merchant.
class WorkOrderTargetPrecheckContext {
  WorkOrderTargetPrecheckContext({
    required this.game,
    required this.player,
    required this.playerId,
    required this.treasury,
    required this.civilianEmbassyWorkAllowed,
    this.factionMembership,
  });

  final Game game;
  final Player player;
  final String playerId;
  final int treasury;

  /// When set, avoids linear scans for Minor/Tribe checks in purchase-land
  /// prevalidation (Refs #2394).
  final DiplomacyFactionMembership? factionMembership;

  /// True when the unit may perform civilian work in a Minor/Tribe province
  /// with embassy + tech (validator-specific).
  final bool Function(String unitType, String? provinceOwnerId)
  civilianEmbassyWorkAllowed;
}

/// Returns a rejection, or `null` when this precheck passes.
typedef WorkOrderTargetPrecheck =
    OrderValidationResult? Function(
      WorkOrderTargetPrecheckContext ctx,
      WorkOrder o,
      String? targetProvinceId,
      String? provinceOwnerId,
      String unitType,
    );

/// Targets that run dedicated territory rules in [workOrderTargetPrechecks] and
/// must not also hit the default non-explorer foreign-province check.
const Set<String> kWorkTargetsSkippingDefaultForeignProvinceCheck = {
  ...kWorkTargetsWithoutMaterialCost,
  kWorkTargetBuildImprovement,
};

OrderValidationResult? precheckUpgradeTown(
  WorkOrderTargetPrecheckContext ctx,
  WorkOrder order,
  String? targetProvinceId,
  String? provinceOwnerId,
  String unitType,
) {
  if (ctx.player.techUnlocked?[kTechIdNationalBureaucracy] != true) {
    return OrderValidationResult.rejected(
      'National Bureaucracy tech required for upgrade_town',
    );
  }
  return null;
}

OrderValidationResult? precheckStealTech(
  WorkOrderTargetPrecheckContext ctx,
  WorkOrder order,
  String? targetProvinceId,
  String? provinceOwnerId,
  String unitType,
) {
  if (targetProvinceId == null) {
    return OrderValidationResult.rejected('Invalid target for steal_tech');
  }
  final otherPlayer = ctx.game.otherGreatPowerAtCapitalProvince(
    targetProvinceId,
    ctx.playerId,
  );
  if (otherPlayer == null) {
    return OrderValidationResult.rejected(
      'steal_tech target must be another Great Power capital province',
    );
  }
  final ourTech = ctx.player.techUnlocked ?? {};
  final theirTech = otherPlayer.techUnlocked ?? {};
  final hasTechWeLack = theirTech.entries.any(
    (e) => e.value == true && ourTech[e.key] != true,
  );
  if (!hasTechWeLack) {
    return OrderValidationResult.rejected('Target has no technology you lack');
  }
  return null;
}

OrderValidationResult? precheckCounterSpy(
  WorkOrderTargetPrecheckContext ctx,
  WorkOrder order,
  String? targetProvinceId,
  String? provinceOwnerId,
  String unitType,
) {
  if (provinceOwnerId != ctx.playerId) {
    return OrderValidationResult.rejected(
      'counter_spy target must be your own province',
    );
  }
  return null;
}

OrderValidationResult? precheckPurchaseLand(
  WorkOrderTargetPrecheckContext ctx,
  WorkOrder o,
  String? targetProvinceId,
  String? ownerId,
  String unitType,
) {
  if (ownerId == null || ownerId == ctx.playerId) {
    return OrderValidationResult.rejected(
      'purchase_land target must be a Minor or Tribe province',
    );
  }
  if (!isMinorOrTribe(
    ctx.game,
    ownerId,
    factionMembership: ctx.factionMembership,
  )) {
    return OrderValidationResult.rejected(
      'purchase_land target must be a Minor or Tribe province',
    );
  }
  final rel = getRelation(ctx.game, ctx.playerId, ownerId);
  if (rel?.atWar == true) {
    return OrderValidationResult.rejected(
      'Cannot purchase land: at war with that faction',
    );
  }
  final overture = getOverture(ctx.game, ctx.playerId, ownerId);
  if (overture == null || !overture.hasEmbassy) {
    return OrderValidationResult.rejected(
      'Cannot purchase land: embassy required with that Minor/Tribe',
    );
  }
  final resourceId = ctx.game.worldState.resourceAtTile(o.targetTileKey);
  if (resourceId == null || resourceId.isEmpty) {
    return OrderValidationResult.rejected('Tile has no resource');
  }
  final mineralRejection = rejectIfMineralTileNotProspected(
    game: ctx.game,
    playerId: ctx.playerId,
    tileKey: o.targetTileKey,
    resourceId: resourceId,
  );
  if (mineralRejection != null) return mineralRejection;
  final cost = purchaseLandCost(resourceId);
  if (ctx.treasury < cost) {
    return OrderValidationResult.rejected(
      'Insufficient treasury for purchase_land (need $cost)',
    );
  }
  final existingBuyer = ctx.game.worldState.purchaserOfTile(o.targetTileKey);
  if (existingBuyer != null) {
    return OrderValidationResult.rejected(
      existingBuyer == ctx.playerId
          ? 'You already own this tile'
          : 'Tile already purchased by another power',
    );
  }
  return null;
}

OrderValidationResult? precheckBuildImprovement(
  WorkOrderTargetPrecheckContext ctx,
  WorkOrder o,
  String? targetProvinceId,
  String? ownerId,
  String unitType,
) {
  final controlled = isTileControlledByPlayer(
    ctx.game,
    ctx.playerId,
    o.targetTileKey,
  );
  final embassyWork = ctx.civilianEmbassyWorkAllowed(unitType, ownerId);
  if (!controlled && !embassyWork) {
    return OrderValidationResult.rejected(
      'Cannot build improvement in foreign or uncontrolled province',
    );
  }
  final resourceId = ctx.game.worldState.resourceAtTile(o.targetTileKey);
  if (resourceId == null || resourceId.isEmpty) {
    return OrderValidationResult.rejected(
      'Tile has no resource; build_improvement requires a resource on the tile',
    );
  }
  final mineralRejection = rejectIfMineralTileNotProspected(
    game: ctx.game,
    playerId: ctx.playerId,
    tileKey: o.targetTileKey,
    resourceId: resourceId,
  );
  if (mineralRejection != null) return mineralRejection;
  final currentLevel = ctx.game.worldState.tileState.improvementLevel(
    o.targetTileKey,
  );
  if (currentLevel >= 4) {
    return OrderValidationResult.rejected(
      'Improvement level already at maximum (4)',
    );
  }
  final techCap = extractionCapForResourceForUnlocked(
    ctx.player.techUnlocked,
    resourceId,
  );
  if (currentLevel + 1 > techCap) {
    return OrderValidationResult.rejected(
      'Insufficient tech for next improvement level on $resourceId '
      '(extraction cap $techCap; unlock gathering tech to raise the cap)',
    );
  }
  return null;
}

/// Map dispatch for target-specific validation before generic work rules.
final Map<String, WorkOrderTargetPrecheck> workOrderTargetPrechecks = {
  kWorkTargetUpgradeTown: precheckUpgradeTown,
  kWorkTargetStealTech: precheckStealTech,
  kWorkTargetCounterSpy: precheckCounterSpy,
  kWorkTargetPurchaseLand: precheckPurchaseLand,
  kWorkTargetBuildImprovement: precheckBuildImprovement,
};

/// Runs the precheck registered for [order.target], if any.
OrderValidationResult? runWorkOrderTargetPrecheck(
  WorkOrderTargetPrecheckContext ctx,
  WorkOrder order,
  String? targetProvinceId,
  String? provinceOwnerId,
  String unitType,
) {
  final fn = workOrderTargetPrechecks[order.target];
  if (fn == null) {
    return null;
  }
  return fn(ctx, order, targetProvinceId, provinceOwnerId, unitType);
}
