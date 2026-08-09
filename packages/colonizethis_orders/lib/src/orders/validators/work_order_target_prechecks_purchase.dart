import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_world/colonizethis_world.dart';

import '../diplomatic_access_helpers.dart';
import '../order_validation_result.dart';
import 'work_order_target_prechecks_shared.dart';

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
  if (targetProvinceId != null) {
    final province = ctx.game.worldState.tryGetProvince(targetProvinceId);
    if (province != null &&
        province.townDevelopmentLevel >= kTownDevelopmentLevelMax) {
      return OrderValidationResult.rejected(
        'Town development level already at maximum (4)',
      );
    }
    if (province != null) {
      final townKey = province.townTileKey;
      if (townKey == null ||
          townKey.isEmpty ||
          townKey != order.targetTileKey) {
        return OrderValidationResult.rejected(
          'upgrade_town target must be the province town tile',
        );
      }
    }
  }
  if (provinceOwnerId != null && provinceOwnerId != ctx.playerId) {
    if (!isMinorOrTribe(
      ctx.game,
      provinceOwnerId,
      factionMembership: ctx.factionMembership,
    )) {
      return OrderValidationResult.rejected(
        'upgrade_town target must be an owned or Minor/Tribe province town',
      );
    }
    final embassyRejection = rejectAtWarOrWithoutEmbassy(
      ctx.game,
      ctx.playerId,
      provinceOwnerId,
      atWarMessage: 'Cannot upgrade town: at war with that faction',
      embassyMessage:
          'Cannot upgrade town: embassy required with that Minor/Tribe',
    );
    if (embassyRejection != null) {
      return embassyRejection;
    }
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
  final embassyRejection = rejectAtWarOrWithoutEmbassy(
    ctx.game,
    ctx.playerId,
    ownerId,
    atWarMessage: 'Cannot purchase land: at war with that faction',
    embassyMessage:
        'Cannot purchase land: embassy required with that Minor/Tribe',
  );
  if (embassyRejection != null) {
    return embassyRejection;
  }
  final resourceGate = resourceOrMineralRejection(
    ctx,
    o.targetTileKey,
    emptyResourceMessage: 'Tile has no resource',
  );
  if (resourceGate.rejection != null) return resourceGate.rejection;
  final resourceId = resourceGate.resourceId;
  if (resourceId == null) {
    return OrderValidationResult.rejected('Tile has no resource');
  }
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
