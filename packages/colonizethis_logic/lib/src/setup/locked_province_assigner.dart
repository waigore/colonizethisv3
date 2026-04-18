// SPEC/program/locked-province-assigner.md — phased seeds + per-faction backtrack + cross-unwind.

import 'dart:math';

import '../../package_logger.dart';

/// When true (`dart run --define=CT_TRACE_LOCKED_ASSIGNER_DFS=true`),
/// prints every DFS branch to stdout (tabu skips, greedy prunes, try_push with
/// full owner map, pop_backtrack, capital-generation restarts) and mirrors the
/// same line at [Level.info] for log sinks. Verbose: use only for small graphs.
const bool _kTraceLockedAssignerDfs = bool.fromEnvironment(
  'CT_TRACE_LOCKED_ASSIGNER_DFS',
  defaultValue: false,
);

final _lockedAssignerLog = packageLogger();

String _lockedAssignerOwnersCompact(Map<String, String> owners) {
  final keys = owners.keys.toList()..sort();
  return keys.map((k) => '$k:${owners[k]}').join(',');
}

/// Default cap on backtracks **while growing one faction** before cross-faction
/// unwind or capital restart (#1830 / phased assigner).
const int kDefaultBacktrackLimitPerFaction = 20;

/// Kept for call sites that still import the old name; equals [kDefaultBacktrackLimitPerFaction].
const int kMaxBacktracksPerLandmassBeforeCapitalRestart =
    kDefaultBacktrackLimitPerFaction;

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

typedef _Placement = ({
  String faction,
  String province,
  bool lockedSeed,
});

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

