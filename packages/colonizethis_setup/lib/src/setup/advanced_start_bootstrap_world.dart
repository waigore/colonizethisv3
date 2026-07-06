// Advanced-start NW exploration (step 8). SPEC/game/advanced-starts.md.

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_world/colonizethis_world.dart';

import 'advanced_start_nw_topology.dart';
import 'game_setup_topology.dart';
import 'setup_logging.dart';

/// Result of NW knowledge bootstrap for one advanced-start pass.
class AdvancedStartWorldKnowledgeResult {
  const AdvancedStartWorldKnowledgeResult({
    required this.game,
    required this.encounteredTribeIds,
  });

  final Game game;
  final Set<String> encounteredTribeIds;
}

String? _ownerIdForLocalProvince(Game game, String localProvinceId) {
  final fullId = ProvinceId.full(kRegionNewWorld, localProvinceId);
  for (final province in game.worldState.newWorld.provinces) {
    final id = ProvinceId.isPrefixed(province.id)
        ? province.id
        : ProvinceId.full(province.regionId, province.id);
    if (id == fullId) return province.ownerId;
  }
  return null;
}

void _setNwSeaZoneTilesFogged({
  required Map<String, String> playerVisibility,
  required Map<String, List<String>> nwTileKeysByProvince,
  required Iterable<String> seaZoneLocalIds,
}) {
  for (final seaLocalId in seaZoneLocalIds) {
    final bucketKey = canonicalSeaZoneTileBucketKey(kRegionNewWorld, seaLocalId);
    final tileKeys = nwTileKeysByProvince[bucketKey] ?? const [];
    for (final tileKey in tileKeys) {
      final current = playerVisibility[tileKey];
      if (current == null || current == VisibilityLevel.unknown.name) {
        playerVisibility[tileKey] = VisibilityLevel.fogged.name;
      }
    }
  }
}

/// Reveals contiguous NW provinces per GP for visibility and diplomacy.
AdvancedStartWorldKnowledgeResult applyAdvancedStartWorldKnowledge({
  required Game game,
  required AdvancedStartType startType,
  required MapTopology topologyOldWorld,
  required MapTopology topologyNewWorld,
  required List<WarpLink> warpLinks,
}) {
  final revealFraction = advancedStartNwRevealFraction(startType);
  final totalNwProvinces = game.worldState.newWorld.provinces.length;
  final targetProvinceCount = (totalNwProvinces * revealFraction).ceil();

  final nwProvinceNeighbours = provinceNeighboursFromTopology(topologyNewWorld);

  final visibilityByPlayer = {
    for (final entry in game.worldState.playerVisibilityByTile.entries)
      entry.key: Map<String, String>.from(entry.value),
  };
  final tileKeysByProvince =
      game.worldState.tileKeysByRegionAndProvince[kRegionNewWorld] ??
      const <String, List<String>>{};

  final encounteredTribes = <String>{};

  for (final player in game.players) {
    final capitalProvinceId = player.capitalProvinceId;
    if (capitalProvinceId == null) continue;
    final capitalLocalId = ProvinceId.localIdFrom(capitalProvinceId);

    final seeds = advancedStartNwEntryProvinceLocalIds(
      capitalLocalProvinceId: capitalLocalId,
      topologyOldWorld: topologyOldWorld,
      topologyNewWorld: topologyNewWorld,
      warpLinks: warpLinks,
    );
    if (seeds.isEmpty) {
      setupLog.w(
        'logic: advanced start NW reveal skipped for ${player.id} — '
        'no warp entry from capital sea',
      );
      continue;
    }

    final revealedLocalIds = advancedStartFloodFillProvinces(
      provinceNeighbours: nwProvinceNeighbours,
      seedLocalIds: seeds,
      targetCount: targetProvinceCount,
    );
    if (revealedLocalIds.length < targetProvinceCount) {
      setupLog.w(
        'logic: advanced start NW flood-fill reached ${revealedLocalIds.length}/'
        '$targetProvinceCount provinces for ${player.id}',
      );
    }

    final entrySeaZones = advancedStartNwSeaZonesFromCapital(
      capitalLocalProvinceId: capitalLocalId,
      topologyOldWorld: topologyOldWorld,
      warpLinks: warpLinks,
    );
    final foggedSeaZones = advancedStartFoggedNwSeaZoneLocalIds(
      topologyNewWorld: topologyNewWorld,
      entrySeaZoneLocalIds: entrySeaZones,
      revealedProvinceLocalIds: revealedLocalIds.toSet(),
    );

    final playerVisibility =
        visibilityByPlayer.putIfAbsent(player.id, () => <String, String>{});

    for (final localId in revealedLocalIds) {
      final ownerId = _ownerIdForLocalProvince(game, localId);
      if (ownerId != null && game.tribes.any((t) => t.id == ownerId)) {
        encounteredTribes.add(ownerId);
      }
      final provinceKey = ProvinceId.full(kRegionNewWorld, localId);
      final tileKeys = tileKeysByProvince[provinceKey] ?? const [];
      for (final tileKey in tileKeys) {
        playerVisibility[tileKey] = VisibilityLevel.fullyVisible.name;
      }
    }

    _setNwSeaZoneTilesFogged(
      playerVisibility: playerVisibility,
      nwTileKeysByProvince: tileKeysByProvince,
      seaZoneLocalIds: foggedSeaZones,
    );
  }

  final updated = game.copyWith(
    worldState: game.worldState.copyWith(
      playerVisibilityByTile: visibilityByPlayer,
    ),
  );

  return AdvancedStartWorldKnowledgeResult(
    game: updated,
    encounteredTribeIds: encounteredTribes,
  );
}

MapTopology _combinedTopologyFromRegions(
  Map<String, MapTopology> topologyByRegion,
) {
  final allNodes = <TopologyNode>[];
  final allEdges = <TopologyEdge>[];
  for (final topology in topologyByRegion.values) {
    allNodes.addAll(topology.nodes);
    allEdges.addAll(topology.edges);
  }
  return MapTopology(nodes: allNodes, edges: allEdges);
}

/// Promotes GP-owned coastal NW sea zones to fullyVisible after colonization.
/// SPEC/game/advanced-starts.md § NW sea-zone visibility.
Game applyAdvancedStartCoastalSeaVisibility({
  required Game game,
  required Map<String, MapTopology> topologyByRegion,
}) {
  final combined = _combinedTopologyFromRegions(topologyByRegion);
  final visibilityAfterCoastal = applyCoastalSeaZoneFullVisibility(
    game,
    game.worldState.playerVisibilityByTile,
    combined,
    topologyByRegion: topologyByRegion,
  );
  return game.copyWith(
    worldState: game.worldState.copyWith(
      playerVisibilityByTile: visibilityAfterCoastal,
    ),
  );
}
