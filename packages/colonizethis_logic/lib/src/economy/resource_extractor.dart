import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

/// Per-player extraction totals: land (same region as capital) vs overseas.
class ExtractionTotals {
  const ExtractionTotals({
    this.land = const {},
    this.overseas = const {},
  });

  final Map<CommodityId, int> land;
  final Map<CommodityId, int> overseas;
}

/// Computes per-player extraction from connected tiles. SPEC/game/extraction-and-improvements.
///
/// For each connected tile: production = min(improvementLevel, techCap);
/// transportLevel = road level (0/1/2/4); town development level caps yield (SPEC capital-and-connectivity).
/// effective = min(production, transportLevel, province.townDevelopmentLevel).
/// Sums by commodity; splits land (same region as capital) vs overseas.
Map<String, ExtractionTotals> computeExtraction({
  required Game game,
  required Map<String, TileMapResult> tileMapByRegion,
  required Map<String, Set<String>> connectivityResult,
  int Function(String playerId) techCapForPlayer = _defaultTechCap,
}) {
  final out = <String, ExtractionTotals>{};
  for (final player in game.players) {
    final connected = connectivityResult[player.id];
    if (connected == null || connected.isEmpty) {
      out[player.id] = const ExtractionTotals();
      continue;
    }
    final cap = player.capitalTile;
    final capitalRegionId = cap?.regionId;
    final techCap = techCapForPlayer(player.id);

    final landTotals = <CommodityId, int>{};
    final overseasTotals = <CommodityId, int>{};

    final prospected = game.worldState.playerProspectedTiles[player.id] ?? const <String>{};

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
      final isMineral = commodityId == 'iron' ||
          commodityId == 'copper' ||
          commodityId == 'tin' ||
          commodityId == 'coal' ||
          commodityId == 'silver' ||
          commodityId == 'gold' ||
          commodityId == 'gems' ||
          commodityId == 'diamonds';

      // Minerals only from prospected tiles. SPEC/program/fog-and-exploration-resolution.md.
      if (isMineral && !prospected.contains(tileKey)) {
        continue;
      }
      final provinceId = '$regionId|${parts[1]}';
      final province = game.worldState.oldWorld.provinces.where((p) => p.id == provinceId).firstOrNull ??
          game.worldState.newWorld.provinces.where((p) => p.id == provinceId).firstOrNull;
      final townDevelopmentCap = province?.townDevelopmentLevel ?? 4;

      final improvementLevel = game.worldState.tileState.improvementLevel(tileKey).clamp(0, 4);
      final roadLevel = game.worldState.tileState.roadLevel(tileKey);
      final isPort = game.worldState.portsByProvinceSeaboard.values.contains(tileKey);
      final transportLevel = isPort ? 4 : (roadLevel > 0 ? roadLevel : 0);

      final production = (improvementLevel < techCap ? improvementLevel : techCap).clamp(0, 4);
      final effective = (production < transportLevel ? production : transportLevel).clamp(0, 4);
      final effectiveCapped = (effective < townDevelopmentCap ? effective : townDevelopmentCap).clamp(0, 4);
      if (effectiveCapped <= 0) continue;

      if (regionId == capitalRegionId) {
        landTotals[commodityId] = (landTotals[commodityId] ?? 0) + effectiveCapped;
      } else {
        overseasTotals[commodityId] = (overseasTotals[commodityId] ?? 0) + effectiveCapped;
      }
    }

    out[player.id] = ExtractionTotals(land: landTotals, overseas: overseasTotals);
  }
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