void _pushUnassignedPpNeighbors(
  String u,
  Set<String> inSet,
  Map<String, Set<String>> neighbours,
  Set<String> seen,
  List<String> stack,
) {
  for (final v in neighbours[u] ?? const <String>{}) {
    if (!inSet.contains(v)) continue;
    if (seen.contains(v)) continue;
    stack.add(v);
  }
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
      _pushUnassignedPpNeighbors(u, inSet, neighbours, seen, stack);
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
      _pushUnassignedPpNeighbors(u, inSet, neighbours, seen, stack);
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

List<T> _rotateList<T>(List<T> items, int start) {
  if (items.isEmpty) return items;
  final s = start % items.length;
  if (s == 0) return items;
  return [...items.sublist(s), ...items.sublist(0, s)];
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

/// BFS size of the P–P component containing [seed] within [nodes] ∩ [land].
int _componentSizeFromSeed(
  String seed,
  Set<String> nodes,
  Map<String, Set<String>> neighbours,
  Set<String> land,
) {
  if (!nodes.contains(seed) || !land.contains(seed)) return 0;
  final seen = <String>{seed};
  final stack = <String>[seed];
  while (stack.isNotEmpty) {
    final u = stack.removeLast();
    for (final v in neighbours[u] ?? const <String>{}) {
      if (!land.contains(v) || !nodes.contains(v)) continue;
      if (seen.add(v)) stack.add(v);
    }
  }
  return seen.length;
}

/// How many provinces [faction] can still reach (current + unassigned only),
/// on [land], if we merge [trialOwners] / [trialUnassigned].
int _reachableTerritoryForFaction({
  required String faction,
  required Map<String, String> trialOwners,
  required Set<String> trialUnassigned,
  required Map<String, Set<String>> neighbours,
  required Set<String> land,
}) {
  final seeds = <String>[];
  for (final e in trialOwners.entries) {
    if (e.value != faction) continue;
    if (!land.contains(e.key)) continue;
    seeds.add(e.key);
  }
  if (seeds.isEmpty) return 0;
  final seen = <String>{};
  final stack = [...seeds];
  while (stack.isNotEmpty) {
    final u = stack.removeLast();
    if (!seen.add(u)) continue;
    for (final v in neighbours[u] ?? const <String>{}) {
      if (!land.contains(v)) continue;
      final owner = trialOwners[v];
      if (owner == faction) {
        stack.add(v);
        continue;
      }
      if (owner != null) continue;
      if (trialUnassigned.contains(v)) stack.add(v);
    }
  }
  return seen.length;
}

/// Phased-growth pruning: do not use the parallel BFS island packing test on
/// every future faction while only [activeFaction] is growing — that over-prunes
/// valid carve orders. Instead: [activeFaction] must reach its final target, and
/// every **not yet started** faction with a mandatory seed must still have a
/// component around that seed large enough for its target (#1830).
bool _phasedGrowthFeasibilityHolds({
  required String activeFaction,
  required String trialProvince,
  required Map<String, String> ownersNow,
  required Set<String> unassignedNow,
  required Map<String, int> trialCounts,
  required Map<String, String> mandatorySeed,
  required List<String> growthOrder,
  required Map<String, int> targetPerFaction,
  required Map<String, Set<String>> neighbours,
  required Set<String> land,
}) {
  final trialOwners = Map<String, String>.from(ownersNow)..[trialProvince] =
      activeFaction;
  final trialUnassigned = Set<String>.from(unassignedNow)..remove(trialProvince);

  if (trialCounts[activeFaction]! < targetPerFaction[activeFaction]!) {
    final reach = _reachableTerritoryForFaction(
      faction: activeFaction,
      trialOwners: trialOwners,
      trialUnassigned: trialUnassigned,
      neighbours: neighbours,
      land: land,
    );
    if (reach < targetPerFaction[activeFaction]!) return false;
  }

  for (final f in growthOrder) {
    if (f == activeFaction) continue;
    if (trialCounts[f]! > 0) continue;
    final fixed = mandatorySeed[f];
    if (fixed == null) continue;
    final nodes = Set<String>.from(trialUnassigned)..add(fixed);
    final comp = _componentSizeFromSeed(
      fixed,
      nodes,
      neighbours,
      land,
    );
    if (comp < targetPerFaction[f]!) return false;
  }

  var sumRemaining = 0;
  for (final f in growthOrder) {
    final rem = targetPerFaction[f]! - trialCounts[f]!;
    if (rem > 0) sumRemaining += rem;
  }
  if (trialUnassigned.length < sumRemaining) return false;

  return true;
}

/// DFS return codes for the outer search loop.
const int _dfsOk = 0;
const int _dfsDeadEnd = 1;
const int _dfsBudget = 2;

/// Phased locked growth on one P–P landmass: factions in [growthOrder] are grown
/// **one at a time**. A faction receives a **seed** only when it becomes active
/// (all earlier factions already at target). Mandatory seeds ([mandatorySeedProvinceByFaction])
/// are applied when that faction is seeded; other factions pick a seed from
/// remaining provinces via [pickSimpleSeeds] / shuffle ([seedPickerRandom]).
///
/// Per-faction backtracks are capped by [backtrackLimitPerFaction]. When the cap
/// is hit, or the search dead-ends, the assigner unwinds the last removable
/// province of the **previous** faction in [growthOrder] (never mandatory seeds).
/// If that is impossible (e.g. first faction), a **capital-generation restart**
/// clears the landmass and retries (bounded).
Map<String, String> assignTerritoriesLockedOnLandmass({
  required Set<String> landmassProvinceIds,
  required Map<String, Set<String>> neighbours,
  required List<String> growthOrder,
  required Map<String, int> targetPerFaction,
  Map<String, String> mandatorySeedProvinceByFaction = const {},
  Random? seedPickerRandom,
  int backtrackLimitPerFaction = kDefaultBacktrackLimitPerFaction,
  LockedAssignerObservation? observation,
}) {
  final land = landmassProvinceIds;
  final mandatory = Map<String, String>.from(mandatorySeedProvinceByFaction);
  final owners = <String, String>{};
  final unassigned = Set<String>.from(land);
  final tabu = <_TabuEntry>{};
  final placementStack = <_Placement>[];
  final countPerFaction = <String, int>{for (final f in growthOrder) f: 0};
  final localBacktracks = <String, int>{for (final f in growthOrder) f: 0};
  var capitalGeneration = 0;
  String? lastBlockedFaction;

  final traceSeq = <int>[0];
  void traceDfs(String msg) {
    if (!_kTraceLockedAssignerDfs) return;
    final line = 'logic: locked_assign_dfs #${traceSeq[0]++} $msg';
    // ignore: avoid_print
    print(line);
    _lockedAssignerLog.i(line);
  }

  void removeTabuAtOrAfterDepth(int d) {
    tabu.removeWhere((e) => e.$1 == capitalGeneration && e.$2 >= d);
  }

  void recomputeCounts() {
    for (final f in growthOrder) {
      countPerFaction[f] = 0;
    }
    for (final e in owners.entries) {
      countPerFaction[e.value] = (countPerFaction[e.value] ?? 0) + 1;
    }
  }

  /// True if [province] is the mandatory seed tile of a faction that appears
  /// **after** [currentFaction] in [growthOrder] (still unassigned for that
  /// faction). Earlier factions must not grow into those tiles.
  bool reservedMandatoryForLaterFaction(String province, String currentFaction) {
    final ci = growthOrder.indexOf(currentFaction);
    if (ci < 0) return false;
    for (final e in mandatory.entries) {
      final idx = growthOrder.indexOf(e.key);
      if (idx <= ci) continue;
      if (e.value == province) return true;
    }
    return false;
  }

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
        if (!unassigned.contains(n) || !land.contains(n)) continue;
        if (reservedMandatoryForLaterFaction(n, faction)) continue;
        out.add(n);
      }
    }
    return out;
  }

  void popOnePlacement() {
    final top = placementStack.removeLast();
    owners.remove(top.province);
    unassigned.add(top.province);
    recomputeCounts();
  }

  /// Removes the last non-[lockedSeed] placement of [prev], and every placement
  /// after it in time order. Returns false if none removable.
  bool unwindLastOfFaction(String prev) {
    var idx = -1;
    for (var i = placementStack.length - 1; i >= 0; i--) {
      final e = placementStack[i];
      if (e.faction == prev && !e.lockedSeed) {
        idx = i;
        break;
      }
    }
    if (idx < 0) return false;
    while (placementStack.length > idx) {
      popOnePlacement();
    }
    tabu.clear();
    return true;
  }

  bool unwindAfterBlock(String blockedFaction) {
    final bi = growthOrder.indexOf(blockedFaction);
    if (bi <= 0) return false;
    final prev = growthOrder[bi - 1];
    return unwindLastOfFaction(prev);
  }

  int dfs() {
    if (landmassComplete()) return _dfsOk;
    final faction = activeFaction();
    if (faction == null) return _dfsOk;
    lastBlockedFaction = faction;

    final needsSeed = !owners.containsValue(faction);
    late final List<String> ranked;
    if (needsSeed) {
      final fixed = mandatory[faction];
      if (fixed != null) {
        if (!(unassigned.contains(fixed) && land.contains(fixed))) {
          lastBlockedFaction = faction;
          return _dfsDeadEnd;
        }
        ranked = _rankLegalNeighbors(
          legal: [fixed],
          unassigned: unassigned,
          neighbours: neighbours,
          land: land,
        );
      } else {
        final cand =
            unassigned
                .where((p) => !reservedMandatoryForLaterFaction(p, faction))
                .toList()
              ..sort();
        if (seedPickerRandom != null) {
          cand.shuffle(seedPickerRandom);
        }
        if (cand.isEmpty) return _dfsDeadEnd;
        ranked = _rankLegalNeighbors(
          legal: cand,
          unassigned: unassigned,
          neighbours: neighbours,
          land: land,
        );
      }
    } else {
      final legalList = _legalNeighborSet(faction).toList()..sort();
      if (legalList.isEmpty) return _dfsDeadEnd;
      ranked = _rankLegalNeighbors(
        legal: legalList,
        unassigned: unassigned,
        neighbours: neighbours,
        land: land,
      );
    }

    final depth = placementStack.length;
    // Vary try-order across capital-generation restarts when ranking is otherwise
    // deterministic (mandatory seeds, sorted legals); otherwise restarts repeat
    // the same failed path without advancing RNG (#1830).
    final tryOrder = _rotateList(
      ranked,
      (capitalGeneration + depth * 31) % max(1, ranked.length),
    );
    for (final p in tryOrder) {
      final tk = (capitalGeneration, depth, p);
      if (tabu.contains(tk)) {
        traceDfs(
          'skip_tabu capGen=$capitalGeneration depth=$depth faction=$faction '
          'prov=$p',
        );
        continue;
      }

      final trialUnassigned = Set<String>.from(unassigned)..remove(p);
      final trialCounts = Map<String, int>.from(countPerFaction);
      trialCounts[faction] = trialCounts[faction]! + 1;
      if (!_phasedGrowthFeasibilityHolds(
        activeFaction: faction,
        trialProvince: p,
        ownersNow: owners,
        unassignedNow: unassigned,
        trialCounts: trialCounts,
        mandatorySeed: mandatory,
        growthOrder: growthOrder,
        targetPerFaction: targetPerFaction,
        neighbours: neighbours,
        land: land,
      )) {
        traceDfs(
          'prune_phased_feasibility capGen=$capitalGeneration depth=$depth '
          'faction=$faction prov=$p trialUnassigned=${trialUnassigned.length}',
        );
        continue;
      }

      final lockedSeed = needsSeed && mandatory.containsKey(faction);
      final stackEnter = placementStack.length;
      owners[p] = faction;
      unassigned.remove(p);
      placementStack.add(
        (faction: faction, province: p, lockedSeed: lockedSeed),
      );
      countPerFaction[faction] = countPerFaction[faction]! + 1;
      traceDfs(
        'try_push capGen=$capitalGeneration depth=$depth faction=$faction prov=$p '
        'needsSeed=$needsSeed owners={${_lockedAssignerOwnersCompact(owners)}} '
        'stack=${placementStack.map((e) => e.province).join(">")}',
      );

      final child = dfs();
      if (child == _dfsOk) {
        localBacktracks[faction] = 0;
        return _dfsOk;
      }
      while (placementStack.length > stackEnter) {
        popOnePlacement();
      }
      if (child == _dfsBudget) {
        return _dfsBudget;
      }
      tabu.add(tk);
      removeTabuAtOrAfterDepth(depth + 1);
      observation?.backtracks++;
      localBacktracks[faction] = (localBacktracks[faction] ?? 0) + 1;
      traceDfs(
        'pop_backtrack capGen=$capitalGeneration depth=$depth faction=$faction '
        'prov=$p localBt=${localBacktracks[faction]}',
      );
      if (localBacktracks[faction]! >= backtrackLimitPerFaction) {
        lastBlockedFaction = faction;
        return _dfsBudget;
      }
    }
    return _dfsDeadEnd;
  }

  while (true) {
    tabu.clear();
    lastBlockedFaction = null;
    for (final f in growthOrder) {
      localBacktracks[f] = 0;
    }
    final rc = dfs();
    if (rc == _dfsOk) {
      return owners;
    }
    final blocked = lastBlockedFaction;
    if (blocked != null && unwindAfterBlock(blocked)) {
      recomputeCounts();
      for (final f in growthOrder) {
        localBacktracks[f] = 0;
      }
      continue;
    }
    if (capitalGeneration >= 512) {
      throw StateError('locked province assigner: search failed on landmass');
    }
    observation?.capitalRestarts++;
    traceDfs(
      'capital_restart capGen=$capitalGeneration->${capitalGeneration + 1}',
    );
    capitalGeneration++;
    owners.clear();
    unassigned.clear();
    unassigned.addAll(land);
    placementStack.clear();
    for (final f in growthOrder) {
      countPerFaction[f] = 0;
      localBacktracks[f] = 0;
    }
    tabu.clear();
  }
}
