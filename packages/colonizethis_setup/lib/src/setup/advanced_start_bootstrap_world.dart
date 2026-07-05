// Advanced-start NW exploration and prospecting (steps 8–9). SPEC/game/advanced-starts.md.

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_world/colonizethis_world.dart';

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

Map<String, Set<String>> _adjacency(MapTopology topology) {
  final adj = <String, Set<String>>{
    for (final n in topology.nodes) n.id: <String>{},
  };
  for (final edge in topology.edges) {
    adj[edge.id1]!.add(edge.id2);
    adj[edge.id2]!.add(edge.id1);
  }
  return adj;
}

Map<String, TopologyNodeType> _nodeTypes(MapTopology topology) {
  return {for (final n in topology.nodes) n.id: n.type};
}

Set<String> _provincesAdjacentToSeaZone(
  Map<String, Set<String>> adjacency,
  Map<String, TopologyNodeType> nodeTypes,
  String localSeaZoneId,
) {
  final adjacent = adjacency[localSeaZoneId];
  if (adjacent == null) return const {};
  return {
    for (final id in adjacent)
      if (nodeTypes[id] == TopologyNodeType.province) id,
  };
}

List<String> _nwSeaZonesFromCapital({
  required String capitalLocalProvinceId,
  required MapTopology topologyOldWorld,
  required List<WarpLink> warpLinks,
}) {
  final owAdj = _adjacency(topologyOldWorld);
  final distances = <String, int>{capitalLocalProvinceId: 0};
  final queue = [capitalLocalProvinceId];
  var head = 0;
  while (head < queue.length) {
    final current = queue[head++];
    final nextDist = distances[current]! + 1;
    for (final next in owAdj[current] ?? const {}) {
      if (distances.containsKey(next)) continue;
      distances[next] = nextDist;
      queue.add(next);
    }
  }

  int? minDist;
  final candidateOwSeas = <String>{};
  for (final link in warpLinks) {
    if (link.regionId != kRegionOldWorld ||
        link.otherRegionId != kRegionNewWorld) {
      continue;
    }
    final dist = distances[link.seaZoneId];
    if (dist == null) continue;
    if (minDist == null || dist < minDist) {
      minDist = dist;
      candidateOwSeas
        ..clear()
        ..add(link.seaZoneId);
    } else if (dist == minDist) {
      candidateOwSeas.add(link.seaZoneId);
    }
  }

  final nwSeaLocalIds = <String>{};
  for (final link in warpLinks) {
    if (link.regionId != kRegionOldWorld ||
        link.otherRegionId != kRegionNewWorld) {
      continue;
    }
    if (candidateOwSeas.contains(link.seaZoneId)) {
      nwSeaLocalIds.add(link.otherSeaZoneId);
    }
  }
  return nwSeaLocalIds.toList()..sort();
}

List<String> _floodFillProvinces({
  required Map<String, Set<String>> provinceNeighbours,
  required List<String> seedLocalIds,
  required int targetCount,
}) {
  if (targetCount <= 0 || seedLocalIds.isEmpty) return const [];

  final visited = <String>{...seedLocalIds};
  final queue = List<String>.from(seedLocalIds)..sort();
  final collected = <String>[];

  var head = 0;
  while (head < queue.length && collected.length < targetCount) {
    final current = queue[head++];
    collected.add(current);
    final nextIds = provinceNeighbours[current]?.toList() ?? const [];
    nextIds.sort();
    for (final next in nextIds) {
      if (visited.add(next)) {
        queue.add(next);
      }
    }
  }

  if (collected.length < targetCount) {
    setupLog.w(
      'logic: advanced start NW flood-fill reached ${collected.length}/'
      '$targetCount provinces from seeds=$seedLocalIds',
    );
  }
  return collected;
}

