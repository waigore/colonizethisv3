import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../constants.dart';
import 'game_world_mutations.dart';
import 'naval.dart';
import 'naval_resolution.dart'
    show
        canonicalSeaZoneTileBucketKey,
        coastalLandTileKeysFromNavalPresenceAtSea,
        landTileKeysForProvinceBucket;
import 'fog_spy_reveal_decay.dart';
import 'player_view.dart';
import 'province_lookup.dart' hide landTileKeysForProvinceBucket;
import 'province_traversal.dart';
import 'tile_key_coordinates.dart';
import 'unit_lookup.dart';

/// Spy 5-turn fog decay: decrement timers; when they expire, set other-faction
/// provinces back to fogged for that player. Timers MUST NOT affect a player's
/// own provinces; own provinces remain fully visible. SPEC/program/fog-and-exploration-resolution.md.
(Map<String, Map<String, String>>, Map<String, Map<String, int>>)
applySpyRevealTimerDecay(Game game) {
  final world = game.worldState;
  var visibilityByTile = Map<String, Map<String, String>>.from(
    world.playerVisibilityByTile.map(
      (k, v) => MapEntry(k, Map<String, String>.from(v)),
    ),
  );

  // Province ownership lookup so we can ensure timers only affect other-faction provinces.
  final ownerByProvinceId = <String, String?>{
    for (final e in traverseProvinces(world)) e.provinceId: e.ownerId,
  };

  final nextSpyTimers = <String, Map<String, int>>{};
  for (final entry in world.spyRevealTurnsByPlayer.entries) {
    final playerId = entry.key;
    final byProvince = entry.value;
    final vis = Map<String, String>.from(visibilityByTile[playerId] ?? {});
    final newByProvince = nextSpyRevealTimersByProvinceAfterDecayStep(
      playerId: playerId,
      byProvince: byProvince,
      ownerByProvinceId: ownerByProvinceId,
      playerVisibility: vis,
      landTileKeysForProvince: (provinceId) => landTileKeysForProvinceBucket(
        world,
        ProvinceId.regionIdFrom(provinceId),
        provinceId,
      ),
    );
    if (newByProvince.isNotEmpty) nextSpyTimers[playerId] = newByProvince;
    visibilityByTile[playerId] = vis;
  }
  return (visibilityByTile, nextSpyTimers);
}

/// For each player, set tiles in other-faction provinces to fogged when no Explorer/Spy in that province.
/// SPEC/program/fog-and-exploration-resolution.md.
Map<String, Map<String, String>> applyFogDecay(
  Game game, {
  MapTopology? navalCoastalIntelTopology,
}) {
  const explorerTypes = {'explorer', 'spy'};
  final ownerByProvince = <String, String?>{
    for (final e in traverseProvinces(game.worldState))
      e.provinceId: e.ownerId,
  };

  final navalCoastalIntelByPlayer = <String, Set<String>>{};
  if (navalCoastalIntelTopology != null) {
    for (final player in game.players) {
      navalCoastalIntelByPlayer[player.id] =
          coastalLandTileKeysFromNavalPresenceAtSea(
            game,
            navalCoastalIntelTopology,
            player.id,
          );
    }
  }

  final provincesWithExplorerByPlayer = <String, Set<String>>{};
  for (final u in allUnitsFromWorld(game.worldState)) {
    if (explorerTypes.contains(u.type.toLowerCase())) {
      provincesWithExplorerByPlayer
          .putIfAbsent(u.ownerId, () => <String>{})
          .add(u.locationProvinceId);
    }
  }
  final provincesWithSpyTimerByPlayer = <String, Set<String>>{};
  for (final entry in game.worldState.spyRevealTurnsByPlayer.entries) {
    final playerId = entry.key;
    final provinces = entry.value.keys;
    if (provinces.isEmpty) continue;
    provincesWithSpyTimerByPlayer[playerId] = provinces.toSet();
  }

  final result = <String, Map<String, String>>{};
  for (final entry in game.worldState.playerVisibilityByTile.entries) {
    final playerId = entry.key;
    final visibility = Map<String, String>.from(entry.value);
    final hasExplorerIn = provincesWithExplorerByPlayer[playerId] ?? const {};
    final hasSpyTimerIn = provincesWithSpyTimerByPlayer[playerId] ?? const {};
    final navalCoastalIntel = navalCoastalIntelByPlayer[playerId] ?? const {};

    for (final tileKey in visibility.keys.toList()) {
      final parsedTile = parseTileKeyCoordinates(tileKey);
      if (parsedTile == null) continue;
      final fullProvinceId = ProvinceId.full(
        parsedTile.regionId,
        parsedTile.provinceLocalId,
      );
      final ownerId = ownerByProvince[fullProvinceId];
      if (ownerId == null || ownerId == playerId) continue;
      if (hasExplorerIn.contains(fullProvinceId)) continue;
      if (hasSpyTimerIn.contains(fullProvinceId)) continue;
      if (navalCoastalIntel.contains(tileKey)) continue;
      final cur = visibility[tileKey];
      if (cur != VisibilityLevel.fullyVisible.name) continue;
      visibility[tileKey] = VisibilityLevel.fogged.name;
    }
    result[playerId] = visibility;
  }
  return result;
}

