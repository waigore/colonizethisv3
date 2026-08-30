import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'package:colonizethis_orders/colonizethis_orders.dart'
    show isMineralEligibleTile;
import 'package:colonizethis_world/colonizethis_world.dart';

import '../constants.dart';

// Shared scan helpers for co-located feedstock prospect probes (Refs #4368 Slice B).

/// Co-located mineral-eligible feedstock tile paired with the idle Explorer
/// that shares its province — the probe target for intra-pass gate checks.
typedef ColocatedFeedstockProspectProbe = ({
  Unit unit,
  String tileKey,
  String provinceIdFull,
  String regionId,
});

Map<String, Set<String>> eligibleMineralFeedstockTileKeysByProvince({
  required Game game,
  required String playerId,
  required Set<String> feedstockIds,
  Map<String, TileMapResult>? tileMapByRegion,
}) {
  if (feedstockIds.isEmpty) return const {};
  final ws = game.worldState;
  final prospected = ws.playerProspectedTiles[playerId] ?? const <String>{};
  final eligibleTileKeysByProvince = <String, Set<String>>{};
  for (final entry in ws.resourceByTileKey.entries) {
    if (!feedstockIds.contains(entry.value)) continue;
    if (!kMineralResourceIds.contains(entry.value)) continue;
    if (Unit.regionIdFromTileKey(entry.key) == kNewWorldRegionId) continue;
    if (prospected.contains(entry.key)) continue;
    if (!isMineralEligibleTile(game, tileMapByRegion, entry.key)) continue;
    final provinceId = Unit.provinceIdFromTileKey(entry.key);
    if (provinceId == null) continue;
    final province = ws.tryGetProvince(provinceId);
    if (province == null || province.ownerId != playerId) continue;
    (eligibleTileKeysByProvince[provinceId] ??= <String>{}).add(entry.key);
  }
  return eligibleTileKeysByProvince;
}

Set<String> colocatedMineralEligibleFeedstockTargetTileKeys({
  required Game game,
  required String playerId,
  required Set<String> feedstockIds,
  Map<String, TileMapResult>? tileMapByRegion,
}) {
  final eligibleTileKeysByProvince = eligibleMineralFeedstockTileKeysByProvince(
    game: game,
    playerId: playerId,
    feedstockIds: feedstockIds,
    tileMapByRegion: tileMapByRegion,
  );
  if (eligibleTileKeysByProvince.isEmpty) return const {};
  final targetTileKeys = <String>{};
  for (final unit in allUnitsFromWorld(game.worldState)) {
    if (unit.ownerId != playerId) continue;
    if (!isExplorerUnit(unit.type)) continue;
    if (unit.currentWork != null) continue;
    final tiles = eligibleTileKeysByProvince[unit.locationProvinceId];
    if (tiles != null) targetTileKeys.addAll(tiles);
  }
  return targetTileKeys;
}

List<ColocatedFeedstockProspectProbe> colocatedMineralEligibleFeedstockProspectProbes({
  required Game game,
  required String playerId,
  required Set<String> feedstockIds,
  Map<String, TileMapResult>? tileMapByRegion,
}) {
  final eligibleTileKeysByProvince = eligibleMineralFeedstockTileKeysByProvince(
    game: game,
    playerId: playerId,
    feedstockIds: feedstockIds,
    tileMapByRegion: tileMapByRegion,
  );
  if (eligibleTileKeysByProvince.isEmpty) return const [];
  final probes = <ColocatedFeedstockProspectProbe>[];
  for (final unit in allUnitsFromWorld(game.worldState)) {
    if (unit.ownerId != playerId) continue;
    if (!isExplorerUnit(unit.type)) continue;
    if (unit.currentWork != null) continue;
    final tiles = eligibleTileKeysByProvince[unit.locationProvinceId];
    if (tiles == null) continue;
    for (final tileKey in tiles) {
      final regionId = Unit.regionIdFromTileKey(tileKey);
      if (regionId == null) continue;
      probes.add((
        unit: unit,
        tileKey: tileKey,
        provinceIdFull: unit.locationProvinceId,
        regionId: regionId,
      ));
    }
  }
  return probes;
}
