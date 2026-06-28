// SPEC/game/capital-and-connectivity.md § Init town roads; SPEC/program/game-setup-pipeline.md.

import 'package:colonizethis_data/colonizethis_data.dart';
import 'setup_logging.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'package:colonizethis_world/colonizethis_world.dart';
import 'grid_bfs.dart';

const int _initTownRoadLevel = 1;

/// Road BFS shares the [bfsGridParents] skeleton (grid_bfs.dart) so its
/// [kGridNeighborsCardinal4] neighbor ordering stays aligned with the capital
/// port-road `_shortestPathOnProvinceTiles` site (Refs #2391).

/// After town assignment: for each faction whose capital lies in a region listed in
/// [GameSetupConfig.initTownRoadWiringRegionIds], raise road level to at least
/// [_initTownRoadLevel] on every tile along a **global** shortest path (4-neighbor,
/// on tiles in provinces **owned by that faction only**) from each owned province’s
/// **town** to the **capital** tile, when such a path exists.
///
/// Init only — not used on capital reassignment during play.
Game applyInitTownRoadsToCapitals({
  required Game game,
  required GameSetupConfig config,
  required Map<String, TileMapResult> tileMapByRegion,
  Map<String, List<String>> bootstrapGrainTileKeysByPlayerId = const {},
}) {
  if (config.initTownRoadWiringRegionIds.isEmpty) {
    return game;
  }

  final ws = game.worldState;
  final toRaise = <String>{};

  void collectForFaction(String factionId, CapitalTile? capital) {
    if (capital == null) return;
    final regionId = capital.regionId;
    if (!config.initTownRoadWiringRegionIds.contains(regionId)) {
      return;
    }
    final map = tileMapByRegion[regionId];
    if (map == null) {
      setupLog.w('init town roads skip regionId=$regionId (no tile map)');
      return;
    }

    final capitalKey = capital.toTileKey();
    final allowed = _allowedTileKeysForFaction(ws, regionId, factionId);
    if (allowed.isEmpty || !allowed.contains(capitalKey)) {
      return;
    }

    final coordToKey = _coordToTileKey(ws, regionId);
    final parent = _bfsParentsFromCapital(
      capitalKey: capitalKey,
      allowed: allowed,
      coordToKey: coordToKey,
      mapWidth: map.width,
      mapHeight: map.height,
    );

    for (final p in ws.provincesForRegion(regionId)) {
      if (p.ownerId != factionId) continue;
      final tk = p.townTileKey;
      if (tk == null) continue;
      if (!parent.containsKey(tk) && tk != capitalKey) {
        continue;
      }
      _addPathTilesToSet(
        townOrCapitalKey: tk,
        capitalKey: capitalKey,
        parent: parent,
        out: toRaise,
      );
    }
  }

  for (final p in game.players) {
    collectForFaction(p.id, p.capitalTile);
    final extra = bootstrapGrainTileKeysByPlayerId[p.id];
    if (extra == null) continue;
    final cap = p.capitalTile;
    if (cap == null) continue;
    final regionId = cap.regionId;
    if (!config.initTownRoadWiringRegionIds.contains(regionId)) continue;
    final map = tileMapByRegion[regionId];
    if (map == null) continue;
    final capitalKey = cap.toTileKey();
    final allowed = _allowedTileKeysForFaction(ws, regionId, p.id);
    if (allowed.isEmpty || !allowed.contains(capitalKey)) continue;
    final coordToKey = _coordToTileKey(ws, regionId);
    final parent = _bfsParentsFromCapital(
      capitalKey: capitalKey,
      allowed: allowed,
      coordToKey: coordToKey,
      mapWidth: map.width,
      mapHeight: map.height,
    );
    for (final farmKey in extra) {
      if (!parent.containsKey(farmKey) && farmKey != capitalKey) {
        continue;
      }
      _addPathTilesToSet(
        townOrCapitalKey: farmKey,
        capitalKey: capitalKey,
        parent: parent,
        out: toRaise,
      );
    }
  }
  for (final m in game.minorNations) {
    collectForFaction(m.id, m.capitalTile);
  }
  for (final t in game.tribes) {
    collectForFaction(t.id, t.capitalTile);
  }

  if (toRaise.isEmpty) {
    return game;
  }

  var tileState = ws.tileState;
  for (final key in toRaise) {
    tileState = _raiseRoadAtLeast(tileState, key, _initTownRoadLevel);
  }

  setupLog.i(
    'init town roads raised $_initTownRoadLevel on ${toRaise.length} tile(s)',
  );
  return game.withTileState(tileState);
}

