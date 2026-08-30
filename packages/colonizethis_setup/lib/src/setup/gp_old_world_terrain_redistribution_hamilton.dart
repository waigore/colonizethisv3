// SPEC/game/tile-map-and-generation.md; SPEC/program/game-setup-pipeline.md (§7d.terrain).
// Hamilton largest-remainder targets and fairness diagnostics for GP Old World
// terrain redistribution (Refs #4349 Slice B).

import 'package:colonizethis_data/colonizethis_data.dart';

import 'gp_old_world_tile_scan.dart';
import 'seed_perturbation.dart';

/// Salt for deterministic tie-breaks when assigning Hamilton +1 remainders.
/// ASCII "TRRN" packed (issue #1872).
const int kGpOwTerrainRedistributionSalt = 0x5452524e;

Map<String, int> eligibleLandCountsByGp(
  List<GpOwLandTile> tiles,
  List<String> gpIdsSorted,
) {
  final m = <String, int>{for (final g in gpIdsSorted) g: 0};
  for (final t in tiles) {
    m[t.gpId] = (m[t.gpId] ?? 0) + 1;
  }
  return m;
}

Map<TerrainType, int> countTerrainOnEligibleTiles({
  required TileMapResult map,
  required List<GpOwLandTile> tiles,
}) {
  final m = <TerrainType, int>{};
  for (final t in tiles) {
    final ter = map.terrainAt(t.x, t.y);
    if (ter == null) continue;
    m[ter] = (m[ter] ?? 0) + 1;
  }
  return m;
}

/// Hamilton largest-remainder: integer targets per GP summing to [nT], weighted by [wByGp].
Map<String, int> hamiltonTargetsForType({
  required int nT,
  required List<String> gpIdsSorted,
  required Map<String, int> wByGp,
  required int tieTerrainIndex,
  required int setupSeedBase,
}) {
  final targets = <String, int>{for (final g in gpIdsSorted) g: 0};
  final wTotal = gpIdsSorted.fold<int>(0, (s, g) => s + (wByGp[g] ?? 0));
  if (wTotal == 0 || nT == 0) {
    return targets;
  }
  final base = <String, int>{};
  final remainder = <String, int>{};
  for (final g in gpIdsSorted) {
    final w = wByGp[g] ?? 0;
    final num = nT * w;
    base[g] = num ~/ wTotal;
    remainder[g] = num % wTotal;
  }
  final sumBase = base.values.fold<int>(0, (a, b) => a + b);
  var need = nT - sumBase;
  final order = List<String>.from(gpIdsSorted)
    ..sort((a, b) {
      final ra = remainder[a] ?? 0;
      final rb = remainder[b] ?? 0;
      final c = rb.compareTo(ra);
      if (c != 0) return c;
      final ha = perturbSeed(
        setupSeedBase,
        kGpOwTerrainRedistributionSalt,
        args: [tieTerrainIndex, nT, a],
      );
      final hb = perturbSeed(
        setupSeedBase,
        kGpOwTerrainRedistributionSalt,
        args: [tieTerrainIndex, nT, b],
      );
      final hc = ha.compareTo(hb);
      if (hc != 0) return hc;
      return a.compareTo(b);
    });
  for (final g in gpIdsSorted) {
    targets[g] = base[g] ?? 0;
  }
  for (var i = 0; i < need && i < order.length; i++) {
    final g = order[i];
    targets[g] = (targets[g] ?? 0) + 1;
  }
  return targets;
}

double fairnessMaxAbsFracDeviation({
  required List<String> gpIdsSorted,
  required Map<String, int> wByGp,
  required Map<TerrainType, int> nTGlobal,
  required Map<String, Map<TerrainType, int>> achieved,
}) {
  final wTotal = gpIdsSorted.fold<int>(0, (s, g) => s + (wByGp[g] ?? 0));
  if (wTotal == 0) return 0;
  var maxDev = 0.0;
  for (final g in gpIdsSorted) {
    final w = wByGp[g] ?? 0;
    if (w == 0) continue;
    for (final t in TerrainType.values) {
      final nT = nTGlobal[t] ?? 0;
      if (nT == 0) continue;
      final ideal = nT * w / wTotal;
      final a = (achieved[g] ?? const {})[t] ?? 0;
      final dev = (a - ideal).abs();
      if (dev > maxDev) maxDev = dev;
    }
  }
  return maxDev;
}
