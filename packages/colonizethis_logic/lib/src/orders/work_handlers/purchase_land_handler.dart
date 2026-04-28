import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../orders_application_context.dart';
import 'shared_work_assignment.dart';

int applyPurchaseLandWorkOrder({
  required BuildWorkState state,
  required Player player,
  required Unit unit,
  required String targetTileKey,
  required int treasury,
  required Map<String, String> purchasedTilesByTileKey,
  required Province? Function(String) provinceById,
  required void Function(String, Unit) updateUnit,
}) {
  final resourceId = state.game.worldState.resourceByTileKey[targetTileKey];
  if (resourceId == null) return treasury;

  final provinceId =
      Unit.provinceIdFromTileKey(targetTileKey) ?? unit.locationProvinceId;
  final province = provinceById(provinceId);
  final ownerId = province?.ownerId;
  if (ownerId == null) return treasury;

  final hasEmbassy = state.game.overtureStates.any(
    (o) => o.gpId == player.id && o.targetId == ownerId && o.hasEmbassy,
  );
  if (!hasEmbassy) return treasury;

  final atWar = state.game.diplomacyRelations.any((rel) {
    final ids = {rel.factionId1, rel.factionId2};
    return ids.contains(player.id) && ids.contains(ownerId) && rel.atWar;
  });
  if (atWar) return treasury;

  final cost = purchaseLandCost(resourceId);
  if (treasury < cost) return treasury;
  if (purchasedTilesByTileKey.containsKey(targetTileKey)) return treasury;

  treasury -= cost;
  purchasedTilesByTileKey[targetTileKey] = player.id;
  completeInstantCivilianOrder(updateUnit, unit, targetTileKey);
  return treasury;
}
