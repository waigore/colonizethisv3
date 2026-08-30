/// Display-only current vs next-level extraction preview for Build improvement.
///
/// SPEC: SPEC/program/province-extraction-snapshot.md; formula:
/// SPEC/game/extraction-and-improvements.md. Does not apply mid-turn drafts.
library;

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'tile_extraction_pipeline.dart';
import 'tile_extraction_yield.dart';

/// Why the next improvement does not raise what arrives, or [raise] when it does.
enum BuildImprovementYieldKind {
  raise,
  roadPathLimit,
  townDevelopmentLimit,
  disconnected,
}

/// Current vs hypothetical next effective yield for one extractable tile.
class BuildImprovementYieldPreview {
  const BuildImprovementYieldPreview({
    required this.commodityId,
    required this.currentEffective,
    required this.nextEffective,
    required this.kind,
  });

  final String commodityId;
  final int currentEffective;
  final int nextEffective;
  final BuildImprovementYieldKind kind;
}

int _yieldAtLevel({
  required Game game,
  required String tileKey,
  required int improvementLevel,
  required int techCap,
  required Province province,
  required bool connected,
  required bool isCapitalProvince,
  required bool usesRoadRule,
  required Set<String> portTileKeys,
  required Map<String, int> pathTransportCap,
}) {
  if (!connected || improvementLevel < 1) {
    return 0;
  }
  final townTileKey = province.townTileKey;
  final townTileIsPort =
      townTileKey != null && portTileKeys.contains(townTileKey);
  return computeEffectiveTileYield(
    tileState: game.worldState.tileState,
    tileKey: tileKey,
    techCap: techCap,
    townDevelopmentCap: province.townDevelopmentLevel,
    townTileIsPort: townTileIsPort,
    isCapitalProvince: isCapitalProvince,
    usesRoadRule: usesRoadRule,
    portTileKeys: portTileKeys,
    pathTransportCap: pathTransportCap,
    improvementLevelOverride: improvementLevel,
  );
}

int _tilePathCap({
  required Game game,
  required String tileKey,
  required Set<String> portTileKeys,
  required Map<String, int> pathTransportCap,
}) {
  final roadLevel = game.worldState.tileState.roadLevel(tileKey);
  final isPort = portTileKeys.contains(tileKey);
  final tileTransportLevel = isPort ? 4 : (roadLevel > 0 ? roadLevel : 0);
  return pathTransportCap[tileKey] ?? tileTransportLevel;
}

/// Hypothetical next improvement (`current + 1`, tech/terrain clamped).
///
/// Returns null when the tile is not extractable or already at improvement 4.
BuildImprovementYieldPreview? computeBuildImprovementYieldPreview({
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
  final currentLevel = game.worldState.tileState
      .improvementLevel(tileKey)
      .clamp(0, 4);
  if (currentLevel >= 4) {
    return null;
  }
  final nextLevel = currentLevel + 1;
  final nextPrelude = resolveImprovedTileProductionPrelude(
    game: game,
    tileMapByRegion: tileMapByRegion,
    tileKey: tileKey,
    logContext: 'buildImprovementYieldPreview',
    techCapForCommodity: techCapForCommodity,
    isCommodityExtractable: isCommodityExtractable,
    provincesByFullId: provincesByFullId,
    improvementLevelOverride: nextLevel,
  );
  if (nextPrelude == null) {
    return null;
  }

  final connected = connectedTileKeys.contains(tileKey);
  final currentEffective = _yieldAtLevel(
    game: game,
    tileKey: tileKey,
    improvementLevel: currentLevel,
    techCap: nextPrelude.techCap,
    province: nextPrelude.province,
    connected: connected,
    isCapitalProvince: nextPrelude.provinceId == capitalProvinceId,
    usesRoadRule: connectedByRoadRule.contains(tileKey),
    portTileKeys: portTileKeys,
    pathTransportCap: pathTransportCap,
  );
  final nextEffective = _yieldAtLevel(
    game: game,
    tileKey: tileKey,
    improvementLevel: nextLevel,
    techCap: nextPrelude.techCap,
    province: nextPrelude.province,
    connected: connected,
    isCapitalProvince: nextPrelude.provinceId == capitalProvinceId,
    usesRoadRule: connectedByRoadRule.contains(tileKey),
    portTileKeys: portTileKeys,
    pathTransportCap: pathTransportCap,
  );

  if (!connected) {
    return BuildImprovementYieldPreview(
      commodityId: nextPrelude.commodityId,
      currentEffective: 0,
      nextEffective: 0,
      kind: BuildImprovementYieldKind.disconnected,
    );
  }
  if (nextEffective > currentEffective) {
    return BuildImprovementYieldPreview(
      commodityId: nextPrelude.commodityId,
      currentEffective: currentEffective,
      nextEffective: nextEffective,
      kind: BuildImprovementYieldKind.raise,
    );
  }

  final pathCap = _tilePathCap(
    game: game,
    tileKey: tileKey,
    portTileKeys: portTileKeys,
    pathTransportCap: pathTransportCap,
  );
  final productionNext = nextPrelude.production;
  final afterPath = productionNext < pathCap ? productionNext : pathCap;
  final kind = afterPath < productionNext
      ? BuildImprovementYieldKind.roadPathLimit
      : BuildImprovementYieldKind.townDevelopmentLimit;
  return BuildImprovementYieldPreview(
    commodityId: nextPrelude.commodityId,
    currentEffective: currentEffective,
    nextEffective: nextEffective,
    kind: kind,
  );
}
