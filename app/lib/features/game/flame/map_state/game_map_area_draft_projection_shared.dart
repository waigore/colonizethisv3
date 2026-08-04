import 'package:colonizethis_map/colonizethis_map.dart';

/// Shared helpers for fleet/civilian draft projection modules (#4240 Slice D).
abstract final class GameMapAreaDraftProjectionShared {
  static int compareTileMarkerMapPosition({
    required int ay,
    required int ax,
    required String aTileKey,
    required int by,
    required int bx,
    required String bTileKey,
  }) {
    final yc = ay.compareTo(by);
    if (yc != 0) {
      return yc;
    }
    final xc = ax.compareTo(bx);
    if (xc != 0) {
      return xc;
    }
    return aTileKey.compareTo(bTileKey);
  }

  static void sortFleetTileMarkersByMapPosition(
    List<FleetTileMarkerView> markers,
  ) {
    markers.sort(
      (a, b) => compareTileMarkerMapPosition(
        ay: a.y,
        ax: a.x,
        aTileKey: a.tileKey,
        by: b.y,
        bx: b.x,
        bTileKey: b.tileKey,
      ),
    );
  }

  static void sortCivilianTileMarkersByMapPosition(
    List<CivilianTileMarkerView> markers,
  ) {
    markers.sort(
      (a, b) => compareTileMarkerMapPosition(
        ay: a.y,
        ax: a.x,
        aTileKey: a.tileKey,
        by: b.y,
        bx: b.x,
        bTileKey: b.tileKey,
      ),
    );
  }

  static RegionMapViewData copyRegionMapViewDataMarkerLayers({
    required RegionMapViewData region,
    List<CivilianTileMarkerView>? civilianTileMarkers,
    List<FleetTileMarkerView>? fleetTileMarkers,
  }) {
    return RegionMapViewData(
      regionId: region.regionId,
      width: region.width,
      height: region.height,
      cellSize: region.cellSize,
      cells: region.cells,
      capitalMarkers: region.capitalMarkers,
      portMarkers: region.portMarkers,
      factionColors: region.factionColors,
      greatPowerFactionIds: region.greatPowerFactionIds,
      terrainColors: region.terrainColors,
      unitMarkers: region.unitMarkers,
      civilianTileMarkers: civilianTileMarkers ?? region.civilianTileMarkers,
      fleetTileMarkers: fleetTileMarkers ?? region.fleetTileMarkers,
      warpMarkers: region.warpMarkers,
      townMarkers: region.townMarkers,
      provinceUnitPresenceByProvinceId: region.provinceUnitPresenceByProvinceId,
      provincePoliticalOwnerByPrefixedProvinceId:
          region.provincePoliticalOwnerByPrefixedProvinceId,
      seaZoneDisplayNameByPrefixedId: region.seaZoneDisplayNameByPrefixedId,
    );
  }
}
