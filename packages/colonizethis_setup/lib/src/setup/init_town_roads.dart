// SPEC/game/capital-and-connectivity.md § Init town roads; SPEC/program/game-setup-pipeline.md.

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_world/colonizethis_world.dart';

import 'setup_logging.dart';
import 'setup_road_wiring.dart';

const int _initTownRoadLevel = 1;

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
    final allowed = ownedTileKeysForFaction(ws, regionId, factionId);
    if (allowed.isEmpty || !allowed.contains(capitalKey)) {
      return;
    }

    final coordToKey = coordToTileKeyForRegion(ws, regionId);
    final parent = bfsParentsFromTileKey(
      startTileKey: capitalKey,
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
      toRaise.addAll(
        pathTileKeysTowardHub(
          fromTileKey: tk,
          hubTileKey: capitalKey,
          parent: parent,
        ),
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
    final allowed = ownedTileKeysForFaction(ws, regionId, p.id);
    if (allowed.isEmpty || !allowed.contains(capitalKey)) continue;
    final coordToKey = coordToTileKeyForRegion(ws, regionId);
    final parent = bfsParentsFromTileKey(
      startTileKey: capitalKey,
      allowed: allowed,
      coordToKey: coordToKey,
      mapWidth: map.width,
      mapHeight: map.height,
    );
    for (final farmKey in extra) {
      if (!parent.containsKey(farmKey) && farmKey != capitalKey) {
        continue;
      }
      toRaise.addAll(
        pathTileKeysTowardHub(
          fromTileKey: farmKey,
          hubTileKey: capitalKey,
          parent: parent,
        ),
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
    tileState = raiseRoadAtLeast(tileState, key, _initTownRoadLevel);
  }

  setupLog.i(
    'init town roads raised $_initTownRoadLevel on ${toRaise.length} tile(s)',
  );
  return game.withTileState(tileState);
}
