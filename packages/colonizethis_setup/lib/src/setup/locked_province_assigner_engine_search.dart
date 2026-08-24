// SPEC/program/locked-province-assigner.md — DFS placement / unwind / tabu
// (Refs #4624 Slice A extract from LockedAssignerEngine).

import 'dart:math';

import 'locked_province_assigner_engine.dart';
import 'locked_province_assigner_engine_candidates.dart';
import 'locked_province_assigner_graph.dart';
import 'locked_province_assigner_types.dart';
import 'setup_logging.dart' show setupLog;

/// When true (`dart run --define=CT_TRACE_LOCKED_ASSIGNER_DFS=true`),
/// prints every DFS branch to stdout and mirrors the same line at [Level.info].
const bool kTraceLockedAssignerDfs = bool.fromEnvironment(
  'CT_TRACE_LOCKED_ASSIGNER_DFS',
  defaultValue: false,
);

String lockedAssignerOwnersCompact(Map<String, String> owners) {
  final keys = owners.keys.toList()..sort();
  return keys.map((k) => '$k:${owners[k]}').join(',');
}

extension LockedAssignerEngineSearch on LockedAssignerEngine {
  int dfs() {
    if (landmassComplete()) return lockedAssignerDfsOk;
    final faction = activeFaction();
    if (faction == null) return lockedAssignerDfsOk;
    lastBlockedFaction = faction;
    final ranked = lockedAssignerRankedCandidatesForFaction(
      faction: faction,
      owners: owners,
      unassigned: unassigned,
      land: land,
      neighbours: neighbours,
      mandatory: mandatory,
      growthOrder: growthOrder,
      seedPickerRandom: seedPickerRandom,
      markBlockedFaction: (f) => lastBlockedFaction = f,
    );
    if (ranked == null || ranked.isEmpty) {
      return lockedAssignerDfsDeadEnd;
    }
    final depth = placementStack.length;
    final tryOrder = rotateList(
      ranked,
      (capitalGeneration + depth * 31) % max(1, ranked.length),
    );
    for (final p in tryOrder) {
      final decision = tryOnePlacement(
        faction: faction,
        province: p,
        depth: depth,
      );
      if (decision == lockedAssignerDfsOk ||
          decision == lockedAssignerDfsBudget) {
        return decision;
      }
    }
    return lockedAssignerDfsDeadEnd;
  }

  int tryOnePlacement({
    required String faction,
    required String province,
    required int depth,
  }) {
    final tk = (capitalGeneration, depth, province);
    if (tabu.contains(tk)) {
      traceDfs(
        'skip_tabu capGen=$capitalGeneration depth=$depth faction=$faction '
        'prov=$province',
      );
      return lockedAssignerDfsDeadEnd;
    }
    final trialCounts = Map<String, int>.from(countPerFaction)
      ..[faction] = countPerFaction[faction]! + 1;
    if (!phasedGrowthFeasibilityHolds(
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
      traceDfs(
        'prune_phased_feasibility capGen=$capitalGeneration depth=$depth '
        'faction=$faction prov=$province',
      );
      return lockedAssignerDfsDeadEnd;
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
    traceDfs(
      'try_push capGen=$capitalGeneration depth=$depth faction=$faction '
      'prov=$province owners={${lockedAssignerOwnersCompact(owners)}}',
    );
    final child = dfs();
    if (child == lockedAssignerDfsOk) {
      localBacktracks[faction] = 0;
      return lockedAssignerDfsOk;
    }
    while (placementStack.length > stackEnter) {
      popOnePlacement();
    }
    if (child == lockedAssignerDfsBudget) {
      return lockedAssignerDfsBudget;
    }
    tabu.add(tk);
    removeTabuAtOrAfterDepth(depth + 1);
    observation?.backtracks++;
    localBacktracks[faction] = (localBacktracks[faction] ?? 0) + 1;
    if (localBacktracks[faction]! >= backtrackLimitPerFaction) {
      lastBlockedFaction = faction;
      return lockedAssignerDfsBudget;
    }
    return lockedAssignerDfsDeadEnd;
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

  void popOnePlacement() {
    final top = placementStack.removeLast();
    owners.remove(top.province);
    unassigned.add(top.province);
    recomputeCounts();
  }

  void recomputeCounts() {
    for (final f in growthOrder) {
      countPerFaction[f] = 0;
    }
    for (final e in owners.entries) {
      countPerFaction[e.value] = (countPerFaction[e.value] ?? 0) + 1;
    }
  }

  bool unwindAfterBlock(String blockedFaction) {
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
      popOnePlacement();
    }
    tabu.clear();
    return true;
  }

  void removeTabuAtOrAfterDepth(int d) {
    tabu.removeWhere((e) => e.$1 == capitalGeneration && e.$2 >= d);
  }

  void traceDfs(String msg) {
    if (!kTraceLockedAssignerDfs) return;
    final line = 'logic: locked_assign_dfs #${traceSeq[0]++} $msg';
    setupLog.i(line);
  }
}
