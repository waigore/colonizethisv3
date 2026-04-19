// Run: dart run --define=CT_TRACE_LOCKED_ASSIGNER_DFS=true tool/trace_locked_assigner_dfs.dart
//
// Prints every DFS branch (tabu skip, greedy prune, try_push with full owner map,
// pop_backtrack, capital restart) for the AC-14 hand-tuned 4-node topology.
import 'package:colonizethis_logic/src/setup/locked_province_assigner.dart';

const _ac14Neighbours = <String, Set<String>>{
  'a': {'c', 'd'},
  'b': {'c'},
  'c': {'a', 'b'},
  'd': {'a'},
};

void main() {
  if (!const bool.fromEnvironment(
    'CT_TRACE_LOCKED_ASSIGNER_DFS',
    defaultValue: false,
  )) {
    // ignore: avoid_print
    print(
      'Re-run with: dart run --define=CT_TRACE_LOCKED_ASSIGNER_DFS=true '
      'tool/trace_locked_assigner_dfs.dart',
    );
    return;
  }
  // ignore: avoid_print
  print('--- AC-14 topology DFS trace (A,B each target 2 provinces) ---');
  assignTerritoriesLockedOnLandmass(
    landmassProvinceIds: {'a', 'b', 'c', 'd'},
    neighbours: _ac14Neighbours,
    growthOrder: const ['A', 'B'],
    targetPerFaction: const {'A': 2, 'B': 2},
    mandatorySeedProvinceByFaction: const {'A': 'a'},
    backtrackLimitPerFaction: 500,
    observation: null,
  );
  // ignore: avoid_print
  print('--- done (success) ---');
}
