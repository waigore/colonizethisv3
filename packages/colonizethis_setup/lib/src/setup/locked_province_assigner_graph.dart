part of 'locked_province_assigner.dart';

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
