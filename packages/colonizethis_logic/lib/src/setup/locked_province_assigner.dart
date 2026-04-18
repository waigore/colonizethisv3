// SPEC/program/locked-province-assigner.md — sequential growth + backtrack + tabu.

/// Optional counters for tests (AC-14 / AC-15).
final class LockedAssignerObservation {
  int backtracks = 0;
  int capitalRestarts = 0;
}

typedef _TabuEntry = (
  int capitalGeneration,
  int choiceDepth,
  String provinceId,
);

int _ppDegreeOnLand(
  String province,
  Map<String, Set<String>> neighbours,
  Set<String> land,
) {
  var d = 0;
  for (final n in neighbours[province] ?? const <String>{}) {
    if (land.contains(n)) d++;
  }
  return d;
}

int _unassignedIslandCountOnLand(
  Set<String> unassigned,
  Map<String, Set<String>> neighbours,
  Set<String> land,
) {
  final inSet = unassigned.intersection(land);
  if (inSet.isEmpty) return 0;
  final seen = <String>{};
  var components = 0;
  for (final start in inSet) {
    if (seen.contains(start)) continue;
    components++;
    final stack = <String>[start];
    while (stack.isNotEmpty) {
      final u = stack.removeLast();
      if (!seen.add(u)) continue;
      for (final v in neighbours[u] ?? const <String>{}) {
        if (inSet.contains(v) && !seen.contains(v)) stack.add(v);
      }
    }
  }
  return components;
}

List<int> _islandSizesOnLand(
  Set<String> unassigned,
  Map<String, Set<String>> neighbours,
  Set<String> land,
) {
  final inSet = unassigned.intersection(land);
  if (inSet.isEmpty) return const [];
  final seen = <String>{};
  final sizes = <int>[];
  for (final start in inSet) {
    if (seen.contains(start)) continue;
    var sz = 0;
    final stack = <String>[start];
    while (stack.isNotEmpty) {
      final u = stack.removeLast();
      if (!seen.add(u)) continue;
      sz++;
      for (final v in neighbours[u] ?? const <String>{}) {
        if (inSet.contains(v) && !seen.contains(v)) stack.add(v);
      }
    }
    sizes.add(sz);
  }
  sizes.sort((a, b) => b.compareTo(a));
  return sizes;
}

/// Greedy necessary check: each residual can be placed on some island at least as large.
bool islandResidualsFeasibleGreedy({
  required Set<String> unassignedOnLand,
  required Map<String, Set<String>> neighbours,
  required Set<String> land,
  required List<int> residualsSortedDesc,
}) {
  if (residualsSortedDesc.isEmpty) return true;
  final islands = _islandSizesOnLand(unassignedOnLand, neighbours, land);
  if (islands.isEmpty) return residualsSortedDesc.every((r) => r == 0);
  var j = 0;
  for (final r in residualsSortedDesc) {
    if (r <= 0) continue;
    while (j < islands.length && islands[j] < r) {
      j++;
    }
    if (j >= islands.length) return false;
    j++;
  }
  return true;
}

List<String> _rankLegalNeighbors({
  required List<String> legal,
  required Set<String> unassigned,
  required Map<String, Set<String>> neighbours,
  required Set<String> land,
}) {
  final scored = <(String id, int deg, int isl)>[];
  for (final p in legal) {
    final u = Set<String>.from(unassigned)..remove(p);
    final deg = _ppDegreeOnLand(p, neighbours, land);
    final isl = _unassignedIslandCountOnLand(u, neighbours, land);
    scored.add((p, deg, isl));
  }
  scored.sort((a, b) {
    final c = b.$2.compareTo(a.$2);
    if (c != 0) return c;
    final d = a.$3.compareTo(b.$3);
    if (d != 0) return d;
    return a.$1.compareTo(b.$1);
  });
  return [for (final t in scored) t.$1];
}

List<int> _unfinishedResidualsSortedDesc({
  required List<String> growthOrder,
  required Map<String, int> targetPerFaction,
  required Map<String, int> countPerFaction,
}) {
  final r = <int>[];
  for (final f in growthOrder) {
    final need = targetPerFaction[f]! - countPerFaction[f]!;
    if (need > 0) r.add(need);
  }
  r.sort((a, b) => b.compareTo(a));
  return r;
}

