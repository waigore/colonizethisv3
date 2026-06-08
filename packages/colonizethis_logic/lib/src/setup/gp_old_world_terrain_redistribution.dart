// SPEC/game/tile-map-and-generation.md; SPEC/program/game-setup-pipeline.md (§7d.terrain).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'setup_logging.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../constants.dart';
import 'package:colonizethis_world/src/world/province_lookup.dart';
import 'town_capital_occupancy.dart';

/// Salt for deterministic tie-breaks when assigning Hamilton +1 remainders.
/// ASCII "TRRN" packed (issue #1872).
const int kGpOwTerrainRedistributionSalt = 0x5452524e;

String _owTileKey(String localProvinceId, int x, int y) => CapitalTile.tileKey(
  kRegionOldWorld,
  ProvinceId.full(kRegionOldWorld, localProvinceId),
  x,
  y,
);

Map<String, String> _ownerByLocalProvinceId(Game game) {
  final m = <String, String>{};
  for (final p in game.worldState.provincesForRegion(kRegionOldWorld)) {
    m[ProvinceId.localIdFrom(p.id)] = p.ownerId ?? '';
  }
  return m;
}

bool _isGpId(String id, Set<String> gpIds) => gpIds.contains(id);

/// In-scope: GP-owned Old World land tiles excluding town/capital keys.
/// Sorted by player slot order, then [y], then [x] for deterministic application.
class _GpOwEligibleTile {
  const _GpOwEligibleTile({
    required this.x,
    required this.y,
    required this.gpId,
  });

  final int x;
  final int y;
  final String gpId;
}

List<_GpOwEligibleTile> _collectEligibleTilesSorted({
  required TileMapResult map,
  required List<String> gpIdsSorted,
  required Set<String> gpIds,
  required Map<String, String> ownerByLocal,
  required Set<String> forbidden,
}) {
  final gpIndex = <String, int>{
    for (var i = 0; i < gpIdsSorted.length; i++) gpIdsSorted[i]: i,
  };
  final out = <_GpOwEligibleTile>[];
  for (var y = 0; y < map.height; y++) {
    for (var x = 0; x < map.width; x++) {
      final local = map.cell(x, y);
      final owner = ownerByLocal[local];
      if (owner == null || !_isGpId(owner, gpIds)) continue;
      if (map.terrainAt(x, y) == null) continue;
      final key = _owTileKey(local, x, y);
      if (forbidden.contains(key)) continue;
      out.add(_GpOwEligibleTile(x: x, y: y, gpId: owner));
    }
  }
  out.sort((a, b) {
    final ia = gpIndex[a.gpId] ?? 999;
    final ib = gpIndex[b.gpId] ?? 999;
    final c = ia.compareTo(ib);
    if (c != 0) return c;
    final cy = a.y.compareTo(b.y);
    if (cy != 0) return cy;
    return a.x.compareTo(b.x);
  });
  return out;
}

Map<String, int> _eligibleLandCountsByGp(
  List<_GpOwEligibleTile> tiles,
  List<String> gpIdsSorted,
) {
  final m = <String, int>{for (final g in gpIdsSorted) g: 0};
  for (final t in tiles) {
    m[t.gpId] = (m[t.gpId] ?? 0) + 1;
  }
  return m;
}

