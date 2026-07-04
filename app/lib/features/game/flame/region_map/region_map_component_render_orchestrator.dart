
part of 'region_map_component.dart';

extension _CtRegionMapRenderOrchestrator on CtRegionMapComponent {
  TileVisibility _visibilityForTerrain(CellViewData cell) {
    return visibilityForTerrainForMapCell(
      visibilityMode: visibilityMode,
      cell: cell,
      fleetTileMarkers: region.fleetTileMarkers,
      civilianTileMarkers: region.civilianTileMarkers,
    );
  }

  void _renderRegionMap(Canvas canvas) {
    _paintTiles(canvas);
    if (showProvinceOwnershipTint) {
      _paintGreatPowerLandOwnershipTint(canvas);
    }
    _paintOverlay(canvas);
    if (showProvinceOverlay) {
      _paintProvinceBorders(canvas);
    }
    if (_hoveredProvinceId != null) {
      _paintHoveredProvinceGlow(canvas);
    }
    if (showPoliticalOverlay && showProvinceOverlay) {
      _paintFactionBorders(canvas);
    }
    if (showProvinceNamesLayer) {
      _paintProvinceNames(canvas);
      _paintSeaZoneNames(canvas);
    }
    _paintCapitals(canvas);
    _paintTowns(canvas);
    _paintWarpZones(canvas);
    _paintCivilianTileMarkers(canvas);
    _paintFleetTileMarkers(canvas);
    if (_hoveredTileX != null && _hoveredTileY != null) {
      _paintSelector(canvas);
    }
    if (selectedTileKey != null) {
      _paintSelectedTile(canvas);
    }
    if (secondaryHighlightTileKey != null) {
      _paintSecondaryHighlightTile(canvas);
    }
    if (validTileKeys != null && validTileKeys!.isNotEmpty) {
      _paintValidTilesGlow(canvas);
    }
  }
}
