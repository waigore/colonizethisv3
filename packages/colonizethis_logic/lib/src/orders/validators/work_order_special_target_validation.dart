import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../../constants.dart';
import '../../diplomacy/diplomacy_resolver.dart';
import '../order_validation_result.dart';

/// Shared inputs for [workOrderSpecialTargetChecks] (spy/merchant targets).
class WorkOrderSpecialTargetContext {
  const WorkOrderSpecialTargetContext({
    required this.game,
    required this.player,
    required this.playerId,
    required this.treasury,
  });

  final Game game;
  final Player player;
  final String playerId;
  final int treasury;
}

/// Returns a rejection, or `null` when this target-specific rule passes.
typedef SpecialTargetWorkCheck =
    OrderValidationResult? Function(
      WorkOrderSpecialTargetContext ctx,
      WorkOrder o,
      String? targetProvinceId,
      String? ownerId,
    );

/// Map dispatch for work targets that previously used a long if–else chain.
/// Unknown targets are not present; caller continues with generic rules.
final Map<String, SpecialTargetWorkCheck> workOrderSpecialTargetChecks = {
  kWorkTargetStealTech: validateStealTechWorkTarget,
  kWorkTargetCounterSpy: validateCounterSpyWorkTarget,
  kWorkTargetPurchaseLand: validatePurchaseLandWorkTarget,
};

OrderValidationResult? validateStealTechWorkTarget(
  WorkOrderSpecialTargetContext ctx,
  WorkOrder _o,
  String? targetProvinceId,
  String? _ownerId,
) {
  if (targetProvinceId == null) {
    return OrderValidationResult.rejected('Invalid target for steal_tech');
  }
  final otherPlayer = ctx.game.players
      .where(
        (p) =>
            p.id != ctx.playerId && p.capitalProvinceId == targetProvinceId,
      )
      .firstOrNull;
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
    return OrderValidationResult.rejected(
      'Target has no technology you lack',
    );
  }
  return null;
}

OrderValidationResult? validateCounterSpyWorkTarget(
  WorkOrderSpecialTargetContext ctx,
  WorkOrder _o,
  String? _targetProvinceId,
  String? ownerId,
) {
  if (ownerId != ctx.playerId) {
    return OrderValidationResult.rejected(
      'counter_spy target must be your own province',
    );
  }
  return null;
}

OrderValidationResult? validatePurchaseLandWorkTarget(
  WorkOrderSpecialTargetContext ctx,
  WorkOrder o,
  String? _targetProvinceId,
  String? ownerId,
) {
  if (ownerId == null || ownerId == ctx.playerId) {
    return OrderValidationResult.rejected(
      'purchase_land target must be a Minor or Tribe province',
    );
  }
  if (!isMinorOrTribe(ctx.game, ownerId)) {
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
  final resourceId = ctx.game.worldState.resourceByTileKey[o.targetTileKey];
  if (resourceId == null || resourceId.isEmpty) {
    return OrderValidationResult.rejected('Tile has no resource');
  }
  if (kMineralResourceIds.contains(resourceId)) {
    final prospected =
        ctx.game.worldState.playerProspectedTiles[ctx.playerId] ??
        const <String>{};
    if (!prospected.contains(o.targetTileKey)) {
      return OrderValidationResult.rejected(
        'Mineral tile must be prospected first',
      );
    }
  }
  final cost = purchaseLandCost(resourceId);
  if (ctx.treasury < cost) {
    return OrderValidationResult.rejected(
      'Insufficient treasury for purchase_land (need $cost)',
    );
  }
  final existingBuyer =
      ctx.game.worldState.purchasedTilesByTileKey[o.targetTileKey];
  if (existingBuyer != null) {
    return OrderValidationResult.rejected(
      existingBuyer == ctx.playerId
          ? 'You already own this tile'
          : 'Tile already purchased by another power',
    );
  }
  return null;
}
