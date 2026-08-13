/// Province identity and terrain palette metadata for map view assembly.
/// SPEC/program/map-visualization.md § Map view model for tools.
library;

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../province_ownership_view.dart';
import '../region_data_access.dart';
import '../tile_map_colors.dart';
import '../tile_map_topology_helpers.dart';
import 'init_game_map_view_data.dart';

({
  Set<String> seaZoneIds,
  List<Province> provinces,
  Map<String, String> ownerByProvinceId,
  Map<String, String> provinceDisplayNameById,
  Map<String, String?> provincePoliticalOwnerByPrefixedProvinceId,
})
buildProvinceMetadata({
  required Game game,
  required String regionId,
  required MapTopology topology,
}) {
  final seaZoneIds = seaZoneIdsFromTopology(topology);
  final provinces = regionDataForMapRegionId(
    game.worldState,
    regionId,
  ).provinces;
  final ownerByProvinceId = provinceOwnerByIdFromProvinces(provinces);
  final provinceDisplayNameById = <String, String>{};
  final provincePoliticalOwnerByPrefixedProvinceId = <String, String?>{};
  for (final p in provinces) {
    provincePoliticalOwnerByPrefixedProvinceId[p.id] = p.ownerId;
    if (p.displayName != null && p.displayName!.isNotEmpty) {
      provinceDisplayNameById[p.id] = p.displayName!;
    }
  }
  return (
    seaZoneIds: seaZoneIds,
    provinces: provinces,
    ownerByProvinceId: ownerByProvinceId,
    provinceDisplayNameById: provinceDisplayNameById,
    provincePoliticalOwnerByPrefixedProvinceId:
        provincePoliticalOwnerByPrefixedProvinceId,
  );
}

Map<TerrainType, Rgb> buildTerrainColors(TileMapResult tileMap) {
  final terrainColors = <TerrainType, Rgb>{};
  final terrainGrid = tileMap.terrainGrid;
  if (terrainGrid == null) {
    return terrainColors;
  }
  for (final row in terrainGrid) {
    for (final terrain in row) {
      if (terrain != null && !terrainColors.containsKey(terrain)) {
        terrainColors[terrain] = terrainColorRgb[terrain]!;
      }
    }
  }
  return terrainColors;
}
