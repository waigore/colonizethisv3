/// Builds province Extraction display projections. Refs #4064.
///
/// SPEC: SPEC/program/province-extraction-snapshot.md
library;

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_world/colonizethis_world.dart';

import 'capital_tile_grain_bonus.dart';
import 'economy_resource_constants.dart';
import 'game_lookup_helpers.dart';
import 'tile_extraction_display_contribution.dart';
import 'tile_extraction_pipeline.dart';

export 'tile_extraction_display_contribution.dart';

/// Mutable per-commodity accumulator used while building a province snapshot.
class _CommodityAcc {
  int effective = 0;
  int full = 0;
  final Set<String> tileKeys = <String>{};
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
  final playersById = {for (final player in game.players) player.id: player};
  final accByProvince = <String, Map<String, _CommodityAcc>>{};
  final ownerByProvince = <String, String>{};
  final capitalBonusByProvince = <String, int>{};

  for (final tileKey in game.worldState.tileState.improvementByTile.keys) {
    final tileContext = resolveTileKeyExtractionContext(
      tileKey: tileKey,
      tileMapByRegion: tileMapByRegion,
      provincesByFullId: provincesByFullId,
      game: game,
      logContext: 'provinceExtractionSnapshot',
    );
    if (tileContext == null) {
      continue;
    }

    final player = playersById[tileContext.province.ownerId];
    if (player == null) {
      continue;
    }

    final cr = connectivityResult[player.id];
    final connected = cr?.connected ?? const <String>{};
    final pathTransportCap = cr?.pathTransportCap ?? const <String, int>{};
    final roadRuleTiles = cr?.connectedByRoadRule ?? const <String>{};
    final prospected =
        game.worldState.playerProspectedTiles[player.id] ?? const <String>{};

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
          !kMineralResourceIds.contains(commodityId) || prospected.contains(tk),
    );
    if (contribution == null) {
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

  for (final player in game.players) {
    final capBonus = capitalTileGrainBonusForPlayer(game: game, player: player);
    final capitalProvinceId = player.capitalProvinceId;
    if (capBonus != null && capitalProvinceId != null) {
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
