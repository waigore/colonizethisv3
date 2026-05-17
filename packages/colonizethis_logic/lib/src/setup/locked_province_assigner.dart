// SPEC/program/locked-province-assigner.md — phased seeds + per-faction backtrack + cross-unwind.

import 'dart:math';

import 'package:colonizethis_logic/src/logging.dart' show logicLog;

/// When true (`dart run --define=CT_TRACE_LOCKED_ASSIGNER_DFS=true`),
/// prints every DFS branch to stdout (tabu skips, greedy prunes, try_push with
/// full owner map, pop_backtrack, capital-generation restarts) and mirrors the
/// same line at [Level.info] for log sinks. Verbose: use only for small graphs.
const bool _kTraceLockedAssignerDfs = bool.fromEnvironment(
  'CT_TRACE_LOCKED_ASSIGNER_DFS',
  defaultValue: false,
);

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

typedef _Placement = ({String faction, String province, bool lockedSeed});

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
  final trialOwners = Map<String, String>.from(ownersNow)
    ..[trialProvince] = activeFaction;
  final trialUnassigned = Set<String>.from(unassignedNow)
    ..remove(trialProvince);

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
    final comp = _componentSizeFromSeed(fixed, nodes, neighbours, land);
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
  final engine = _LockedAssignerEngine(
    landmassProvinceIds: landmassProvinceIds,
    neighbours: neighbours,
    growthOrder: growthOrder,
    targetPerFaction: targetPerFaction,
    mandatorySeedProvinceByFaction: mandatorySeedProvinceByFaction,
    seedPickerRandom: seedPickerRandom,
    backtrackLimitPerFaction: backtrackLimitPerFaction,
    observation: observation,
  );
  return engine.run();
}

final class _LockedAssignerEngine {
  _LockedAssignerEngine({
    required Set<String> landmassProvinceIds,
    required this.neighbours,
    required this.growthOrder,
    required this.targetPerFaction,
    required Map<String, String> mandatorySeedProvinceByFaction,
    required this.seedPickerRandom,
    required this.backtrackLimitPerFaction,
    required this.observation,
  }) : land = landmassProvinceIds,
       mandatory = Map<String, String>.from(mandatorySeedProvinceByFaction),
       unassigned = Set<String>.from(landmassProvinceIds),
       countPerFaction = <String, int>{for (final f in growthOrder) f: 0},
       localBacktracks = <String, int>{for (final f in growthOrder) f: 0};

  final Set<String> land;
  final Map<String, Set<String>> neighbours;
  final List<String> growthOrder;
  final Map<String, int> targetPerFaction;
  final Map<String, String> mandatory;
  final Random? seedPickerRandom;
  final int backtrackLimitPerFaction;
  final LockedAssignerObservation? observation;

  final owners = <String, String>{};
  final Set<String> unassigned;
  final tabu = <_TabuEntry>{};
  final placementStack = <_Placement>[];
  final Map<String, int> countPerFaction;
  final Map<String, int> localBacktracks;
  final traceSeq = <int>[0];
  int capitalGeneration = 0;
  String? lastBlockedFaction;

