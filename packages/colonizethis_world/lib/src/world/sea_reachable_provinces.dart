import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'package:colonizethis_world/src/utils/graph_traversal.dart';

import 'player_view.dart';
import 'topology_helpers.dart';

/// Non-owned provinces reachable from GP-owned anchors through owned provinces
/// and sea zones (including warp S–S links). Foreign provinces are collected but
/// not expanded through. SPEC/ai/ai-architecture.md § Colonial expansion.
///
/// Expressed in terms of [reachableNonOwnedProvinceDistancesViaSeas]: the
/// distance map's keys are exactly the reachable non-owned province ids
/// (Refs #3403 Phase 2).
Set<String> reachableNonOwnedProvinceIdsViaSeas(
  MapTopology topology,
  Set<String> anchorProvinceIds,
  PlayerView view, {
  String? regionIdFilter,
}) => reachableNonOwnedProvinceDistancesViaSeas(
  topology,
  anchorProvinceIds,
  view,
  regionIdFilter: regionIdFilter,
).keys.toSet();

/// Non-owned provinces reachable from GP-owned anchors through owned provinces
/// and sea zones (including warp S-S links), keyed by their BFS topology
/// distance from the **nearest** owned anchor. Foreign provinces are
/// collected but not expanded through (same termination contract as
/// [reachableNonOwnedProvinceIdsViaSeas]).
///
/// The distance is measured as **edges traversed in the topology graph**:
/// owned-to-sea-zone counts as 1, sea-to-foreign-province as 1 more, etc.
/// A foreign province sharing a direct province-province border with an
/// owned anchor therefore has distance 1, and a New World province
/// reached via the canonical owned-anchor -> OW sea zone -> NW sea zone
/// -> NW colony route has distance 3.
///
/// When the same foreign province is reachable via multiple paths the
/// **shortest** distance wins (BFS first-discovery semantics with each
/// edge weighted 1). The result is deterministic for fixed inputs
/// (Refs #2509 Must-have #7) -- BFS visits topology neighbors in the
/// insertion order of [MapTopology.edges], which is stable across runs
/// for a given map.
///
/// Refs #2509 § COLONIAL phase planner § planColonialAcquisition --
/// "For each unowned-visible newWorld| province (sorted by adjacency
/// distance to owned territory)". This helper supplies the
/// adjacency-distance key the acquisition planner uses to break ties
/// between candidate NW provinces.
Map<String, int> reachableNonOwnedProvinceDistancesViaSeas(
  MapTopology topology,
  Set<String> anchorProvinceIds,
  PlayerView view, {
  String? regionIdFilter,
}) {
  final owned = <String>{
    for (final id in anchorProvinceIds)
      if (view.provincesById[id]?.ownerId == view.playerId) id,
  };

  bool isOwnProvince(String id) =>
      view.provincesById[id]?.ownerId == view.playerId;

  bool isForeignProvince(String id) {
    final ownerId = view.provincesById[id]?.ownerId;
    if (ownerId == null || ownerId.isEmpty) return false;
    if (ownerId == view.playerId) return false;
    return regionIdFilter == null ||
        ProvinceId.regionIdFrom(id) == regionIdFilter;
  }

  final invadable = <String, int>{};
  bfsTopologyGraph(
    sourceIds: owned,
    nodeType: topologyNodeTypeById(topology),
    adjacency: topologyAdjacency(topology),
    isExpandableProvince: isOwnProvince,
    isForeignProvince: isForeignProvince,
    onForeignProvinceDiscovered: (id, distance) => invadable[id] = distance,
  );
  return invadable;
}
