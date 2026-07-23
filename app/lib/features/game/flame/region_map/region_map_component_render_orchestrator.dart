import 'package:flutter/material.dart';

import 'region_map_component.dart';
import 'region_map_component_render_core.dart';
import 'region_map_component_render_core_overlays.dart';
import 'region_map_component_render_markers_selection.dart';
import 'region_map_component_render_markers_settlements_capitals.dart';
import 'region_map_component_render_markers_settlements_towns.dart';
import 'region_map_component_render_markers_settlements_warp.dart';
import 'region_map_component_render_markers_units_civilian.dart';
import 'region_map_component_render_markers_units_fleet.dart';
import 'region_map_component_render_political_borders_faction.dart';
import 'region_map_component_render_political_borders_province.dart';
import 'region_map_component_render_political_labels_province_paint.dart';
import 'region_map_component_render_political_labels_sea.dart';

void regionMapComponentRenderRegionMap(
  CtRegionMapComponent component,
  Canvas canvas,
) {
  regionMapComponentPaintTiles(component, canvas);
  if (component.showProvinceOwnershipTint) {
    regionMapComponentPaintGreatPowerLandOwnershipTint(component, canvas);
  }
  regionMapComponentPaintOverlay(component, canvas);
  if (component.showProvinceOverlay) {
    regionMapComponentPaintProvinceBorders(component, canvas);
  }
  if (component.session.hoveredProvinceId != null) {
    regionMapComponentPaintHoveredProvinceGlow(component, canvas);
  }
  if (component.showPoliticalOverlay && component.showProvinceOverlay) {
    regionMapComponentPaintFactionBorders(component, canvas);
  }
  if (component.showProvinceNamesLayer) {
    regionMapComponentPaintProvinceNames(component, canvas);
    regionMapComponentPaintSeaZoneNames(component, canvas);
  }
  regionMapComponentPaintCapitals(component, canvas);
  regionMapComponentPaintTowns(component, canvas);
  regionMapComponentPaintWarpZones(component, canvas);
  regionMapComponentPaintCivilianTileMarkers(component, canvas);
  regionMapComponentPaintFleetTileMarkers(component, canvas);
  if (component.session.hoveredTileX != null && component.session.hoveredTileY != null) {
    regionMapComponentPaintSelector(component, canvas);
  }
  if (component.selectedTileKey != null) {
    regionMapComponentPaintSelectedTile(component, canvas);
  }
  final multiSecondary = component.secondaryHighlightTileKeys;
  if (multiSecondary != null && multiSecondary.isNotEmpty) {
    regionMapComponentPaintSecondaryHighlightTiles(
      component,
      canvas,
      multiSecondary,
    );
  } else if (component.secondaryHighlightTileKey != null) {
    regionMapComponentPaintSecondaryHighlightTile(component, canvas);
  }
  if (component.validTileKeys != null && component.validTileKeys!.isNotEmpty) {
    regionMapComponentPaintValidTilesGlow(component, canvas);
  }
}
