part of 'perception_snapshot.dart';

ThreatSummary _buildThreatSummary(PlayerView view, MapTopology? topology) {
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

OpportunitySummary _buildOpportunitySummary(
  PlayerView view,
  MapTopology? topology,
) {
  var unclaimed = 0;
  var richUnexploited = 0;
  for (final p in view.provincesById.values) {
    if (p.ownerId == null || p.ownerId!.isEmpty) {
      unclaimed++;
      richUnexploited++;
    } else if (p.ownerId != view.playerId && p.townDevelopmentLevel > 0) {
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

ConquestSummary _buildConquestSummary(
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

ColonialSummary _buildColonialSummary(
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

EconomySummary _buildEconomySummary(PlayerView view) {
  final p = view.player;
  final workerCount = p.workerPool.totalWorkers;
  final treasury = p.treasury;
  var ownCount = 0;
  for (final prov in view.provincesById.values) {
    if (prov.ownerId == view.playerId) ownCount++;
  }
  return EconomySummary(
    workerCount: workerCount,
    treasury: treasury,
    ownProvinceCount: ownCount,
  );
}
