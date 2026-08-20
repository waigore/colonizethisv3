/// Per-tile dual-yield contribution for province Extraction display projections.
///
/// SPEC: SPEC/program/province-extraction-snapshot.md
library;

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'tile_extraction_pipeline.dart';
import 'tile_extraction_yield.dart';

/// Dual production/effective contribution for one improved extractable tile.
class TileExtractionDisplayContribution {
  const TileExtractionDisplayContribution({
    required this.provinceId,
    required this.commodityId,
    required this.effective,
    required this.full,
    required this.tileKey,
  });

  final String provinceId;
  final String commodityId;
  final int effective;
  final int full;
  final String tileKey;
}

/// Computes production (full) and effective yield for one improved tile,
/// including disconnected tiles where effective is 0 and full > 0.
///
/// Shares resolve/clamp/production with [computeTileYieldContribution] via
/// [resolveImprovedTileProductionPrelude] (Refs #4014).
TileExtractionDisplayContribution? computeTileExtractionDisplayContribution({
  required Game game,
  required Map<String, TileMapResult> tileMapByRegion,
  required String tileKey,
  required Set<String> connectedTileKeys,
  required Map<String, int> pathTransportCap,
  required Set<String> connectedByRoadRule,
  required Set<String> portTileKeys,
  required String? capitalProvinceId,
  required int Function(CommodityId commodityId) techCapForCommodity,
  required bool Function(String tileKey, CommodityId commodityId)
  isCommodityExtractable,
  Map<String, Province>? provincesByFullId,
}) {
  final prelude = resolveImprovedTileProductionPrelude(
    game: game,
    tileMapByRegion: tileMapByRegion,
    tileKey: tileKey,
    provincesByFullId: provincesByFullId,
    logContext: 'provinceExtractionSnapshot',
    techCapForCommodity: techCapForCommodity,
    isCommodityExtractable: isCommodityExtractable,
  );
  if (prelude == null) {
    return null;
  }

  var effective = 0;
  if (connectedTileKeys.contains(tileKey)) {
    final province = prelude.province;
    final townTileKey = province.townTileKey;
    final townTileIsPort =
        townTileKey != null && portTileKeys.contains(townTileKey);
    effective = computeEffectiveTileYield(
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
  }

  return TileExtractionDisplayContribution(
    provinceId: prelude.provinceId,
    commodityId: prelude.commodityId,
    effective: effective,
    full: prelude.production,
    tileKey: tileKey,
  );
}
