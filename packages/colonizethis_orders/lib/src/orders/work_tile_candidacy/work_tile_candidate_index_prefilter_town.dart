import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_world/colonizethis_world.dart';

import '../diplomatic_access_helpers.dart';
import '../order_work_constants.dart';
import 'work_tile_candidate_index_prefilter_walkers.dart';
import 'work_tile_candidate_index_types.dart';

void prefilterWtTownWork(WorkTilePrefilterSession c) {
  addCandidateTilesForTownWork(
    game: c.game,
    ownedProvinceIds: c.ownedProvinceIds,
    result: c.result,
  );
}

void prefilterWtUpgradeTown(WorkTilePrefilterSession c) {
  addCandidateTilesForTownWork(
    game: c.game,
    ownedProvinceIds: c.ownedProvinceIds,
    result: c.result,
  );
  addMinorTribeTownTilesForEmbassyUpgrade(c);
}

void addMinorTribeTownTilesForEmbassyUpgrade(WorkTilePrefilterSession c) {
  final factionMembership =
      c.factionMembership ?? DiplomacyFactionMembership.from(c.game);
  for (final regionEntry in c.tileKeysByRegion.entries) {
    for (final provinceEntry in regionEntry.value.entries) {
      final provinceId = provinceEntry.key;
      if (!ProvinceId.isPrefixed(provinceId)) continue;
      if (c.ownedProvinceIds.contains(provinceId)) continue;
      final province = c.game.worldState.tryGetProvince(provinceId);
      if (province == null) continue;
      final ownerId = province.ownerId;
      if (ownerId == null || ownerId == c.playerId) continue;
      if (!factionMembership.isMinorOrTribe(ownerId)) continue;
      if (!hasPeaceTimeEmbassy(c.game, c.playerId, ownerId)) continue;
      final townTileKey = province.townTileKey;
      if (townTileKey == null || townTileKey.isEmpty) continue;
      c.result.add(townTileKey);
    }
  }
}

void prefilterWtOwnedProvinceTiles(WorkTilePrefilterSession c) {
  addAllTilesInOwnedPrefixedProvinces(
    tileKeysByRegion: c.tileKeysByRegion,
    ownedProvinceIds: c.ownedProvinceIds,
    result: c.result,
  );
}

final Map<String, WorkTilePrefilterOp> workTargetTownPrefilters =
    <String, WorkTilePrefilterOp>{
      kWorkTargetUpgradeTown: prefilterWtUpgradeTown,
      kWorkTargetBuildFort: prefilterWtTownWork,
      kWorkTargetBuildPort: prefilterWtOwnedProvinceTiles,
      kWorkTargetCounterSpy: prefilterWtOwnedProvinceTiles,
    };
