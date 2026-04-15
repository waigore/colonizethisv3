// SPEC/game/game-setup.md § GP land connectivity repair.
// Old World only: 1:1 swaps so each GP's provinces are one P–P component.

/// Setup failed after maximum Old World assignment attempts and connectivity repair.
/// [reasonCode] is `gp_land_connectivity_exhausted` per SPEC/game/game-setup.md.
class GameSetupConnectivityFailure implements Exception {
  GameSetupConnectivityFailure(
    this.message, {
    this.reasonCode = 'gp_land_connectivity_exhausted',
  });

  final String message;
  final String reasonCode;

  @override
  String toString() => 'GameSetupConnectivityFailure($reasonCode): $message';
}

/// Maximum repair rounds per assignment attempt (SPEC/game/game-setup.md).
const kGpLandConnectivityRepairRounds = 10;
const _kSwapStateSearchDepthLimit = 3;
const _kSwapStateBranchLimit = 48;

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
    if (!gpProvincesAreLandConnected(gp, owners, neighbours)) return false;
    if (!_gpOneLandmass(gp, owners, landmassIds)) return false;
    if (!_gpHasSeaBoundProvince(gp, owners, seaBoundLocalIds)) return false;
  }
  return true;
}

String _ownerStateKey(
  Map<String, String> owners,
  List<String> allProvinceIdsSorted,
) => allProvinceIdsSorted.map((id) => owners[id] ?? '').join('|');

Iterable<(String a, String b)> _candidateSameLandmassSwaps({
  required Map<String, String> owners,
  required List<String> gpIdsSorted,
  required Map<String, Set<String>> neighbours,
  required Map<String, int> landmassIds,
  required List<String> allProvinceIdsSorted,
}) sync* {
  final gpSet = gpIdsSorted.toSet();
  final disconnectedGps = <String>[
    for (final gpId in gpIdsSorted)
      if (!gpProvincesAreLandConnected(gpId, owners, neighbours)) gpId,
  ];
  final primaryGp = disconnectedGps.isEmpty
      ? gpIdsSorted.first
      : disconnectedGps.first;
  final ownedByGp = allProvinceIdsSorted.where((id) => owners[id] == primaryGp);
  var yielded = 0;
  for (final a in ownedByGp) {
    final landmass = landmassIds[a];
    if (landmass == null) continue;
    for (final b in allProvinceIdsSorted) {
      if (a == b) continue;
      if (landmassIds[b] != landmass) continue;
      final ownerB = owners[b];
      if (ownerB == null || ownerB == primaryGp) continue;
      if (!gpSet.contains(ownerB) && !ownerB.startsWith('minor')) continue;
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
  required List<String> gpIdsSorted,
  required Map<String, Set<String>> neighbours,
  required Map<String, int> landmassIds,
  required Set<String> seaBoundLocalIds,
  required List<String> allProvinceIdsSorted,
  required Set<String> visited,
  required int depth,
}) {
  if (_allGpsSatisfyHardRules(
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
    gpIdsSorted: gpIdsSorted,
    neighbours: neighbours,
    landmassIds: landmassIds,
    allProvinceIdsSorted: allProvinceIdsSorted,
  )) {
    final a = swap.$1;
    final b = swap.$2;
    final ownerA = owners[a]!;
    final ownerB = owners[b]!;
    owners[a] = ownerB;
    owners[b] = ownerA;
    final keepSearching =
        _gpOneLandmass(ownerA, owners, landmassIds) &&
        _gpHasSeaBoundProvince(ownerA, owners, seaBoundLocalIds);
    final otherIsGp = gpIdsSorted.contains(ownerB);
    final keepOther =
        !otherIsGp ||
        (_gpOneLandmass(ownerB, owners, landmassIds) &&
            _gpHasSeaBoundProvince(ownerB, owners, seaBoundLocalIds));
    if (keepSearching && keepOther) {
      final solved = _dfsSwapStateSearch(
        owners: owners,
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
bool repairGpLandOwnershipMutating({
  required Map<String, String> owners,
  required List<String> gpIdsSorted,
  required Map<String, Set<String>> neighbours,
  required Map<String, int> landmassIds,
  required Set<String> seaBoundLocalIds,
  required List<String> allProvinceIdsSorted,
  int maxRounds = kGpLandConnectivityRepairRounds,
}) {
  if (_allGpsSatisfyHardRules(
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

  return _allGpsSatisfyHardRules(
    owners,
    gpIdsSorted,
    neighbours,
    landmassIds,
    seaBoundLocalIds,
  );
}
