/// Generic BFS territory assignment for province ownership.
/// Used by game_setup to assign Great Powers, Minor Nations, and Tribes.
library;

export 'province_assignment_bfs_growth.dart';

/// True if [provinceId] shares a P–P edge with a province owned by [factionId].
bool provinceTouchesFaction(
  String provinceId,
  String factionId,
  Map<String, String> owners,
  Map<String, Set<String>> neighbours,
) {
  for (final n in neighbours[provinceId] ?? const <String>{}) {
    if (owners[n] == factionId) return true;
  }
  return false;
}

/// Computes fair target counts: divides [total] among [count] factions,
/// distributing remainders to earlier factions.
Map<String, int> computeFairTargets(List<String> factionIds, int total) {
  final count = factionIds.length;
  if (count == 0) return {};
  final base = total ~/ count;
  var remainder = total % count;
  return {
    for (var i = 0; i < count; i++)
      factionIds[i]: base + (remainder-- > 0 ? 1 : 0),
  };
}

/// Picks one seed per faction from [candidateIds], consuming from available set.
Map<String, String> pickSimpleSeeds({
  required List<String> factionIds,
  required List<String> candidateIds,
  required Set<String> available,
}) {
  final seeds = <String, String>{};
  for (final factionId in factionIds) {
    if (available.isEmpty) break;
    final seed = candidateIds.firstWhere(
      (p) => available.contains(p),
      orElse: () => '',
    );
    if (seed.isEmpty) break;
    seeds[seed] = factionId;
  }
  return seeds;
}
