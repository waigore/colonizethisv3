
part of 'region_map_component.dart';

extension _CtRegionMapRenderOrchestrator on CtRegionMapComponent {
  TileVisibility _visibilityForTerrain(CellViewData cell) {
    return regionMapComponentVisibilityForTerrain(this, cell);
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
    if (session.hoveredProvinceId != null) {
      _paintHoveredProvinceGlow(canvas);
    }
    if (showPoliticalOverlay && showProvinceOverlay) {
      _paintFactionBorders(canvas);
    }
    if (showProvinceNamesLayer) {
      _paintProvinceNames(canvas);
      _paintSeaZoneNames(canvas);
    }
    regionMapComponentPaintCapitals(this, canvas);
    regionMapComponentPaintTowns(this, canvas);
    regionMapComponentPaintWarpZones(this, canvas);
    regionMapComponentPaintCivilianTileMarkers(this, canvas);
    regionMapComponentPaintFleetTileMarkers(this, canvas);
    if (session.hoveredTileX != null && session.hoveredTileY != null) {
      regionMapComponentPaintSelector(this, canvas);
    }
    if (selectedTileKey != null) {
      regionMapComponentPaintSelectedTile(this, canvas);
    }
    final multiSecondary = secondaryHighlightTileKeys;
    if (multiSecondary != null && multiSecondary.isNotEmpty) {
      regionMapComponentPaintSecondaryHighlightTiles(
        this,
        canvas,
        multiSecondary,
      );
    } else if (secondaryHighlightTileKey != null) {
      regionMapComponentPaintSecondaryHighlightTile(this, canvas);
    }
    if (validTileKeys != null && validTileKeys!.isNotEmpty) {
      regionMapComponentPaintValidTilesGlow(this, canvas);
    }
  }
}
