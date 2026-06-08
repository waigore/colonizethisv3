// SPEC/game/tile-map-and-generation.md § Great Power starting grain (bootstrap).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'setup_logging.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../constants.dart';
import 'package:colonizethis_world/src/world/game_world_mutations.dart';
import 'package:colonizethis_world/src/world/tile_key_coordinates.dart';
import 'town_capital_occupancy.dart';

/// Thrown when the capital province cannot host four bootstrap grain farms on land tiles.
class GreatPowerGrainBootstrapError implements Exception {
  GreatPowerGrainBootstrapError(this.message);
  final String message;

  @override
  String toString() => 'GreatPowerGrainBootstrapError: $message';
}

/// Closest **land** cells in the capital province by Manhattan distance;
/// tie-break ascending y, then x. Skips [forbiddenTileKeys] (town/capital tiles).
/// Tile keys `regionId|localId|x|y`. Exposed for tests (SPEC § Great Power starting grain).
List<String> selectGreatPowerBootstrapGrainTileKeysLandOnly({
  required TileMapResult map,
  required CapitalTile capital,
  Set<String> forbiddenTileKeys = const {},
}) {
  final regionId = capital.regionId;
  final localId = ProvinceId.isPrefixed(capital.provinceId)
      ? ProvinceId.localIdFrom(capital.provinceId)
      : capital.provinceId;
  final ranked = <(int dist, int y, int x, String key)>[];
  for (var y = 0; y < map.height; y++) {
    for (var x = 0; x < map.width; x++) {
      if (map.cell(x, y) != localId) continue;
      final dist = (x - capital.x).abs() + (y - capital.y).abs();
      final key = CapitalTile.tileKey(regionId, capital.provinceId, x, y);
      if (forbiddenTileKeys.contains(key)) continue;
      ranked.add((dist, y, x, key));
    }
  }
  ranked.sort((a, b) {
    final c = a.$1.compareTo(b.$1);
    if (c != 0) return c;
    final cy = a.$2.compareTo(b.$2);
    if (cy != 0) return cy;
    return a.$3.compareTo(b.$3);
  });
  return ranked.take(4).map((e) => e.$4).toList();
}

/// After capitals and §7d town assignment: place four `grain` / improvement 1 for each
/// Great Power in the Old World. When a chosen tile’s terrain does not allow `grain`,
/// terrain is set to **plains** so placement stays rules-legal after bootstrap
/// (deterministic post-pass; SPEC tile-map-and-generation).
///
/// When the OW map lacks [TileMapResult.terrainGrid] or [TileMapResult.resourceGrid],
/// skips bootstrap (hand-made test maps). Generated maps include both.
({
  Game game,
  TileMapResult tileMap,
  Map<String, List<String>> grainKeysByPlayerId,
})
applyGreatPowerStartingGrainBootstrap({
  required Game game,
  required TileMapResult tileMapOldWorld,
  required ResourceRules resourceRules,
}) {
  final terrain = tileMapOldWorld.terrainGrid;
  final resGrid = tileMapOldWorld.resourceGrid;
  if (terrain == null || resGrid == null) {
    setupLog.i(
      'skip Great Power grain bootstrap (missing terrain or resource grid)',
    );
    return (
      game: game,
      tileMap: tileMapOldWorld,
      grainKeysByPlayerId: const {},
    );
  }

  final forbidden = collectTownAndCapitalTileKeys(game);

  var map = tileMapOldWorld;
  var ws = game.worldState;
  final keysOut = <String, List<String>>{};

  for (final player in game.players) {
    final cap = player.capitalTile;
    final capProv = player.capitalProvinceId;
    if (cap == null || capProv == null) continue;
    if (cap.regionId != kRegionOldWorld) continue;

    final pickedKeys = selectGreatPowerBootstrapGrainTileKeysLandOnly(
      map: map,
      capital: cap,
      forbiddenTileKeys: forbidden,
    );
    if (pickedKeys.length < 4) {
      throw GreatPowerGrainBootstrapError(
        'player ${player.id} capital province $capProv has only ${pickedKeys.length} '
        'eligible land tiles excluding town/capital (need 4)',
      );
    }

    keysOut[player.id] = List<String>.from(pickedKeys);
    var tileState = ws.tileState;
    final resMap = Map<String, String>.from(ws.resourceByTileKey);
    for (final key in pickedKeys) {
      final parsed = parseTileKeyCoordinates(key);
      if (parsed == null) continue;
      final t = map.terrainAt(parsed.x, parsed.y);
      final allowedRegion = resourceRules.isAllowedInRegion(
        Resource.grain,
        cap.regionId,
      );
      final allowedTerrain =
          t != null && resourceRules.isAllowedOnTerrain(Resource.grain, t);
      if (!allowedRegion || !allowedTerrain) {
        map = map.withTerrainAt(parsed.x, parsed.y, TerrainType.plains);
      }
      map = map.withResourceAt(parsed.x, parsed.y, Resource.grain);
      tileState = tileState.setImprovement(key, 1);
      resMap[key] = Resource.grain.name;
    }
    ws = ws.copyWith(tileState: tileState, resourceByTileKey: resMap);
  }

  return (
    game: game.withWorldState(ws),
    tileMap: map,
    grainKeysByPlayerId: keysOut,
  );
}
