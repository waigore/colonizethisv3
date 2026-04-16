// SPEC/game/game-setup.md § fair assignment connectivity repair.
// Ownership 1:1 swaps so required factions remain one P–P component.

/// Setup failed after maximum assignment attempts and connectivity repair.
/// [reasonCode] is `fair_assignment_connectivity_exhausted` per SPEC/game/game-setup.md.
class GameSetupConnectivityFailure implements Exception {
  GameSetupConnectivityFailure(
    this.message, {
    this.reasonCode = 'fair_assignment_connectivity_exhausted',
  });

  final String message;
  final String reasonCode;

  @override
  String toString() => 'GameSetupConnectivityFailure($reasonCode): $message';
}

/// Maximum greedy-improvement passes per assignment attempt
/// (SPEC/game/game-setup.md). Setup also retries whole OW assignments
/// (`game_setup_create.dart`) before failing.
const kGpLandConnectivityRepairRounds = 10;

/// True if [factionId]'s provinces induce a single connected component on [neighbours] (P–P only).
bool factionProvincesAreLandConnected(
  String factionId,
  Map<String, String> owners,
  Map<String, Set<String>> neighbours,
) {
  final mine = owners.entries
      .where((e) => e.value == factionId)
      .map((e) => e.key)
      .toSet();
  if (mine.length <= 1) return true;
  final start = mine.toList()..sort();
  final seed = start.first;
  final queue = <String>[seed];
  final seen = <String>{seed};
  while (queue.isNotEmpty) {
    final u = queue.removeAt(0);
    for (final v in neighbours[u] ?? const <String>{}) {
      if (!mine.contains(v)) continue;
      if (seen.add(v)) queue.add(v);
    }
  }
  return seen.length == mine.length;
}

/// Backward-compatible alias retained for GP-specific callers/tests.
bool gpProvincesAreLandConnected(
  String gpId,
  Map<String, String> owners,
  Map<String, Set<String>> neighbours,
) => factionProvincesAreLandConnected(gpId, owners, neighbours);

bool _gpOneLandmass(
  String gpId,
  Map<String, String> owners,
  Map<String, int> landmassIds,
) {
  int? only;
  for (final e in owners.entries) {
    if (e.value != gpId) continue;
    final lm = landmassIds[e.key];
    if (lm == null) return false;
    only ??= lm;
    if (only != lm) return false;
  }
  return true;
}

bool _gpHasSeaBoundProvince(
  String gpId,
  Map<String, String> owners,
  Set<String> seaBoundLocalIds,
) {
  for (final e in owners.entries) {
    if (e.value != gpId) continue;
    if (seaBoundLocalIds.contains(e.key)) return true;
  }
  return false;
}

bool _allGpsSatisfyHardRules(
  Map<String, String> owners,
  List<String> gpIdsSorted,
  Map<String, Set<String>> neighbours,
  Map<String, int> landmassIds,
  Set<String> seaBoundLocalIds,
) {
  for (final gp in gpIdsSorted) {
    if (!factionProvincesAreLandConnected(gp, owners, neighbours)) return false;
    if (!_gpOneLandmass(gp, owners, landmassIds)) return false;
    if (!_gpHasSeaBoundProvince(gp, owners, seaBoundLocalIds)) return false;
  }
  return true;
}

bool _allRequiredFactionsConnected(
  Map<String, String> owners,
  List<String> requiredConnectedFactionIdsSorted,
  Map<String, Set<String>> neighbours,
) {
  for (final factionId in requiredConnectedFactionIdsSorted) {
    if (!factionProvincesAreLandConnected(factionId, owners, neighbours)) {
      return false;
    }
  }
  return true;
}

int _fairAssignmentViolationCount({
  required Map<String, String> owners,
  required List<String> requiredConnectedFactionIdsSorted,
  required List<String> gpIdsSorted,
  required Map<String, Set<String>> neighbours,
  required Map<String, int> landmassIds,
  required Set<String> seaBoundLocalIds,
}) {
  var violations = 0;
  for (final factionId in requiredConnectedFactionIdsSorted) {
    if (!factionProvincesAreLandConnected(factionId, owners, neighbours)) {
      violations++;
    }
  }
  for (final gp in gpIdsSorted) {
    if (!_gpOneLandmass(gp, owners, landmassIds)) violations++;
    if (!_gpHasSeaBoundProvince(gp, owners, seaBoundLocalIds)) violations++;
  }
  return violations;
}

/// Sum of (P–P component count − 1) per required faction; positive only when split.
int _factionFragmentationExcess({
  required Map<String, String> owners,
  required List<String> factionIds,
  required Map<String, Set<String>> neighbours,
}) {
  var excess = 0;
  for (final fid in factionIds) {
    final mine = owners.entries
        .where((e) => e.value == fid)
        .map((e) => e.key)
        .toList();
    if (mine.length <= 1) continue;
    final mineSet = mine.toSet();
    final seen = <String>{};
    var components = 0;
    for (final start in mineSet) {
      if (seen.contains(start)) continue;
      components++;
      _markOwnedConnectedComponent(
        start: start,
        owned: mineSet,
        neighbours: neighbours,
        seen: seen,
      );
    }
    excess += components - 1;
  }
  return excess;
}