Map<String, String> _coordToTileKey(WorldState ws, String regionId) {
  final m = <String, String>{};
  final byProvince = ws.tileKeysByRegionAndProvince[regionId];
  if (byProvince == null) return m;
  for (final list in byProvince.values) {
    for (final tk in list) {
      final coords = parseTileKeyCoordinates(tk);
      if (coords == null || coords.regionId != regionId) continue;
      m[gridCoordKey(coords.x, coords.y)] = tk;
    }
  }
  return m;
}

Set<String> _allowedTileKeysForFaction(
  WorldState ws,
  String regionId,
  String factionId,
) {
  final keys = <String>{};
  final byProvince = ws.tileKeysByRegionAndProvince[regionId];
  if (byProvince == null) return keys;
  for (final p in ws.provincesForRegion(regionId)) {
    if (p.ownerId != factionId) continue;
    final list = byProvince[p.id];
    if (list == null) continue;
    keys.addAll(list);
  }
  return keys;
}

/// Returns map tileKey -> predecessor tileKey toward [capitalKey]. [capitalKey] maps to
/// itself (identity). Unreachable tiles are absent except the capital.
///
/// Delegates the 4-neighbor breadth-first walk to the shared [bfsGridParents]
/// skeleton (grid_bfs.dart) over coordinates, then maps the coord-keyed parent
/// map back onto canonical tile keys via [coordToKey].
Map<String, String> _bfsParentsFromCapital({
  required String capitalKey,
  required Set<String> allowed,
  required Map<String, String> coordToKey,
  required int mapWidth,
  required int mapHeight,
}) {
  final capitalXY = _parseTileKeyXY(capitalKey);
  if (capitalXY == null) return <String, String>{capitalKey: capitalKey};
  final (capX, capY) = capitalXY;

  final coordParents = bfsGridParents(
    startX: capX,
    startY: capY,
    width: mapWidth,
    height: mapHeight,
    passable: (x, y) {
      final tile = coordToKey[gridCoordKey(x, y)];
      return tile != null && allowed.contains(tile);
    },
  );

  final parent = <String, String>{capitalKey: capitalKey};
  for (final entry in coordParents.entries) {
    final tile = coordToKey[entry.key];
    if (tile == null) continue;
    final pc = entry.value;
    final parentTile = coordToKey[gridCoordKey(pc.$1, pc.$2)];
    if (parentTile == null) continue;
    parent[tile] = parentTile;
  }
  return parent;
}

(int, int)? _parseTileKeyXY(String tileKey) {
  final coords = parseTileKeyCoordinates(tileKey);
  if (coords == null) return null;
  return (coords.x, coords.y);
}

void _addPathTilesToSet({
  required String townOrCapitalKey,
  required String capitalKey,
  required Map<String, String> parent,
  required Set<String> out,
}) {
  var k = townOrCapitalKey;
  while (true) {
    out.add(k);
    if (k == capitalKey) break;
    final pr = parent[k];
    if (pr == null || pr == k) break;
    k = pr;
  }
}

TileMapState _raiseRoadAtLeast(
  TileMapState tileState,
  String tileKey,
  int minLevel,
) {
  final current = tileState.roadLevel(tileKey);
  if (current >= minLevel) return tileState;
  return tileState.setRoadLevel(tileKey, minLevel);
}
