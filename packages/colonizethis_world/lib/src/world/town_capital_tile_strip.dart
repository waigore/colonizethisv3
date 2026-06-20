// SPEC/game/tile-map-and-generation.md § Town/capital occupancy.

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'game_world_mutations.dart';
import 'province_lookup.dart';

/// Every player / minor / tribe capital tile and every province [Province.townTileKey].
/// Used to forbid resources and extraction improvements on those tiles only
/// (roads / rail / ports remain). SPEC/game/tile-map-and-generation.md.
Set<String> collectTownAndCapitalTileKeys(Game game) {
  final keys = <String>{};
  for (final p in game.players) {
    final c = p.capitalTile;
    if (c != null) keys.add(c.toTileKey());
  }
  for (final m in game.minorNations) {
    final c = m.capitalTile;
    if (c != null) keys.add(c.toTileKey());
  }
  for (final t in game.tribes) {
    final c = t.capitalTile;
    if (c != null) keys.add(c.toTileKey());
  }
  for (final p in game.worldState.allProvinces()) {
    final tk = p.townTileKey;
    if (tk != null && tk.isNotEmpty) keys.add(tk);
  }
  return keys;
}

/// Clears static map resource and [WorldState.resourceByTileKey] entries, and sets
/// extraction improvement to 0 for each key. Does **not** change road/port/rail levels.
///
/// When [tileMapByRegion] is null, only [Game.worldState] is updated (map views may be
/// stale until callers refresh).
(Game game, Map<String, TileMapResult>? tileMapByRegion)
stripResourcesAndExtractionImprovementsOnTileKeys(
  Game game,
  Map<String, TileMapResult>? tileMapByRegion,
  Iterable<String> tileKeys,
) {
  var ws = game.worldState;
  var tileState = ws.tileState;
  final resMap = Map<String, String>.from(ws.resourceByTileKey);
  final maps = tileMapByRegion != null
      ? Map<String, TileMapResult>.from(tileMapByRegion)
      : null;

  for (final key in tileKeys) {
    final parsed = parseTileKeyCoordinates(key);
    if (parsed == null) continue;

    if (maps != null) {
      final map = maps[parsed.regionId];
      if (map?.resourceGrid != null) {
        maps[parsed.regionId] = map!.withResourceAt(parsed.x, parsed.y, null);
      }
    }
    resMap.remove(key);
    tileState = tileState.setImprovement(key, 0);
  }

  final nextGame = game.updateWorldState(
    (ws) => ws.copyWith(tileState: tileState, resourceByTileKey: resMap),
  );
  return (nextGame, maps);
}
