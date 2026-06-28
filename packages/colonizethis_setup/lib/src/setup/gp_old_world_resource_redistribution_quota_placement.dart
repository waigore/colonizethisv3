part of 'gp_old_world_resource_redistribution.dart';

// GP Old World resource-redistribution placement-pass + quota-pool logic,
// extracted from `gp_old_world_resource_redistribution.dart` for
// maintainability (Refs #3290 Phase 0 file-split). Behaviour-preserving move:
// this is a `part of` the redistribution library, so imports, shared tile-scan
// helpers, the `GpOldWorldResourceRedistributionInfeasibleException` type, and
// private visibility are all unchanged.

/// One pass: place resources for each GP until targets met or no eligible tile.
TileMapResult _runGpPlacementPass({
  required TileMapResult mapIn,
  required Map<String, String> resMap,
  required List<String> shuffled,
  required Map<String, int> targets,
  required Map<String, int> placed,
  required Set<String> used,
  required Resource r,
  required ResourceRules resourceRules,
  required Map<String, String> ownerByLocal,
  required Set<String> gpIds,
  required Set<String> forbidden,
}) {
  var map = mapIn;
  for (final gp in shuffled) {
    while (true) {
      if ((targets[gp] ?? 0) <= (placed[gp] ?? 0)) break;
      final key = _firstLexEligibleEmptyTileForGp(
        map: map,
        r: r,
        rules: resourceRules,
        gp: gp,
        ownerByLocal: ownerByLocal,
        gpIds: gpIds,
        forbidden: forbidden,
        used: used,
      );
      if (key == null) break;
      map = _placeResourceAtKey(map, key, r);
      used.add(key);
      placed[gp] = (placed[gp] ?? 0) + 1;
      resMap[key] = r.name;
    }
  }
  return map;
}

/// Caps targets to reachable counts; returns surplus moved into [pool].
int _accumulateSpilloverPool({
  required List<String> shuffled,
  required Map<String, int> targets,
  required Map<String, int> placed,
  required TileMapResult map,
  required Resource r,
  required ResourceRules resourceRules,
  required Map<String, String> ownerByLocal,
  required Set<String> gpIds,
  required Set<String> forbidden,
  required Set<String> used,
}) {
  var pool = 0;
  for (final gp in shuffled) {
    final tgt = targets[gp] ?? 0;
    final pl = placed[gp] ?? 0;
    final deficit = tgt - pl;
    if (deficit <= 0) continue;
    final eg = _eligibleEmptyCountForGp(
      map: map,
      r: r,
      rules: resourceRules,
      gp: gp,
      ownerByLocal: ownerByLocal,
      gpIds: gpIds,
      forbidden: forbidden,
      used: used,
    );
    final maxTarget = pl + eg;
    if (tgt <= maxTarget) continue;
    pool += tgt - maxTarget;
    targets[gp] = maxTarget;
  }
  return pool;
}

({int newPool, bool anyIncrement}) _applyOneQuotaPoolRound({
  required int pool,
  required List<String> shuffled,
  required Map<String, int> targets,
  required Map<String, int> placed,
  required TileMapResult map,
  required Resource r,
  required ResourceRules resourceRules,
  required Map<String, String> ownerByLocal,
  required Set<String> gpIds,
  required Set<String> forbidden,
  required Set<String> used,
}) {
  var p = pool;
  var moved = false;
  for (final h in shuffled) {
    if (p <= 0) break;
    final pl = placed[h] ?? 0;
    final tgt = targets[h] ?? 0;
    final eg = _eligibleEmptyCountForGp(
      map: map,
      r: r,
      rules: resourceRules,
      gp: h,
      ownerByLocal: ownerByLocal,
      gpIds: gpIds,
      forbidden: forbidden,
      used: used,
    );
    final maxTarget = pl + eg;
    if (tgt >= maxTarget) continue;
    targets[h] = tgt + 1;
    p--;
    moved = true;
  }
  return (newPool: p, anyIncrement: moved);
}

