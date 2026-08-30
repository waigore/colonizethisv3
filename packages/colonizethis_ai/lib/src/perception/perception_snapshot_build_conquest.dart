import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/ai_api.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'perception_topology.dart';
import 'summary_models.dart';

ConquestSummary buildConquestSummary(
  PlayerView view,
  MapTopology? topology,
  ThreatSummary threats,
  OpportunitySummary opportunities,
) {
  var oldWorldOwned = 0;
  for (final p in view.provincesById.entries) {
    if (p.value.ownerId != view.playerId) continue;
    if (ProvinceId.regionIdFrom(p.key) != kOldWorldRegionId) continue;
    oldWorldOwned++;
  }
  final provincesToVictory = provincesToVictoryFromOldWorldOwned(oldWorldOwned);
  final invadable = topology == null
      ? <String>[]
      : _invadableOldWorldProvinceIds(view, topology);
  final adjacentOwners = topology == null
      ? <String>[]
      : _adjacentOwnerFactionIdsSorted(view, topology);
  final preferredTargets = <String>{
    ...threats.atWarWith,
    ...opportunities.weakNeighbors,
    ...adjacentOwners,
  }.toList()..sort();
  return ConquestSummary(
    oldWorldProvincesOwned: oldWorldOwned,
    provincesToVictory: provincesToVictory,
    invadableProvinceIdsSorted: invadable,
    preferredConquestTargetFactionIdsSorted: preferredTargets,
    adjacentOwnerFactionIdsSorted: adjacentOwners,
  );
}

List<String> _adjacentOwnerFactionIdsSorted(
  PlayerView view,
  MapTopology topology,
) {
  return _adjacentOwnerFactionIdsForRegion(view, topology, kOldWorldRegionId);
}

List<String> _adjacentOwnerFactionIdsForRegion(
  PlayerView view,
  MapTopology topology,
  String regionId,
) {
  final anchorProvinces = <String>{};
  for (final p in view.provincesById.entries) {
    if (p.value.ownerId == view.playerId) {
      anchorProvinces.add(p.key);
    }
  }
  final neighbors = neighborProvinceIdsFromTopology(
    topology,
    anchorProvinces,
    view,
  );
  final owners = <String>{};
  for (final fullId in neighbors) {
    if (ProvinceId.regionIdFrom(fullId) != regionId) continue;
    final ownerId = view.provincesById[fullId]?.ownerId;
    if (ownerId == null || ownerId.isEmpty || ownerId == view.playerId) {
      continue;
    }
    owners.add(ownerId);
  }
  final sorted = owners.toList()..sort();
  return sorted;
}

List<String> _invadableOldWorldProvinceIds(
  PlayerView view,
  MapTopology topology,
) {
  return _invadableProvinceIdsForRegion(view, topology, kOldWorldRegionId);
}

List<String> _invadableProvinceIdsForRegion(
  PlayerView view,
  MapTopology topology,
  String regionId,
) {
  final anchorProvinces = <String>{};
  for (final p in view.provincesById.entries) {
    if (p.value.ownerId == view.playerId) {
      anchorProvinces.add(p.key);
    }
  }
  for (final u in view.ownUnits) {
    final loc = u.locationProvinceId;
    if (loc.isNotEmpty) anchorProvinces.add(loc);
  }
  final neighbors = neighborProvinceIdsFromTopology(
    topology,
    anchorProvinces,
    view,
  );
  final invadable = <String>[];
  for (final fullId in neighbors) {
    if (ProvinceId.regionIdFrom(fullId) != regionId) continue;
    final prov = view.provincesById[fullId];
    if (prov == null) continue;
    final ownerId = prov.ownerId;
    if (ownerId == null || ownerId.isEmpty || ownerId == view.playerId) {
      continue;
    }
    invadable.add(fullId);
  }
  invadable.sort();
  return invadable;
}
