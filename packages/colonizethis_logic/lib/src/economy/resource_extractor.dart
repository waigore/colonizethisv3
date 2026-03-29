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
/// effective = min(production, pathTransportCap, province.townDevelopmentLevel).
/// Path transport cap = min road/port level along path to town then to capital (from [connectivityResult]);
/// when absent, falls back to tile's own transport level.
/// Sums by commodity; splits land (same region as capital) vs overseas.
Map<String, ExtractionTotals> computeExtraction({
  required Game game,
  required Map<String, TileMapResult> tileMapByRegion,
  required Map<String, ConnectivityResult> connectivityResult,
  int Function(String playerId) techCapForPlayer = _defaultTechCap,
}) {
  _log.d('extraction compute start players=${game.players.length}');
  final out = <String, ExtractionTotals>{};
  for (final player in game.players) {
    final cr = connectivityResult[player.id];
    final connected = cr?.connected;
    if (connected == null || connected.isEmpty) {
      out[player.id] = const ExtractionTotals();
      continue;
    }
    final pathTransportCap = cr!.pathTransportCap;
    final cap = player.capitalTile;
    final capitalRegionId = cap?.regionId;
    final techCap = techCapForPlayer(player.id);

    final landTotals = <CommodityId, int>{};
    final overseasTotals = <CommodityId, int>{};

    final prospected =
        game.worldState.playerProspectedTiles[player.id] ?? const <String>{};

    for (final tileKey in connected) {
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
      final townDevelopmentCap = province?.townDevelopmentLevel ?? 4;

      final improvementLevel = game.worldState.tileState
          .improvementLevel(tileKey)
          .clamp(0, 4);
      final roadLevel = game.worldState.tileState.roadLevel(tileKey);
      final isPort = game.worldState.portsByProvinceSeaboard.values.contains(
        tileKey,
      );
      final tileTransportLevel = isPort ? 4 : (roadLevel > 0 ? roadLevel : 0);
      final pathCap = pathTransportCap[tileKey] ?? tileTransportLevel;

      final production =
          (improvementLevel < techCap ? improvementLevel : techCap).clamp(0, 4);
      final effective = (production < pathCap ? production : pathCap).clamp(
        0,
        4,
      );
      final effectiveCapped =
          (effective < townDevelopmentCap ? effective : townDevelopmentCap)
              .clamp(0, 4);
      if (effectiveCapped <= 0) continue;

      if (regionId == capitalRegionId) {
        landTotals[commodityId] =
            (landTotals[commodityId] ?? 0) + effectiveCapped;
      } else {
        overseasTotals[commodityId] =
            (overseasTotals[commodityId] ?? 0) + effectiveCapped;
      }
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