/// Clears Spy reveal timers for [playerId] in [provinceId]. Used when a province
/// changes hands or becomes owned by [playerId] so that own provinces never
/// decay via Spy timers. SPEC/program/fog-and-exploration-resolution.md.
Map<String, Map<String, int>> clearSpyRevealTimersForProvince(
  Map<String, Map<String, int>> existing,
  String playerId,
  String provinceId,
) {
  final timers = <String, Map<String, int>>{};
  existing.forEach((pid, byProv) {
    final inner = Map<String, int>.from(byProv);
    if (pid == playerId) {
      inner.remove(provinceId);
    }
    if (inner.isNotEmpty) {
      timers[pid] = inner;
    }
  });
  return timers;
}

/// Clears Spy reveal timers for both [oldOwnerId] and [newOwnerId] on
/// [provinceId] when ownership transfers from old to new.
/// SPEC/program/fog-and-exploration-resolution.md (province transfer).
Map<String, Map<String, int>> clearSpyRevealTimersForProvinceOwnershipTransfer(
  Map<String, Map<String, int>> existing,
  String provinceId,
  String oldOwnerId,
  String newOwnerId,
) {
  final timers = <String, Map<String, int>>{};
  existing.forEach((pid, byProv) {
    if (pid != oldOwnerId && pid != newOwnerId) {
      if (byProv.isNotEmpty) {
        timers[pid] = Map<String, int>.from(byProv);
      }
      return;
    }
    final inner = Map<String, int>.from(byProv)..remove(provinceId);
    if (inner.isNotEmpty) {
      timers[pid] = inner;
    }
  });
  return timers;
}

/// Immediate visibility adjustment when province [provinceId] (prefixed id or
/// legacy short id from [resolveProvinceRowForOwnershipTransfer]) transfers from
/// [oldOwnerId] to [newOwnerId]: new owner gets land tiles in the province set
/// to fully visible; former owner's stored visibility for those tiles is
/// downgraded from fully visible to fogged where applicable (unknown unchanged).
/// Returns updated [game] and counts for structured transfer reporting.
/// SPEC/program/fog-and-exploration-resolution.md.
({Game game, ProvinceOwnershipVisibilitySummary visibilitySummary})
applyProvinceOwnershipChangeVisibility(
  Game game,
  String provinceId,
  String oldOwnerId,
  String newOwnerId,
) {
  final row = resolveProvinceRowForOwnershipTransfer(
    game.worldState,
    provinceId,
  );
  if (row == null) {
    return (
      game: game,
      visibilitySummary: const ProvinceOwnershipVisibilitySummary(
        tilesSetFullyVisibleForNewOwner: 0,
        tilesDowngradedForFormerOwner: 0,
      ),
    );
  }
  final canonicalId = row.canonicalProvinceId;
  final regionId = row.province.regionId;
  final tileKeys = landTileKeysForProvinceBucket(
    game.worldState,
    regionId,
    canonicalId,
  );
  if (tileKeys.isEmpty) {
    return (
      game: game,
      visibilitySummary: const ProvinceOwnershipVisibilitySummary(
        tilesSetFullyVisibleForNewOwner: 0,
        tilesDowngradedForFormerOwner: 0,
      ),
    );
  }

  final visMaps = game.worldState.playerVisibilityByTile.map(
    (k, v) => MapEntry(k, Map<String, String>.from(v)),
  );

  var setForNew = 0;
  final newVis = Map<String, String>.from(visMaps[newOwnerId] ?? {});
  for (final tk in tileKeys) {
    newVis[tk] = VisibilityLevel.fullyVisible.name;
    setForNew++;
  }
  visMaps[newOwnerId] = newVis;

  var downgradedForOld = 0;
  final oldVis = Map<String, String>.from(visMaps[oldOwnerId] ?? {});
  for (final tk in tileKeys) {
    final cur = oldVis[tk];
    if (cur == VisibilityLevel.fullyVisible.name) {
      oldVis[tk] = VisibilityLevel.fogged.name;
      downgradedForOld++;
    }
  }
  visMaps[oldOwnerId] = oldVis;

  final nextGame = game.updateWorldState(
    (ws) => ws.copyWith(playerVisibilityByTile: visMaps),
  );

  return (
    game: nextGame,
    visibilitySummary: ProvinceOwnershipVisibilitySummary(
      tilesSetFullyVisibleForNewOwner: setForNew,
      tilesDowngradedForFormerOwner: downgradedForOld,
    ),
  );
}