Map<TerrainType, int> _countTerrainOnEligibleTiles({
  required TileMapResult map,
  required List<_GpOwEligibleTile> tiles,
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
Map<String, int> _hamiltonTargetsForType({
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
      final ha = Object.hash(
        setupSeedBase,
        kGpOwTerrainRedistributionSalt,
        tieTerrainIndex,
        nT,
        a,
      );
      final hb = Object.hash(
        setupSeedBase,
        kGpOwTerrainRedistributionSalt,
        tieTerrainIndex,
        nT,
        b,
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

double _fairnessMaxAbsFracDeviation({
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

/// Best-effort GP Old World terrain balancing after §7d.strip and before §7d.redist
/// resource redistribution. Never throws for terrain fairness; see SPEC/program/game-setup-pipeline.md.
({Game game, TileMapResult tileMap, double fairnessMaxAbsFracDeviation})
applyGreatPowerOldWorldTerrainRedistribution({
  required Game game,
  required TileMapResult tileMapOldWorld,
  required int setupSeedBase,
}) {
  final terrainGrid = tileMapOldWorld.terrainGrid;
  final resGrid = tileMapOldWorld.resourceGrid;
  if (terrainGrid == null || resGrid == null) {
    setupLog.i(
      'skip GP Old World terrain redistribution (missing terrain or resource grid)',
    );
    return (game: game, tileMap: tileMapOldWorld, fairnessMaxAbsFracDeviation: 0);
  }

  final gpIdsSorted = game.players.map((p) => p.id).toList();
  final gpIds = gpIdsSorted.toSet();
  if (gpIdsSorted.isEmpty) {
    return (game: game, tileMap: tileMapOldWorld, fairnessMaxAbsFracDeviation: 0);
  }

  final ownerByLocal = _ownerByLocalProvinceId(game);
  final forbidden = collectTownAndCapitalTileKeys(game);
  final tiles = _collectEligibleTilesSorted(
    map: tileMapOldWorld,
    gpIdsSorted: gpIdsSorted,
    gpIds: gpIds,
    ownerByLocal: ownerByLocal,
    forbidden: forbidden,
  );
  if (tiles.isEmpty) {
    setupLog.i('GP Old World terrain redistribution: no eligible GP land tiles');
    return (game: game, tileMap: tileMapOldWorld, fairnessMaxAbsFracDeviation: 0);
  }

  final wByGp = _eligibleLandCountsByGp(tiles, gpIdsSorted);
  final nTGlobal = _countTerrainOnEligibleTiles(map: tileMapOldWorld, tiles: tiles);

  final targetByGpTerrain = <String, Map<TerrainType, int>>{
    for (final g in gpIdsSorted) g: <TerrainType, int>{},
  };
  for (final t in TerrainType.values) {
    final nT = nTGlobal[t] ?? 0;
    if (nT <= 0) continue;
    final perGp = _hamiltonTargetsForType(
      nT: nT,
      gpIdsSorted: gpIdsSorted,
      wByGp: wByGp,
      tieTerrainIndex: t.index,
      setupSeedBase: setupSeedBase,
    );
    for (final g in gpIdsSorted) {
      targetByGpTerrain[g]![t] = perGp[g] ?? 0;
    }
  }

  final sequence = <TerrainType>[];
  for (final g in gpIdsSorted) {
    final row = targetByGpTerrain[g]!;
    for (final t in TerrainType.values) {
      final c = row[t] ?? 0;
      for (var i = 0; i < c; i++) {
        sequence.add(t);
      }
    }
  }

  if (sequence.length != tiles.length) {
    setupLog.e(
      'logic: GP OW terrain redistribution internal length mismatch '
      'seq=${sequence.length} tiles=${tiles.length} — leaving map unchanged',
    );
    return (game: game, tileMap: tileMapOldWorld, fairnessMaxAbsFracDeviation: 0);
  }

  final nextTerrain = <List<TerrainType?>>[
    for (var row = 0; row < tileMapOldWorld.height; row++)
      List<TerrainType?>.from(terrainGrid[row]),
  ];
  for (var i = 0; i < tiles.length; i++) {
    final c = tiles[i];
    nextTerrain[c.y][c.x] = sequence[i];
  }
  var map = TileMapResult(
    width: tileMapOldWorld.width,
    height: tileMapOldWorld.height,
    grid: tileMapOldWorld.grid,
    terrainGrid: nextTerrain,
    resourceGrid: resGrid,
  );

  final achieved = <String, Map<TerrainType, int>>{
    for (final g in gpIdsSorted) g: {},
  };
  for (final c in tiles) {
    final ter = map.terrainAt(c.x, c.y);
    if (ter == null) continue;
    final row = achieved[c.gpId]!;
    row[ter] = (row[ter] ?? 0) + 1;
  }

  final fairness = _fairnessMaxAbsFracDeviation(
    gpIdsSorted: gpIdsSorted,
    wByGp: wByGp,
    nTGlobal: nTGlobal,
    achieved: achieved,
  );

  setupLog.i(
    'GP Old World terrain redistribution complete '
    'eligibleTiles=${tiles.length} fairnessMaxAbsFracDev=$fairness '
    '(diagnostic; setup does not fail on terrain fairness)',
  );

  return (game: game, tileMap: map, fairnessMaxAbsFracDeviation: fairness);
}

/// Test helper: counts [terrain] on eligible GP Old World land tiles (excl. town/capital).
int countTerrainOnGpOldWorldEligibleTiles({
  required Game game,
  required TileMapResult map,
  required TerrainType terrain,
}) {
  final gpIdsSorted = game.players.map((p) => p.id).toList();
  final gpIds = gpIdsSorted.toSet();
  final ownerByLocal = _ownerByLocalProvinceId(game);
  final forbidden = collectTownAndCapitalTileKeys(game);
  final tiles = _collectEligibleTilesSorted(
    map: map,
    gpIdsSorted: gpIdsSorted,
    gpIds: gpIds,
    ownerByLocal: ownerByLocal,
    forbidden: forbidden,
  );
  var n = 0;
  for (final t in tiles) {
    if (map.terrainAt(t.x, t.y) == terrain) n++;
  }
  return n;
}
