import 'package:flutter/material.dart';

import '../tilesets/tilesets.dart';
import 'region_map_component.dart';
import 'region_map_component_render_core_base_tiles_land.dart';
import 'region_map_component_render_core_base_tiles_sea.dart';
import 'region_map_component_render_core_transport_feature.dart';
import 'region_map_component_shared_visibility.dart';

void regionMapComponentPaintTiles(
  CtRegionMapComponent component,
  Canvas canvas,
) {
  if (!terrainTilesetCache.isLoaded) {
    return;
  }
  regionMapComponentPaintTilesWithTilesets(component, canvas);
}

void regionMapComponentPaintTilesWithTilesets(
  CtRegionMapComponent component,
  Canvas canvas,
) {
  for (final cell in component.region.cells) {
    if (cell.isSea) {
      regionMapComponentPaintSeaCell(component, canvas, cell);
    }
  }

  for (final cell in component.region.cells) {
    if (!cell.isSea) {
      regionMapComponentPaintLandBaseCell(component, canvas, cell);
    }
  }

  regionMapComponentPaintTransportOverlayTiles(component, canvas);

  regionMapComponentPaintL1PlainsInteriorResourceVariantOverlays(component, canvas);

  for (final cell in component.region.cells) {
    if (!cell.isSea &&
        cell.terrainType != null &&
        regionMapComponentIsFeatureTerrain(cell.terrainType!)) {
      regionMapComponentPaintFeatureCell(component, canvas, cell);
    }
  }
}