/// Strict sequential growth on one P–P landmass (#1822): each faction in [growthOrder]
/// reaches its [targetPerFaction] before the next. [seeds] must place the first tile
/// for every faction that appears in [growthOrder].
Map<String, String> assignTerritoriesLockedOnLandmass({
  required Set<String> landmassProvinceIds,
  required Map<String, Set<String>> neighbours,
  required List<String> growthOrder,
  required Map<String, int> targetPerFaction,
  required Map<String, String> seeds,
  required int backtrackLimitPerLandmass,
  LockedAssignerObservation? observation,
}) {
  final land = landmassProvinceIds;
  final owners = <String, String>{};
  final unassigned = Set<String>.from(land);
  final tabu = <_TabuEntry>{};
  var capitalGeneration = 0;

  void removeTabuAtOrAfterDepth(int d) {
    tabu.removeWhere((e) => e.$1 == capitalGeneration && e.$2 >= d);
  }

  for (final e in seeds.entries) {
    if (!land.contains(e.key)) {
      throw StateError(
        'locked assigner: seed province ${e.key} not on landmass',
      );
    }
    owners[e.key] = e.value;
    unassigned.remove(e.key);
  }

  final countPerFaction = <String, int>{for (final f in growthOrder) f: 0};
  for (final e in owners.entries) {
    countPerFaction[e.value] = (countPerFaction[e.value] ?? 0) + 1;
  }

  final trail = <String>[];
  var backtracksOnLandmass = 0;

  bool landmassComplete() {
    for (final f in growthOrder) {
      if (countPerFaction[f]! < targetPerFaction[f]!) return false;
    }
    return true;
  }

  String? activeFaction() {
    for (final f in growthOrder) {
      if (countPerFaction[f]! < targetPerFaction[f]!) return f;
    }
    return null;
  }

  Set<String> _legalNeighborSet(String faction) {
    final out = <String>{};
    for (final e in owners.entries) {
      if (e.value != faction) continue;
      for (final n in neighbours[e.key] ?? const <String>{}) {
        if (unassigned.contains(n) && land.contains(n)) out.add(n);
      }
    }
    return out;
  }

  bool dfs() {
    if (landmassComplete()) return true;
    final faction = activeFaction();
    if (faction == null) return true;

    final legal = _legalNeighborSet(faction).toList()..sort();
    if (legal.isEmpty) {
      return false;
    }
    final ranked = _rankLegalNeighbors(
      legal: legal,
      unassigned: unassigned,
      neighbours: neighbours,
      land: land,
    );

    final depth = trail.length;
    for (final p in ranked) {
      final tk = (capitalGeneration, depth, p);
      if (tabu.contains(tk)) continue;

      final trialUnassigned = Set<String>.from(unassigned)..remove(p);
      final trialCounts = Map<String, int>.from(countPerFaction);
      trialCounts[faction] = trialCounts[faction]! + 1;
      final residuals = _unfinishedResidualsSortedDesc(
        growthOrder: growthOrder,
        targetPerFaction: targetPerFaction,
        countPerFaction: trialCounts,
      );
      if (!islandResidualsFeasibleGreedy(
        unassignedOnLand: trialUnassigned,
        neighbours: neighbours,
        land: land,
        residualsSortedDesc: residuals,
      )) {
        continue;
      }

      owners[p] = faction;
      unassigned.remove(p);
      countPerFaction[faction] = countPerFaction[faction]! + 1;
      trail.add(p);

      if (dfs()) return true;

      trail.removeLast();
      countPerFaction[faction] = countPerFaction[faction]! - 1;
      unassigned.add(p);
      owners.remove(p);
      observation?.backtracks++;
      backtracksOnLandmass++;
      tabu.add(tk);
      removeTabuAtOrAfterDepth(depth + 1);

      if (backtracksOnLandmass > backtrackLimitPerLandmass) {
        observation?.capitalRestarts++;
        if (capitalGeneration >= 512) {
          return false;
        }
        capitalGeneration++;
        tabu.clear();
        owners.clear();
        unassigned
          ..clear()
          ..addAll(land);
        for (final e in seeds.entries) {
          owners[e.key] = e.value;
          unassigned.remove(e.key);
        }
        for (final f in growthOrder) {
          countPerFaction[f] = 0;
        }
        for (final e in owners.entries) {
          countPerFaction[e.value] = (countPerFaction[e.value] ?? 0) + 1;
        }
        trail.clear();
        backtracksOnLandmass = 0;
        return dfs();
      }
    }
    return false;
  }

  if (!dfs()) {
    throw StateError('locked province assigner: search failed on landmass');
  }
  return owners;
}
