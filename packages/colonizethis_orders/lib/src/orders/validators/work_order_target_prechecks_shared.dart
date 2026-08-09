import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_world/colonizethis_world.dart';

import '../diplomatic_access_helpers.dart';
import '../order_work_constants.dart';
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
    required this.devExclusiveTiles,
    this.factionMembership,
    this.tileMapByRegion,
  });

  final Game game;
  final Player player;
  final String playerId;
  final int treasury;

  /// Tiles already reserved by accepted dev-exclusive work for this player.
  final Set<String> devExclusiveTiles;

  /// Per-region tile maps, used to resolve terrain for terrain-dependent caps
  /// (e.g. the scrub-forest timber level-1 hard cap, R4 / issue #3573). May be
  /// `null` in contexts without map data, in which case terrain caps are skipped.
  final Map<String, TileMapResult>? tileMapByRegion;

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
  kWorkTargetUpgradeTown,
};

/// Shared empty-resource + mineral-prospected gate for purchase_land /
/// build_improvement (Refs #3949 item 7).
({String? resourceId, OrderValidationResult? rejection})
resourceOrMineralRejection(
  WorkOrderTargetPrecheckContext ctx,
  String tileKey, {
  required String emptyResourceMessage,
}) {
  final resourceId = ctx.game.worldState.resourceAtTile(tileKey);
  if (resourceId == null || resourceId.isEmpty) {
    return (
      resourceId: null,
      rejection: OrderValidationResult.rejected(emptyResourceMessage),
    );
  }
  final mineralRejection = rejectIfMineralTileNotProspected(
    game: ctx.game,
    playerId: ctx.playerId,
    tileKey: tileKey,
    resourceId: resourceId,
  );
  if (mineralRejection != null) {
    return (resourceId: null, rejection: mineralRejection);
  }
  return (resourceId: resourceId, rejection: null);
}

/// Shared controlled-or-embassy civilian access gate (Refs #3949 item 7).
OrderValidationResult? rejectIfUncontrolledWithoutEmbassyWork(
  WorkOrderTargetPrecheckContext ctx,
  String tileKey, {
  required String unitType,
  required String? provinceOwnerId,
  required String message,
}) {
  final controlled = isTileControlledByPlayer(
    ctx.game,
    ctx.playerId,
    tileKey,
  );
  final embassyWork = ctx.civilianEmbassyWorkAllowed(
    unitType,
    provinceOwnerId,
  );
  if (controlled || embassyWork) return null;
  return OrderValidationResult.rejected(message);
}
