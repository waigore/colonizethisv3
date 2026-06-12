import 'dart:collection';

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_world/src/logging.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../world_constants.dart';
import 'package:colonizethis_world/src/utils/graph_traversal.dart';
import 'diplomatic_relation_lookup.dart';
import 'connectivity_blockade_target.dart';
import 'port_seaboard_registry_key.dart';
import 'province_traversal.dart';
import 'topology_helpers.dart';

part 'connectivity_metrics.dart';
part 'connectivity_tile_helpers.dart';
part 'connectivity_propagation.dart';

/// Result of connectivity resolution: connected tile set and per-tile path transport cap.
/// SPEC/game/capital-and-connectivity, extraction-and-improvements: effective yield is
/// capped by min transport level along path to town then to capital; [pathTransportCap]
/// is that cap (max over paths of min road level on path).
///
/// [connectedByRoadRule] is the tile set before § Town rule expansion (Road rule + sea
/// port wiring per resolver). Used for extraction town-development caps.
class ConnectivityResult {
  const ConnectivityResult({
    required this.connected,
    this.pathTransportCap = const {},
    this.connectedByRoadRule = const {},
  });

  final Set<String> connected;
  final Map<String, int> pathTransportCap;

  /// Tiles reachable under Road rule + overseas/port phases **before** 4-adjacent town closure.
  final Set<String> connectedByRoadRule;
}

/// Resolves which tiles are connected to each player's capital. SPEC/game/capital-and-connectivity.
///
/// Connectivity: from capital, BFS over land; edges are same-province adjacency;
/// we expand only from capital or tiles with road/port. Overseas: ports connected
/// by shared sea zone; from those ports, BFS within province by road/adjacency.
/// Also computes [ConnectivityResult.pathTransportCap]: for each connected tile,
/// the maximum over paths from capital of (min road/port level on that path).

/// Blockade state: per player, the set of port province ids (full prefixed) that are blockaded.
///
/// A province is blockaded for its owner when an **enemy fleet at sea** (at war) is on Blockade
/// mission targeting it and the fleet's sea zone is **adjacent to that province's port**.
/// SPEC/game/capital-and-connectivity.md § Blockade.
Map<String, Set<String>> computeBlockadedPortProvincesByPlayer(
  Game game,
  MapTopology topology,
) {
  final result = <String, Set<String>>{};
  for (final player in game.players) {
    result[player.id] = {};
  }
  final fleets = game.worldState.fleets;
  for (final fleet in fleets) {
    final ownerId = blockadedProvinceOwnerIdForFleet(
      fleet: fleet,
      worldState: game.worldState,
      topology: topology,
      areFactionsAtWar: (attackerFactionId, defenderFactionId) =>
          factionsAtWar(game, attackerFactionId, defenderFactionId),
    );
    if (ownerId == null) continue;
    final targetProvinceId = fleet.targetProvinceId!;
    result[ownerId] ??= {};
    result[ownerId]!.add(targetProvinceId);
  }
  return result;
}

/// Returns per player id [ConnectivityResult] (connected set + path transport cap).
/// Players without capital or with no tile map get an empty result.
/// When [blockadedPortProvincesByPlayerId] is null, it is computed from [game] (fleets on Blockade mission, at war). SPEC/game/capital-and-connectivity.md § Blockade.
Map<String, ConnectivityResult> resolveConnectivity({
  required Game game,
  required Map<String, TileMapResult> tileMapByRegion,
  required MapTopology topology,
  Map<String, Set<String>>? blockadedPortProvincesByPlayerId,
}) {
  worldLog.d(
    'connectivity resolve start players=${game.players.length} regions=${tileMapByRegion.keys.join(",")}',
  );
  final provinceIdsByType = provinceNodeIds(topology);
  final topologySeaZones = seaZoneNodeIds(topology);
  final blockadedByPlayer =
      blockadedPortProvincesByPlayerId ??
      computeBlockadedPortProvincesByPlayer(game, topology);
  // Pre-compute once for all players; worldState is fixed across the player loop.
  final portInfo = _portToProvinceSeaZone(game.worldState);
  // Single dual-region province scan: bucket ownership and town-tile lookups by
  // playerId so per-player loops below run O(1) lookups instead of repeating
  // O(provinces) scans (Refs #2394).
  final perPlayer = _buildPerPlayerProvinceCaches(game);
  final ownedByPlayer = perPlayer.ownedByPlayer;
  final townByTileKeyByPlayer = perPlayer.townByTileKeyByPlayer;
  final result = <String, ConnectivityResult>{};

  for (final player in game.players) {
    final capital = player.capitalTile;
    if (capital == null || player.capitalProvinceId == null) {
      worldLog.d('connectivity resolve player=${player.id} skipped (no capital)');
      result[player.id] = const ConnectivityResult(connected: {});
      continue;
    }

    final cr = _connectedTilesForPlayer(
      game: game,
      playerId: player.id,
      capital: capital,
      tileMapByRegion: tileMapByRegion,
      topology: topology,
      provinceIdsByType: provinceIdsByType,
      seaZoneNodeIds: topologySeaZones,
      portInfo: portInfo,
      owned: ownedByPlayer[player.id] ?? const <String>{},
      townByTileKey:
          townByTileKeyByPlayer[player.id] ?? const <String, Province>{},
      blockadedPortProvinces: blockadedByPlayer[player.id] ?? const {},
    );
    result[player.id] = cr;
  }

  final summary = result.entries
      .map((e) => '${e.key}:${e.value.connected.length}')
      .join(' ');
  worldLog.d('connectivity resolve end $summary');
  return result;
}

