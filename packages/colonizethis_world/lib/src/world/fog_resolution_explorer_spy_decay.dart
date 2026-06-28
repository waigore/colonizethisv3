part of 'fog_resolution.dart';

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
  final ownerByProvinceId = ownerByProvinceIdMap(world);

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
        allowLocalIdFallback: true,
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
  final ownerByProvince = ownerByProvinceIdMap(game.worldState);

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
      final fullProvinceId = fullProvinceIdFromTileKey(tileKey);
      if (fullProvinceId == null) continue;
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
