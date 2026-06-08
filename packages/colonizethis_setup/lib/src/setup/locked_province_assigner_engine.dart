part of 'locked_province_assigner.dart';

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

typedef _TabuEntry = (
  int capitalGeneration,
  int choiceDepth,
  String provinceId,
);

typedef _Placement = ({String faction, String province, bool lockedSeed});

/// DFS return codes for the outer search loop.
const int _dfsOk = 0;
const int _dfsDeadEnd = 1;
const int _dfsBudget = 2;

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
    setupLog.i(line);
  }
}
