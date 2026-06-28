// Legacy connectivity helper retained for tests and diagnostics (no repair pass).
// SPEC/program/locked-province-assigner.md — product uses locked assigner only.

import 'dart:collection';

/// True if [gpId]'s provinces induce a single connected component on [neighbours] (P–P only).
bool gpProvincesAreLandConnected(
  String gpId,
  Map<String, String> owners,
  Map<String, Set<String>> neighbours,
) {
  final mine = owners.entries
      .where((e) => e.value == gpId)
      .map((e) => e.key)
      .toSet();
  if (mine.length <= 1) return true;
  final start = mine.toList()..sort();
  final seed = start.first;
  final queue = Queue<String>()..add(seed);
  final seen = <String>{seed};
  while (queue.isNotEmpty) {
    final u = queue.removeFirst();
    for (final v in neighbours[u] ?? const <String>{}) {
      if (!mine.contains(v)) continue;
      if (seen.add(v)) queue.add(v);
    }
  }
  return seen.length == mine.length;
}