  Map<String, String> run() {
    while (true) {
      tabu.clear();
      lastBlockedFaction = null;
      for (final f in growthOrder) {
        localBacktracks[f] = 0;
      }
      final rc = _dfs();
      if (rc == _dfsOk) {
        return owners;
      }
      final blocked = lastBlockedFaction;
      if (blocked != null && _unwindAfterBlock(blocked)) {
        _recomputeCounts();
        for (final f in growthOrder) {
          localBacktracks[f] = 0;
        }
        continue;
      }
      if (capitalGeneration >= 512) {
        throw StateError('locked province assigner: search failed on landmass');
      }
      observation?.capitalRestarts++;
      _traceDfs('capital_restart capGen=$capitalGeneration->${capitalGeneration + 1}');
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

  int _dfs() {
    if (_landmassComplete()) return _dfsOk;
    final faction = _activeFaction();
    if (faction == null) return _dfsOk;
    lastBlockedFaction = faction;
    final ranked = _rankedCandidatesForFaction(faction);
    if (ranked == null || ranked.isEmpty) {
      return _dfsDeadEnd;
    }
    final depth = placementStack.length;
    final tryOrder = _rotateList(
      ranked,
      (capitalGeneration + depth * 31) % max(1, ranked.length),
    );
    for (final p in tryOrder) {
      final decision = _tryOnePlacement(faction: faction, province: p, depth: depth);
      if (decision == _dfsOk || decision == _dfsBudget) {
        return decision;
      }
    }
    return _dfsDeadEnd;
  }

  int _tryOnePlacement({
    required String faction,
    required String province,
    required int depth,
  }) {
    final tk = (capitalGeneration, depth, province);
    if (tabu.contains(tk)) {
      _traceDfs(
        'skip_tabu capGen=$capitalGeneration depth=$depth faction=$faction prov=$province',
      );
      return _dfsDeadEnd;
    }
    final trialCounts = Map<String, int>.from(countPerFaction)
      ..[faction] = countPerFaction[faction]! + 1;
    if (!_phasedGrowthFeasibilityHolds(
      activeFaction: faction,
      trialProvince: province,
      ownersNow: owners,
      unassignedNow: unassigned,
      trialCounts: trialCounts,
      mandatorySeed: mandatory,
      growthOrder: growthOrder,
      targetPerFaction: targetPerFaction,
      neighbours: neighbours,
      land: land,
    )) {
      _traceDfs(
        'prune_phased_feasibility capGen=$capitalGeneration depth=$depth '
        'faction=$faction prov=$province',
      );
      return _dfsDeadEnd;
    }
    final needsSeed = !owners.containsValue(faction);
    final stackEnter = placementStack.length;
    owners[province] = faction;
    unassigned.remove(province);
    placementStack.add((
      faction: faction,
      province: province,
      lockedSeed: needsSeed && mandatory.containsKey(faction),
    ));
    countPerFaction[faction] = countPerFaction[faction]! + 1;
    _traceDfs(
      'try_push capGen=$capitalGeneration depth=$depth faction=$faction prov=$province '
      'owners={${_lockedAssignerOwnersCompact(owners)}}',
    );
    final child = _dfs();
    if (child == _dfsOk) {
      localBacktracks[faction] = 0;
      return _dfsOk;
    }
    while (placementStack.length > stackEnter) {
      _popOnePlacement();
    }
    if (child == _dfsBudget) {
      return _dfsBudget;
    }
    tabu.add(tk);
    _removeTabuAtOrAfterDepth(depth + 1);
    observation?.backtracks++;
    localBacktracks[faction] = (localBacktracks[faction] ?? 0) + 1;
    if (localBacktracks[faction]! >= backtrackLimitPerFaction) {
      lastBlockedFaction = faction;
      return _dfsBudget;
    }
    return _dfsDeadEnd;
  }

  List<String>? _rankedCandidatesForFaction(String faction) {
    final needsSeed = !owners.containsValue(faction);
    if (needsSeed) {
      final fixed = mandatory[faction];
      if (fixed != null) {
        if (!(unassigned.contains(fixed) && land.contains(fixed))) {
          lastBlockedFaction = faction;
          return null;
        }
        return _rankLegalNeighbors(
          legal: [fixed],
          unassigned: unassigned,
          neighbours: neighbours,
          land: land,
        );
      }
      final cand = unassigned
          .where((p) => !_reservedMandatoryForLaterFaction(p, faction))
          .toList()
        ..sort();
      if (seedPickerRandom != null) {
        cand.shuffle(seedPickerRandom);
      }
      if (cand.isEmpty) return null;
      return _rankLegalNeighbors(
        legal: cand,
        unassigned: unassigned,
        neighbours: neighbours,
        land: land,
      );
    }
    final legalList = _legalNeighborSet(faction).toList()..sort();
    if (legalList.isEmpty) return null;
    return _rankLegalNeighbors(
      legal: legalList,
      unassigned: unassigned,
      neighbours: neighbours,
      land: land,
    );
  }

  bool _landmassComplete() {
    for (final f in growthOrder) {
      if (countPerFaction[f]! < targetPerFaction[f]!) return false;
    }
    return true;
  }

  String? _activeFaction() {
    for (final f in growthOrder) {
      if (countPerFaction[f]! < targetPerFaction[f]!) return f;
    }
    return null;
  }

  bool _reservedMandatoryForLaterFaction(String province, String currentFaction) {
    final ci = growthOrder.indexOf(currentFaction);
    if (ci < 0) return false;
    for (final e in mandatory.entries) {
      final idx = growthOrder.indexOf(e.key);
      if (idx <= ci) continue;
      if (e.value == province) return true;
    }
    return false;
  }

  Set<String> _legalNeighborSet(String faction) {
    final out = <String>{};
    for (final e in owners.entries) {
      if (e.value != faction) continue;
      for (final n in neighbours[e.key] ?? const <String>{}) {
        if (!unassigned.contains(n) || !land.contains(n)) continue;
        if (_reservedMandatoryForLaterFaction(n, faction)) continue;
        out.add(n);
      }
    }
    return out;
  }

  void _popOnePlacement() {
    final top = placementStack.removeLast();
    owners.remove(top.province);
    unassigned.add(top.province);
    _recomputeCounts();
  }

  void _recomputeCounts() {
    for (final f in growthOrder) {
      countPerFaction[f] = 0;
    }
    for (final e in owners.entries) {
      countPerFaction[e.value] = (countPerFaction[e.value] ?? 0) + 1;
    }
  }

  bool _unwindAfterBlock(String blockedFaction) {
    final bi = growthOrder.indexOf(blockedFaction);
    if (bi <= 0) return false;
    final prev = growthOrder[bi - 1];
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
      _popOnePlacement();
    }
    tabu.clear();
    return true;
  }

  void _removeTabuAtOrAfterDepth(int d) {
    tabu.removeWhere((e) => e.$1 == capitalGeneration && e.$2 >= d);
  }

  void _traceDfs(String msg) {
    if (!_kTraceLockedAssignerDfs) return;
    final line = 'logic: locked_assign_dfs #${traceSeq[0]++} $msg';
    logicLog.i(line);
  }
}
