part of 'region_map_component.dart';

extension _CtRegionMapRenderOrchestrator on CtRegionMapComponent {
  TileVisibility _visibilityForTerrain(CellViewData cell) {
    if (visibilityMode != CtMapVisibilityMode.playerConstrained) {
      return cell.visibility;
    }
    if (_isUnderFleetRevealHalo(cell.x, cell.y)) {
      return TileVisibility.visible;
    }
    return cell.visibility;
  }

  bool _isUnderFleetRevealHalo(int x, int y) {
    for (final m in region.fleetTileMarkers) {
      if (!m.applyFleetRevealHalo) {
        continue;
      }
      if (math.max((x - m.x).abs(), (y - m.y).abs()) <= 2) {
        return true;
      }
    }
    return false;
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
