import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'connectivity_metrics.dart';
import 'connectivity_propagation.dart';
import 'connectivity_result.dart';
import 'connectivity_tile_helpers.dart';
import 'province_traversal.dart';
import 'topology_helpers.dart';

/// Shared faction-input / province-cache setup for GP and non-GP connectivity
/// resolvers (Refs #3968). Public APIs and blockade policy stay on the
/// resolver entrypoints; this core only holds topology/port/ownership inputs
/// and the per-faction [connectedTilesForPlayer] call.
class ConnectivityFactionInput {
  ConnectivityFactionInput._({
    required this.provinceIdsByType,
    required this.topologySeaZones,
    required this.portInfo,
    required this.ownedByFaction,
    required this.townByTileKeyByFaction,
  });

  /// Builds topology, port, and ownership caches once for a connectivity pass.
  factory ConnectivityFactionInput.fromGame({
    required Game game,
    required MapTopology topology,
  }) {
    final perFaction = buildFactionProvinceCaches(game);
    return ConnectivityFactionInput._(
      provinceIdsByType: provinceNodeIds(topology),
      topologySeaZones: seaZoneNodeIds(topology),
      portInfo: portToProvinceSeaZone(game.worldState),
      ownedByFaction: perFaction.ownedByFaction,
      townByTileKeyByFaction: perFaction.townByTileKeyByFaction,
    );
  }

  final Set<String> provinceIdsByType;
  final Set<String> topologySeaZones;
  final Map<String, (String, String)> portInfo;
  final Map<String, Set<String>> ownedByFaction;
  final Map<String, Map<String, Province>> townByTileKeyByFaction;

  /// Resolves connected tiles for one faction id using this shared input.
  ///
  /// [blockadedPortProvinces] is an explicit policy parameter: GP resolvers
  /// pass computed blockades; non-GP resolvers pass an empty set.
  ConnectivityResult resolveFaction({
    required Game game,
    required String factionId,
    required CapitalTile capital,
    required Map<String, TileMapResult> tileMapByRegion,
    required MapTopology topology,
    required Set<String> blockadedPortProvinces,
    ConnectivityHotPathMetrics? metrics,
  }) {
    return connectedTilesForPlayer(
      game: game,
      playerId: factionId,
      capital: capital,
      tileMapByRegion: tileMapByRegion,
      topology: topology,
      provinceIdsByType: provinceIdsByType,
      seaZoneNodeIds: topologySeaZones,
      portInfo: portInfo,
      owned: ownedByFaction[factionId] ?? const <String>{},
      townByTileKey:
          townByTileKeyByFaction[factionId] ?? const <String, Province>{},
      blockadedPortProvinces: blockadedPortProvinces,
      metrics: metrics,
    );
  }
}

/// Buckets a single dual-region province pass by owner id so per-faction work
/// avoids repeating that scan. Returned maps key by `Province.ownerId` and
/// include only provinces with a non-null owner. (Refs #2394 / #3968.)
({
  Map<String, Set<String>> ownedByFaction,
  Map<String, Map<String, Province>> townByTileKeyByFaction,
})
buildFactionProvinceCaches(Game game) {
  final ownedByFaction = <String, Set<String>>{};
  final townByTileKeyByFaction = <String, Map<String, Province>>{};
  for (final entry in traverseProvinces(game.worldState)) {
    final ownerId = entry.ownerId;
    if (ownerId == null) continue;
    final province = entry.province;
    ownedByFaction.putIfAbsent(ownerId, () => <String>{}).add(province.id);
    final tk = province.townTileKey;
    if (tk != null) {
      townByTileKeyByFaction.putIfAbsent(
        ownerId,
        () => <String, Province>{},
      )[tk] = province;
    }
  }
  return (
    ownedByFaction: ownedByFaction,
    townByTileKeyByFaction: townByTileKeyByFaction,
  );
}
