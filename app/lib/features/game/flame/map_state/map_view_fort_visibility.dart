import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_world/colonizethis_world.dart';

/// Resolves whether a province fort glyph should appear on the map for the
/// current player view. Refs #4280; military-intel gate matches #4216.
int? resolveMapVisibleFortLevel({
  required Game game,
  required PlayerView view,
  required String humanPlayerId,
  required String prefixedProvinceId,
  required int worldFortLevel,
  required bool revealAllForts,
}) {
  if (worldFortLevel < 1) return null;
  if (revealAllForts) return worldFortLevel.clamp(1, 3);
  final province = game.worldState.tryGetProvince(prefixedProvinceId);
  if (province?.ownerId == humanPlayerId) {
    return worldFortLevel.clamp(1, 3);
  }
  final regionId = ProvinceId.regionIdFrom(prefixedProvinceId);
  final tileKeys =
      game.worldState.tileKeysByRegionAndProvince[regionId]?[prefixedProvinceId] ??
      const <String>[];
  if (provincePanelShowsFullTileDerivedIntel(
    game: game,
    view: view,
    humanPlayerId: humanPlayerId,
    provinceId: prefixedProvinceId,
    provinceTileKeys: tileKeys,
  )) {
    return worldFortLevel.clamp(1, 3);
  }
  return null;
}

InitGameMapViewData applyMapFortVisibility({
  required InitGameMapViewData data,
  required Game game,
  required PlayerView view,
  required String humanPlayerId,
  required bool revealAllForts,
}) {
  RegionMapViewData applyRegion(RegionMapViewData region) {
    final towns = [
      for (final town in region.townMarkers)
        TownMarkerView(
          x: town.x,
          y: town.y,
          provinceId: town.provinceId,
          isCoastal: town.isCoastal,
          isPort: town.isPort,
          touchesSea: town.touchesSea,
          townDevelopmentLevel: town.townDevelopmentLevel,
          townIconStyle: town.townIconStyle,
          portIconX: town.portIconX,
          portIconY: town.portIconY,
          worldFortLevel: town.worldFortLevel,
          mapVisibleFortLevel: resolveMapVisibleFortLevel(
            game: game,
            view: view,
            humanPlayerId: humanPlayerId,
            prefixedProvinceId: '${region.regionId}|${town.provinceId}',
            worldFortLevel: town.worldFortLevel,
            revealAllForts: revealAllForts,
          ),
        ),
    ];
    return RegionMapViewData(
      regionId: region.regionId,
      width: region.width,
      height: region.height,
      cellSize: region.cellSize,
      cells: region.cells,
      capitalMarkers: region.capitalMarkers,
      portMarkers: region.portMarkers,
      warpMarkers: region.warpMarkers,
      townMarkers: towns,
      factionColors: region.factionColors,
      greatPowerFactionIds: region.greatPowerFactionIds,
      terrainColors: region.terrainColors,
      unitMarkers: region.unitMarkers,
      civilianTileMarkers: region.civilianTileMarkers,
      fleetTileMarkers: region.fleetTileMarkers,
      provinceUnitPresenceByProvinceId: region.provinceUnitPresenceByProvinceId,
      provincePoliticalOwnerByPrefixedProvinceId:
          region.provincePoliticalOwnerByPrefixedProvinceId,
      seaZoneDisplayNameByPrefixedId: region.seaZoneDisplayNameByPrefixedId,
    );
  }

  return InitGameMapViewData(
    oldWorld: applyRegion(data.oldWorld),
    newWorld: applyRegion(data.newWorld),
    combinedTopology: data.combinedTopology,
    seed: data.seed,
    configSummary: data.configSummary,
  );
}
