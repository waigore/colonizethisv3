part of 'game_setup_ownership.dart';

List<String> _lockedGrowthOrder(
  List<String> factionIds,
  Map<String, int> targetPerFaction,
) {
  final list = List<String>.from(factionIds)
    ..sort((a, b) => compareByTargetDescThenIdAsc(a, b, targetPerFaction));
  return list;
}

List<MapEntry<int, List<String>>> _landmassEntriesSortedBySize(
  Map<int, List<String>> landmassToProvinces,
) {
  final list = landmassToProvinces.entries.toList()
    ..sort((a, b) => compareBySizeDescThenMinIdAsc(a.value, b.value));
  return list;
}

List<String> _lockedMinorIdsOnSortedLandmassIndex({
  required int landmassIndexSorted,
  required List<String> minorIdsSorted,
}) {
  if (minorIdsSorted.length != 6) return const [];
  switch (landmassIndexSorted) {
    case 0:
      return [minorIdsSorted[0]];
    case 1:
      return [minorIdsSorted[1]];
    case 2:
      return [minorIdsSorted[2], minorIdsSorted[3]];
    case 3:
      return [minorIdsSorted[4], minorIdsSorted[5]];
    default:
      return const [];
  }
}

Map<String, String> _assignFactionsSingleComponentLocked({
  required List<String> factionIds,
  required Set<String> universe,
  required Map<String, Set<String>> neighbours,
  required Random? assignmentRandom,
  required int backtrackLimitPerFaction,
}) {
  if (factionIds.isEmpty || universe.isEmpty) return {};
  final targets = computeFairTargets(factionIds, universe.length);
  final comps = connectedComponentsInSubset(universe, neighbours);
  if (comps.length != 1) {
    throw SetupTopologyDataException(
      code: 'assignment_remainder_not_connected',
      details:
          'Locked-style assignment requires one P–P component on remainder '
          '(found ${comps.length} for factions ${factionIds.join(",")})',
    );
  }
  final land = comps.single;
  final order = _lockedGrowthOrder(factionIds, targets);
  return assignTerritoriesLockedOnLandmass(
    landmassProvinceIds: land,
    neighbours: neighbours,
    growthOrder: order,
    targetPerFaction: targets,
    mandatorySeedProvinceByFaction: const {},
    seedPickerRandom: assignmentRandom,
    backtrackLimitPerFaction: backtrackLimitPerFaction,
    observation: null,
  );
}

/// DFS over component choices (largest slack first) finds a feasible packing
/// when one exists; bounded for pathological branching.
const _kMultiComponentPackSearchNodeCap = 500000;

bool _tryPackFactionsOntoPpComponentsDfs({
  required List<String> facsOrdered,
  required Map<String, int> targets,
  required List<Set<String>> components,
  required List<int> allocated,
  required Map<String, int> compForFaction,
  required int idx,
  required int Function() bumpSearchNodes,
}) {
  if (idx >= facsOrdered.length) return true;
  if (bumpSearchNodes() > _kMultiComponentPackSearchNodeCap) return false;
  final f = facsOrdered[idx];
  final t = targets[f]!;
  final candidates = <int>[];
  for (var ci = 0; ci < components.length; ci++) {
    final slack = components[ci].length - allocated[ci];
    if (slack >= t) candidates.add(ci);
  }
  if (candidates.isEmpty) return false;
  candidates.sort((a, b) {
    final sa = components[a].length - allocated[a];
    final sb = components[b].length - allocated[b];
    final c = sb.compareTo(sa);
    if (c != 0) return c;
    return a.compareTo(b);
  });
  for (final ci in candidates) {
    allocated[ci] += t;
    compForFaction[f] = ci;
    if (_tryPackFactionsOntoPpComponentsDfs(
      facsOrdered: facsOrdered,
      targets: targets,
      components: components,
      allocated: allocated,
      compForFaction: compForFaction,
      idx: idx + 1,
      bumpSearchNodes: bumpSearchNodes,
    )) {
      return true;
    }
    allocated[ci] -= t;
    compForFaction.remove(f);
  }
  return false;
}

Map<String, String> _assignFactionsMultiComponentLocked({
  required List<String> factionIds,
  required Set<String> universe,
  required Map<String, Set<String>> neighbours,
  required Random? assignmentRandom,
  required int backtrackLimitPerFaction,
}) {
  if (factionIds.isEmpty || universe.isEmpty) return {};
  final targets = computeFairTargets(factionIds, universe.length);
  var components = connectedComponentsInSubset(universe, neighbours);
  components.sort(compareBySizeDescThenMinIdAsc);
  final allocated = List<int>.filled(components.length, 0);
  final compForFaction = <String, int>{};
  final facsOrdered = factionIds.toList()
    ..sort((a, b) => compareByTargetDescThenIdAsc(a, b, targets));
  var searchNodes = 0;
  int bump() => ++searchNodes;
  if (!_tryPackFactionsOntoPpComponentsDfs(
    facsOrdered: facsOrdered,
    targets: targets,
    components: components,
    allocated: allocated,
    compForFaction: compForFaction,
    idx: 0,
    bumpSearchNodes: bump,
  )) {
    throw SetupTopologyDataException(
      code: 'faction_component_bin_pack_failed',
      details:
          'Cannot assign factions ${facsOrdered.join(",")} with targets '
          '$targets to remainder P–P components (sizes '
          '${components.map((c) => c.length).join(",")}; searchNodes=$searchNodes)',
    );
  }
  final byComp = <int, List<String>>{};
  for (final f in factionIds) {
    byComp.putIfAbsent(compForFaction[f]!, () => []).add(f);
  }
  final out = <String, String>{};
  for (final e in byComp.entries) {
    final land = components[e.key];
    final fs = e.value
      ..sort((a, b) => compareByTargetDescThenIdAsc(a, b, targets));
    final localTargets = {for (final f in fs) f: targets[f]!};
    final order = _lockedGrowthOrder(fs, localTargets);
    out.addAll(
      assignTerritoriesLockedOnLandmass(
        landmassProvinceIds: land,
        neighbours: neighbours,
        growthOrder: order,
        targetPerFaction: localTargets,
        mandatorySeedProvinceByFaction: const {},
        seedPickerRandom: assignmentRandom,
        backtrackLimitPerFaction: backtrackLimitPerFaction,
        observation: null,
      ),
    );
  }
  return out;
}

Map<String, String> _assignFactionsOnRemainderAuto({
  required List<String> factionIds,
  required Set<String> universe,
  required Map<String, Set<String>> neighbours,
  required Random? assignmentRandom,
  required int backtrackLimitPerFaction,
}) {
  final comps = connectedComponentsInSubset(universe, neighbours);
  if (comps.length == 1) {
    return _assignFactionsSingleComponentLocked(
      factionIds: factionIds,
      universe: universe,
      neighbours: neighbours,
      assignmentRandom: assignmentRandom,
      backtrackLimitPerFaction: backtrackLimitPerFaction,
    );
  }
  return _assignFactionsMultiComponentLocked(
    factionIds: factionIds,
    universe: universe,
    neighbours: neighbours,
    assignmentRandom: assignmentRandom,
    backtrackLimitPerFaction: backtrackLimitPerFaction,
  );
}
