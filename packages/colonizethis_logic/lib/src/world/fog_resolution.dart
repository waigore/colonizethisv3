import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../constants.dart';
import 'naval.dart';
import 'player_view.dart';
import 'province_lookup.dart';
import 'unit_lookup.dart';

/// Spy 5-turn fog decay: decrement timers; when they expire, set other-faction
/// provinces back to fogged for that player. Timers MUST NOT affect a player's
/// own provinces; own provinces remain fully visible. SPEC/program/fog-and-exploration-resolution.md.
(Map<String, Map<String, String>>, Map<String, Map<String, int>>)
applySpyRevealTimerDecay(Game game) {
  final world = game.worldState;
  final tileKeysByRegion = world.tileKeysByRegionAndProvince;
  var visibilityByTile = Map<String, Map<String, String>>.from(
    world.playerVisibilityByTile.map(
      (k, v) => MapEntry(k, Map<String, String>.from(v)),
    ),
  );

  // Province ownership lookup so we can ensure timers only affect other-faction provinces.
  final ownerByProvinceId = <String, String?>{
    for (final p in allProvinces(world)) p.id: p.ownerId,
  };

  final nextSpyTimers = <String, Map<String, int>>{};
  for (final entry in world.spyRevealTurnsByPlayer.entries) {
    final playerId = entry.key;
    final byProvince = entry.value;
    final newByProvince = <String, int>{};
    final vis = Map<String, String>.from(visibilityByTile[playerId] ?? {});
    for (final provEntry in byProvince.entries) {
      final provinceId = provEntry.key;
      final turns = provEntry.value;

      // Never apply Spy timers to a player's own provinces; clear any such timers without changing visibility.
      final ownerId = ownerByProvinceId[provinceId];
      if (ownerId == playerId) {
        continue;
      }

      final nextTurns = turns - 1;
      if (nextTurns <= 0) {
        final regionId = ProvinceId.regionIdFrom(provinceId);
        final tileKeys = tileKeysByRegion[regionId]?[provinceId] ?? [];
        for (final tk in tileKeys) {
          vis[tk] = VisibilityLevel.fogged.name;
        }
      } else {
        newByProvince[provinceId] = nextTurns;
      }
    }
    if (newByProvince.isNotEmpty) nextSpyTimers[playerId] = newByProvince;
    visibilityByTile[playerId] = vis;
  }
  return (visibilityByTile, nextSpyTimers);
}

/// For each player, set tiles in other-faction provinces to fogged when no Explorer/Spy in that province.
/// SPEC/program/fog-and-exploration-resolution.md.
Map<String, Map<String, String>> applyFogDecay(Game game) {
  const explorerTypes = {'explorer', 'spy'};
  final ownerByProvince = <String, String?>{
    for (final p in allProvinces(game.worldState)) p.id: p.ownerId,
  };

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

    for (final tileKey in visibility.keys.toList()) {
      final parts = tileKey.split('|');
      if (parts.length != 4) continue;
      final fullProvinceId = ProvinceId.full(parts[0], parts[1]);
      final ownerId = ownerByProvince[fullProvinceId];
      if (ownerId == null || ownerId == playerId) continue;
      if (!hasExplorerIn.contains(fullProvinceId) &&
          !hasSpyTimerIn.contains(fullProvinceId)) {
        visibility[tileKey] = VisibilityLevel.fogged.name;
      }
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

  for (final regionId in [kRegionOldWorld, kRegionNewWorld]) {
    final regionData = regionId == kRegionOldWorld
        ? game.worldState.oldWorld
        : game.worldState.newWorld;
    final regionTopology = _topologyForRegion(
      topology,
      topologyByRegion,
      regionId,
    );
    final regionTileKeys = tileKeysByRegion[regionId];
    if (regionTileKeys == null) continue;

    for (final player in game.players) {
      if (!gpIds.contains(player.id)) continue;
      final playerId = player.id;
      final vis = result[playerId];
      if (vis == null) continue;

      for (final province in regionData.provinces) {
        if (province.ownerId != playerId) continue;
        final fullProvinceId = province.id;
        final adjacentSeaZones = seaZoneIdsAdjacentToProvince(
          regionTopology,
          fullProvinceId,
          regionId: regionId,
        );
        for (final seaZoneLocalId in adjacentSeaZones) {
          final tileKeys = regionTileKeys[seaZoneLocalId];
          if (tileKeys == null) continue;
          for (final tileKey in tileKeys) {
            vis[tileKey] = VisibilityLevel.fullyVisible.name;
          }
        }
      }
    }
  }

  return result;
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

bool _playerHasFleetAtSeaInZone(
  Game game,
  String playerId,
  String regionId,
  String seaZoneLocalId,
) {
  for (final f in game.worldState.fleets) {
    if (f.ownerId != playerId) continue;
    if (!f.isAtSea || f.seaZoneId != seaZoneLocalId) continue;
    if (f.regionId != regionId) continue;
    return true;
  }
  return false;
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

  for (final regionId in [kRegionOldWorld, kRegionNewWorld]) {
    final regionTopology = _topologyForRegion(
      topology,
      topologyByRegion,
      regionId,
    );
    final seaZoneIds = regionTopology.nodes
        .where((n) => n.type == TopologyNodeType.seaZone)
        .map((n) => n.id);
    final regionTileKeys = tileKeysByRegion[regionId];
    if (regionTileKeys == null) continue;

    for (final player in game.players) {
      if (!gpIds.contains(player.id)) continue;
      final playerId = player.id;
      final vis = result[playerId];
      if (vis == null) continue;

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
        if (_playerHasFleetAtSeaInZone(game, playerId, regionId, seaZoneId)) {
          continue;
        }
        final keys = regionTileKeys[seaZoneId];
        if (keys == null) continue;
        for (final tk in keys) {
          final cur = vis[tk];
          if (cur == null || cur == VisibilityLevel.unknown.name) continue;
          vis[tk] = VisibilityLevel.fogged.name;
        }
      }
    }
  }

  return result;
}
