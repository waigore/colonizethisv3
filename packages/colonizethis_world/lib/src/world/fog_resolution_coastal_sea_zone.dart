part of 'fog_resolution.dart';

void _fullyVisibleAllTilesInSeaZoneBuckets(
  Map<String, String> vis,
  Map<String, List<String>> regionTileKeys,
  String regionId,
  Iterable<String> adjacentSeaZoneIds,
) {
  for (final seaZoneId in adjacentSeaZoneIds) {
    final seaZoneBucketKey = canonicalSeaZoneTileBucketKey(regionId, seaZoneId);
    final tileKeys = regionTileKeys[seaZoneBucketKey];
    if (tileKeys == null) continue;
    setTilesFullyVisible(vis, tileKeys);
  }
}

// Phase 6b slice 16 (SPEC/program/worldstate-projection.md; Refs #3393): this
// helper runs per GP player x per region each end-of-turn fog pass, so the prior
// `regionData.provinces.where((p) => p.ownerId == playerId)` rescan walked the
// whole region province list once per (player, region). [ProvinceOwnerCache
// .provincesOwnedByInRegion] preserves the region's `RegionData.provinces`
// order, so the iterated province ids are identical to the prior scan
// (behaviour-preserving).
void _applyCoastalFullVisibilityForGpPlayerInRegion({
  required String playerId,
  required String regionId,
  required ProvinceOwnerCache ownerCache,
  required MapTopology regionTopology,
  required Map<String, List<String>> regionTileKeys,
  required Map<String, String> vis,
}) {
  for (final province in ownerCache.provincesOwnedByInRegion(
    playerId,
    regionId,
  )) {
    final adjacentSeaZones = seaZoneIdsAdjacentToProvince(
      regionTopology,
      province.id,
      regionId: regionId,
    );
    _fullyVisibleAllTilesInSeaZoneBuckets(
      vis,
      regionTileKeys,
      regionId,
      adjacentSeaZones,
    );
  }
}

/// For each Great Power, sets all tiles in sea zones adjacent to provinces they
/// fully own to fullyVisible. Runs after fog decay in End-of-turn.
/// SPEC/program/fog-and-exploration-resolution.md § Coastal sea zone full visibility.
Map<String, Map<String, String>> applyCoastalSeaZoneFullVisibility(
  Game game,
  Map<String, Map<String, String>> visibilityAfterFogDecay,
  MapTopology topology, {
  Map<String, MapTopology>? topologyByRegion,
}) {
  final ownerCache = ProvinceOwnerCache.of(game.worldState);

  return _forEachWorldRegionGpVisibility(
    game: game,
    visibility: visibilityAfterFogDecay,
    topology: topology,
    topologyByRegion: topologyByRegion,
    perRegion: (regionId, regionTopology, regionTileKeys, forEachGpPlayer) {
      forEachGpPlayer(
        (playerId, vis) => _applyCoastalFullVisibilityForGpPlayerInRegion(
          playerId: playerId,
          regionId: regionId,
          ownerCache: ownerCache,
          regionTopology: regionTopology,
          regionTileKeys: regionTileKeys,
          vis: vis,
        ),
      );
    },
  );
}

/// Sets adjacent sea-zone water tiles to fullyVisible for [playerId] for each
/// targeted coastal province id in [targetProvinceIds].
Map<String, String> applyCoastalSeaZoneFullVisibilityForProvinceTargets({
  required Game game,
  required String playerId,
  required Iterable<String> targetProvinceIds,
  required Map<String, String> visibility,
  required MapTopology topology,
  Map<String, MapTopology>? topologyByRegion,
}) {
  final updated = Map<String, String>.from(visibility);
  final tileKeysByRegion = game.worldState.tileKeysByRegionAndProvince;
  final uniqueProvinceIds = targetProvinceIds.toSet();
  for (final provinceId in uniqueProvinceIds) {
    if (!ProvinceId.isPrefixed(provinceId)) {
      continue;
    }
    final regionId = ProvinceId.regionIdFrom(provinceId);
    final regionTileKeys = tileKeysByRegion[regionId];
    if (regionTileKeys == null) continue;
    final regionTopology = topologyForRegion(
      topology,
      regionId,
      topologyByRegion: topologyByRegion,
    );
    final adjacentSeaZones = seaZoneIdsAdjacentToProvince(
      regionTopology,
      provinceId,
      regionId: regionId,
    );
    _fullyVisibleAllTilesInSeaZoneBuckets(
      updated,
      regionTileKeys,
      regionId,
      adjacentSeaZones,
    );
  }
  return updated;
}
