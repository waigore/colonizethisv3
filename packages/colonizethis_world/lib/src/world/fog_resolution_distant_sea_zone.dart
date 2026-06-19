part of 'fog_resolution.dart';

bool _seaZoneHasOwnedCoastalProvinceForPlayer(
  Game game,
  String playerId,
  String regionId,
  String seaZoneLocalId,
  MapTopology regionTopology,
) {
  final adjacentLocal = provinceIdsAdjacentToSeaZone(
    regionTopology,
    seaZoneLocalId,
    regionId: regionId,
  );
  for (final localPid in adjacentLocal) {
    final full = ProvinceId.full(regionId, localPid);
    final p = game.worldState.tryGetProvince(full);
    if (p != null && p.ownerId == playerId) return true;
  }
  return false;
}

Map<String, Set<String>> _fleetAtSeaZoneKeysByPlayerInRegion(
  Game game,
  String regionId,
) {
  final byPlayer = <String, Set<String>>{};
  for (final f in game.worldState.fleets) {
    if (!f.isAtSea || f.seaZoneId == null) continue;
    // Same-region fleets only: canonicalizing [f.seaZoneId] requires [regionId]
    // to match the fleet's region; other-region fleets must be skipped first
    // (GitHub #2023).
    if (f.regionId != regionId) continue;
    final fleetSeaZoneId = canonicalSeaZoneTileBucketKey(
      regionId,
      f.seaZoneId!,
    );
    byPlayer.putIfAbsent(f.ownerId, () => <String>{}).add(fleetSeaZoneId);
  }
  return byPlayer;
}

bool _playerHasFleetAtSeaInZone(
  Map<String, Set<String>> fleetAtSeaZoneKeysByPlayer,
  String playerId,
  String regionId,
  String seaZoneId,
) {
  final playerSeaZones = fleetAtSeaZoneKeysByPlayer[playerId];
  if (playerSeaZones == null || playerSeaZones.isEmpty) return false;
  final expectedSeaZoneId = canonicalSeaZoneTileBucketKey(regionId, seaZoneId);
  return playerSeaZones.contains(expectedSeaZoneId);
}

void _fogSeaZoneWaterTilesExceptUnknown(
  Map<String, String> vis,
  List<String> keys,
) {
  for (final tk in keys) {
    final cur = vis[tk];
    if (cur == null || cur == VisibilityLevel.unknown.name) continue;
    vis[tk] = VisibilityLevel.fogged.name;
  }
}

void _applyDistantSeaFogForGpPlayerInRegion({
  required Game game,
  required String playerId,
  required String regionId,
  required MapTopology regionTopology,
  required Iterable<String> seaZoneIds,
  required Map<String, List<String>> regionTileKeys,
  required Map<String, Set<String>> fleetAtSeaZoneKeysByPlayer,
  required Map<String, String> vis,
}) {
  for (final seaZoneId in seaZoneIds) {
    if (_seaZoneHasOwnedCoastalProvinceForPlayer(
      game,
      playerId,
      regionId,
      seaZoneId,
      regionTopology,
    )) {
      continue;
    }
    if (_playerHasFleetAtSeaInZone(
      fleetAtSeaZoneKeysByPlayer,
      playerId,
      regionId,
      seaZoneId,
    )) {
      continue;
    }
    final seaZoneBucketKey = canonicalSeaZoneTileBucketKey(regionId, seaZoneId);
    final keys = regionTileKeys[seaZoneBucketKey];
    if (keys == null) continue;
    _fogSeaZoneWaterTilesExceptUnknown(vis, keys);
  }
}

/// For each Great Power, every sea zone that is **not** adjacent (P–S) to a
/// province that player **fully owns**, and where that player has **no** fleet
/// **at sea** in that zone: set all **water** tiles in that zone to **fogged**
/// (tiles currently **unknown** are unchanged).
///
/// Runs after Explorer/Spy fog decay and **before** coastal sea zone full
/// visibility. SPEC/program/fog-and-exploration-resolution.md § Distant sea zone fog.
Map<String, Map<String, String>> applyDistantSeaZoneFogRevert(
  Game game,
  Map<String, Map<String, String>> visibility,
  MapTopology topology, {
  Map<String, MapTopology>? topologyByRegion,
}) {
  return _forEachWorldRegionGpVisibility(
    game: game,
    visibility: visibility,
    topology: topology,
    topologyByRegion: topologyByRegion,
    perRegion: (regionId, regionTopology, regionTileKeys, forEachGpPlayer) {
      final seaZoneIds = seaZoneNodeIds(regionTopology);
      final fleetAtSeaZoneKeysByPlayer = _fleetAtSeaZoneKeysByPlayerInRegion(
        game,
        regionId,
      );
      forEachGpPlayer(
        (playerId, vis) => _applyDistantSeaFogForGpPlayerInRegion(
          game: game,
          playerId: playerId,
          regionId: regionId,
          regionTopology: regionTopology,
          seaZoneIds: seaZoneIds,
          regionTileKeys: regionTileKeys,
          fleetAtSeaZoneKeysByPlayer: fleetAtSeaZoneKeysByPlayer,
          vis: vis,
        ),
      );
    },
  );
}
