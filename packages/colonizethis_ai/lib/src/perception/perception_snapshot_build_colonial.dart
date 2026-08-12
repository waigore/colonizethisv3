import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/ai_api.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'summary_models.dart';

ColonialSummary buildColonialSummary(
  PlayerView view,
  MapTopology? topology,
  ThreatSummary threats,
  OpportunitySummary opportunities,
) {
  var nwOwned = 0;
  for (final p in view.provincesById.entries) {
    if (p.value.ownerId != view.playerId) continue;
    if (ProvinceId.regionIdFrom(p.key) != kNewWorldRegionId) continue;
    nwOwned++;
  }
  final invadable = topology == null
      ? <String>[]
      : _invadableNewWorldProvinceIds(view, topology);
  final invadableByDistance = topology == null
      ? const <String>[]
      : _invadableNewWorldProvinceIdsByDistance(view, topology);
  final adjacentOwners = <String>{};
  for (final provId in invadable) {
    final ownerId = view.provincesById[provId]?.ownerId;
    if (ownerId == null || ownerId.isEmpty || ownerId == view.playerId) {
      continue;
    }
    adjacentOwners.add(ownerId);
  }
  final adjacentOwnersSorted = adjacentOwners.toList()..sort();
  final preferredTargets = <String>{
    ...threats.atWarWith,
    ...opportunities.weakNeighbors,
    ...adjacentOwners,
  }.toList()..sort();
  return ColonialSummary(
    newWorldProvincesOwned: nwOwned,
    invadableNewWorldProvinceIdsSorted: invadable,
    invadableNewWorldProvinceIdsByDistance: invadableByDistance,
    adjacentNewWorldOwnerFactionIdsSorted: adjacentOwnersSorted,
    preferredColonialTargetFactionIdsSorted: preferredTargets,
  );
}

/// New World targets reachable via coastal seas and warp zones (not P–P only).
List<String> _invadableNewWorldProvinceIds(
  PlayerView view,
  MapTopology topology,
) {
  final anchorProvinces = _colonialAnchorProvinceIds(view);
  final reachable = reachableNonOwnedProvinceIdsViaSeas(
    topology,
    anchorProvinces,
    view,
    regionIdFilter: kNewWorldRegionId,
  );
  final sorted = reachable.toList()..sort();
  return sorted;
}

/// NW invadable province ids sorted by BFS adjacency distance ascending,
/// then by province id ascending. Refs #2509 § COLONIAL phase planner §
/// planColonialAcquisition.
List<String> _invadableNewWorldProvinceIdsByDistance(
  PlayerView view,
  MapTopology topology,
) {
  final anchorProvinces = _colonialAnchorProvinceIds(view);
  final distances = reachableNonOwnedProvinceDistancesViaSeas(
    topology,
    anchorProvinces,
    view,
    regionIdFilter: kNewWorldRegionId,
  );
  final entries = distances.entries.toList()
    ..sort((a, b) {
      final byDistance = a.value.compareTo(b.value);
      if (byDistance != 0) return byDistance;
      return a.key.compareTo(b.key);
    });
  return <String>[for (final e in entries) e.key];
}

Set<String> _colonialAnchorProvinceIds(PlayerView view) {
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
  return anchorProvinces;
}
