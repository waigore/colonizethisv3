import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_world/colonizethis_world.dart';

import 'town_manufacturing_bonus.dart';

/// Current and next-level town-workshop bonus from one connectivity walk.
///
/// Overlay hosts must call this once per rebuild (Refs #4747).
({
  ProvinceManufacturingBonus currentByProvinceId,
  ProvinceManufacturingBonus nextByProvinceId,
})
previewTownManufacturingBonusCurrentAndNextByProvince({
  required Game game,
  required MapTopology topology,
  Map<String, TileMapResult>? tileMapByRegion,
}) {
  if (tileMapByRegion == null || tileMapByRegion.isEmpty) {
    return (
      currentByProvinceId: const <String, Map<String, int>>{},
      nextByProvinceId: const <String, Map<String, int>>{},
    );
  }
  final gpConnectivity = resolveConnectivity(
    game: game,
    tileMapByRegion: tileMapByRegion,
    topology: topology,
  );
  final nonGpConnectivity = resolveNonGreatPowerConnectivity(
    game: game,
    tileMapByRegion: tileMapByRegion,
    topology: topology,
  );
  final computed = computeTownManufacturingBonusForGame(
    game: game,
    tileMapByRegion: tileMapByRegion,
    gpConnectivityByPlayerId: gpConnectivity,
    nonGpConnectivityByFactionId: nonGpConnectivity,
  );
  final nextByProvince = <String, Map<String, int>>{};
  for (final province in allProvinces(game.worldState)) {
    final level = province.townDevelopmentLevel;
    if (level >= kTownDevelopmentLevelMax) continue;
    final ownerId = province.ownerId;
    if (ownerId == null || ownerId.isEmpty) continue;
    final raw = computed.deliveredRawByProvince[province.id];
    if (raw == null || raw.isEmpty) continue;
    final next = computeTownManufacturingBonusForProvince(
      townDevelopmentLevel: level + 1,
      townConnectedDeliveredRawByCommodity: raw,
      techUnlocked: game.playerById(ownerId)?.techUnlocked,
    );
    if (next.isNotEmpty) {
      nextByProvince[province.id] = next;
    }
  }
  return (
    currentByProvinceId: computed.bonusByProvinceId,
    nextByProvinceId: nextByProvince,
  );
}
