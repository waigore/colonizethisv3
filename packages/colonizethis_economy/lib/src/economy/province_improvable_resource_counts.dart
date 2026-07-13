/// Improvable resource tile counts for province Available display. Refs #4002.
///
/// SPEC: SPEC/program/province-extraction-snapshot.md
library;

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_world/colonizethis_world.dart';

import 'economy_resource_constants.dart';
import 'tile_extraction_pipeline.dart';

/// Per-commodity improvable tile count and highlight keys.
class ProvinceImprovableCommodityCount {
  const ProvinceImprovableCommodityCount({
    required this.count,
    this.tileKeys = const [],
  });

  final int count;
  final List<String> tileKeys;
}

/// Counts tiles in [provinceId] that can still be improved under the owner's
/// tech/terrain extraction cap. Minerals require prospected by [ownerId].
Map<String, ProvinceImprovableCommodityCount>
provinceImprovableResourceTileCounts({
  required Game game,
  required String provinceId,
  required String ownerId,
  required Map<String, TileMapResult> tileMapByRegion,
  Map<String, bool>? ownerTechUnlocked,
}) {
  final techUnlocked =
      ownerTechUnlocked ??
      game.playerById(ownerId)?.techUnlocked ??
      const <String, bool>{};
  final prospected =
      game.worldState.playerProspectedTiles[ownerId] ?? const <String>{};
  final tileState = game.worldState.tileState;

  final tileKeys = _tileKeysForProvince(
    game: game,
    provinceId: provinceId,
    tileMapByRegion: tileMapByRegion,
  );

  final acc = <String, List<String>>{};
  for (final tileKey in tileKeys) {
    final resourceContext = resolveTileKeyResourceContext(
      tileKey: tileKey,
      tileMapByRegion: tileMapByRegion,
    );
    if (resourceContext == null) continue;
    if (resourceContext.provinceId != provinceId) continue;

    final commodityId = resourceContext.commodityId;
    if (kMineralResourceIds.contains(commodityId) &&
        !prospected.contains(tileKey)) {
      continue;
    }

    final terrain = tileMapByRegion[resourceContext.regionId]?.terrainAt(
      resourceContext.x,
      resourceContext.y,
    );
    final cap = terrain == null
        ? extractionCapForResourceForUnlocked(techUnlocked, commodityId)
        : extractionCapForResourceOnTerrain(techUnlocked, commodityId, terrain);
    final improvement = tileState.improvementLevel(tileKey);
    if (improvement >= cap) continue;

    acc.putIfAbsent(commodityId, () => []).add(tileKey);
  }

  final out = <String, ProvinceImprovableCommodityCount>{};
  for (final commodity in CommodityCatalog.all) {
    final keys = acc[commodity.id];
    if (keys == null || keys.isEmpty) continue;
    keys.sort();
    out[commodity.id] = ProvinceImprovableCommodityCount(
      count: keys.length,
      tileKeys: List<String>.from(keys),
    );
  }
  return out;
}

List<String> _tileKeysForProvince({
  required Game game,
  required String provinceId,
  required Map<String, TileMapResult> tileMapByRegion,
}) {
  final parts = provinceId.split('|');
  if (parts.length < 2) return const [];
  final regionId = parts[0];
  final localId = parts.sublist(1).join('|');

  final fromIndex =
      game.worldState.tileKeysByRegionAndProvince[regionId]?[localId] ??
      game.worldState.tileKeysByRegionAndProvince[regionId]?[provinceId];
  if (fromIndex != null && fromIndex.isNotEmpty) {
    return List<String>.from(fromIndex);
  }

  final map = tileMapByRegion[regionId];
  if (map == null) return const [];
  final keys = <String>[];
  for (var y = 0; y < map.height; y++) {
    for (var x = 0; x < map.width; x++) {
      final cell = map.cell(x, y);
      if (cell != localId && cell != provinceId) continue;
      keys.add('$regionId|$localId|$x|$y');
    }
  }
  return keys;
}
