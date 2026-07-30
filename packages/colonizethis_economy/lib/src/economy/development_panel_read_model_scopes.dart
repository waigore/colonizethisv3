/// Development panel scope/improvable/extraction helpers. Refs #4175.
///
/// SPEC: SPEC/program/development-panel-read-model.md
library;

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart' show CommodityId, Game;
import 'package:colonizethis_world/colonizethis_world.dart';

import 'commodity_totals.dart';
import 'development_panel_model.dart';
import 'development_panel_visibility.dart';
import 'economy_resource_constants.dart';
import 'game_lookup_helpers.dart';
import 'province_improvable_resource_counts.dart';
import 'resource_extractor.dart';
import 'tile_extraction_pipeline.dart';

List<DevelopmentPanelScopeRow> buildDevelopmentPurchasedScopes({
  required Game game,
  required String playerId,
  required String regionId,
  required Map<String, TileMapResult> tileMapByRegion,
  required Map<String, String> provinceDisplayNamesById,
  required Map<String, String> playerDisplayNamesById,
  required ProvinceOwnerCache ownerCache,
  PlayerView? playerView,
}) {
  final bySourceProvince = <String, List<String>>{};
  for (final entry in game.worldState.purchasedTilesByTileKey.entries) {
    if (entry.value != playerId) continue;
    final tileKey = entry.key;
    final provinceId = developmentProvinceIdFromTileKey(tileKey);
    if (provinceId == null) continue;
    if (!provinceId.startsWith('$regionId|')) continue;
    bySourceProvince.putIfAbsent(provinceId, () => []).add(tileKey);
  }

  final scopes = <DevelopmentPanelScopeRow>[];
  final sortedProvinceIds = bySourceProvince.keys.toList()..sort();
  for (final provinceId in sortedProvinceIds) {
    final tileKeys = bySourceProvince[provinceId]!..sort();
    final improvable = developmentImprovableRowsForTileKeys(
      game: game,
      playerId: playerId,
      tileKeys: tileKeys,
      tileMapByRegion: tileMapByRegion,
      playerView: playerView,
    );
    final ownerId = ownerCache.ownerOf(provinceId);
    scopes.add(
      DevelopmentPanelScopeRow(
        scopeKey: 'purchased:$provinceId',
        provinceId: provinceId,
        displayName:
            provinceDisplayNamesById[provinceId] ?? provinceId,
        provinceOwnerId: ownerId,
        provinceOwnerDisplayName: ownerId == null
            ? null
            : playerDisplayNamesById[ownerId] ?? ownerId,
        isPurchasedLand: true,
        improvableCommodities: improvable,
      ),
    );
  }
  return scopes;
}

List<DevelopmentImprovableCommodityRow> developmentImprovableRowsFromCounts(
  Map<String, ProvinceImprovableCommodityCount> counts, {
  PlayerView? playerView,
}) {
  final rows = <DevelopmentImprovableCommodityRow>[];
  for (final commodity in CommodityCatalog.all) {
    final entry = counts[commodity.id];
    if (entry == null || entry.count <= 0) continue;
    var tileKeys = entry.tileKeys;
    if (playerView != null) {
      tileKeys = developmentFilterVisibilityKnownTileKeys(playerView, tileKeys);
    }
    if (tileKeys.isEmpty) continue;
    rows.add(
      DevelopmentImprovableCommodityRow(
        commodityId: commodity.id,
        tileKeys: List<String>.from(tileKeys),
      ),
    );
  }
  return rows;
}