/// Returns per-faction [ConnectivityResult] for **non-Great-Power factions**
/// (Minor Nations and Tribes). Keys are `MinorNation.id` and `Tribe.id`; there
/// is no overlap with Great Power player ids returned by [resolveConnectivity].
///
/// Iterates `Game.minorNations` and `Game.tribes` instead of `Game.players` and
/// shares the same Road and Town rules as Great Power connectivity per
/// [SPEC/game/capital-and-connectivity.md] § Connectivity (Game Rule). Three
/// non-Great-Power-specific differences are normative in
/// [SPEC/game/capital-and-connectivity.md] § Non-Great-Power capital connectivity
/// and [SPEC/game/factions.md] § Minor and Tribe capital connectivity:
///
///   1. **Land-only output.** Minors and Tribes do not own provinces in the
///      other region; the overseas branch in § Connectivity (Game Rule) cannot
///      match because of the per-faction ownership filter.
///   2. **No blockade interaction.** The resolver passes an **empty** blockade
///      set so World-Market participation is independent of fleets on Blockade
///      missions, per [SPEC/game/world-market.md] § Minor and tribe auto-sell.
///   3. **No GP-only town-development bump.** Capital-province
///      `townDevelopmentLevel = 4` is set for Great Powers only.
///
/// Factions with `capitalTile == null` or `capitalProvinceId == null` (e.g.
/// before [SPEC/game/capital-and-connectivity.md] § Minor Nation and Tribe
/// terminal fall removes the entry) are emitted with an empty
/// [ConnectivityResult]. Empty `Game.minorNations` and `Game.tribes` returns
/// an empty map without iterating Great Power state.
///
/// Output is consumed by `computeNonGreatPowerExtraction` (issue #2991 C2 in
/// `economy/non_gp_extraction.dart`) which treats the result as the per-faction
/// connectivity input it does not compute itself.
Map<String, ConnectivityResult> resolveNonGreatPowerConnectivity({
  required Game game,
  required Map<String, TileMapResult> tileMapByRegion,
  required MapTopology topology,
}) {
  if (game.minorNations.isEmpty && game.tribes.isEmpty) {
    return const <String, ConnectivityResult>{};
  }
  worldLog.d(
    'non_gp connectivity resolve start minors=${game.minorNations.length} '
    'tribes=${game.tribes.length} '
    'regions=${tileMapByRegion.keys.join(",")}',
  );
  final provinceIdsByType = provinceNodeIds(topology);
  final topologySeaZones = seaZoneNodeIds(topology);
  final portInfo = _portToProvinceSeaZone(game.worldState);
  // Reuses the same single dual-region province scan used for Great Powers
  // (Refs #2394). The cache buckets ownership by `Province.ownerId`, which for
  // non-Great-Power-owned provinces equals the `MinorNation.id` or `Tribe.id`,
  // so the cache surface is faction-agnostic and no separate bucketing is
  // required.
  final perFaction = _buildPerPlayerProvinceCaches(game);
  final ownedByFaction = perFaction.ownedByPlayer;
  final townByTileKeyByFaction = perFaction.townByTileKeyByPlayer;
  final result = <String, ConnectivityResult>{};

  void runForFaction({
    required String factionId,
    required CapitalTile? capitalTile,
    required String? capitalProvinceId,
  }) {
    if (capitalTile == null || capitalProvinceId == null) {
      worldLog.d('non_gp connectivity resolve faction=$factionId skipped (no capital)');
      result[factionId] = const ConnectivityResult(connected: {});
      return;
    }
    final cr = _connectedTilesForPlayer(
      game: game,
      playerId: factionId,
      capital: capitalTile,
      tileMapByRegion: tileMapByRegion,
      topology: topology,
      provinceIdsByType: provinceIdsByType,
      seaZoneNodeIds: topologySeaZones,
      portInfo: portInfo,
      owned: ownedByFaction[factionId] ?? const <String>{},
      townByTileKey:
          townByTileKeyByFaction[factionId] ?? const <String, Province>{},
      blockadedPortProvinces: const <String>{},
    );
    result[factionId] = cr;
  }

  for (final minor in game.minorNations) {
    runForFaction(
      factionId: minor.id,
      capitalTile: minor.capitalTile,
      capitalProvinceId: minor.capitalProvinceId,
    );
  }
  for (final tribe in game.tribes) {
    runForFaction(
      factionId: tribe.id,
      capitalTile: tribe.capitalTile,
      capitalProvinceId: tribe.capitalProvinceId,
    );
  }

  final summary = result.entries
      .map((e) => '${e.key}:${e.value.connected.length}')
      .join(' ');
  worldLog.d('non_gp connectivity resolve end $summary');
  return result;
}

/// Buckets a single dual-region province pass by playerId so per-player work
/// below avoids repeating that scan. Returned maps key by `Province.ownerId`
/// and include only provinces with a non-null owner. (Refs #2394.)
({
  Map<String, Set<String>> ownedByPlayer,
  Map<String, Map<String, Province>> townByTileKeyByPlayer,
})
_buildPerPlayerProvinceCaches(Game game) {
  final ownedByPlayer = <String, Set<String>>{};
  final townByTileKeyByPlayer = <String, Map<String, Province>>{};
  for (final entry in traverseProvinces(game.worldState)) {
    final ownerId = entry.ownerId;
    if (ownerId == null) continue;
    final province = entry.province;
    ownedByPlayer.putIfAbsent(ownerId, () => <String>{}).add(province.id);
    final tk = province.townTileKey;
    if (tk != null) {
      townByTileKeyByPlayer
          .putIfAbsent(ownerId, () => <String, Province>{})[tk] = province;
    }
  }
  return (
    ownedByPlayer: ownedByPlayer,
    townByTileKeyByPlayer: townByTileKeyByPlayer,
  );
}
