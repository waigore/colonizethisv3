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

/// Maximum repair rounds per assignment attempt (SPEC/game/game-setup.md).
const kGpLandConnectivityRepairRounds = 10;
const _kSwapStateSearchDepthLimit = 6;
const _kSwapStateBranchLimit = 256;

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

String _ownerStateKey(
  Map<String, String> owners,
  List<String> allProvinceIdsSorted,
) => allProvinceIdsSorted.map((id) => owners[id] ?? '').join('|');

Iterable<(String a, String b)> _candidateSameLandmassSwaps({
  required Map<String, String> owners,
  required List<String> requiredConnectedFactionIdsSorted,
  required Map<String, Set<String>> neighbours,
  required Map<String, int> landmassIds,
  required List<String> allProvinceIdsSorted,
}) sync* {
  final disconnectedFactions = <String>[
    for (final factionId in requiredConnectedFactionIdsSorted)
      if (!factionProvincesAreLandConnected(factionId, owners, neighbours))
        factionId,
  ];
  final primaryFaction = disconnectedFactions.isEmpty
      ? requiredConnectedFactionIdsSorted.first
      : disconnectedFactions.first;
  final ownedByPrimary = allProvinceIdsSorted.where(
    (id) => owners[id] == primaryFaction,
  );
  var yielded = 0;
  for (final a in ownedByPrimary) {
    final landmass = landmassIds[a];
    if (landmass == null) continue;
    for (final b in allProvinceIdsSorted) {
      if (a == b) continue;
      if (landmassIds[b] != landmass) continue;
      final ownerB = owners[b];
      if (ownerB == null || ownerB == primaryFaction) continue;
      if (ownerB.isEmpty) continue;
      yield (a, b);
      yielded++;
      if (yielded >= _kSwapStateBranchLimit) {
        return;
      }
    }
  }
}

bool _dfsSwapStateSearch({
  required Map<String, String> owners,
  required List<String> requiredConnectedFactionIdsSorted,
  required List<String> gpIdsSorted,
  required Map<String, Set<String>> neighbours,
  required Map<String, int> landmassIds,
  required Set<String> seaBoundLocalIds,
  required List<String> allProvinceIdsSorted,
  required Set<String> visited,
  required int depth,
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
  if (depth >= _kSwapStateSearchDepthLimit) {
    return false;
  }
  final stateKey = _ownerStateKey(owners, allProvinceIdsSorted);
  if (!visited.add(stateKey)) {
    return false;
  }
  for (final swap in _candidateSameLandmassSwaps(
    owners: owners,
    requiredConnectedFactionIdsSorted: requiredConnectedFactionIdsSorted,
    neighbours: neighbours,
    landmassIds: landmassIds,
    allProvinceIdsSorted: allProvinceIdsSorted,
  )) {
    final a = swap.$1;
    final b = swap.$2;
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
    var keepSearching = true;
    if (ownerAConnectedBefore &&
        !factionProvincesAreLandConnected(ownerA, owners, neighbours)) {
      keepSearching = false;
    }
    if (keepSearching &&
        ownerBConnectedBefore &&
        !factionProvincesAreLandConnected(ownerB, owners, neighbours)) {
      keepSearching = false;
    }
    final ownerAIsGp = gpIdsSorted.contains(ownerA);
    if (keepSearching && ownerAIsGp) {
      keepSearching =
          _gpOneLandmass(ownerA, owners, landmassIds) &&
          _gpHasSeaBoundProvince(ownerA, owners, seaBoundLocalIds);
    }
    final ownerBIsGp = gpIdsSorted.contains(ownerB);
    if (keepSearching && ownerBIsGp) {
      keepSearching =
          _gpOneLandmass(ownerB, owners, landmassIds) &&
          _gpHasSeaBoundProvince(ownerB, owners, seaBoundLocalIds);
    }
    if (keepSearching) {
      final solved = _dfsSwapStateSearch(
        owners: owners,
        requiredConnectedFactionIdsSorted: requiredConnectedFactionIdsSorted,
        gpIdsSorted: gpIdsSorted,
        neighbours: neighbours,
        landmassIds: landmassIds,
        seaBoundLocalIds: seaBoundLocalIds,
        allProvinceIdsSorted: allProvinceIdsSorted,
        visited: visited,
        depth: depth + 1,
      );
      if (solved) {
        return true;
      }
    }
    owners[a] = ownerA;
    owners[b] = ownerB;
  }
  return false;
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

  for (var round = 0; round < maxRounds; round++) {
    final solved = _dfsSwapStateSearch(
      owners: owners,
      requiredConnectedFactionIdsSorted: requiredConnectedFactionIdsSorted,
      gpIdsSorted: gpIdsSorted,
      neighbours: neighbours,
      landmassIds: landmassIds,
      seaBoundLocalIds: seaBoundLocalIds,
      allProvinceIdsSorted: allProvinceIdsSorted,
      visited: <String>{},
      depth: 0,
    );
    if (solved) {
      return true;
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
