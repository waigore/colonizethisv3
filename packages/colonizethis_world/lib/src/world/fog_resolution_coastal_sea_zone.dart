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
    for (final tileKey in tileKeys) {
      vis[tileKey] = VisibilityLevel.fullyVisible.name;
    }
  }
}

void _applyCoastalFullVisibilityForGpPlayerInRegion({
  required String playerId,
  required String regionId,
  required RegionData regionData,
  required MapTopology regionTopology,
  required Map<String, List<String>> regionTileKeys,
  required Map<String, String> vis,
}) {
  for (final province in regionData.provinces) {
    if (province.ownerId != playerId) continue;
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
  final gpIds = game.players.map((p) => p.id).toSet();
  final tileKeysByRegion = game.worldState.tileKeysByRegionAndProvince;
  final result = _mutableGpVisibilityCopy(visibilityAfterFogDecay);

  forEachWorldRegion(game.worldState, (regionId, regionData) {
    final regionTileKeys = tileKeysByRegion[regionId];
    if (regionTileKeys == null) return;
    final regionTopology = topologyForRegion(
      topology,
      regionId,
      topologyByRegion: topologyByRegion,
    );
    _forEachGpPlayerVisibility(
      game: game,
      gpIds: gpIds,
      result: result,
      action: (playerId, vis) => _applyCoastalFullVisibilityForGpPlayerInRegion(
        playerId: playerId,
        regionId: regionId,
        regionData: regionData,
        regionTopology: regionTopology,
        regionTileKeys: regionTileKeys,
        vis: vis,
      ),
    );
  });

  return result;
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
