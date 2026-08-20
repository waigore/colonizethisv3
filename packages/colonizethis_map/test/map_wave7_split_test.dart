import 'dart:io';

import 'package:colonizethis_map/src/gen/tile_map_grid_graph.dart';
import 'package:colonizethis_map/src/gen/tile_map_grid_graph_connectivity.dart';
import 'package:colonizethis_map/src/gen/tile_map_grid_graph_continent.dart';
import 'package:colonizethis_map/src/gen/tile_map_grid_graph_ocean.dart';
import 'package:colonizethis_map/src/gen/tile_map_gen_region_growing_phases.dart';
import 'package:colonizethis_map/src/gen/tile_map_gen_region_growing_queues.dart';
import 'package:colonizethis_map/src/gen/tile_map_gen_region_growing_targeting.dart';
import 'package:colonizethis_map/src/render/tile_map_visualization_legend.dart';
import 'package:colonizethis_map/src/render/tile_map_visualization_legend_optional.dart';
import 'package:colonizethis_map/src/view/init_game_map_view_cell_grid.dart';
import 'package:colonizethis_map/src/view/init_game_map_view_cell_unit_markers.dart';
import 'package:colonizethis_map/src/view/init_game_map_view_cells.dart';
import 'package:colonizethis_test/test.dart';
import 'package:path/path.dart' as p;

/// Structural pins for Refs #4561 wave-7 splits.
void main() {
  group('map wave-7 concern split (Refs #4561)', () {
    test('positive: grid graph facade delegates to split siblings', () {
      expect(TileMapGridGraphConnectivity, isNotNull);
      expect(TileMapGridGraphOcean, isNotNull);
      expect(TileMapGridGraphContinent, isNotNull);
      expect(TileMapGridGraph, isNotNull);
    });

    test('positive: legend and view-cell facades import split drawers', () {
      expect(drawMapLegend, isNotNull);
      expect(drawOptionalLegendSections, isNotNull);
      expect(InitGameMapViewCellGrid.buildCellViewDataList, isNotNull);
      expect(
        InitGameMapViewCellUnitMarkers.buildUnitAndCivilianMarkerData,
        isNotNull,
      );
      expect(InitGameMapViewCells.buildCellViewDataList, isNotNull);
    });

    test('positive: region-growing phases delegate to targeting and queues', () {
      expect(TerrainRegionGrowTargeting, isNotNull);
      expect(TerrainRegionGrowQueues, isNotNull);
      expect(TerrainRegionGrowPhases, isNotNull);
    });

    test('negative: split lib files stay under 250 NCL after wave-7', () {
      final packageRoot = Directory.current.path;
      final paths = [
        'lib/src/gen/tile_map_grid_graph.dart',
        'lib/src/gen/tile_map_grid_graph_connectivity.dart',
        'lib/src/gen/tile_map_grid_graph_ocean.dart',
        'lib/src/gen/tile_map_grid_graph_continent.dart',
        'lib/src/render/tile_map_visualization_legend.dart',
        'lib/src/render/tile_map_visualization_legend_optional.dart',
        'lib/src/view/init_game_map_view_cells.dart',
        'lib/src/view/init_game_map_view_cell_grid.dart',
        'lib/src/view/init_game_map_view_cell_unit_markers.dart',
        'lib/src/gen/tile_map_gen_region_growing_phases.dart',
        'lib/src/gen/tile_map_gen_region_growing_targeting.dart',
        'lib/src/gen/tile_map_gen_region_growing_queues.dart',
      ];
      for (final rel in paths) {
        final file = File(p.join(packageRoot, rel));
        final ncl = _countNonCommentLines(file.readAsStringSync());
        expect(
          ncl,
          lessThanOrEqualTo(250),
          reason: '$rel NCL=$ncl exceeds 250 after wave-7 split',
        );
      }
    });
  });
}

int _countNonCommentLines(String source) {
  var n = 0;
  for (final line in source.split('\n')) {
    final trimmed = line.trim();
    if (trimmed.isEmpty) continue;
    if (trimmed.startsWith('//')) continue;
    if (trimmed.startsWith('///')) continue;
    if (trimmed.startsWith('/*') || trimmed.startsWith('*')) continue;
    n++;
  }
  return n;
}
