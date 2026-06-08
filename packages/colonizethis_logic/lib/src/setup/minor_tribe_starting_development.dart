// SPEC/game/factions.md § Starting developed resources (Minor Nations and Tribes).
// SPEC/program/game-setup-pipeline.md § 7d.dev.

import 'package:colonizethis_data/colonizethis_data.dart';
import 'setup_logging.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../constants.dart';
import 'package:colonizethis_world/src/world/game_world_mutations.dart';
import 'setup_exceptions.dart';
import 'town_capital_occupancy.dart';

/// Default per-capital developed tile count for Minor Nations and Tribes at
/// game setup. SPEC/game/factions.md § Starting developed resources.
const int kMinorTribeStartingDevelopedTilesPerCapital = 2;

/// Result of applying the starting-developed-resources rule to a [Game].
class MinorTribeStartingDevelopmentResult {
  const MinorTribeStartingDevelopmentResult({
    required this.game,
    required this.developedTileKeysByFactionId,
  });

  final Game game;

  /// Minor/tribe faction id (e.g. `minor1`, `tribe1`) → list of developed tile
  /// keys for that faction (deterministic order: selection order).
  final Map<String, List<String>> developedTileKeysByFactionId;
}

/// Returns the eligible tile keys for [F]'s capital province in [map] ranked by
/// the deterministic selection order defined in
/// SPEC/game/factions.md § Starting developed resources.
///
/// Eligibility: tile is inside the capital province, not in [forbiddenTileKeys]
/// (capital/town tiles), has non-null terrain, has a non-null resource, and the
/// current [WorldState.tileState] improvement level is `0`.
///
/// Selection order: Manhattan distance from the capital tile ascending, then
/// `y` ascending, then `x` ascending.
///
/// Returns at most [maxTiles] keys (or all eligible tiles when fewer exist).
List<String> selectMinorTribeStartingDevelopmentTileKeys({
  required TileMapResult map,
  required CapitalTile capital,
  required TileMapState tileState,
  required Set<String> forbiddenTileKeys,
  int maxTiles = kMinorTribeStartingDevelopedTilesPerCapital,
}) {
  if (maxTiles <= 0) return const <String>[];
  final terrainGrid = map.terrainGrid;
  final resGrid = map.resourceGrid;
  if (terrainGrid == null || resGrid == null) {
    return const <String>[];
  }
  final regionId = capital.regionId;
  final localId = ProvinceId.isPrefixed(capital.provinceId)
      ? ProvinceId.localIdFrom(capital.provinceId)
      : capital.provinceId;
  final ranked = <(int dist, int y, int x, String key)>[];
  for (var y = 0; y < map.height; y++) {
    for (var x = 0; x < map.width; x++) {
      if (map.cell(x, y) != localId) continue;
      if (map.terrainAt(x, y) == null) continue;
      if (map.resourceAt(x, y) == null) continue;
      final key = CapitalTile.tileKey(regionId, capital.provinceId, x, y);
      if (forbiddenTileKeys.contains(key)) continue;
      if (tileState.improvementLevel(key) != 0) continue;
      final dist = (x - capital.x).abs() + (y - capital.y).abs();
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
  return ranked.take(maxTiles).map((e) => e.$4).toList();
}

/// Applies SPEC/game/factions.md § Starting developed resources rule for every
/// Minor Nation and Tribe with a non-null capital tile in [game]. Sets
/// `tileState.improvementLevel` to `1` for each selected tile. Terrain,
/// resources, and transport on each tile are left unchanged. Capital and town
/// tiles are excluded from selection.
///
/// When [maxTilesPerCapital] resolves to `0`, this step performs no mutation
/// (useful for scenarios that explicitly disable the bootstrap). When a
/// capital province has fewer eligible tiles than the requested count, the
/// step develops every eligible tile and does not raise an error.
///
/// Hand-made test maps that lack `terrainGrid`/`resourceGrid` for a region are
/// skipped silently for factions whose capital sits in that region; remaining
/// factions are still processed.
MinorTribeStartingDevelopmentResult applyMinorTribeStartingDevelopment({
  required Game game,
  required Map<String, TileMapResult> tileMapByRegion,
  int maxTilesPerCapital = kMinorTribeStartingDevelopedTilesPerCapital,
}) {
  if (maxTilesPerCapital < 0) {
    throw SetupConfigConstraintException(
      code: 'minor_tribe_starting_development_negative_count',
      details:
          'maxTilesPerCapital must be >= 0; got $maxTilesPerCapital',
    );
  }
  final result = <String, List<String>>{};
  if (maxTilesPerCapital == 0) {
    setupLog.i('skip minor/tribe starting development (count=0)');
    return MinorTribeStartingDevelopmentResult(
      game: game,
      developedTileKeysByFactionId: result,
    );
  }

  final forbidden = collectTownAndCapitalTileKeys(game);
  var ws = game.worldState;

  Iterable<({String id, CapitalTile? capital, String expectedRegion})>
  factionsToDevelop() sync* {
    for (final m in game.minorNations) {
      yield (id: m.id, capital: m.capitalTile, expectedRegion: kRegionOldWorld);
    }
    for (final t in game.tribes) {
      yield (id: t.id, capital: t.capitalTile, expectedRegion: kRegionNewWorld);
    }
  }

  var totalDeveloped = 0;
  for (final faction in factionsToDevelop()) {
    final capital = faction.capital;
    if (capital == null) continue;
    if (capital.regionId != faction.expectedRegion) {
      setupLog.w(
        'logic:setup minor/tribe ${faction.id} capital region '
        '"${capital.regionId}" != expected "${faction.expectedRegion}"; skipping development',
      );
      continue;
    }
    final map = tileMapByRegion[capital.regionId];
    if (map == null) continue;
    final picked = selectMinorTribeStartingDevelopmentTileKeys(
      map: map,
      capital: capital,
      tileState: ws.tileState,
      forbiddenTileKeys: forbidden,
      maxTiles: maxTilesPerCapital,
    );
    if (picked.isEmpty) {
      setupLog.d(
        'logic:setup minor/tribe ${faction.id} no eligible developed tiles in '
        'capital province ${capital.provinceId}',
      );
      continue;
    }
    var tileState = ws.tileState;
    for (final key in picked) {
      tileState = tileState.setImprovement(key, 1);
    }
    ws = ws.copyWith(tileState: tileState);
    result[faction.id] = picked;
    totalDeveloped += picked.length;
  }

  setupLog.i(
    'logic:setup minor/tribe starting development applied '
    'factions=${result.length} tiles=$totalDeveloped maxPerCapital=$maxTilesPerCapital',
  );
  return MinorTribeStartingDevelopmentResult(
    game: game.withWorldState(ws),
    developedTileKeysByFactionId: result,
  );
}
