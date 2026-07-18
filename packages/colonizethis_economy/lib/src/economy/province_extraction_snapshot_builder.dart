/// Builds province Extraction display projections. Refs #4064.
///
/// SPEC: SPEC/program/province-extraction-snapshot.md
library;

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_world/colonizethis_world.dart';

import 'economy_resource_constants.dart';
import 'game_lookup_helpers.dart';
import 'tile_extraction_pipeline.dart';
import 'tile_extraction_yield.dart';

/// Mutable per-commodity accumulator used while building a province snapshot.
class _CommodityAcc {
  int effective = 0;
  int full = 0;
  final Set<String> tileKeys = <String>{};
}

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

/// Projects Extraction for a single province from the current post-resolution
/// world (display-only; does not apply stockpile). Refs #4064.
ProvinceExtractionSnapshot? projectProvinceExtraction({
  required Game game,
  required Map<String, TileMapResult> tileMapByRegion,
  required MapTopology topology,
  required String provinceId,
  int Function(String playerId) techCapForPlayer = _defaultTechCap,
  int Function(String playerId, String resourceId)? techCapForPlayerAndResource,
}) {
  if (tileMapByRegion.isEmpty) return null;
  final connectivity = resolveConnectivity(
    game: game,
    tileMapByRegion: tileMapByRegion,
    topology: topology,
  );
  return computeProvinceExtractionSnapshots(
    game: game,
    tileMapByRegion: tileMapByRegion,
    connectivityResult: connectivity,
    techCapForPlayer: techCapForPlayer,
    techCapForPlayerAndResource: techCapForPlayerAndResource,
  )[provinceId];
}

/// Builds Extraction projections for all GP-owned provinces with contributions.
Map<String, ProvinceExtractionSnapshot> computeProvinceExtractionSnapshots({
  required Game game,
  required Map<String, TileMapResult> tileMapByRegion,
  required Map<String, ConnectivityResult> connectivityResult,
  int Function(String playerId) techCapForPlayer = _defaultTechCap,
  int Function(String playerId, String resourceId)? techCapForPlayerAndResource,
}) {
  final provincesByFullId = buildProvinceIndex(game);
  final portTileKeys = collectPortTileKeys(game);
  final accByProvince = <String, Map<String, _CommodityAcc>>{};
  final ownerByProvince = <String, String>{};
  final capitalBonusByProvince = <String, int>{};

  for (final player in game.players) {
    final cr = connectivityResult[player.id];
    final connected = cr?.connected ?? const <String>{};
    final pathTransportCap = cr?.pathTransportCap ?? const <String, int>{};
    final roadRuleTiles = cr?.connectedByRoadRule ?? const <String>{};
    final prospected =
        game.worldState.playerProspectedTiles[player.id] ?? const <String>{};

    for (final tileKey in game.worldState.tileState.improvementByTile.keys) {
      final contribution = computeTileExtractionDisplayContribution(
        game: game,
        tileMapByRegion: tileMapByRegion,
        tileKey: tileKey,
        connectedTileKeys: connected,
        pathTransportCap: pathTransportCap,
        connectedByRoadRule: roadRuleTiles,
        portTileKeys: portTileKeys,
        capitalProvinceId: player.capitalProvinceId,
        provincesByFullId: provincesByFullId,
        techCapForCommodity: (commodityId) =>
            techCapForPlayerAndResource?.call(player.id, commodityId) ??
            techCapForPlayer(player.id),
        isCommodityExtractable: (tk, commodityId) =>
            !kMineralResourceIds.contains(commodityId) ||
            prospected.contains(tk),
      );
      if (contribution == null) {
        continue;
      }

      final province = provincesByFullId[contribution.provinceId];
      if (province == null || province.ownerId != player.id) {
        continue;
      }

      ownerByProvince[contribution.provinceId] = player.id;
      final byCommodity = accByProvince.putIfAbsent(
        contribution.provinceId,
        () => {},
      );
      final acc = byCommodity.putIfAbsent(
        contribution.commodityId,
        _CommodityAcc.new,
      );
      acc.effective += contribution.effective;
      acc.full += contribution.full;
      acc.tileKeys.add(contribution.tileKey);
    }

    final capBonus = game.capitalTileGrainBonusPerTurn;
    final capitalProvinceId = player.capitalProvinceId;
    if (player.capitalTile != null &&
        capitalProvinceId != null &&
        capBonus > 0) {
      ownerByProvince[capitalProvinceId] = player.id;
      capitalBonusByProvince[capitalProvinceId] = capBonus;
      final byCommodity = accByProvince.putIfAbsent(
        capitalProvinceId,
        () => {},
      );
      final acc = byCommodity.putIfAbsent(
        CommodityCatalog.grain.id,
        _CommodityAcc.new,
      );
      acc.effective += capBonus;
      acc.full += capBonus;
    }
  }

  final out = <String, ProvinceExtractionSnapshot>{};
  for (final provinceId in accByProvince.keys.toList()..sort()) {
    final ownerId = ownerByProvince[provinceId];
    if (ownerId == null) continue;
    final byCommodity = <String, ProvinceExtractionCommodityTotals>{};
    final raw = accByProvince[provinceId]!;
    for (final commodityId in raw.keys.toList()..sort()) {
      final acc = raw[commodityId]!;
      if (acc.effective <= 0 && acc.full <= 0) continue;
      final keys = acc.tileKeys.toList()..sort();
      byCommodity[commodityId] = ProvinceExtractionCommodityTotals(
        effective: acc.effective,
        full: acc.full,
        tileKeys: keys,
      );
    }
    if (byCommodity.isEmpty) continue;
    out[provinceId] = ProvinceExtractionSnapshot(
      ownerId: ownerId,
      byCommodity: byCommodity,
      capitalGrainBonus: capitalBonusByProvince[provinceId] ?? 0,
    );
  }
  return out;
}

int _defaultTechCap(String playerId) => defaultExtractionCap;
