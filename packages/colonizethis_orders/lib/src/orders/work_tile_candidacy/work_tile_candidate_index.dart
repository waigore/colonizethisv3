import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_diplomacy/colonizethis_diplomacy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_world/colonizethis_world.dart';

import '../build_rail_work_rules.dart';
import '../diplomatic_access_helpers.dart';
import '../order_work_constants.dart';
import '../orders_application_helpers.dart';

// Shared work-tile candidacy index (Refs #3877 AC4).
// Spec: SPEC/program/order-suggestions.md § Pre-filtering by work target type.

/// Shared tile/province snapshot for work-target pre-filtering and tile-keys
/// probing. Both suggestion prefilter and UI tile-key highlight paths consume
/// this index instead of duplicating ownership/resource scans.
class WorkTileCandidateIndex {
  WorkTileCandidateIndex({
    required this.game,
    required this.playerId,
    required this.tileKeysByRegion,
    required this.resourceByTile,
    required this.purchasedTiles,
    required this.ownedProvinceIds,
    this.tileMapByRegion,
    this.factionMembership,
  });

  final Game game;
  final String playerId;
  final Map<String, Map<String, List<String>>> tileKeysByRegion;
  final Map<String, String> resourceByTile;
  final Map<String, String> purchasedTiles;
  final Set<String> ownedProvinceIds;
  final Map<String, TileMapResult>? tileMapByRegion;
  final DiplomacyFactionMembership? factionMembership;

  /// Returns raw candidate tile keys for [workTarget] before visibility or
  /// order-engine validation.
  Set<String> candidateTilesForWorkTarget(
    String workTarget, {
    Set<String>? exploreProvinceScope,
  }) {
    final result = <String>{};
    final session = _WorkTilePrefilterSession(
      index: this,
      exploreProvinceScope: exploreProvinceScope,
      result: result,
    );
    final op = _workTargetPrefilters[workTarget];
    if (op != null) {
      op(session);
    } else {
      _prefilterWorkTargetDefault(session);
    }
    return result;
  }
}

class _WorkTilePrefilterSession {
  _WorkTilePrefilterSession({
    required this.index,
    required this.exploreProvinceScope,
    required this.result,
  });

  final WorkTileCandidateIndex index;
  final Set<String>? exploreProvinceScope;
  final Set<String> result;

  Game get game => index.game;
  String get playerId => index.playerId;
  Map<String, Map<String, List<String>>> get tileKeysByRegion =>
      index.tileKeysByRegion;
  Map<String, String> get resourceByTile => index.resourceByTile;
  Map<String, String> get purchasedTiles => index.purchasedTiles;
  Set<String> get ownedProvinceIds => index.ownedProvinceIds;
  Map<String, TileMapResult>? get tileMapByRegion => index.tileMapByRegion;
  DiplomacyFactionMembership? get factionMembership => index.factionMembership;
}

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

typedef _WorkTilePrefilterOp = void Function(_WorkTilePrefilterSession c);

void _prefilterWtBuildImprovement(_WorkTilePrefilterSession c) {
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

void _prefilterWtBuildRoad(_WorkTilePrefilterSession c) {
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

void _prefilterWtBuildRail(_WorkTilePrefilterSession c) {
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

void _prefilterWtTownWork(_WorkTilePrefilterSession c) {
  _addCandidateTilesForTownWork(
    game: c.game,
    ownedProvinceIds: c.ownedProvinceIds,
    result: c.result,
  );
}

void _prefilterWtUpgradeTown(_WorkTilePrefilterSession c) {
  _addCandidateTilesForTownWork(
    game: c.game,
    ownedProvinceIds: c.ownedProvinceIds,
    result: c.result,
  );
  _addMinorTribeTownTilesForEmbassyUpgrade(c);
}

void _addMinorTribeTownTilesForEmbassyUpgrade(_WorkTilePrefilterSession c) {
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

void _prefilterWtOwnedProvinceTiles(_WorkTilePrefilterSession c) {
  _addAllTilesInOwnedPrefixedProvinces(
    tileKeysByRegion: c.tileKeysByRegion,
    ownedProvinceIds: c.ownedProvinceIds,
    result: c.result,
  );
}

void _prefilterWtPurchaseLand(_WorkTilePrefilterSession c) {
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
      final existingBuyer = c.game.worldState.purchaserOfTile(tileKey);
      if (existingBuyer != null) return;
      c.result.add(tileKey);
    },
  );
}

void _prefilterWtExplore(_WorkTilePrefilterSession c) {
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

void _prefilterWtProspect(_WorkTilePrefilterSession c) {
  final prospected = c.game.worldState.prospectedTilesForPlayer(c.playerId);
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

void _prefilterWorkTargetDefault(_WorkTilePrefilterSession c) {
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
      kWorkTargetUpgradeTown: _prefilterWtUpgradeTown,
      kWorkTargetBuildFort: _prefilterWtTownWork,
      kWorkTargetBuildPort: _prefilterWtOwnedProvinceTiles,
      kWorkTargetCounterSpy: _prefilterWtOwnedProvinceTiles,
      kWorkTargetPurchaseLand: _prefilterWtPurchaseLand,
      kWorkTargetExplore: _prefilterWtExplore,
      kWorkTargetProspect: _prefilterWtProspect,
    };
