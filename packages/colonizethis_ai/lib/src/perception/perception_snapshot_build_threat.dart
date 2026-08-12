import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/ai_api.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'perception_topology.dart';
import 'summary_models.dart';

ThreatSummary buildThreatSummary(PlayerView view, MapTopology? topology) {
  final atWarWith = <String>[];
  for (final e in view.diplomacyByOtherId.entries) {
    final rel = e.value;
    if (rel.state == RelationState.atWar) {
      atWarWith.add(e.key);
    }
  }
  if (topology == null) {
    return ThreatSummary(atWarWith: atWarWith);
  }
  final ownedIds = <String>{};
  for (final p in view.provincesById.entries) {
    if (p.value.ownerId == view.playerId) ownedIds.add(p.key);
  }
  var neighborProvincesHostile = 0;
  final neighborProvinceIds = neighborProvinceIdsFromTopology(
    topology,
    ownedIds,
    view,
  );
  for (final neighborFullId in neighborProvinceIds) {
    final prov = view.provincesById[neighborFullId];
    if (prov == null) continue;
    final ownerId = prov.ownerId;
    if (ownerId == null || ownerId.isEmpty || ownerId == view.playerId)
      continue;
    final rel = view.diplomacyByOtherId[ownerId];
    if (rel != null && rel.state == RelationState.atWar) {
      neighborProvincesHostile++;
    }
  }
  var capitalThreatened = false;
  final capitalId = view.player.capitalProvinceId;
  if (capitalId != null &&
      capitalId.isNotEmpty &&
      ownedIds.contains(capitalId)) {
    final capitalNeighbors = neighborProvinceIdsFromTopology(topology, {
      capitalId,
    }, view);
    for (final neighborFullId in capitalNeighbors) {
      final prov = view.provincesById[neighborFullId];
      if (prov == null) continue;
      final ownerId = prov.ownerId;
      if (ownerId == null || ownerId.isEmpty || ownerId == view.playerId) {
        continue;
      }
      final rel = view.diplomacyByOtherId[ownerId];
      if (rel != null && rel.state == RelationState.atWar) {
        capitalThreatened = true;
        break;
      }
    }
  }
  return ThreatSummary(
    atWarWith: atWarWith,
    neighborProvincesHostile: neighborProvincesHostile,
    capitalThreatened: capitalThreatened,
  );
}
