// SPEC/game/game-setup.md § GP land connectivity repair.
// Old World only: 1:1 swaps so each GP's provinces are one P–P component.

/// Setup failed after maximum Old World assignment attempts and connectivity repair.
/// [reasonCode] is `gp_land_connectivity_exhausted` per SPEC/game/game-setup.md.
class GameSetupConnectivityFailure implements Exception {
  GameSetupConnectivityFailure(this.message, {this.reasonCode = 'gp_land_connectivity_exhausted'});

  final String message;
  final String reasonCode;

  @override
  String toString() => 'GameSetupConnectivityFailure($reasonCode): $message';
}

/// Maximum repair rounds per assignment attempt (SPEC/game/game-setup.md).
const kGpLandConnectivityRepairRounds = 10;

/// Maximum full Old World assignment retries on the same map (implementation cap).
const kMaxOldWorldAssignmentAttempts = 256;

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

bool _tryApplyFirstLegalSwap(
  Map<String, String> owners,
  String disconnectedGp,
  List<String> gpIdsSorted,
  Map<String, Set<String>> neighbours,
  Map<String, int> landmassIds,
  Set<String> seaBoundLocalIds,
  List<String> allProvinceIdsSorted,
) {
  final mine = owners.entries
      .where((e) => e.value == disconnectedGp)
      .map((e) => e.key)
      .toList()
    ..sort();

  for (final a in mine) {
    for (final b in allProvinceIdsSorted) {
      if (a == b) continue;
      final ob = owners[b];
      if (ob == null) continue;
      if (ob == disconnectedGp) continue;

      final oa = owners[a]!;
      owners[a] = ob;
      owners[b] = oa;

      final ok = _allGpsSatisfyHardRules(
        owners,
        gpIdsSorted,
        neighbours,
        landmassIds,
        seaBoundLocalIds,
      );

      if (!ok) {
        owners[a] = oa;
        owners[b] = ob;
        continue;
      }
      return true;
    }
  }
  return false;
}

/// Two sequential 1:1 exchanges on four distinct provinces; legality checked only after both.
/// See SPEC/game/game-setup.md § GP land connectivity repair (compound repair).
bool _tryApplyCompoundTwoExchange(
  Map<String, String> owners,
  String disconnectedGp,
  List<String> gpIdsSorted,
  Map<String, Set<String>> neighbours,
  Map<String, int> landmassIds,
  Set<String> seaBoundLocalIds,
  List<String> allProvinceIdsSorted,
) {
  final mine = owners.entries
      .where((e) => e.value == disconnectedGp)
      .map((e) => e.key)
      .toList()
    ..sort();

  for (final a in mine) {
    for (final b in allProvinceIdsSorted) {
      if (a == b) continue;
      final ob = owners[b];
      if (ob == null || ob == disconnectedGp) continue;
      final oa = owners[a]!;
      owners[a] = ob;
      owners[b] = oa;

      for (final c in allProvinceIdsSorted) {
        if (c == a || c == b) continue;
        for (final d in allProvinceIdsSorted) {
          if (d == a || d == b || c == d) continue;
          final oc = owners[c]!;
          final od = owners[d]!;
          owners[c] = od;
          owners[d] = oc;
          final ok = _allGpsSatisfyHardRules(
            owners,
            gpIdsSorted,
            neighbours,
            landmassIds,
            seaBoundLocalIds,
          );
          if (ok) {
            return true;
          }
          owners[c] = oc;
          owners[d] = od;
        }
      }

      owners[a] = oa;
      owners[b] = ob;
    }
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

  /// Inner sweeps per round so multiple 1:1 swaps can chain before the next round.
  const maxInnerSweepsPerRound = 200;

  for (var round = 0; round < maxRounds; round++) {
    if (_allGpsSatisfyHardRules(
      owners,
      gpIdsSorted,
      neighbours,
      landmassIds,
      seaBoundLocalIds,
    )) {
      return true;
    }

    var roundMadeSwap = false;
    for (var inner = 0; inner < maxInnerSweepsPerRound; inner++) {
      var sweepMadeSwap = false;
      for (final gp in gpIdsSorted) {
        if (gpProvincesAreLandConnected(gp, owners, neighbours)) continue;
        final fixed = _tryApplyFirstLegalSwap(
          owners,
          gp,
          gpIdsSorted,
          neighbours,
          landmassIds,
          seaBoundLocalIds,
          allProvinceIdsSorted,
        ) ||
            _tryApplyCompoundTwoExchange(
              owners,
              gp,
              gpIdsSorted,
              neighbours,
              landmassIds,
              seaBoundLocalIds,
              allProvinceIdsSorted,
            );
        if (fixed) {
          sweepMadeSwap = true;
          roundMadeSwap = true;
        }
      }
      if (_allGpsSatisfyHardRules(
        owners,
        gpIdsSorted,
        neighbours,
        landmassIds,
        seaBoundLocalIds,
      )) {
        return true;
      }
      if (!sweepMadeSwap) break;
    }

    if (!roundMadeSwap) break;
  }

  return _allGpsSatisfyHardRules(
    owners,
    gpIdsSorted,
    neighbours,
    landmassIds,
    seaBoundLocalIds,
  );
}