List<DevelopmentImprovableCommodityRow> developmentImprovableRowsForTileKeys({
  required Game game,
  required String playerId,
  required List<String> tileKeys,
  required Map<String, TileMapResult> tileMapByRegion,
  PlayerView? playerView,
}) {
  final techUnlocked =
      game.playerById(playerId)?.techUnlocked ?? const <String, bool>{};
  final prospected =
      game.worldState.playerProspectedTiles[playerId] ?? const <String>{};
  final tileState = game.worldState.tileState;
  final acc = <String, List<String>>{};

  for (final tileKey in tileKeys) {
    final resourceContext = resolveTileKeyResourceContext(
      tileKey: tileKey,
      tileMapByRegion: tileMapByRegion,
    );
    if (resourceContext == null) continue;

    final commodityId = resourceContext.commodityId;
    if (kMineralResourceIds.contains(commodityId) &&
        !prospected.contains(tileKey)) {
      continue;
    }

    final terrain = tileMapByRegion[resourceContext.regionId]?.terrainAt(
      resourceContext.x,
      resourceContext.y,
    );
    final cap = terrain == null
        ? extractionCapForResourceForUnlocked(techUnlocked, commodityId)
        : extractionCapForResourceOnTerrain(techUnlocked, commodityId, terrain);
    final improvement = tileState.improvementLevel(tileKey);
    if (improvement >= cap) continue;

    acc.putIfAbsent(commodityId, () => []).add(tileKey);
  }

  final rows = <DevelopmentImprovableCommodityRow>[];
  for (final commodity in CommodityCatalog.all) {
    final keys = acc[commodity.id];
    if (keys == null || keys.isEmpty) continue;
    var filteredKeys = keys;
    if (playerView != null) {
      filteredKeys = developmentFilterVisibilityKnownTileKeys(playerView, keys);
    }
    if (filteredKeys.isEmpty) continue;
    filteredKeys.sort();
    rows.add(
      DevelopmentImprovableCommodityRow(
        commodityId: commodity.id,
        tileKeys: List<String>.from(filteredKeys),
      ),
    );
  }
  return rows;
}

Map<String, int> developmentExtractionProjectionForRegion({
  required Game game,
  required String playerId,
  required String regionId,
  required Map<String, TileMapResult> tileMapByRegion,
  required ConnectivityResult? connectivity,
}) {
  final player = game.playerById(playerId);
  if (player == null || connectivity == null) return const {};

  final connected = connectivity.connected;
  final pathTransportCap = connectivity.pathTransportCap;
  final roadRuleTiles = connectivity.connectedByRoadRule;
  final portTileKeys = collectPortTileKeys(game);
  final prospected =
      game.worldState.playerProspectedTiles[playerId] ?? const <String>{};
  final provincesByFullId = buildProvinceIndex(game);
  final totals = <CommodityId, int>{};

  for (final tileKey in connected) {
    if (!tileKey.startsWith('$regionId|')) continue;
    final contribution = computeTileExtractionContributionForPlayer(
      game: game,
      tileMapByRegion: tileMapByRegion,
      player: player,
      tileKey: tileKey,
      connectedTileKeys: connected,
      pathTransportCap: pathTransportCap,
      connectedByRoadRule: roadRuleTiles,
      portTileKeys: portTileKeys,
      prospectedTileKeys: prospected,
      capitalRegionId: player.capitalTile?.regionId,
      provincesByFullId: provincesByFullId,
    );
    if (contribution == null || contribution.units <= 0) continue;
    addUnits(totals, contribution.commodityId, contribution.units);
  }

  final capBonus = game.capitalTileGrainBonusPerTurn;
  final capitalRegionId = player.capitalTile?.regionId;
  if (regionId == capitalRegionId &&
      player.capitalTile != null &&
      capBonus > 0) {
    addUnits(totals, CommodityCatalog.grain.id, capBonus);
  }

  final out = <String, int>{};
  for (final commodity in CommodityCatalog.all) {
    final qty = totals[commodity.id];
    if (qty == null || qty <= 0) continue;
    out[commodity.id] = qty;
  }
  return out;
}

String? developmentProvinceIdFromTileKey(String tileKey) {
  final parts = tileKey.split('|');
  if (parts.length < 4) return null;
  return '${parts[0]}|${parts[1]}';
}
