import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../orders_application_context.dart';
import 'shared_work_assignment.dart';

/// Result of attempting purchase_land: updated treasury and purchased-tile map.
({int treasury, Map<String, String> purchasedTilesByTileKey})
applyPurchaseLandWorkOrder({
  required BuildWorkState state,
  required Player player,
  required Unit unit,
  required String targetTileKey,
  required int treasury,
  required Map<String, String> purchasedTilesByTileKey,
  required Province? Function(String) provinceById,
  required void Function(String, Unit) updateUnit,
}) {
  final purchased = Map<String, String>.from(purchasedTilesByTileKey);
  final resourceId = state.game.worldState.resourceByTileKey[targetTileKey];
  if (resourceId == null) return (treasury: treasury, purchasedTilesByTileKey: purchased);

  final provinceId =
      Unit.provinceIdFromTileKey(targetTileKey) ?? unit.locationProvinceId;
  final province = provinceById(provinceId);
  final ownerId = province?.ownerId;
  if (ownerId == null) return (treasury: treasury, purchasedTilesByTileKey: purchased);

  final hasEmbassy = state.game.overtureStates.any(
    (o) => o.gpId == player.id && o.targetId == ownerId && o.hasEmbassy,
  );
  if (!hasEmbassy) return (treasury: treasury, purchasedTilesByTileKey: purchased);

  final atWar = state.game.diplomacyRelations.any((rel) {
    final ids = {rel.factionId1, rel.factionId2};
    return ids.contains(player.id) && ids.contains(ownerId) && rel.atWar;
  });
  if (atWar) return (treasury: treasury, purchasedTilesByTileKey: purchased);

  final cost = purchaseLandCost(resourceId);
  if (treasury < cost) return (treasury: treasury, purchasedTilesByTileKey: purchased);
  if (purchased.containsKey(targetTileKey)) {
    return (treasury: treasury, purchasedTilesByTileKey: purchased);
  }

  var nextTreasury = treasury - cost;
  purchased[targetTileKey] = player.id;
  completeInstantCivilianOrder(updateUnit, unit, targetTileKey);
  return (treasury: nextTreasury, purchasedTilesByTileKey: purchased);
}
