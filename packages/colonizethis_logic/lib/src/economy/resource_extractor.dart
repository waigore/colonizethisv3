import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logger/colonizethis_logger.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../constants.dart';
import '../world/connectivity_resolver.dart';
import '../world/province_lookup.dart';

final _log = logicLogger();

/// Per-player extraction totals: land (same region as capital) vs overseas.
class ExtractionTotals {
  const ExtractionTotals({this.land = const {}, this.overseas = const {}});

  final Map<CommodityId, int> land;
  final Map<CommodityId, int> overseas;
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

  /// When set, only these tile keys contribute (must still be in [ConnectivityResult.connected]).
  /// Used by tests (e.g. Great Power bootstrap farms) without duplicating extraction rules.
  Set<String>? restrictToTileKeys,
}) {
  _log.d('extraction compute start players=${game.players.length}');
  final out = <String, ExtractionTotals>{};
  for (final player in game.players) {
    final cr = connectivityResult[player.id];
    final connected = cr?.connected ?? const <String>{};
    final pathTransportCap = cr?.pathTransportCap ?? const <String, int>{};
    final roadRuleTiles = cr?.connectedByRoadRule ?? const <String>{};
    final portTileKeys = game.worldState.portsByProvinceSeaboard.values.toSet();
    final cap = player.capitalTile;
    final capitalRegionId = cap?.regionId;
    final techCap = techCapForPlayer(player.id);

    final landTotals = <CommodityId, int>{};
    final overseasTotals = <CommodityId, int>{};

    final prospected =
        game.worldState.playerProspectedTiles[player.id] ?? const <String>{};

    for (final tileKey in connected) {
      if (restrictToTileKeys != null && !restrictToTileKeys.contains(tileKey)) {
        continue;
      }
      final parts = tileKey.split('|');
      if (parts.length != 4) continue;
      final regionId = parts[0];
      final x = int.tryParse(parts[2]) ?? -1;
      final y = int.tryParse(parts[3]) ?? -1;
      if (x < 0 || y < 0) continue;

      final map = tileMapByRegion[regionId];
      if (map == null) continue;

      final resource = map.resourceAt(x, y);
      if (resource == null) continue;

      final commodityId = _resourceToCommodityId(resource);
      final isMineral = kMineralResourceIds.contains(commodityId);

      // Minerals only from prospected tiles. SPEC/program/fog-and-exploration-resolution.md.
      if (isMineral && !prospected.contains(tileKey)) {
        continue;
      }
      // Province lookup must be region-scoped. SPEC/game/world-model-identity.md.
      final provinceId = '$regionId|${parts[1]}';
      final regionData = regionDataForId(game.worldState, regionId);
      final province = regionData?.provinces
          .where((p) => p.id == provinceId)
          .firstOrNull;
      if (regionData == null || province == null) {
        final msg =
            'extraction province missing tileKey=$tileKey provinceId=$provinceId '
            '(region-scoped lookup failed; SPEC/game/world-model-identity.md)';
        _log.e(msg, error: StateError(msg), stackTrace: StackTrace.current);
        continue;
      }
      final townDevelopmentCap = province.townDevelopmentLevel;
      final townTileKey = province.townTileKey;
      final townTileIsPort =
          townTileKey != null && portTileKeys.contains(townTileKey);

      final improvementLevel = game.worldState.tileState
          .improvementLevel(tileKey)
          .clamp(0, 4);
      final roadLevel = game.worldState.tileState.roadLevel(tileKey);
      final isPort = portTileKeys.contains(tileKey);
      final tileTransportLevel = isPort ? 4 : (roadLevel > 0 ? roadLevel : 0);
      final pathCap = pathTransportCap[tileKey] ?? tileTransportLevel;

      final production =
          (improvementLevel < techCap ? improvementLevel : techCap).clamp(0, 4);
      var effective = (production < pathCap ? production : pathCap).clamp(0, 4);

      final isCapitalProvince = provinceId == player.capitalProvinceId;
      final usesRoadRule = roadRuleTiles.contains(tileKey);
      if (isCapitalProvince) {
        effective =
            (effective < townDevelopmentCap ? effective : townDevelopmentCap)
                .clamp(0, 4);
      } else if (usesRoadRule) {
        // Non-capital + Road rule: town development does not cap yield.
      } else {
        // Town rule only (non-capital).
        if (townTileIsPort) {
          effective =
              (effective < townDevelopmentCap ? effective : townDevelopmentCap)
                  .clamp(0, 4);
        }
      }
      final effectiveCapped = effective;
      if (effectiveCapped <= 0) continue;

      if (regionId == capitalRegionId) {
        landTotals[commodityId] =
            (landTotals[commodityId] ?? 0) + effectiveCapped;
      } else {
        overseasTotals[commodityId] =
            (overseasTotals[commodityId] ?? 0) + effectiveCapped;
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
  _log.d(
    'extraction compute end players=${out.length} landTotal=$landSum overseasTotal=$overseasSum',
  );
  return out;
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
