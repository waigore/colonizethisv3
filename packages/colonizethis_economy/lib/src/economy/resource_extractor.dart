import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_economy/src/logging.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'economy_resource_constants.dart';
import 'game_lookup_helpers.dart';
import 'tile_extraction_yield.dart';
import 'package:colonizethis_world/src/world/connectivity_resolver.dart';
import 'package:colonizethis_world/src/world/province_lookup.dart';
import 'package:colonizethis_world/src/world/tile_key_coordinates.dart';

/// Per-player extraction totals: land (same region as capital) vs overseas.
class ExtractionTotals {
  const ExtractionTotals({this.land = const {}, this.overseas = const {}});

  final Map<CommodityId, int> land;
  final Map<CommodityId, int> overseas;
}

/// Tile-scoped extraction contribution used by map overlays and previews.
class TileExtractionContribution {
  const TileExtractionContribution({
    required this.tileKey,
    required this.commodityId,
    required this.units,
    required this.isLandRelativeToCapital,
  });

  final String tileKey;
  final CommodityId commodityId;
  final int units;

  /// True when tile region matches player's capital region (land bucket).
  final bool isLandRelativeToCapital;
}

/// Computes per-player extraction from connected tiles. SPEC/game/extraction-and-improvements.
///
/// For each connected tile: production = min(improvementLevel, techCap);
/// transport cap for yield = [ConnectivityResult.pathTransportCap]\[tileKey] when present,
/// else the tile's own transport level (port = 4, else road level or 0).
/// Effective yield applies GDD branches: min(production, transport cap), then town development
/// caps where applicable ([Province.townDevelopmentLevel]).
/// Sums by commodity; splits land (same region as capital) vs overseas.
/// Adds [Game.capitalTileGrainBonusPerTurn] grain to each player's land totals
/// when that player has a capital tile (unconditional on connectivity).
Map<String, ExtractionTotals> computeExtraction({
  required Game game,
  required Map<String, TileMapResult> tileMapByRegion,
  required Map<String, ConnectivityResult> connectivityResult,
  int Function(String playerId) techCapForPlayer = _defaultTechCap,
  int Function(String playerId, String resourceId)? techCapForPlayerAndResource,

  /// When set, only these tile keys contribute (must still be in [ConnectivityResult.connected]).
  /// Used by tests (e.g. Great Power bootstrap farms) without duplicating extraction rules.
  Set<String>? restrictToTileKeys,
}) {
  economyLog.d('extraction compute start players=${game.players.length}');
  final provincesByFullId = buildProvinceIndex(game);
  final portTileKeys = collectPortTileKeys(game);
  final out = <String, ExtractionTotals>{};
  for (final player in game.players) {
    final cr = connectivityResult[player.id];
    final connected = cr?.connected ?? const <String>{};
    final pathTransportCap = cr?.pathTransportCap ?? const <String, int>{};
    final roadRuleTiles = cr?.connectedByRoadRule ?? const <String>{};
    final cap = player.capitalTile;
    final capitalRegionId = cap?.regionId;

    final landTotals = <CommodityId, int>{};
    final overseasTotals = <CommodityId, int>{};

    final prospected =
        game.worldState.playerProspectedTiles[player.id] ?? const <String>{};

    for (final tileKey in connected) {
      if (restrictToTileKeys != null && !restrictToTileKeys.contains(tileKey)) {
        continue;
      }
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
        capitalRegionId: capitalRegionId,
        techCapForPlayer: techCapForPlayer,
        techCapForPlayerAndResource: techCapForPlayerAndResource,
        provincesByFullId: provincesByFullId,
      );
      if (contribution == null) {
        continue;
      }

      if (contribution.isLandRelativeToCapital) {
        landTotals[contribution.commodityId] =
            (landTotals[contribution.commodityId] ?? 0) + contribution.units;
      } else {
        overseasTotals[contribution.commodityId] =
            (overseasTotals[contribution.commodityId] ?? 0) +
            contribution.units;
      }
    }

    final capBonus = game.capitalTileGrainBonusPerTurn;
    if (player.capitalTile != null && capBonus > 0) {
      final grainId = CommodityCatalog.grain.id;
      landTotals[grainId] = (landTotals[grainId] ?? 0) + capBonus;
    }

    out[player.id] = ExtractionTotals(
      land: landTotals,
      overseas: overseasTotals,
    );
  }
  final landSum = out.values.fold<int>(
    0,
    (s, t) => s + t.land.values.fold(0, (a, b) => a + b),
  );
  final overseasSum = out.values.fold<int>(
    0,
    (s, t) => s + t.overseas.values.fold(0, (a, b) => a + b),
  );
  economyLog.d(
    'extraction compute end players=${out.length} landTotal=$landSum overseasTotal=$overseasSum',
  );
  return out;
}

