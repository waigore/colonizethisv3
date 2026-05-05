import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'debug_command_helpers.dart';

DebugCommandResult applyDebugRevealProvince({
  required Game? currentGame,
  required RevealDebugProvinceEvent event,
  required MapTopology combinedTopology,
  Map<String, MapTopology>? topologyByRegion,
}) {
  if (currentGame == null) {
    return (
      game: null,
      message: 'Debug reveal_province ignored: no active game.',
    );
  }
  if (currentGame.worldState.turnState.phase != TurnPhase.orders) {
    return (
      game: null,
      message:
          'Debug reveal_province rejected: command is allowed only during human Orders phase.',
    );
  }
  final human = findPlayerById(currentGame, event.humanPlayerId);
  if (human == null) {
    return (
      game: null,
      message:
          'Debug reveal_province ignored: unknown player ${event.humanPlayerId}.',
    );
  }
  final resolved = _resolveTargetProvince(currentGame.worldState, event.target);
  if (resolved.errorMessage != null) {
    return (game: null, message: resolved.errorMessage!);
  }
  final province = resolved.province;
  if (province == null) {
    return (
      game: null,
      message:
          'Debug reveal_province rejected: target "${event.target}" not found.',
    );
  }

  final visibilityBefore = currentGame.worldState.playerVisibilityByTile;
  final currentPlayerVisibility = Map<String, String>.from(
    visibilityBefore[event.humanPlayerId] ?? const <String, String>{},
  );
  final provinceTileKeys = landTileKeysForProvinceBucket(
    currentGame.worldState,
    province.regionId,
    province.id,
  );
  var changedTileCount = 0;
  for (final tileKey in provinceTileKeys) {
    if (currentPlayerVisibility[tileKey] != VisibilityLevel.fullyVisible.name) {
      changedTileCount++;
    }
    currentPlayerVisibility[tileKey] = VisibilityLevel.fullyVisible.name;
  }

  final seaTileKeys = _adjacentSeaZoneTileKeys(
    worldState: currentGame.worldState,
    province: province,
    combinedTopology: combinedTopology,
    topologyByRegion: topologyByRegion,
  );
  for (final tileKey in seaTileKeys) {
    if (currentPlayerVisibility[tileKey] != VisibilityLevel.fullyVisible.name) {
      changedTileCount++;
    }
    currentPlayerVisibility[tileKey] = VisibilityLevel.fullyVisible.name;
  }
  if (changedTileCount == 0) {
    return (
      game: currentGame,
      message:
          'Revealed province ${province.id}: no-op (already fully visible for ${event.humanPlayerId}).',
    );
  }

  final nextGame = currentGame.copyWith(
    worldState: currentGame.worldState.copyWith(
      playerVisibilityByTile: {
        ...visibilityBefore,
        event.humanPlayerId: currentPlayerVisibility,
      },
    ),
  );
  return (
    game: nextGame,
    message:
        'Revealed province ${province.id}: +$changedTileCount tiles fully visible for ${event.humanPlayerId}.',
  );
}

({Province? province, String? errorMessage}) _resolveTargetProvince(
  WorldState worldState,
  String target,
) {
  final trimmed = target.trim();
  if (ProvinceId.isPrefixed(trimmed)) {
    final province = worldState.tryGetProvince(trimmed);
    return (province: province, errorMessage: null);
  }
  final normalized = trimmed.toLowerCase();
  final matches = worldState
      .allProvinces()
      .where((province) {
        final displayName = province.displayName ?? '';
        return displayName.trim().toLowerCase() == normalized;
      })
      .toList(growable: false);
  if (matches.isEmpty) {
    return (province: null, errorMessage: null);
  }
  if (matches.length > 1) {
    final ids = matches.map((p) => p.id).toList()..sort();
    return (
      province: null,
      errorMessage:
          'Debug reveal_province rejected: province "$target" is ambiguous. Candidate ids: ${ids.join(', ')}. Retry with /reveal_province <regionId|localId>.',
    );
  }
  return (province: matches.single, errorMessage: null);
}

Set<String> _adjacentSeaZoneTileKeys({
  required WorldState worldState,
  required Province province,
  required MapTopology combinedTopology,
  Map<String, MapTopology>? topologyByRegion,
}) {
  final tileKeysByRegion =
      worldState.tileKeysByRegionAndProvince[province.regionId];
  if (tileKeysByRegion == null) {
    return const {};
  }
  final regionTopology =
      topologyByRegion?[province.regionId] ??
      _topologyForRegion(combinedTopology, province.regionId);
  final adjacentSeaZoneIds = seaZoneIdsAdjacentToProvince(
    regionTopology,
    ProvinceId.localIdFrom(province.id),
    regionId: province.regionId,
  );
  final tileKeys = <String>{};
  for (final seaZoneId in adjacentSeaZoneIds) {
    final bucketKey = ProvinceId.full(province.regionId, seaZoneId);
    final keys = tileKeysByRegion[bucketKey];
    if (keys == null) {
      continue;
    }
    tileKeys.addAll(keys);
  }
  return tileKeys;
}

MapTopology _topologyForRegion(MapTopology topology, String regionId) {
  final regionNodeIds = topology.nodes
      .where((n) => n.regionId == regionId)
      .map((n) => n.id)
      .toSet();
  if (regionNodeIds.isEmpty) {
    return const MapTopology(nodes: [], edges: []);
  }
  final regionNodes = topology.nodes
      .where((n) => n.regionId == regionId)
      .toList(growable: false);
  final regionEdges = topology.edges
      .where(
        (e) => regionNodeIds.contains(e.id1) && regionNodeIds.contains(e.id2),
      )
      .toList(growable: false);
  return MapTopology(nodes: regionNodes, edges: regionEdges);
}
