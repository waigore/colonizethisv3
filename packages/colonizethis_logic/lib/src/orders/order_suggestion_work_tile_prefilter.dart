import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../constants.dart';
import '../diplomacy/diplomacy_resolver.dart';
import '../world/province_lookup.dart';
import 'build_rail_work_rules.dart';
import 'orders_application_helpers.dart';

/// Pre-filters tiles based on work-target-specific criteria per SPEC/program/order-suggestions.md.
/// Returns a set of candidate tile keys that pass work-target requirements.
Set<String> _preFilterWorkTargetTiles({
  required Game game,
  required String workTarget,
  required String playerId,
  required Map<String, Map<String, List<String>>> tileKeysByRegion,
  required Map<String, String> resourceByTile,
  required Map<String, String> purchasedTiles,
  required Set<String> ownedProvinceIds,
  Set<String>? exploreProvinceScope,
  Map<String, TileMapResult>? tileMapByRegion,
  DiplomacyFactionMembership? factionMembership,
}) {
  final result = <String>{};
  final ctx = _WorkTilePrefilterCtx(
    game: game,
    playerId: playerId,
    tileKeysByRegion: tileKeysByRegion,
    resourceByTile: resourceByTile,
    purchasedTiles: purchasedTiles,
    ownedProvinceIds: ownedProvinceIds,
    exploreProvinceScope: exploreProvinceScope,
    tileMapByRegion: tileMapByRegion,
    factionMembership: factionMembership,
    result: result,
  );
  final op = _workTargetPrefilters[workTarget];
  if (op != null) {
    op(ctx);
  } else {
    _prefilterWorkTargetDefault(ctx);
  }
  return result;
}

Set<String> rawCandidateTilesForWorkTarget({
  required Game game,
  required String playerId,
  required String workTarget,
  Set<String>? exploreProvinceScope,
  Map<String, TileMapResult>? tileMapByRegion,

  /// When non-null, must match the ids produced by scanning [allProvinces] for
  /// provinces owned by [playerId] (same as the default path). Callers that
  /// invoke this repeatedly in one suggestion pass should supply a shared set
  /// to avoid O(targets × provinces) rescans (Refs #2394).
  Set<String>? playerOwnedProvinceIds,

  /// When non-null, [kWorkTargetPurchaseLand] prefilter reuses this snapshot
  /// instead of calling [DiplomacyFactionMembership.from] again (Refs #2394 —
  /// same pass often already built membership for incremental validation).
  DiplomacyFactionMembership? factionMembership,
}) {
  final world = game.worldState;
  final ownedProvinceIds =
      playerOwnedProvinceIds ??
      <String>{
        for (final p in allProvinces(world))
          if (p.ownerId == playerId) p.id,
      };
  return _preFilterWorkTargetTiles(
    game: game,
    workTarget: workTarget,
    playerId: playerId,
    tileKeysByRegion: world.tileKeysByRegionAndProvince,
    resourceByTile: world.resourceByTileKey,
    purchasedTiles: world.purchasedTilesByTileKey,
    ownedProvinceIds: ownedProvinceIds,
    exploreProvinceScope: exploreProvinceScope,
    tileMapByRegion: tileMapByRegion,
    factionMembership: factionMembership,
  );
}

