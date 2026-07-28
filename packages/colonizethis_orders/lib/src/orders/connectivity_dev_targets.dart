import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_world/colonizethis_world.dart';

import 'connectivity_dev_snapshot.dart';
import 'order_work_constants.dart';

/// Stable-partitions [sortedVisible] by connectivity tier without crossing
/// partition boundaries (feedstock front/back precedence preserved).
List<String> stablePartitionByConnectivityTier(
  List<String> sortedVisible,
  int Function(String tileKey) tierFor,
) {
  if (sortedVisible.length < 2) return sortedVisible;
  final buckets = <int, List<String>>{};
  for (final tileKey in sortedVisible) {
    buckets.putIfAbsent(tierFor(tileKey), () => <String>[]).add(tileKey);
  }
  final tiers = buckets.keys.toList()..sort();
  return [for (final tier in tiers) ...buckets[tier]!];
}

List<String> prioritizeBuildRoadCandidatesByConnectivity({
  required ConnectivityDevSnapshot snapshot,
  required List<String> sortedVisible,
}) {
  if (!snapshot.hasUnconnectedDevTargets) return sortedVisible;
  final frontier = <String>[];
  final nonFrontier = <String>[];
  for (final tileKey in sortedVisible) {
    if (snapshot.frontierExtensionTiles.contains(tileKey)) {
      frontier.add(tileKey);
    } else {
      nonFrontier.add(tileKey);
    }
  }
  int distance(String tileKey) =>
      snapshot.extensionDistanceByTile[tileKey] ?? (1 << 30);
  frontier.sort((a, b) {
    final d = distance(a).compareTo(distance(b));
    if (d != 0) return d;
    return a.compareTo(b);
  });
  return <String>[...frontier, ...nonFrontier];
}

List<String> prioritizeBuildRailCandidatesByConnectivity({
  required ConnectivityDevSnapshot snapshot,
  required List<String> sortedVisible,
}) {
  if (!snapshot.hasUnconnectedDevTargets) return sortedVisible;
  return stablePartitionByConnectivityTier(
    sortedVisible,
    (tileKey) {
      if (!snapshot.connected.contains(tileKey)) return 2;
      if (snapshot.bottleneckRailTiles.contains(tileKey)) return 0;
      return 1;
    },
  );
}

List<String> prioritizeBuildImprovementCandidatesByConnectivity({
  required ConnectivityDevSnapshot snapshot,
  required List<String> sortedVisible,
}) {
  if (!snapshot.hasUnconnectedDevTargets) return sortedVisible;
  return stablePartitionByConnectivityTier(
    sortedVisible,
    (tileKey) {
      if (snapshot.connected.contains(tileKey)) return 0;
      if (snapshot.adjacentToConnectedTiles.contains(tileKey)) return 1;
      return 2;
    },
  );
}

List<String> prioritizeBuildPortCandidatesByConnectivity({
  required ConnectivityDevSnapshot snapshot,
  required List<String> sortedVisible,
  required Game game,
  required MapTopology topology,
}) {
  if (!snapshot.hasUnconnectedDevTargets) return sortedVisible;
  return stablePartitionByConnectivityTier(
    sortedVisible,
    (tileKey) => _buildPortConnectivityTier(
      tileKey: tileKey,
      snapshot: snapshot,
      game: game,
      topology: topology,
    ),
  );
}

int _buildPortConnectivityTier({
  required String tileKey,
  required ConnectivityDevSnapshot snapshot,
  required Game game,
  required MapTopology topology,
}) {
  final provinceId = Unit.provinceIdFromTileKey(tileKey);
  if (provinceId == null) return 2;
  if (!snapshot.provincesWithUnconnectedDevTargets.contains(provinceId)) {
    return 2;
  }
  final seaZoneId = _seaZoneIdForProvincePort(
    game: game,
    topology: topology,
    fullProvinceId: provinceId,
  );
  if (seaZoneId == null) return 2;
  final prefixedTopology = topologyUsesPrefixedIds(topology);
  final regionId = ProvinceId.regionIdFrom(provinceId);
  final reachableId = prefixedTopology ? '$regionId|$seaZoneId' : seaZoneId;
  if (!snapshot.seaZonesReachableFromCapital.contains(reachableId) &&
      !snapshot.seaZonesReachableFromCapital.contains(seaZoneId)) {
    return 2;
  }
  return 0;
}

String? _seaZoneIdForProvincePort({
  required Game game,
  required MapTopology topology,
  required String fullProvinceId,
}) {
  final localId = ProvinceId.localIdFrom(fullProvinceId);
  final regionId = ProvinceId.regionIdFrom(fullProvinceId);
  final zones = seaZoneIdsAdjacentToProvince(
    topology,
    topologyUsesPrefixedIds(topology) ? fullProvinceId : localId,
    regionId: regionId,
  );
  if (zones.isEmpty) return null;
  return zones.first;
}

List<String> applyConnectivityDevTargetOrdering({
  required String workTarget,
  required List<String> sortedVisible,
  required ConnectivityDevSnapshot snapshot,
  required Game game,
  required MapTopology topology,
  required Map<String, TileMapResult> tileMapByRegion,
}) {
  switch (workTarget) {
    case kWorkTargetBuildRoad:
      return prioritizeBuildRoadCandidatesByConnectivity(
        snapshot: snapshot,
        sortedVisible: sortedVisible,
      );
    case kWorkTargetBuildRail:
      return prioritizeBuildRailCandidatesByConnectivity(
        snapshot: snapshot,
        sortedVisible: sortedVisible,
      );
    case kWorkTargetBuildImprovement:
      return prioritizeBuildImprovementCandidatesByConnectivity(
        snapshot: snapshot,
        sortedVisible: sortedVisible,
      );
    case kWorkTargetBuildPort:
      return prioritizeBuildPortCandidatesByConnectivity(
        snapshot: snapshot,
        sortedVisible: sortedVisible,
        game: game,
        topology: topology,
      );
    default:
      return sortedVisible;
  }
}