void _markOwnedConnectedComponent({
  required String start,
  required Set<String> owned,
  required Map<String, Set<String>> neighbours,
  required Set<String> seen,
}) {
  final stack = <String>[start];
  seen.add(start);
  while (stack.isNotEmpty) {
    final u = stack.removeLast();
    for (final v in neighbours[u] ?? const <String>{}) {
      if (!owned.contains(v)) continue;
      if (seen.add(v)) stack.add(v);
    }
  }
}

(int, int) _repairProgressTuple({
  required Map<String, String> owners,
  required List<String> requiredConnectedFactionIdsSorted,
  required List<String> gpIdsSorted,
  required Map<String, Set<String>> neighbours,
  required Map<String, int> landmassIds,
  required Set<String> seaBoundLocalIds,
}) {
  final violations = _fairAssignmentViolationCount(
    owners: owners,
    requiredConnectedFactionIdsSorted: requiredConnectedFactionIdsSorted,
    gpIdsSorted: gpIdsSorted,
    neighbours: neighbours,
    landmassIds: landmassIds,
    seaBoundLocalIds: seaBoundLocalIds,
  );
  final frag = _factionFragmentationExcess(
    owners: owners,
    factionIds: requiredConnectedFactionIdsSorted,
    neighbours: neighbours,
  );
  return (violations, frag);
}

bool _repairProgressLexStrictlyBetter((int, int) after, (int, int) before) =>
    after.$1 < before.$1 || (after.$1 == before.$1 && after.$2 < before.$2);

/// Same-landmass 1:1 swaps in deterministic province-id order (full scan).
Iterable<(String a, String b)> _sameLandmassSwapsDeterministic({
  required Map<String, String> owners,
  required Map<String, int> landmassIds,
  required List<String> allProvinceIdsSorted,
}) sync* {
  final n = allProvinceIdsSorted.length;
  for (var i = 0; i < n; i++) {
    final a = allProvinceIdsSorted[i];
    final lmA = landmassIds[a];
    if (lmA == null) continue;
    final oa = owners[a];
    if (oa == null || oa.isEmpty) continue;
    for (var j = i + 1; j < n; j++) {
      final b = allProvinceIdsSorted[j];
      if (landmassIds[b] != lmA) continue;
      final ob = owners[b];
      if (ob == null || ob.isEmpty || ob == oa) continue;
      yield (a, b);
    }
  }
}

bool _swapIsImmediatelyLegal({
  required Map<String, String> owners,
  required String a,
  required String b,
  required List<String> gpIdsSorted,
  required Map<String, Set<String>> neighbours,
  required Map<String, int> landmassIds,
  required Set<String> seaBoundLocalIds,
}) {
  final ownerA = owners[a]!;
  final ownerB = owners[b]!;
  final ownerAConnectedBefore = factionProvincesAreLandConnected(
    ownerA,
    owners,
    neighbours,
  );
  final ownerBConnectedBefore = factionProvincesAreLandConnected(
    ownerB,
    owners,
    neighbours,
  );
  owners[a] = ownerB;
  owners[b] = ownerA;
  var ok = true;
  if (ownerAConnectedBefore &&
      !factionProvincesAreLandConnected(ownerA, owners, neighbours)) {
    ok = false;
  }
  if (ok &&
      ownerBConnectedBefore &&
      !factionProvincesAreLandConnected(ownerB, owners, neighbours)) {
    ok = false;
  }
  final ownerAIsGp = gpIdsSorted.contains(ownerA);
  if (ok && ownerAIsGp) {
    ok = _gpOneLandmass(ownerA, owners, landmassIds) &&
        _gpHasSeaBoundProvince(ownerA, owners, seaBoundLocalIds);
  }
  final ownerBIsGp = gpIdsSorted.contains(ownerB);
  if (ok && ownerBIsGp) {
    ok = _gpOneLandmass(ownerB, owners, landmassIds) &&
        _gpHasSeaBoundProvince(ownerB, owners, seaBoundLocalIds);
  }
  owners[a] = ownerA;
  owners[b] = ownerB;
  return ok;
}

