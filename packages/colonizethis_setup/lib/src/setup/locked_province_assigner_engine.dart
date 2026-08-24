// SPEC/program/locked-province-assigner.md — DFS engine for locked assigner
// (Refs #4086 Slice B de-part; #4349 Slice A candidate extract; #4624 search extract).

import 'dart:math';

import 'locked_province_assigner_engine_search.dart';
import 'locked_province_assigner_types.dart';

final class LockedAssignerEngine {
  LockedAssignerEngine({
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
  final tabu = <LockedAssignerTabuKey>{};
  final placementStack = <LockedAssignerPlacement>[];
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
      final rc = dfs();
      if (rc == lockedAssignerDfsOk) {
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
}