/// Computes per-tile extraction contribution for one player's connected tile.
///
/// Returns null when the tile contributes no extraction units (not connected,
/// invalid tile key, missing map/province/resource, mineral not prospected, or
/// computed effective units <= 0).
TileExtractionContribution? computeTileExtractionContributionForPlayer({
  required Game game,
  required Map<String, TileMapResult> tileMapByRegion,
  required Player player,
  required String tileKey,
  required Set<String> connectedTileKeys,
  required Map<String, int> pathTransportCap,
  required Set<String> connectedByRoadRule,
  required Set<String> portTileKeys,
  required Set<String> prospectedTileKeys,
  required String? capitalRegionId,
  int Function(String playerId) techCapForPlayer = _defaultTechCap,
  int Function(String playerId, String resourceId)? techCapForPlayerAndResource,

  /// When non-null (typically built once per [computeExtraction] pass), province
  /// rows are resolved by id in O(1) instead of scanning the region list per tile.
  Map<String, Province>? provincesByFullId,
}) {
  if (!connectedTileKeys.contains(tileKey)) {
    return null;
  }
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

  final commodityId = _resourceToCommodityId(resource);
  final techCap =
      techCapForPlayerAndResource?.call(player.id, commodityId) ??
      techCapForPlayer(player.id);
  final isMineral = kMineralResourceIds.contains(commodityId);
  if (isMineral && !prospectedTileKeys.contains(tileKey)) {
    return null;
  }

  // Province lookup must be region-scoped. SPEC/game/world-model-identity.md.
  final provinceId = '${coords.regionId}|${coords.provinceLocalId}';
  final province = provincesByFullId != null
      ? provincesByFullId[provinceId]
      : tryGetProvince(game.worldState, provinceId);
  if (province == null) {
    final msg =
        'extraction province missing tileKey=$tileKey provinceId=$provinceId '
        '(region-scoped lookup failed; SPEC/game/world-model-identity.md)';
    economyLog.e(msg, error: StateError(msg), stackTrace: StackTrace.current);
    return null;
  }
  final townDevelopmentCap = province.townDevelopmentLevel;
  final townTileKey = province.townTileKey;
  final townTileIsPort =
      townTileKey != null && portTileKeys.contains(townTileKey);

  final isCapitalProvince = provinceId == player.capitalProvinceId;
  final usesRoadRule = connectedByRoadRule.contains(tileKey);
  final effectiveCapped = computeEffectiveTileYield(
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
  if (effectiveCapped <= 0) {
    return null;
  }

  return TileExtractionContribution(
    tileKey: tileKey,
    commodityId: commodityId,
    units: effectiveCapped,
    isLandRelativeToCapital: coords.regionId == capitalRegionId,
  );
}

int _defaultTechCap(String playerId) => defaultExtractionCap;

CommodityId _resourceToCommodityId(Resource resource) {
  switch (resource) {
    case Resource.grain:
      return 'grain';
    case Resource.meat:
      return 'meat';
    case Resource.wool:
      return 'wool';
    case Resource.horses:
      return 'horses';
    case Resource.timber:
      return 'timber';
    case Resource.iron:
      return 'iron';
    case Resource.copper:
      return 'copper';
    case Resource.tin:
      return 'tin';
    case Resource.coal:
      return 'coal';
    case Resource.sugarCane:
      return 'sugarCane';
    case Resource.tobacco:
      return 'tobacco';
    case Resource.cotton:
      return 'cotton';
    case Resource.furs:
      return 'furs';
    case Resource.spices:
      return 'spices';
    case Resource.silver:
      return 'silver';
    case Resource.gold:
      return 'gold';
    case Resource.gems:
      return 'gems';
    case Resource.diamonds:
      return 'diamonds';
  }
}
