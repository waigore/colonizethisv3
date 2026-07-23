part of 'map_view_provider.dart';

class _MapResourceExtractionMaps {
  const _MapResourceExtractionMaps({
    required this.unitsByTile,
    required this.effectiveUnitsByTile,
    required this.blockedUnitsByTile,
  });

  final Map<String, int> unitsByTile;
  final Map<String, int> effectiveUnitsByTile;
  final Map<String, int> blockedUnitsByTile;
}

_MapResourceExtractionMaps _mapViewBuildResourceExtractionMaps({
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
  for (final tileKey in connectivityForHuman.connected) {
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
      connectedTileKeys: connectivityForHuman.connected,
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
    final techCap = extractionCapForUnlocked(mapPlayer.techUnlocked);
    final productionUnits =
        (improvementLevel < techCap ? improvementLevel : techCap).clamp(0, 4);
    final effectiveUnits = contribution.units.clamp(0, productionUnits);
    final blockedUnits = (productionUnits - effectiveUnits).clamp(0, 4);
    if (productionUnits <= 0) {
      continue;
    }
    resourceExtractionUnitsByTile[tileKey] = productionUnits;
    resourceExtractionEffectiveUnitsByTile[tileKey] = effectiveUnits;
    resourceExtractionBlockedUnitsByTile[tileKey] = blockedUnits;
  }
  return _MapResourceExtractionMaps(
    unitsByTile: resourceExtractionUnitsByTile,
    effectiveUnitsByTile: resourceExtractionEffectiveUnitsByTile,
    blockedUnitsByTile: resourceExtractionBlockedUnitsByTile,
  );
}