/// Per-province visibility counts after [applyProvinceOwnershipChangeVisibility].
class ProvinceOwnershipVisibilitySummary {
  const ProvinceOwnershipVisibilitySummary({
    required this.tilesSetFullyVisibleForNewOwner,
    required this.tilesDowngradedForFormerOwner,
  });

  final int tilesSetFullyVisibleForNewOwner;
  final int tilesDowngradedForFormerOwner;
}

/// Returns topology for [regionId]: [topologyByRegion][regionId] if set, otherwise
/// subgraph of [topology] with nodes and edges in that region.
MapTopology _topologyForRegion(
  MapTopology topology,
  Map<String, MapTopology>? topologyByRegion,
  String regionId,
) {
  final regionTopology = topologyByRegion?[regionId];
  if (regionTopology != null) return regionTopology;
  final regionNodeIds = topology.nodes
      .where((n) => n.regionId == regionId)
      .map((n) => n.id)
      .toSet();
  if (regionNodeIds.isEmpty) {
    return const MapTopology(nodes: [], edges: []);
  }
  final regionNodes = topology.nodes
      .where((n) => n.regionId == regionId)
      .toList();
  final regionEdges = topology.edges
      .where(
        (e) => regionNodeIds.contains(e.id1) && regionNodeIds.contains(e.id2),
      )
      .toList();
  return MapTopology(nodes: regionNodes, edges: regionEdges);
}

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
  final result = <String, Map<String, String>>{};
  for (final entry in visibilityAfterFogDecay.entries) {
    result[entry.key] = Map<String, String>.from(entry.value);
  }

  forEachWorldRegion(game.worldState, (regionId, regionData) {
    final regionTopology = _topologyForRegion(
      topology,
      topologyByRegion,
      regionId,
    );
    final regionTileKeys = tileKeysByRegion[regionId];
    if (regionTileKeys == null) return;

    for (final player in game.players) {
      if (!gpIds.contains(player.id)) continue;
      final playerId = player.id;
      final vis = result[playerId];
      if (vis == null) continue;

      _applyCoastalFullVisibilityForGpPlayerInRegion(
        playerId: playerId,
        regionId: regionId,
        regionData: regionData,
        regionTopology: regionTopology,
        regionTileKeys: regionTileKeys,
        vis: vis,
      );
    }
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
    final regionTopology = _topologyForRegion(
      topology,
      topologyByRegion,
      regionId,
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
  final gpIds = game.players.map((p) => p.id).toSet();
  final tileKeysByRegion = game.worldState.tileKeysByRegionAndProvince;
  final result = <String, Map<String, String>>{};
  for (final entry in visibility.entries) {
    result[entry.key] = Map<String, String>.from(entry.value);
  }

  forEachWorldRegion(game.worldState, (regionId, _) {
    final regionTopology = _topologyForRegion(
      topology,
      topologyByRegion,
      regionId,
    );
    final seaZoneIds = regionTopology.nodes
        .where((n) => n.type == TopologyNodeType.seaZone)
        .map((n) => n.id);
    final regionTileKeys = tileKeysByRegion[regionId];
    if (regionTileKeys == null) return;
    final fleetAtSeaZoneKeysByPlayer = _fleetAtSeaZoneKeysByPlayerInRegion(
      game,
      regionId,
    );

    for (final player in game.players) {
      if (!gpIds.contains(player.id)) continue;
      final playerId = player.id;
      final vis = result[playerId];
      if (vis == null) continue;

      _applyDistantSeaFogForGpPlayerInRegion(
        game: game,
        playerId: playerId,
        regionId: regionId,
        regionTopology: regionTopology,
        seaZoneIds: seaZoneIds,
        regionTileKeys: regionTileKeys,
        fleetAtSeaZoneKeysByPlayer: fleetAtSeaZoneKeysByPlayer,
        vis: vis,
      );
    }
  });

  return result;
}