/// Greedy hill-climb: repeatedly scan same-landmass pairs in deterministic order
/// and apply the first legal swap that strictly improves a lexicographic pair
/// ([_fairAssignmentViolationCount], then [_factionFragmentationExcess]) so
/// plateau moves that merge split components still progress. After each accepted
/// swap the scan restarts. Stops when [maxStableScans] consecutive **full** scans
/// find no improving swap.
bool _greedySwapRepair({
  required Map<String, String> owners,
  required List<String> requiredConnectedFactionIdsSorted,
  required List<String> gpIdsSorted,
  required Map<String, Set<String>> neighbours,
  required Map<String, int> landmassIds,
  required Set<String> seaBoundLocalIds,
  required List<String> allProvinceIdsSorted,
  required int maxStableScans,
}) {
  if (_allRequiredFactionsConnected(
        owners,
        requiredConnectedFactionIdsSorted,
        neighbours,
      ) &&
      _allGpsSatisfyHardRules(
        owners,
        gpIdsSorted,
        neighbours,
        landmassIds,
        seaBoundLocalIds,
      )) {
    return true;
  }

  var stableFullScans = 0;
  while (stableFullScans < maxStableScans) {
    if (_allRequiredFactionsConnected(
          owners,
          requiredConnectedFactionIdsSorted,
          neighbours,
        ) &&
        _allGpsSatisfyHardRules(
          owners,
          gpIdsSorted,
          neighbours,
          landmassIds,
          seaBoundLocalIds,
        )) {
      return true;
    }

    final beforeScan = _repairProgressTuple(
      owners: owners,
      requiredConnectedFactionIdsSorted: requiredConnectedFactionIdsSorted,
      gpIdsSorted: gpIdsSorted,
      neighbours: neighbours,
      landmassIds: landmassIds,
      seaBoundLocalIds: seaBoundLocalIds,
    );

    var improvedThisScan = false;
    for (final swap in _sameLandmassSwapsDeterministic(
      owners: owners,
      landmassIds: landmassIds,
      allProvinceIdsSorted: allProvinceIdsSorted,
    )) {
      final a = swap.$1;
      final b = swap.$2;
      if (!_swapIsImmediatelyLegal(
        owners: owners,
        a: a,
        b: b,
        gpIdsSorted: gpIdsSorted,
        neighbours: neighbours,
        landmassIds: landmassIds,
        seaBoundLocalIds: seaBoundLocalIds,
      )) {
        continue;
      }
      final ownerA = owners[a]!;
      final ownerB = owners[b]!;
      owners[a] = ownerB;
      owners[b] = ownerA;
      final afterScan = _repairProgressTuple(
        owners: owners,
        requiredConnectedFactionIdsSorted: requiredConnectedFactionIdsSorted,
        gpIdsSorted: gpIdsSorted,
        neighbours: neighbours,
        landmassIds: landmassIds,
        seaBoundLocalIds: seaBoundLocalIds,
      );
      if (_repairProgressLexStrictlyBetter(afterScan, beforeScan)) {
        improvedThisScan = true;
        stableFullScans = 0;
        break;
      }
      owners[a] = ownerA;
      owners[b] = ownerB;
    }

    if (!improvedThisScan) {
      stableFullScans++;
    }
  }

  return _allRequiredFactionsConnected(
        owners,
        requiredConnectedFactionIdsSorted,
        neighbours,
      ) &&
      _allGpsSatisfyHardRules(
        owners,
        gpIdsSorted,
        neighbours,
        landmassIds,
        seaBoundLocalIds,
      );
}

/// Mutates [owners]. Returns true if every GP is land-connected and hard rules hold.
bool repairFactionLandOwnershipMutating({
  required Map<String, String> owners,
  required List<String> requiredConnectedFactionIdsSorted,
  required List<String> gpIdsSorted,
  required Map<String, Set<String>> neighbours,
  required Map<String, int> landmassIds,
  required Set<String> seaBoundLocalIds,
  required List<String> allProvinceIdsSorted,
  int maxRounds = kGpLandConnectivityRepairRounds,
}) {
  if (_allRequiredFactionsConnected(
        owners,
        requiredConnectedFactionIdsSorted,
        neighbours,
      ) &&
      _allGpsSatisfyHardRules(
        owners,
        gpIdsSorted,
        neighbours,
        landmassIds,
        seaBoundLocalIds,
      )) {
    return true;
  }

  final solved = _greedySwapRepair(
    owners: owners,
    requiredConnectedFactionIdsSorted: requiredConnectedFactionIdsSorted,
    gpIdsSorted: gpIdsSorted,
    neighbours: neighbours,
    landmassIds: landmassIds,
    seaBoundLocalIds: seaBoundLocalIds,
    allProvinceIdsSorted: allProvinceIdsSorted,
    maxStableScans: maxRounds,
  );
  if (solved) {
    return true;
  }

  return _allRequiredFactionsConnected(
        owners,
        requiredConnectedFactionIdsSorted,
        neighbours,
      ) &&
      _allGpsSatisfyHardRules(
        owners,
        gpIdsSorted,
        neighbours,
        landmassIds,
        seaBoundLocalIds,
      );
}

/// Backward-compatible wrapper retained for GP-only callers/tests.
bool repairGpLandOwnershipMutating({
  required Map<String, String> owners,
  required List<String> gpIdsSorted,
  required Map<String, Set<String>> neighbours,
  required Map<String, int> landmassIds,
  required Set<String> seaBoundLocalIds,
  required List<String> allProvinceIdsSorted,
  int maxRounds = kGpLandConnectivityRepairRounds,
}) => repairFactionLandOwnershipMutating(
  owners: owners,
  requiredConnectedFactionIdsSorted: gpIdsSorted,
  gpIdsSorted: gpIdsSorted,
  neighbours: neighbours,
  landmassIds: landmassIds,
  seaBoundLocalIds: seaBoundLocalIds,
  allProvinceIdsSorted: allProvinceIdsSorted,
  maxRounds: maxRounds,
);
