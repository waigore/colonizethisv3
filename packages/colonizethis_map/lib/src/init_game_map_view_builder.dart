/// Builder for InitGameMapViewData from game + tile maps + topology.
/// SPEC/program/map-visualization.md § Map view model for tools.
library;

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_map/package_logger.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'civilian_unit_view.dart';
import 'combine_region_topologies.dart';
import 'init_game_map_view_data.dart';
import 'map_pipe_string_util.dart';
import 'port_icon_placement.dart';
import 'province_ownership_view.dart';
import 'region_constants.dart';
import 'region_data_access.dart';
import 'sea_zone_centroid_tile.dart';
import 'tile_key_util.dart';
import 'tile_map_capital_markers.dart';
import 'tile_map_grid.dart';
import 'tile_map_topology_helpers.dart';
import 'render/tile_map_visualization_shared.dart';

part 'init_game_map_view_builder_fleet_markers_part.dart';
part 'init_game_map_view_builder_orchestration_part.dart';
part 'init_game_map_view_builder_cells_markers_part.dart';
part 'init_game_map_view_builder_map_markers_part.dart';

final _log = packageLogger();
