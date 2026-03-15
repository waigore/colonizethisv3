import 'package:colonizethis_models/colonizethis_models.dart';

import '../constants.dart';
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

