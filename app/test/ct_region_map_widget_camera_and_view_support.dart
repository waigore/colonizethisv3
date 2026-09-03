// Marker / interaction helpers for CtRegionMap camera/view widget tests (Refs #4352).

import 'package:colonizethis_map/colonizethis_map.dart';

import 'ct_region_map_test_support.dart';

export 'ct_region_map_widget_camera_marker_pumps.dart';

RegionMapViewData ctRegionMapCivilianMarkerRegion({
  required String localProvinceId,
  required String markerTileKey,
  String displayName = 'Marker Province',
}) {
  return ctRegionMapMiniLandStrip(
    base: ctRegionMapTestOldWorldRegion(),
    width: 1,
    height: 1,
    cellSize: 24,
    regionCellId: localProvinceId,
    displayName: displayName,
    civilianTileMarkers: [
      ctRegionMapCivilianMarker(
        tileKey: markerTileKey,
        x: 0,
        y: 0,
        localProvinceId: localProvinceId,
      ),
    ],
  );
}

RegionMapViewData ctRegionMapFleetMarkerRegion({
  required String localSeaId,
  required String markerTileKey,
  String displayName = 'Marker Sea',
}) {
  return ctRegionMapMiniLandStrip(
    base: ctRegionMapTestOldWorldRegion(),
    width: 1,
    height: 1,
    cellSize: 24,
    regionCellId: localSeaId,
    displayName: displayName,
    sea: true,
    fleetTileMarkers: [
      ctRegionMapFleetMarker(
        tileKey: markerTileKey,
        x: 0,
        y: 0,
        locationScopeKey: 'sea:oldWorld|fleet_scope',
      ),
    ],
  );
}

RegionMapViewData ctRegionMapArmyMarkerRegion({
  required String localProvinceId,
  required String markerTileKey,
  String displayName = 'Army Province',
  List<String> armyIds = const ['army_field'],
  List<String> fieldArmyIds = const ['army_field'],
  bool hasHomeArmy = false,
  List<CivilianTileMarkerView> civilianTileMarkers = const [],
}) {
  return ctRegionMapMiniLandStrip(
    base: ctRegionMapTestOldWorldRegion(),
    width: 1,
    height: 1,
    cellSize: 24,
    regionCellId: localProvinceId,
    displayName: displayName,
    civilianTileMarkers: civilianTileMarkers,
    armyTileMarkers: [
      ctRegionMapArmyMarker(
        tileKey: markerTileKey,
        x: 0,
        y: 0,
        provinceId: 'oldWorld|$localProvinceId',
        armyIds: armyIds,
        fieldArmyIds: fieldArmyIds,
        hasHomeArmy: hasHomeArmy,
      ),
    ],
  );
}

RegionMapViewData ctRegionMapTownMarkerRegion({
  required String localProvinceId,
  String displayName = 'Town Province',
}) {
  return ctRegionMapMiniLandStrip(
    base: ctRegionMapTestOldWorldRegion(),
    width: 1,
    height: 1,
    cellSize: 24,
    regionCellId: localProvinceId,
    displayName: displayName,
    townMarkers: [
      TownMarkerView(
        x: 0,
        y: 0,
        provinceId: localProvinceId,
        isCoastal: false,
        isPort: false,
        touchesSea: false,
        townDevelopmentLevel: 1,
        townIconStyle: 'euro',
      ),
    ],
  );
}
