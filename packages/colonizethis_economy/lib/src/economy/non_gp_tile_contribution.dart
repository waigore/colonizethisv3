import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'economy_resource_constants.dart';
import 'tile_extraction_pipeline.dart';
import 'package:colonizethis_economy/src/logging.dart';

/// Single-commodity contribution from one connected tile owned by a non-GP
/// faction. Returned by [forEachNonGpTileContribution] for each tile that
/// yields units.
class NonGpTileContribution {
  const NonGpTileContribution({
    required this.commodityId,
    required this.units,
  });

  final CommodityId commodityId;
  final int units;
}

/// Single-tile non-GP extraction contribution. Library-internal; shared by
/// [forEachNonGpTileContribution], town manufacturing bonus, and tests.
///
/// Returns null when the tile contributes no units (not connected, invalid tile
/// key, no resource, mineral resource excluded for non-GPs, missing province
/// row, or computed effective units `<= 0`).
///
/// Mirrors the per-tile branches of
/// [computeTileExtractionContributionForPlayer](resource_extractor.dart) with
/// the three documented non-GP simplifications (default tech cap, no
/// prospecting, no capital-tile grain bonus). The town-development-cap branch
/// (capital province; non-capital with connected port town) is preserved
/// byte-for-byte so that minors and tribes whose capital province has a
/// non-default town-development level are extracted with the same
/// town-development semantics as Great Powers.
NonGpTileContribution? computeNonGpTileContribution({
  required Game game,
  required Map<String, TileMapResult> tileMapByRegion,
  required String factionCapitalProvinceId,
  required String factionCapitalRegionId,
  required String tileKey,
  required Set<String> connectedTileKeys,
  required Map<String, int> pathTransportCap,
  required Set<String> connectedByRoadRule,
  required Set<String> portTileKeys,
  required Map<String, Province> provincesByFullId,
}) {
  // Thin non-Great-Power wrapper over the shared [computeTileYieldContribution]
  // orchestration with the two non-GP knobs: a fixed default tech cap for every
  // resource (Minors and Tribes do not research tech) and unconditional mineral
  // exclusion (non-GP factions never prospect). SPEC/game/extraction-and-
  // improvements.md § Non-Great-Power extraction. Refs #3517 Cluster 1.
  final contribution = computeTileYieldContribution(
    game: game,
    tileMapByRegion: tileMapByRegion,
    tileKey: tileKey,
    connectedTileKeys: connectedTileKeys,
    pathTransportCap: pathTransportCap,
    connectedByRoadRule: connectedByRoadRule,
    portTileKeys: portTileKeys,
    capitalProvinceId: factionCapitalProvinceId,
    capitalRegionId: factionCapitalRegionId,
    logContext: 'non_gp_extraction',
    provincesByFullId: provincesByFullId,
    techCapForCommodity: (_) => defaultExtractionCap,
    isCommodityExtractable: (_, commodityId) =>
        !kMineralResourceIds.contains(commodityId),
  );
  if (contribution == null) {
    return null;
  }
  // The faction-capital-region check is preserved for parity with the GP
  // helper; in current SPEC every owned non-GP tile is same-region, so this
  // branch is informational only — non-GP output is always land-only.
  if (!contribution.isLandRelativeToCapital) {
    // Non-GP factions cannot own tiles outside their capital region under
    // current SPEC; emit a debug log and skip so this stays observable if a
    // future ruleset changes that invariant.
    economyLog.d(
      'non_gp_extraction skip overseas tile factionCapitalRegionId='
      '$factionCapitalRegionId tileRegionId=${contribution.regionId} '
      'tileKey=$tileKey',
    );
    return null;
  }
  return NonGpTileContribution(
    commodityId: contribution.commodityId,
    units: contribution.units,
  );
}
