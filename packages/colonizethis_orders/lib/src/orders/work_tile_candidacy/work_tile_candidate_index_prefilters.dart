import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_diplomacy/colonizethis_diplomacy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_world/colonizethis_world.dart';

import '../build_rail_work_rules.dart';
import '../diplomatic_access_helpers.dart';
import '../order_work_constants.dart';
import '../orders_application_helpers.dart';
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

void prefilterWtBuildImprovement(WorkTilePrefilterSession c) {
  forEachPrefixedProvinceTile(
    tileKeysByRegion: c.tileKeysByRegion,
    onTile: (provinceId, tileKey) {
      final isOwnedProvince = c.ownedProvinceIds.contains(provinceId);
      final isPurchased = c.purchasedTiles[tileKey] == c.playerId;
      if (!isOwnedProvince && !isPurchased) return;
      final resourceId = c.resourceByTile[tileKey];
      if (resourceId == null || resourceId.isEmpty) return;
      c.result.add(tileKey);
    },
  );
}

void prefilterWtBuildRoad(WorkTilePrefilterSession c) {
  forEachPrefixedProvinceTile(
    tileKeysByRegion: c.tileKeysByRegion,
    onTile: (provinceId, tileKey) {
      final isOwnedProvince = c.ownedProvinceIds.contains(provinceId);
      final isPurchased = c.purchasedTiles[tileKey] == c.playerId;
      if (!isOwnedProvince && !isPurchased) return;
      c.result.add(tileKey);
    },
  );
}

void prefilterWtBuildRail(WorkTilePrefilterSession c) {
  final player = c.game.playerById(c.playerId);
  if (player == null) return;
  final tech = player.techUnlocked;
  final tileState = c.game.worldState.tileState;
  forEachPrefixedProvinceTile(
    tileKeysByRegion: c.tileKeysByRegion,
    onTile: (provinceId, tileKey) {
      final isOwnedProvince = c.ownedProvinceIds.contains(provinceId);
      final isPurchased = c.purchasedTiles[tileKey] == c.playerId;
      if (!isOwnedProvince && !isPurchased) return;
      final roadLevel = tileState.roadLevel(tileKey);
      if (roadLevel != 1 && roadLevel != 2) return;
      final terrain = terrainTypeForTileKey(c.tileMapByRegion, tileKey);
      if (rejectionReasonForBuildRailOrder(
            techUnlocked: tech,
            roadLevel: roadLevel,
            terrain: terrain,
          ) !=
          null) {
        return;
      }
      c.result.add(tileKey);
    },
  );
}

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

void prefilterWtPurchaseLand(WorkTilePrefilterSession c) {
  final factionMembership =
      c.factionMembership ?? DiplomacyFactionMembership.from(c.game);
  forEachPrefixedProvinceTile(
    tileKeysByRegion: c.tileKeysByRegion,
    onTile: (provinceId, tileKey) {
      final province = c.game.worldState.tryGetProvince(provinceId);
      if (province == null) return;
      final ownerId = province.ownerId;
      if (ownerId == null) return;
      if (factionMembership.isGreatPower(ownerId)) return;
      if (!factionMembership.isMinorOrTribe(ownerId)) {
        return;
      }
      final resourceId = c.resourceByTile[tileKey];
      if (resourceId == null || resourceId.isEmpty) return;
      final existingBuyer = c.game.worldState.purchaserOfTile(tileKey);
      if (existingBuyer != null) return;
      c.result.add(tileKey);
    },
  );
}

void prefilterWtExplore(WorkTilePrefilterSession c) {
  final scoped = c.exploreProvinceScope;
  if (scoped != null) {
    for (final regionEntry in c.tileKeysByRegion.entries) {
      for (final provinceEntry in regionEntry.value.entries) {
        if (!scoped.contains(provinceEntry.key)) continue;
        c.result.addAll(provinceEntry.value);
      }
    }
    return;
  }
  for (final regionEntry in c.tileKeysByRegion.entries) {
    for (final provinceEntry in regionEntry.value.entries) {
      c.result.addAll(provinceEntry.value);
    }
  }
}

void prefilterWtProspect(WorkTilePrefilterSession c) {
  final prospected = c.game.worldState.prospectedTilesForPlayer(c.playerId);
  forEachPrefixedProvinceTile(
    tileKeysByRegion: c.tileKeysByRegion,
    onTile: (provinceId, tileKey) {
      if (prospected.contains(tileKey)) return;
      if (!isMineralEligibleTile(c.game, c.tileMapByRegion, tileKey)) {
        return;
      }
      c.result.add(tileKey);
    },
  );
}

void prefilterWorkTargetDefault(WorkTilePrefilterSession c) {
  for (final regionEntry in c.tileKeysByRegion.entries) {
    for (final provinceEntry in regionEntry.value.entries) {
      c.result.addAll(provinceEntry.value);
    }
  }
}

final Map<String, WorkTilePrefilterOp> workTargetPrefilters =
    <String, WorkTilePrefilterOp>{
      kWorkTargetBuildImprovement: prefilterWtBuildImprovement,
      kWorkTargetBuildRoad: prefilterWtBuildRoad,
      'build_rail': prefilterWtBuildRail,
      kWorkTargetUpgradeTown: prefilterWtUpgradeTown,
      kWorkTargetBuildFort: prefilterWtTownWork,
      kWorkTargetBuildPort: prefilterWtOwnedProvinceTiles,
      kWorkTargetCounterSpy: prefilterWtOwnedProvinceTiles,
      kWorkTargetPurchaseLand: prefilterWtPurchaseLand,
      kWorkTargetExplore: prefilterWtExplore,
      kWorkTargetProspect: prefilterWtProspect,
    };
