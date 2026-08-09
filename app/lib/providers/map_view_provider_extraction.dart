import 'package:colonizethis_app/core/utils/prefixed_id.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_economy/economy_resource_constants_api.dart'
    show kMineralResourceIds;
import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_world/colonizethis_world.dart';

import 'package:colonizethis_models/colonizethis_models.dart';

class MapResourceExtractionMaps {
  const MapResourceExtractionMaps({
    required this.unitsByTile,
    required this.effectiveUnitsByTile,
    required this.blockedUnitsByTile,
  });

  static const empty = MapResourceExtractionMaps(
    unitsByTile: {},
    effectiveUnitsByTile: {},
    blockedUnitsByTile: {},
  );

  final Map<String, int> unitsByTile;
  final Map<String, int> effectiveUnitsByTile;
  final Map<String, int> blockedUnitsByTile;
}

void _recordExtractionDiscs({
  required Map<String, int> unitsByTile,
  required Map<String, int> effectiveUnitsByTile,
  required Map<String, int> blockedUnitsByTile,
  required String tileKey,
  required int productionUnits,
  required int effectiveUnits,
  required int blockedUnits,
}) {
  if (productionUnits <= 0) {
    return;
  }
  unitsByTile[tileKey] = productionUnits;
  effectiveUnitsByTile[tileKey] = effectiveUnits;
  blockedUnitsByTile[tileKey] = blockedUnits;
}

MapResourceExtractionMaps mapViewBuildResourceExtractionMaps({
  required Game game,
  required Player mapPlayer,
  required Map<String, TileMapResult> tileMapByRegion,
  required ConnectivityResult connectivityForHuman,
}) {
  final resourceExtractionUnitsByTile = <String, int>{};
  final resourceExtractionEffectiveUnitsByTile = <String, int>{};
  final resourceExtractionBlockedUnitsByTile = <String, int>{};
  final portTileKeys = game.worldState.portsByProvinceSeaboard.values.toSet();
  final prospected =
      game.worldState.playerProspectedTiles[mapPlayer.id] ?? const <String>{};
  final provincesByFullId = game.worldState.allProvincesById;
  final connected = connectivityForHuman.connected;
  final techCap = extractionCapForUnlocked(mapPlayer.techUnlocked);

  for (final tileKey in connected) {
    final parsed = tryParseTileKey(tileKey);
    if (parsed == null) {
      continue;
    }
    final regionId = parsed.regionId;
    final localProvinceId = parsed.provinceLocalId;
    final ownedByHuman = game.worldState
        .provincesForRegion(regionId)
        .any(
          (province) =>
              province.id == '$regionId|$localProvinceId' &&
              province.ownerId == mapPlayer.id,
        );
    if (!ownedByHuman) {
      continue;
    }
    final contribution = computeTileExtractionContributionForPlayer(
      game: game,
      tileMapByRegion: tileMapByRegion,
      player: mapPlayer,
      tileKey: tileKey,
      connectedTileKeys: connected,
      pathTransportCap: connectivityForHuman.pathTransportCap,
      connectedByRoadRule: connectivityForHuman.connectedByRoadRule,
      portTileKeys: portTileKeys,
      prospectedTileKeys: prospected,
      capitalRegionId: mapPlayer.capitalTile?.regionId,
      techCapForPlayer: (id) {
        final player = game.playerById(id);
        return extractionCapForUnlocked(player?.techUnlocked);
      },
      provincesByFullId: provincesByFullId,
    );
    if (contribution == null) {
      continue;
    }
    final improvementLevel = game.worldState.tileState
        .improvementLevel(tileKey)
        .clamp(0, 4);
    final productionUnits =
        (improvementLevel < techCap ? improvementLevel : techCap).clamp(0, 4);
    final effectiveUnits = contribution.units.clamp(0, productionUnits);
    final blockedUnits = (productionUnits - effectiveUnits).clamp(0, 4);
    _recordExtractionDiscs(
      unitsByTile: resourceExtractionUnitsByTile,
      effectiveUnitsByTile: resourceExtractionEffectiveUnitsByTile,
      blockedUnitsByTile: resourceExtractionBlockedUnitsByTile,
      tileKey: tileKey,
      productionUnits: productionUnits,
      effectiveUnits: effectiveUnits,
      blockedUnits: blockedUnits,
    );
  }

  for (final regionEntry in game.worldState.tileKeysByRegionAndProvince.entries) {
    for (final provinceEntry in regionEntry.value.entries) {
      final province = provincesByFullId[provinceEntry.key] ??
          game.worldState.tryGetProvince(provinceEntry.key);
      if (province?.ownerId != mapPlayer.id) {
        continue;
      }
      for (final tileKey in provinceEntry.value) {
        if (connected.contains(tileKey)) {
          continue;
        }
        final contribution = computeTileExtractionDisplayContribution(
          game: game,
          tileMapByRegion: tileMapByRegion,
          tileKey: tileKey,
          connectedTileKeys: connected,
          pathTransportCap: connectivityForHuman.pathTransportCap,
          connectedByRoadRule: connectivityForHuman.connectedByRoadRule,
          portTileKeys: portTileKeys,
          capitalProvinceId: mapPlayer.capitalProvinceId,
          techCapForCommodity: (_) => techCap,
          isCommodityExtractable: (tk, commodityId) =>
              !kMineralResourceIds.contains(commodityId) ||
              prospected.contains(tk),
          provincesByFullId: provincesByFullId,
        );
        if (contribution == null || contribution.full <= 0) {
          continue;
        }
        final productionUnits = contribution.full;
        _recordExtractionDiscs(
          unitsByTile: resourceExtractionUnitsByTile,
          effectiveUnitsByTile: resourceExtractionEffectiveUnitsByTile,
          blockedUnitsByTile: resourceExtractionBlockedUnitsByTile,
          tileKey: tileKey,
          productionUnits: productionUnits,
          effectiveUnits: 0,
          blockedUnits: productionUnits,
        );
      }
    }
  }

  return MapResourceExtractionMaps(
    unitsByTile: resourceExtractionUnitsByTile,
    effectiveUnitsByTile: resourceExtractionEffectiveUnitsByTile,
    blockedUnitsByTile: resourceExtractionBlockedUnitsByTile,
  );
}
