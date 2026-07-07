part of 'region_map_component.dart';

Future<void> _ctRegionMapComponentAfterSuperOnLoad(
  CtRegionMapComponent component,
) async {
  await Future.wait([
    terrainTilesetCache.load(),
    transportOverlayTilesetCache.load(),
    resourceIconCache.load(),
    civilianIconCache.load(),
    townIconCache.load(),
    provinceLabelIconCache.load(),
  ]);
  // Fleet icon uses ui.decodeImageFromList; awaiting it here can deadlock with
  // Flutter's test/game bootstrap (decode needs frames while onLoad blocks).
  unawaited(
    fleetIconCache.load().catchError((Object _, StackTrace stackTrace) {
      // Errors are already logged inside FleetIconCache.load.
    }),
  );
  _log.i(
    'TerrainTilesetCache loaded. '
    'sea_plains: ${terrainTilesetCache.getSeaPlainsTileset() != null}, '
    'sea_desert: ${terrainTilesetCache.getSeaDesertTileset() != null}, '
    'plains_desert: ${terrainTilesetCache.getPlainsDesertTileset() != null}. '
    'TransportOverlayTilesetCache loaded: ${transportOverlayTilesetCache.isLoaded}. '
    'ResourceIconCache loaded: ${resourceIconCache.isLoaded}. '
    'CivilianIconCache loaded: ${civilianIconCache.isLoaded}. '
    'TownIconCache loaded: ${townIconCache.isLoaded}. '
    'ProvinceLabelIconCache loaded: ${provinceLabelIconCache.isLoaded}',
  );
  component.size = Vector2(
    component.region.width * component.cellSize,
    component.region.height * component.cellSize,
  );
}

void _ctRegionMapComponentAdvanceHoverAnimation(
  CtRegionMapComponent component,
  double dt,
) {
  component._hoverAnimationT += dt;
}
