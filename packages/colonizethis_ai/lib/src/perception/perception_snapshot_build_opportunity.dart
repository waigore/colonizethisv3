import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/ai_api.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'perception_topology.dart';
import 'summary_models.dart';

OpportunitySummary buildOpportunitySummary(
  PlayerView view,
  MapTopology? topology,
) {
  var unclaimed = 0;
  var richUnexploited = 0;
  for (final p in view.provincesById.values) {
    if (p.ownerId == null || p.ownerId!.isEmpty) {
      unclaimed++;
      richUnexploited++;
    } else if (p.ownerId != view.playerId &&
        p.townDevelopmentLevel > kTownDevelopmentLevelMin) {
      richUnexploited++;
    }
  }
  final weakNeighbors = topology == null
      ? <String>[]
      : _weakNeighborOwnerIds(view, topology);
  return OpportunitySummary(
    weakNeighbors: weakNeighbors,
    richUnexploitedProvinces: richUnexploited,
    unclaimedProvinces: unclaimed,
  );
}

List<String> _weakNeighborOwnerIds(PlayerView view, MapTopology topology) {
  final ownedIds = <String>{};
  for (final p in view.provincesById.entries) {
    if (p.value.ownerId == view.playerId) ownedIds.add(p.key);
  }
  final neighborIds = neighborProvinceIdsFromTopology(topology, ownedIds, view);
  final weakNeighbors = <String>[];
  for (final fid in neighborIds) {
    final prov = view.provincesById[fid];
    if (prov == null) continue;
    final ownerId = prov.ownerId;
    if (ownerId == null || ownerId.isEmpty || ownerId == view.playerId) {
      continue;
    }
    if (!weakNeighbors.contains(ownerId)) weakNeighbors.add(ownerId);
  }
  return weakNeighbors;
}
