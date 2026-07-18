// SPEC/game/capital-choice-phase.md; SPEC/game/capital-and-connectivity.md § Town;
// SPEC/program/game-setup-pipeline.md — convert selected settlement tile to plains if needed.

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'package:colonizethis_world/colonizethis_world.dart';

/// If [tileKey] is already plains (or has no terrain), returns [game] unchanged.
/// Otherwise converts the cell to [TerrainType.plains] and clears resource /
/// extraction improvement on that key. Mutates [tileMapByRegion] in place when
/// conversion runs.
({Game game, bool converted}) ensureTileIsPlains({
  required Game game,
  required Map<String, TileMapResult> tileMapByRegion,
  required String tileKey,
}) {
  final parsed = parseTileKeyCoordinates(tileKey);
  if (parsed == null) {
    return (game: game, converted: false);
  }
  final map = tileMapByRegion[parsed.regionId];
  if (map == null || map.terrainGrid == null) {
    return (game: game, converted: false);
  }
  final terrain = map.terrainAt(parsed.x, parsed.y);
  if (terrain == null || terrain == TerrainType.plains) {
    return (game: game, converted: false);
  }

  tileMapByRegion[parsed.regionId] = map.withTerrainAt(
    parsed.x,
    parsed.y,
    TerrainType.plains,
  );
  final strip = stripResourcesAndExtractionImprovementsOnTileKeys(
    game,
    tileMapByRegion,
    [tileKey],
  );
  final strippedMaps = strip.$2;
  if (strippedMaps != null) {
    for (final e in strippedMaps.entries) {
      tileMapByRegion[e.key] = e.value;
    }
  }
  return (game: strip.$1, converted: true);
}

/// When any candidate is plains, return only plains candidates; otherwise [candidates].
List<String> preferPlainsTownCandidates({
  required List<String> candidates,
  required TileMapResult? tileMap,
}) {
  if (tileMap == null || tileMap.terrainGrid == null || candidates.isEmpty) {
    return candidates;
  }
  final plains = <String>[];
  for (final key in candidates) {
    final parsed = parseTileKeyCoordinates(key);
    if (parsed == null) continue;
    if (tileMap.terrainAt(parsed.x, parsed.y) == TerrainType.plains) {
      plains.add(key);
    }
  }
  return plains.isNotEmpty ? plains : candidates;
}
