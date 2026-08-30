import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_world/colonizethis_world.dart';

import 'work_tile_candidate_index_types.dart';

typedef WorkTilePrefilterOp = void Function(WorkTilePrefilterSession c);

void forEachPrefixedProvinceTile({
  required Map<String, Map<String, List<String>>> tileKeysByRegion,
  required void Function(String provinceId, String tileKey) onTile,
}) {
  for (final regionEntry in tileKeysByRegion.entries) {
    for (final provinceEntry in regionEntry.value.entries) {
      final provinceId = provinceEntry.key;
      if (!ProvinceId.isPrefixed(provinceId)) continue;
      for (final tileKey in provinceEntry.value) {
        onTile(provinceId, tileKey);
      }
    }
  }
}

void addAllTilesInOwnedPrefixedProvinces({
  required Map<String, Map<String, List<String>>> tileKeysByRegion,
  required Set<String> ownedProvinceIds,
  required Set<String> result,
}) {
  for (final regionEntry in tileKeysByRegion.entries) {
    for (final provinceEntry in regionEntry.value.entries) {
      final provinceId = provinceEntry.key;
      if (!ProvinceId.isPrefixed(provinceId)) continue;
      if (!ownedProvinceIds.contains(provinceId)) continue;
      result.addAll(provinceEntry.value);
    }
  }
}

void addCandidateTilesForTownWork({
  required Game game,
  required Set<String> ownedProvinceIds,
  required Set<String> result,
}) {
  final world = game.worldState;
  for (final provinceId in ownedProvinceIds) {
    final province = world.tryGetProvince(provinceId);
    if (province == null) continue;
    final townTileKey = province.townTileKey;
    if (townTileKey == null || townTileKey.isEmpty) continue;
    result.add(townTileKey);
  }
}
