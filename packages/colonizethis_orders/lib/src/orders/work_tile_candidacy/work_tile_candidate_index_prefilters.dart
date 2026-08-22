import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_world/colonizethis_world.dart';

import '../build_rail_work_rules.dart';
import '../order_work_constants.dart';
import '../orders_application_helpers.dart';
import 'work_tile_candidate_index_prefilter_town.dart';
import 'work_tile_candidate_index_prefilter_walkers.dart';
import 'work_tile_candidate_index_types.dart';

export 'work_tile_candidate_index_prefilter_town.dart';
export 'work_tile_candidate_index_prefilter_walkers.dart';

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
      ...workTargetTownPrefilters,
      kWorkTargetPurchaseLand: prefilterWtPurchaseLand,
      kWorkTargetExplore: prefilterWtExplore,
      kWorkTargetProspect: prefilterWtProspect,
    };