/// Iterates every tile in land provinces (prefixed province ids), skipping sea zones.
/// Used by work-target pre-filtering; per-tile logic lives in [onTile].
void _forEachPrefixedProvinceTile({
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

/// All land tiles in owned provinces with prefixed ids (build_port, counter_spy pre-filter).
void _addAllTilesInOwnedPrefixedProvinces({
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

/// Adds candidate tiles for upgrade_town/build_fort: town tiles in owned provinces.
///
/// Iterates [ownedProvinceIds] with O(1) [WorldState.tryGetProvince] lookups
/// instead of scanning every province in both regions (Refs #2394).
void _addCandidateTilesForTownWork({
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

/// Adds candidate tiles for steal_tech: other GP capital provinces.
void _addCandidateTilesForStealTech({
  required Game game,
  required String playerId,
  required Set<String> result,
}) {
  for (final other in game.players) {
    if (other.id == playerId) continue;
    final capitalProvinceId = other.capitalProvinceId;
    if (capitalProvinceId == null) continue;

    // Find a tile in the capital province
    final regionId = ProvinceId.regionIdFrom(capitalProvinceId);
    final byProvince = game.worldState.tileKeysByRegionAndProvince[regionId];
    final tiles = byProvince?[capitalProvinceId];
    if (tiles != null && tiles.isNotEmpty) {
      result.add(tiles.first);
    }
  }
}

/// Context for [_workTargetPrefilters] map dispatch (work-target tile pre-filter).
class _WorkTilePrefilterCtx {
  _WorkTilePrefilterCtx({
    required this.game,
    required this.playerId,
    required this.tileKeysByRegion,
    required this.resourceByTile,
    required this.purchasedTiles,
    required this.ownedProvinceIds,
    required this.exploreProvinceScope,
    required this.tileMapByRegion,
    this.factionMembership,
    required this.result,
  });

  final Game game;
  final String playerId;
  final Map<String, Map<String, List<String>>> tileKeysByRegion;
  final Map<String, String> resourceByTile;
  final Map<String, String> purchasedTiles;
  final Set<String> ownedProvinceIds;
  final Set<String>? exploreProvinceScope;
  final Map<String, TileMapResult>? tileMapByRegion;
  final DiplomacyFactionMembership? factionMembership;
  final Set<String> result;
}

typedef _WorkTilePrefilterOp = void Function(_WorkTilePrefilterCtx c);

void _prefilterWtBuildImprovement(_WorkTilePrefilterCtx c) {
  _forEachPrefixedProvinceTile(
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

void _prefilterWtBuildRoad(_WorkTilePrefilterCtx c) {
  _forEachPrefixedProvinceTile(
    tileKeysByRegion: c.tileKeysByRegion,
    onTile: (provinceId, tileKey) {
      final isOwnedProvince = c.ownedProvinceIds.contains(provinceId);
      final isPurchased = c.purchasedTiles[tileKey] == c.playerId;
      if (!isOwnedProvince && !isPurchased) return;
      c.result.add(tileKey);
    },
  );
}

void _prefilterWtBuildRail(_WorkTilePrefilterCtx c) {
  final player = c.game.playerById(c.playerId);
  if (player == null) return;
  final tech = player.techUnlocked;
  final tileState = c.game.worldState.tileState;
  _forEachPrefixedProvinceTile(
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

void _prefilterWtTownWork(_WorkTilePrefilterCtx c) {
  _addCandidateTilesForTownWork(
    game: c.game,
    ownedProvinceIds: c.ownedProvinceIds,
    result: c.result,
  );
}

void _prefilterWtOwnedProvinceTiles(_WorkTilePrefilterCtx c) {
  _addAllTilesInOwnedPrefixedProvinces(
    tileKeysByRegion: c.tileKeysByRegion,
    ownedProvinceIds: c.ownedProvinceIds,
    result: c.result,
  );
}

void _prefilterWtStealTech(_WorkTilePrefilterCtx c) {
  _addCandidateTilesForStealTech(
    game: c.game,
    playerId: c.playerId,
    result: c.result,
  );
}

void _prefilterWtPurchaseLand(_WorkTilePrefilterCtx c) {
  final factionMembership =
      c.factionMembership ?? DiplomacyFactionMembership.from(c.game);
  _forEachPrefixedProvinceTile(
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
      final existingBuyer = c.game.worldState.purchasedTilesByTileKey[tileKey];
      if (existingBuyer != null) return;
      c.result.add(tileKey);
    },
  );
}

void _prefilterWtExplore(_WorkTilePrefilterCtx c) {
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

void _prefilterWtProspect(_WorkTilePrefilterCtx c) {
  final prospected =
      c.game.worldState.playerProspectedTiles[c.playerId] ?? const <String>{};
  _forEachPrefixedProvinceTile(
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

void _prefilterWorkTargetDefault(_WorkTilePrefilterCtx c) {
  for (final regionEntry in c.tileKeysByRegion.entries) {
    for (final provinceEntry in regionEntry.value.entries) {
      c.result.addAll(provinceEntry.value);
    }
  }
}

final Map<String, _WorkTilePrefilterOp> _workTargetPrefilters =
    <String, _WorkTilePrefilterOp>{
      kWorkTargetBuildImprovement: _prefilterWtBuildImprovement,
      kWorkTargetBuildRoad: _prefilterWtBuildRoad,
      'build_rail': _prefilterWtBuildRail,
      kWorkTargetUpgradeTown: _prefilterWtTownWork,
      kWorkTargetBuildFort: _prefilterWtTownWork,
      kWorkTargetBuildPort: _prefilterWtOwnedProvinceTiles,
      kWorkTargetCounterSpy: _prefilterWtOwnedProvinceTiles,
      kWorkTargetStealTech: _prefilterWtStealTech,
      kWorkTargetPurchaseLand: _prefilterWtPurchaseLand,
      kWorkTargetExplore: _prefilterWtExplore,
      kWorkTargetProspect: _prefilterWtProspect,
    };
