
part of 'region_map_component.dart';

extension _CtRegionMapRenderCoreTiles on CtRegionMapComponent {
  void _paintTiles(Canvas canvas) {
    if (!terrainTilesetCache.isLoaded) {
      return;
    }
    _paintTilesWithTilesets(canvas);
  }

  void _paintTilesWithTilesets(Canvas canvas) {
    for (final cell in region.cells) {
      if (cell.isSea) {
        _paintSeaCell(canvas, cell);
      }
    }

    for (final cell in region.cells) {
      if (!cell.isSea) {
        _paintLandBaseCell(canvas, cell);
      }
    }

    _paintTransportOverlayTiles(canvas);

    _paintL1PlainsInteriorResourceVariantOverlays(canvas);

    for (final cell in region.cells) {
      if (!cell.isSea &&
          cell.terrainType != null &&
          regionMapComponentIsFeatureTerrain(cell.terrainType!)) {
        _paintFeatureCell(canvas, cell);
      }
    }
  }
}
