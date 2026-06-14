/// Builder for InitGameMapViewData from game + tile maps + topology.
/// SPEC/program/map-visualization.md § Map view model for tools.
library;

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_map/package_logger.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'combine_region_topologies.dart';
import 'init_game_map_view_data.dart';
import 'map_pipe_string_util.dart';
import 'port_icon_placement.dart';
import 'province_ownership_view.dart';
import 'region_constants.dart';
import 'sea_zone_centroid_tile.dart';
import 'tile_key_util.dart';
import 'tile_map_capital_markers.dart';
import 'tile_map_topology_helpers.dart';
import 'tile_map_visualization_shared.dart';

part 'init_game_map_view_builder_fleet_markers_part.dart';
part 'init_game_map_view_builder_orchestration_part.dart';
part 'init_game_map_view_builder_cells_markers_part.dart';
part 'init_game_map_view_builder_map_markers_part.dart';

final _log = packageLogger();

String _normalizeCivilianTypeForPriority(String type) {
  return type.toLowerCase().replaceAll(RegExp(r'[\s_\-]'), '');
}

int _civilianIconPriorityForType(String type) {
  final normalized = _normalizeCivilianTypeForPriority(type);
  // Lower number = higher icon priority.
  switch (normalized) {
    case 'builder':
      return 0;
    case 'engineer':
      return 1;
    case 'railbuilder':
      return 2;
    case 'explorer':
      return 3;
    case 'merchant':
      return 4;
    case 'spy':
      return 5;
    default:
      return 999;
  }
}

bool _isCivilianUnitType(String unitType) {
  final role = unitRoleForType(unitType);
  if (role == null) {
    return false;
  }
  return role != UnitRole.military && role != UnitRole.naval;
}
