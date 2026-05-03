import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'orders_application_context.dart';

/// True when [purchase_land] may be assigned (same gates as completion, no
/// state mutation).
bool purchaseLandEligibleAtAssign({
  required BuildWorkState state,
  required Player player,
  required Unit unit,
  required String targetTileKey,
  required int treasury,
  required Map<String, String> purchasedTilesByTileKey,
  required Province? Function(String) provinceById,
}) {
  if (purchasedTilesByTileKey.containsKey(targetTileKey)) {
    return false;
  }
  final resourceId = state.game.worldState.resourceByTileKey[targetTileKey];
  if (resourceId == null) {
    return false;
  }

  final provinceId =
      Unit.provinceIdFromTileKey(targetTileKey) ?? unit.locationProvinceId;
  final province = provinceById(provinceId);
  final ownerId = province?.ownerId;
  if (ownerId == null) {
    return false;
  }

  final hasEmbassy = state.game.overtureStates.any(
    (o) => o.gpId == player.id && o.targetId == ownerId && o.hasEmbassy,
  );
  if (!hasEmbassy) {
    return false;
  }

  final atWar = state.game.diplomacyRelations.any((rel) {
    final ids = {rel.factionId1, rel.factionId2};
    return ids.contains(player.id) && ids.contains(ownerId) && rel.atWar;
  });
  if (atWar) {
    return false;
  }

  final cost = purchaseLandCost(resourceId);
  return treasury >= cost;
}

/// Applies [purchase_land] treasury deduction and [purchasedTilesByTileKey] at
/// work completion. No-op when preconditions no longer hold.
({int treasury, Map<String, String> purchasedTilesByTileKey})
applyPurchaseLandCompletion({
  required BuildWorkState state,
  required Player player,
  required Unit unit,
  required String targetTileKey,
  required int treasury,
  required Map<String, String> purchasedTilesByTileKey,
  required Province? Function(String) provinceById,
}) {
  final purchased = Map<String, String>.from(purchasedTilesByTileKey);
  final resourceId = state.game.worldState.resourceByTileKey[targetTileKey];
  if (resourceId == null) {
    return (treasury: treasury, purchasedTilesByTileKey: purchased);
  }

  final provinceId =
      Unit.provinceIdFromTileKey(targetTileKey) ?? unit.locationProvinceId;
  final province = provinceById(provinceId);
  final ownerId = province?.ownerId;
  if (ownerId == null) {
    return (treasury: treasury, purchasedTilesByTileKey: purchased);
  }

  final hasEmbassy = state.game.overtureStates.any(
    (o) => o.gpId == player.id && o.targetId == ownerId && o.hasEmbassy,
  );
  if (!hasEmbassy) {
    return (treasury: treasury, purchasedTilesByTileKey: purchased);
  }

  final atWar = state.game.diplomacyRelations.any((rel) {
    final ids = {rel.factionId1, rel.factionId2};
    return ids.contains(player.id) && ids.contains(ownerId) && rel.atWar;
  });
  if (atWar) {
    return (treasury: treasury, purchasedTilesByTileKey: purchased);
  }

  final cost = purchaseLandCost(resourceId);
  if (treasury < cost) {
    return (treasury: treasury, purchasedTilesByTileKey: purchased);
  }
  if (purchased.containsKey(targetTileKey)) {
    return (treasury: treasury, purchasedTilesByTileKey: purchased);
  }

  final nextTreasury = treasury - cost;
  purchased[targetTileKey] = player.id;
  return (treasury: nextTreasury, purchasedTilesByTileKey: purchased);
}
