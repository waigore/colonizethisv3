/// Fleet marker location-scope → tile-key resolution.
/// SPEC/program/map-visualization.md. Refs #4654.
library;

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_map/package_logger.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../map_pipe_string_util.dart';
import '../port_icon_placement.dart';
import '../sea_zone_centroid_tile.dart';
import '../tile_key_util.dart';

final _log = packageLogger();

String? inPortFleetMarkerTileKey({
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

(int?, int?) xyFromMapTileKey(String tileKey) {
  final parsed = tryParseMapTileKeySuffixXY(tileKey);
  if (parsed == null) {
    return (null, null);
  }
  return (parsed.x, parsed.y);
}

String? fleetMarkerTileKeyForLocationScope({
  required String scopeKey,
  required String regionId,
  required Game game,
  required TileMapResult tileMap,
  required Set<String> seaZoneIds,
  required Map<String, Province> provinceMap,
}) {
  if (scopeKey.startsWith('sea:')) {
    final zoneKey = scopeKey.substring(4);
    final local = mapPipeLastSegmentOrWhole(zoneKey);
    return seaZoneCentroidTileKey(
      tileMap: tileMap,
      regionId: regionId,
      localSeaZoneId: local,
      seaZoneNodeIds: seaZoneIds,
    );
  }
  if (!scopeKey.startsWith('port:')) return null;
  final fullProv = scopeKey.substring(5);
  final province = provinceMap[fullProv];
  if (province == null) return null;
  return inPortFleetMarkerTileKey(
    game: game,
    regionId: regionId,
    province: province,
    tileMap: tileMap,
    seaZoneIds: seaZoneIds,
  );
}

void addFleetToLocationBuckets({
  required Fleet fleet,
  required String regionId,
  required Map<String, Province> provinceMap,
  required Map<String, List<Fleet>> byLocation,
}) {
  if (fleet.isAtSea && fleet.seaZoneId != null) {
    final z = fleet.seaZoneId!;
    final zoneKey = z.contains('|') ? z : '$regionId|$z';
    byLocation.putIfAbsent('sea:$zoneKey', () => []).add(fleet);
    return;
  }
  if (fleet.inPortAtProvinceId == null) return;
  final province =
      provinceMap['$regionId|${fleet.inPortAtProvinceId}'] ??
      provinceMap[fleet.inPortAtProvinceId!];
  if (province == null) return;
  byLocation
      .putIfAbsent('port:${province.regionId}|${province.id}', () => [])
      .add(fleet);
}