Set<String> _prospectTilesForPlayer({
  required Set<String> revealedTileKeys,
  required Map<String, String> resourceByTileKey,
  required double prospectFraction,
}) {
  final prospectable = revealedTileKeys
      .where((key) {
        final resourceId = resourceByTileKey[key];
        return resourceId != null &&
            kProspectRequiredResourceIds.contains(resourceId);
      })
      .toList()
    ..sort();
  if (prospectable.isEmpty) return const {};
  final target = (prospectable.length * prospectFraction).ceil();
  return prospectable.take(target).toSet();
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

/// Reveals contiguous NW provinces per GP and prospects a tier fraction of
/// prospect-required tiles in those provinces.
AdvancedStartWorldKnowledgeResult applyAdvancedStartWorldKnowledge({
  required Game game,
  required AdvancedStartType startType,
  required MapTopology topologyOldWorld,
  required MapTopology topologyNewWorld,
  required List<WarpLink> warpLinks,
}) {
  final revealFraction = advancedStartNwRevealFraction(startType);
  final prospectFraction = advancedStartProspectFraction(startType);
  final totalNwProvinces = game.worldState.newWorld.provinces.length;
  final targetProvinceCount = (totalNwProvinces * revealFraction).ceil();

  final nwProvinceNeighbours = provinceNeighboursFromTopology(topologyNewWorld);
  final nwAdj = _adjacency(topologyNewWorld);
  final nwTypes = _nodeTypes(topologyNewWorld);

  final visibilityByPlayer = {
    for (final entry in game.worldState.playerVisibilityByTile.entries)
      entry.key: Map<String, String>.from(entry.value),
  };
  final prospectedByPlayer = {
    for (final entry in game.worldState.playerProspectedTiles.entries)
      entry.key: Set<String>.from(entry.value),
  };
  final tileKeysByProvince =
      game.worldState.tileKeysByRegionAndProvince[kRegionNewWorld] ??
      const <String, List<String>>{};

  final encounteredTribes = <String>{};

  for (final player in game.players) {
    final capitalProvinceId = player.capitalProvinceId;
    if (capitalProvinceId == null) continue;
    final capitalLocalId = ProvinceId.localIdFrom(capitalProvinceId);

    final nwSeaZones = _nwSeaZonesFromCapital(
      capitalLocalProvinceId: capitalLocalId,
      topologyOldWorld: topologyOldWorld,
      warpLinks: warpLinks,
    );
    if (nwSeaZones.isEmpty) {
      setupLog.w(
        'logic: advanced start NW reveal skipped for ${player.id} — '
        'no warp entry from capital sea',
      );
      continue;
    }

    final entryProvinces = <String>{};
    for (final seaId in nwSeaZones) {
      entryProvinces.addAll(
        _provincesAdjacentToSeaZone(nwAdj, nwTypes, seaId),
      );
    }
    final seeds = entryProvinces.toList()..sort();
    if (seeds.isEmpty) continue;

    final revealedLocalIds = _floodFillProvinces(
      provinceNeighbours: nwProvinceNeighbours,
      seedLocalIds: seeds,
      targetCount: targetProvinceCount,
    );

    final playerVisibility =
        visibilityByPlayer.putIfAbsent(player.id, () => <String, String>{});
    final playerProspected =
        prospectedByPlayer.putIfAbsent(player.id, () => <String>{});

    final revealedTileKeys = <String>{};
    for (final localId in revealedLocalIds) {
      final ownerId = _ownerIdForLocalProvince(game, localId);
      if (ownerId != null && game.tribes.any((t) => t.id == ownerId)) {
        encounteredTribes.add(ownerId);
      }
      final provinceKey = ProvinceId.full(kRegionNewWorld, localId);
      final tileKeys = tileKeysByProvince[provinceKey] ?? const [];
      for (final tileKey in tileKeys) {
        playerVisibility[tileKey] = VisibilityLevel.fullyVisible.name;
        revealedTileKeys.add(tileKey);
      }
    }

    playerProspected.addAll(
      _prospectTilesForPlayer(
        revealedTileKeys: revealedTileKeys,
        resourceByTileKey: game.worldState.resourceByTileKey,
        prospectFraction: prospectFraction,
      ),
    );
  }

  final updated = game.copyWith(
    worldState: game.worldState.copyWith(
      playerVisibilityByTile: visibilityByPlayer,
      playerProspectedTiles: prospectedByPlayer,
    ),
  );

  return AdvancedStartWorldKnowledgeResult(
    game: updated,
    encounteredTribeIds: encounteredTribes,
  );
}
