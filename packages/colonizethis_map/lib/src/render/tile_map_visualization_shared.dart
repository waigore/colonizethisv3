// Barrel for shared tile-map and game-world PNG visualization helpers.
// SPEC/program/map-visualization.md § Tile map visualizers, Legend layout abstraction.

import '../view/init_game_map_view_data.dart';

export '../tile_map_colors.dart';
export 'tile_map_resource_legend.dart';
export 'tile_map_visualization_cell_fill.dart';
export 'tile_map_visualization_legend_layout.dart';
export 'tile_map_visualization_png_markers.dart';

/// Sea-zone local ids from flattened [RegionMapViewData] cells.
///
/// Use when rendering from view data without a [MapTopology] (dual with
/// [seaZoneIdsFromTopology]). Order is not preserved; ids are unique.
Set<String> seaZoneLocalIdsFromRegionCells(List<CellViewData> cells) {
  final out = <String>{};
  for (final cell in cells) {
    if (cell.isSea) {
      out.add(cell.regionCellId);
    }
  }
  return out;
}
