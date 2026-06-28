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

import 'tile_extraction_yield.dart';

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

/// Effective per-tile extraction yield for one connected tile, shared by the
/// Great-Power and non-Great-Power extraction paths.
///
/// [units] is the computed effective extracted quantity (always `> 0`;
/// non-yielding tiles return `null` from [computeTileYieldContribution]).
/// [regionId] / [isLandRelativeToCapital] classify the tile against the
/// caller's capital region so callers decide whether to keep overseas
/// contributions (Great Powers) or drop them (non-GP factions).
class TileYieldContribution {
  const TileYieldContribution({
    required this.commodityId,
    required this.units,
    required this.regionId,
    required this.isLandRelativeToCapital,
  });

  final CommodityId commodityId;
  final int units;
  final String regionId;

  /// True when the tile's region matches the caller-supplied capital region.
  final bool isLandRelativeToCapital;
}

/// Computes the effective extraction contribution for one connected [tileKey],
/// hosting the orchestration shared by the Great-Power
/// ([computeTileExtractionContributionForPlayer], `resource_extractor.dart`)
/// and non-Great-Power (`_computeNonGpTileContribution`,
/// `non_gp_extraction_shared.dart`) paths.
///
/// The two call sites diverge only by the three documented non-GP
/// simplifications (`SPEC/game/extraction-and-improvements.md` § Non-Great-Power
/// extraction), supplied here as knobs so the shared production / transport-cap
/// / town-development math stays provably in lockstep (Refs #3517 Cluster 1):
///
///   * [techCapForCommodity] resolves the per-resource tech cap (Great Powers
///     use the player / per-resource cap; non-GP factions use the package
///     default for every resource).
///   * [isCommodityExtractable] is the mineral gate (Great Powers require the
///     tile to be prospected for mineral commodities; non-GP factions exclude
///     minerals unconditionally). Returning `false` skips the tile.
///   * [capitalProvinceId] selects the capital-province yield branch and
///     [capitalRegionId] drives [TileYieldContribution.isLandRelativeToCapital].
///
/// Returns `null` when the tile contributes no extraction units: not in
/// [connectedTileKeys], an invalid tile key, missing map / province / resource,
/// a gated commodity, or computed effective units `<= 0`.
TileYieldContribution? computeTileYieldContribution({
  required Game game,
  required Map<String, TileMapResult> tileMapByRegion,
  required String tileKey,
  required Set<String> connectedTileKeys,
  required Map<String, int> pathTransportCap,
  required Set<String> connectedByRoadRule,
  required Set<String> portTileKeys,
  required String? capitalProvinceId,
  required String? capitalRegionId,
  required String logContext,
  required int Function(CommodityId commodityId) techCapForCommodity,
  required bool Function(String tileKey, CommodityId commodityId)
  isCommodityExtractable,
  Map<String, Province>? provincesByFullId,
}) {
  if (!connectedTileKeys.contains(tileKey)) {
    return null;
  }

  final tileContext = resolveTileKeyExtractionContext(
    tileKey: tileKey,
    tileMapByRegion: tileMapByRegion,
    provincesByFullId: provincesByFullId,
    game: game,
    logContext: logContext,
  );
  if (tileContext == null) {
    return null;
  }

  final commodityId = tileContext.commodityId;
  if (!isCommodityExtractable(tileKey, commodityId)) {
    return null;
  }

  // Terrain hard caps (R4, issue #3573): scrub-forest timber is clamped to
  // level 1 regardless of unlocked gathering tech. The terrain is resolved from
  // the same region map the resource came from; when terrain data is absent the
  // tech cap is used unchanged. SPEC/game/extraction-and-improvements.md.
  final rawTechCap = techCapForCommodity(commodityId);
  final terrain = tileMapByRegion[tileContext.regionId]?.terrainAt(
    tileContext.resourceContext.x,
    tileContext.resourceContext.y,
  );
  final techCap = terrain == null
      ? rawTechCap
      : clampExtractionCapForTerrain(rawTechCap, commodityId, terrain);
  final province = tileContext.province;
  final provinceId = tileContext.provinceId;
  final townDevelopmentCap = province.townDevelopmentLevel;
  final townTileKey = province.townTileKey;
  final townTileIsPort =
      townTileKey != null && portTileKeys.contains(townTileKey);

  final isCapitalProvince = provinceId == capitalProvinceId;
  final usesRoadRule = connectedByRoadRule.contains(tileKey);
  final effective = computeEffectiveTileYield(
    tileState: game.worldState.tileState,
    tileKey: tileKey,
    techCap: techCap,
    townDevelopmentCap: townDevelopmentCap,
    townTileIsPort: townTileIsPort,
    isCapitalProvince: isCapitalProvince,
    usesRoadRule: usesRoadRule,
    portTileKeys: portTileKeys,
    pathTransportCap: pathTransportCap,
  );
  if (effective <= 0) {
    return null;
  }

  return TileYieldContribution(
    commodityId: commodityId,
    units: effective,
    regionId: tileContext.regionId,
    isLandRelativeToCapital: tileContext.regionId == capitalRegionId,
  );
}
