/// Shared per-tile **yield contribution** orchestration for extraction paths
/// (Refs #3517 Cluster 1, #4014; phase-7 split Refs #4049).
///
/// Great-Power extraction ([computeTileExtractionContributionForPlayer] in
/// `resource_extractor.dart`), non-GP extraction (`_computeNonGpTileContribution`
/// in `non_gp_extraction.dart`), and purchased-tile riches
/// ([computePurchasedTileRichesCredits] in `purchased_tile_riches.dart`) all
/// performed the same parse → coordinates → map → resource → commodity-id steps
/// independently. The context/prelude **resolution** types now live in the
/// sibling `tile_extraction_context.dart` (re-exported here); this module
/// keeps production prelude resolve and effective-yield orchestration. Callers
/// supply the documented per-path gates (prospecting, mineral exclusion,
/// riches filter) and yield math via [computeEffectiveTileYield].
library;

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'tile_extraction_context.dart';
import 'tile_extraction_pipeline_types.dart';
import 'tile_extraction_yield.dart';

export 'tile_extraction_context.dart';
export 'tile_extraction_pipeline_types.dart';

/// Resolves tile context, applies [isCommodityExtractable], clamps tech for
/// terrain, and computes production = min(improvement, techCap). Returns null
/// when the tile is not an improved extractable resource tile.
ImprovedTileProductionPrelude? resolveImprovedTileProductionPrelude({
  required Game game,
  required Map<String, TileMapResult> tileMapByRegion,
  required String tileKey,
  required String logContext,
  required int Function(CommodityId commodityId) techCapForCommodity,
  required bool Function(String tileKey, CommodityId commodityId)
  isCommodityExtractable,
  Map<String, Province>? provincesByFullId,
  int? improvementLevelOverride,
}) {
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

  final improvementLevel =
      (improvementLevelOverride ??
              game.worldState.tileState.improvementLevel(tileKey))
          .clamp(0, 4);
  if (improvementLevel < 1) {
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

  final production = (improvementLevel < techCap ? improvementLevel : techCap)
      .clamp(0, 4);
  if (production <= 0) {
    return null;
  }

  return ImprovedTileProductionPrelude(
    tileContext: tileContext,
    techCap: techCap,
    production: production,
  );
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
/// / town-development math stays in lockstep (Refs #3517 Cluster 1):
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

  final prelude = resolveImprovedTileProductionPrelude(
    game: game,
    tileMapByRegion: tileMapByRegion,
    tileKey: tileKey,
    provincesByFullId: provincesByFullId,
    logContext: logContext,
    techCapForCommodity: techCapForCommodity,
    isCommodityExtractable: isCommodityExtractable,
  );
  if (prelude == null) {
    return null;
  }

  final province = prelude.province;
  final townTileKey = province.townTileKey;
  final townTileIsPort =
      townTileKey != null && portTileKeys.contains(townTileKey);
  final effective = computeEffectiveTileYield(
    tileState: game.worldState.tileState,
    tileKey: tileKey,
    techCap: prelude.techCap,
    townDevelopmentCap: province.townDevelopmentLevel,
    townTileIsPort: townTileIsPort,
    isCapitalProvince: prelude.provinceId == capitalProvinceId,
    usesRoadRule: connectedByRoadRule.contains(tileKey),
    portTileKeys: portTileKeys,
    pathTransportCap: pathTransportCap,
  );
  if (effective <= 0) {
    return null;
  }

  return TileYieldContribution(
    commodityId: prelude.commodityId,
    units: effective,
    regionId: prelude.tileContext.regionId,
    isLandRelativeToCapital: prelude.tileContext.regionId == capitalRegionId,
  );
}
