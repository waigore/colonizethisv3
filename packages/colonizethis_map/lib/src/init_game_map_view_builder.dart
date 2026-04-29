/// Builder for InitGameMapViewData from game + tile maps + topology.
/// SPEC/program/map-visualization.md § Map view model for tools.
library;

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_map/package_logger.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'combine_region_topologies.dart';
import 'init_game_map_view_data.dart';
import 'port_icon_placement.dart';
import 'sea_zone_centroid_tile.dart';
import 'tile_map_visualization_shared.dart';

part 'init_game_map_view_builder_impl.dart';
part 'init_game_map_view_builder_impl2.dart';


final _log = packageLogger();

const String _regionOldWorld = 'oldWorld';
const String _regionNewWorld = 'newWorld';

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

String _homeFleetIdForMapMarker(String playerId) => 'fleet_$playerId';

bool _fleetAtHumanCapital(Game game, String playerId, Fleet fleet) {
  if (!fleet.isInPort || fleet.inPortAtProvinceId == null) {
    return false;
  }
  final player = game.players.firstWhere(
    (p) => p.id == playerId,
    orElse: () => game.players.first,
  );
  if (!player.isHuman) {
    return false;
  }
  final cap = player.capitalTile;
  if (cap == null) {
    return false;
  }
  final capParts = cap.toTileKey().split('|');
  if (capParts.length < 2) {
    return false;
  }
  final capReg = capParts[0];
  final capProvLocal = capParts[1];
  if (fleet.regionId != capReg) {
    return false;
  }
  final port = fleet.inPortAtProvinceId!;
  return port == capProvLocal || port == '$capReg|$capProvLocal';
}

bool _includeFleetForTileMarker(
  Game game,
  Fleet f,
  String regionId,
  Set<String> humanIds,
) {
  if (!humanIds.contains(f.ownerId) || f.regionId != regionId) {
    return false;
  }
  if (f.shipTypeIds.isNotEmpty) {
    return true;
  }
  return f.id == _homeFleetIdForMapMarker(f.ownerId) &&
      _fleetAtHumanCapital(game, f.ownerId, f);
}

String? _inPortFleetMarkerTileKey({
  required Game game,
  required String regionId,
  required Province province,
  required TileMapResult tileMap,
  required Set<String> seaZoneIds,
}) {
  final localProvinceId = ProvinceId.localIdFrom(province.id);
  final tileKey = harborDrawableSeaTileKeyForPortProvince(
    game: game,
    regionId: regionId,
    localProvinceId: localProvinceId,
    tileMap: tileMap,
    seaZoneIds: seaZoneIds,
    contextLabel: 'fleet marker region=$regionId province=$localProvinceId',
  );
  if (tileKey == null) {
    _log.w(
      'map: in-port fleet marker skipped: no portsByProvinceSeaboard entry '
      'for region=$regionId province=$localProvinceId',
    );
  }
  return tileKey;
}

(int?, int?) _xyFromMapTileKey(String tileKey) {
  final parts = tileKey.split('|');
  if (parts.length < 4) {
    return (null, null);
  }
  final x = int.tryParse(parts[parts.length - 2]);
  final y = int.tryParse(parts[parts.length - 1]);
  return (x, y);
}

