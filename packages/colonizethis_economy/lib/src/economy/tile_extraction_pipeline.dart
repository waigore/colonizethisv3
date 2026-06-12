/// Shared tile-key → map → resource → province resolution for extraction paths.
///
/// Great-Power extraction ([computeTileExtractionContributionForPlayer] in
/// `resource_extractor.dart`), non-GP extraction (`_computeNonGpTileContribution`
/// in `non_gp_extraction.dart`), and purchased-tile riches
/// ([computePurchasedTileRichesCredits] in `purchased_tile_riches.dart`) all
/// performed the same parse → coordinates → map → resource → commodity-id steps
/// independently. This module holds that shared pipeline; callers supply the
/// documented per-path gates (prospecting, mineral exclusion, riches filter) and
/// yield math via [computeEffectiveTileYield].
library;

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_economy/src/logging.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_world/colonizethis_world.dart';
import 'package:colonizethis_world/src/world/tile_key_coordinates.dart';

/// Tile key resolved through map lookup to a [Resource] and [CommodityId].
class TileKeyResourceContext {
  const TileKeyResourceContext({
    required this.tileKey,
    required this.regionId,
    required this.provinceLocalId,
    required this.x,
    required this.y,
    required this.resource,
    required this.commodityId,
  });

  final String tileKey;
  final String regionId;
  final String provinceLocalId;
  final int x;
  final int y;
  final Resource resource;
  final CommodityId commodityId;

  /// Region-scoped province id per `SPEC/game/world-model-identity.md`.
  String get provinceId => '$regionId|$provinceLocalId';
}

/// [TileKeyResourceContext] extended with a resolved [Province] row.
class TileKeyExtractionContext {
  const TileKeyExtractionContext({
    required this.resourceContext,
    required this.province,
  });

  final TileKeyResourceContext resourceContext;
  final Province province;

  String get tileKey => resourceContext.tileKey;
  CommodityId get commodityId => resourceContext.commodityId;
  String get provinceId => resourceContext.provinceId;
  String get regionId => resourceContext.regionId;
}

/// Parses [tileKey], resolves the region map, and returns the tile [Resource].
///
/// Returns null when the key is invalid, coordinates are negative, the region
/// map is missing, or the tile has no resource. [commodityId] is always
/// [Resource.name] — the canonical mapping shared across all extraction paths.
TileKeyResourceContext? resolveTileKeyResourceContext({
  required String tileKey,
  required Map<String, TileMapResult> tileMapByRegion,
}) {
  final coords = parseTileKeyCoordinates(tileKey);
  if (coords == null) {
    return null;
  }
  if (coords.x < 0 || coords.y < 0) {
    return null;
  }

  final map = tileMapByRegion[coords.regionId];
  if (map == null) {
    return null;
  }

  final resource = map.resourceAt(coords.x, coords.y);
  if (resource == null) {
    return null;
  }

  return TileKeyResourceContext(
    tileKey: tileKey,
    regionId: coords.regionId,
    provinceLocalId: coords.provinceLocalId,
    x: coords.x,
    y: coords.y,
    resource: resource,
    commodityId: resource.name,
  );
}

/// Resolves [resolveTileKeyResourceContext] and looks up the owning [Province].
///
/// [provincesByFullId] is preferred when supplied (built once per extraction
/// pass). When absent or missing the row, [game] is consulted via
/// [WorldState.tryGetProvince]. Returns null and logs when the province row
/// cannot be resolved.
TileKeyExtractionContext? resolveTileKeyExtractionContext({
  required String tileKey,
  required Map<String, TileMapResult> tileMapByRegion,
  Map<String, Province>? provincesByFullId,
  Game? game,
  required String logContext,
}) {
  final resourceContext = resolveTileKeyResourceContext(
    tileKey: tileKey,
    tileMapByRegion: tileMapByRegion,
  );
  if (resourceContext == null) {
    return null;
  }

  final provinceId = resourceContext.provinceId;
  final province =
      provincesByFullId?[provinceId] ??
      game?.worldState.tryGetProvince(provinceId);
  if (province == null) {
    final msg =
        '$logContext province missing tileKey=$tileKey provinceId=$provinceId '
        '(region-scoped lookup failed; SPEC/game/world-model-identity.md)';
    economyLog.e(msg, error: StateError(msg), stackTrace: StackTrace.current);
    return null;
  }

  return TileKeyExtractionContext(
    resourceContext: resourceContext,
    province: province,
  );
}
