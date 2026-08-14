// SPEC/game/tile-map-and-generation.md; SPEC/program/game-setup-pipeline.md (§7d.redist).
// GP Old World resource-redistribution placement-pass + quota-pool logic
// (Refs #4086 Slice B de-part).

import 'dart:math';

import 'package:colonizethis_data/colonizethis_data.dart';

import 'gp_old_world_resource_redistribution_quota_spillover.dart';
import 'gp_old_world_resource_redistribution_tile_scans.dart';
import 'gp_old_world_resource_redistribution_types.dart';
import 'seed_perturbation.dart';

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
  required List<GpOwTileInvEntry> inventory,
  required Set<String> forbidden,
}) {
  var map = mapIn;
  for (final gp in shuffled) {
    while (true) {
      if ((targets[gp] ?? 0) <= (placed[gp] ?? 0)) break;
      final key = firstLexEligibleEmptyTileForGp(
        inventory: inventory,
        r: r,
        rules: resourceRules,
        gp: gp,
        forbidden: forbidden,
        used: used,
      );
      if (key == null) break;
      map = placeResourceAtKey(map, key, r);
      used.add(key);
      placed[gp] = (placed[gp] ?? 0) + 1;
      resMap[key] = r.name;
    }
  }
  return map;
}

({TileMapResult map, Map<String, String> resMap}) redistributeOneResource({
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

  // One inventory for this resource pass (Refs #4029); `used` covers placements
  // within the pass so snapshot resource fields stay valid for emptiness checks.
  final inventory = buildGpOwTileInventory(
    map: map,
    ownerByLocal: ownerByLocal,
    gpIds: gpIds,
  );

  var totalCapacity = 0;
  for (final gp in gpIdsSorted) {
    totalCapacity += eligibleEmptyCountForGp(
      inventory: inventory,
      r: r,
      rules: resourceRules,
      gp: gp,
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
      inventory: inventory,
      forbidden: forbidden,
    );

    final sumPlaced = sumPlacedAll(placed, gpIdsSorted);
    if (sumPlaced >= nR) {
      return (map: map, resMap: resMap);
    }

    final pool = accumulateSpilloverPool(
      shuffled: shuffled,
      targets: targets,
      placed: placed,
      r: r,
      resourceRules: resourceRules,
      inventory: inventory,
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

    distributeQuotaPool(
      initialPool: pool,
      shuffled: shuffled,
      targets: targets,
      placed: placed,
      r: r,
      resourceRules: resourceRules,
      inventory: inventory,
      forbidden: forbidden,
      used: used,
      sumPlaced: sumPlaced,
      nR: nR,
    );
  }
}