void _distributeQuotaPool({
  required int initialPool,
  required List<String> shuffled,
  required Map<String, int> targets,
  required Map<String, int> placed,
  required TileMapResult map,
  required Resource r,
  required ResourceRules resourceRules,
  required Map<String, String> ownerByLocal,
  required Set<String> gpIds,
  required Set<String> forbidden,
  required Set<String> used,
  required int sumPlaced,
  required int nR,
}) {
  var pool = initialPool;
  while (pool > 0) {
    final round = _applyOneQuotaPoolRound(
      pool: pool,
      shuffled: shuffled,
      targets: targets,
      placed: placed,
      map: map,
      r: r,
      resourceRules: resourceRules,
      ownerByLocal: ownerByLocal,
      gpIds: gpIds,
      forbidden: forbidden,
      used: used,
    );
    pool = round.newPool;
    if (!round.anyIncrement) {
      throw GpOldWorldResourceRedistributionInfeasibleException(
        resource: r,
        details:
            'cannot distribute quota pool=$pool sumPlaced=$sumPlaced nR=$nR',
      );
    }
  }
}

({TileMapResult map, Map<String, String> resMap}) _redistributeOneResource({
  required TileMapResult mapIn,
  required Map<String, String> resMapIn,
  required Resource r,
  required int nR,
  required ResourceRules resourceRules,
  required List<String> gpIdsSorted,
  required Set<String> gpIds,
  required Map<String, String> ownerByLocal,
  required Set<String> forbidden,
  required int setupSeedBase,
}) {
  var map = mapIn;
  var resMap = Map<String, String>.from(resMapIn);
  final g = gpIdsSorted.length;
  final rnd = Random(
    perturbSeed(
      setupSeedBase,
      kGpOwResourceRedistributionSalt,
      args: [r.index],
    ),
  );
  final shuffled = List<String>.from(gpIdsSorted)..shuffle(rnd);

  final base = nR ~/ g;
  final rem = nR % g;
  final targets = <String, int>{};
  for (var i = 0; i < shuffled.length; i++) {
    targets[shuffled[i]] = base + (i < rem ? 1 : 0);
  }

  final placed = <String, int>{for (final id in gpIdsSorted) id: 0};
  final used = <String>{};

  var totalCapacity = 0;
  for (final gp in gpIdsSorted) {
    totalCapacity += _eligibleEmptyCountForGp(
      map: map,
      r: r,
      rules: resourceRules,
      gp: gp,
      ownerByLocal: ownerByLocal,
      gpIds: gpIds,
      forbidden: forbidden,
      used: const {},
    );
  }
  if (nR > totalCapacity) {
    throw GpOldWorldResourceRedistributionInfeasibleException(
      resource: r,
      details:
          'N_r=$nR exceeds total terrain-eligible capacity=$totalCapacity on GP Old World tiles',
    );
  }

  while (true) {
    map = _runGpPlacementPass(
      mapIn: map,
      resMap: resMap,
      shuffled: shuffled,
      targets: targets,
      placed: placed,
      used: used,
      r: r,
      resourceRules: resourceRules,
      ownerByLocal: ownerByLocal,
      gpIds: gpIds,
      forbidden: forbidden,
    );

    final sumPlaced = _sumPlacedAll(placed, gpIdsSorted);
    if (sumPlaced >= nR) {
      return (map: map, resMap: resMap);
    }

    final pool = _accumulateSpilloverPool(
      shuffled: shuffled,
      targets: targets,
      placed: placed,
      map: map,
      r: r,
      resourceRules: resourceRules,
      ownerByLocal: ownerByLocal,
      gpIds: gpIds,
      forbidden: forbidden,
      used: used,
    );

    if (pool == 0) {
      throw GpOldWorldResourceRedistributionInfeasibleException(
        resource: r,
        details:
            'stalled with sumPlaced=$sumPlaced nR=$nR after spillover (pool=0)',
      );
    }

    _distributeQuotaPool(
      initialPool: pool,
      shuffled: shuffled,
      targets: targets,
      placed: placed,
      map: map,
      r: r,
      resourceRules: resourceRules,
      ownerByLocal: ownerByLocal,
      gpIds: gpIds,
      forbidden: forbidden,
      used: used,
      sumPlaced: sumPlaced,
      nR: nR,
    );
  }
}
