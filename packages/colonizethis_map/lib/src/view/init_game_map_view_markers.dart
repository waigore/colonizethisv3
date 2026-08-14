/// Thin façade for map marker builders (fleet, army, land/overlay).
/// SPEC/program/map-visualization.md § Map view model for tools. Refs #4022.
library;

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'init_game_map_view_army_markers.dart';
import 'init_game_map_view_data.dart';
import 'init_game_map_view_fleet_markers.dart';
import 'init_game_map_view_land_markers.dart';

/// Stateless facade over [InitGameMapViewFleetMarkers] and
/// [InitGameMapViewLandMarkers] so builder call sites stay compact.
class InitGameMapViewMarkers {
  const InitGameMapViewMarkers._();

  static List<FleetTileMarkerView> buildFleetTileMarkersForRegion({
    required Game game,
    required String regionId,
    required List<Province> provinces,
    required TileMapResult tileMap,
    required Set<String> seaZoneIds,
  }) => InitGameMapViewFleetMarkers.buildFleetTileMarkersForRegion(
    game: game,
    regionId: regionId,
    provinces: provinces,
    tileMap: tileMap,
    seaZoneIds: seaZoneIds,
  );

  static List<CapitalMarkerView> buildCapitalMarkers({
    required Game game,
    required String regionId,
  }) => InitGameMapViewLandMarkers.buildCapitalMarkers(
    game: game,
    regionId: regionId,
  );

  static List<PortMarkerView> buildPortMarkers({
    required String regionId,
    required Map<String, String> portsByProvinceSeaboard,
  }) => InitGameMapViewLandMarkers.buildPortMarkers(
    regionId: regionId,
    portsByProvinceSeaboard: portsByProvinceSeaboard,
  );

  static Set<String> buildCoastalProvinceIds({
    required MapTopology topology,
    required Set<String> seaZoneIds,
  }) => InitGameMapViewLandMarkers.buildCoastalProvinceIds(
    topology: topology,
    seaZoneIds: seaZoneIds,
  );

  static List<TownMarkerView> buildTownMarkers({
    required Game game,
    required String regionId,
    required List<Province> provinces,
    required List<PortMarkerView> ports,
    required Set<String> coastalProvinceIds,
    required TileMapResult tileMap,
    required Set<String> seaZoneIds,
  }) => InitGameMapViewLandMarkers.buildTownMarkers(
    game: game,
    regionId: regionId,
    provinces: provinces,
    ports: ports,
    coastalProvinceIds: coastalProvinceIds,
    tileMap: tileMap,
    seaZoneIds: seaZoneIds,
  );

  static Map<String, (int x, int y)> buildSeaZoneToRepresentativeTile({
    required TileMapResult tileMap,
    required Set<String> seaZoneIds,
  }) => InitGameMapViewLandMarkers.buildSeaZoneToRepresentativeTile(
    tileMap: tileMap,
    seaZoneIds: seaZoneIds,
  );

  static List<WarpMarkerView> buildWarpMarkers({
    required String regionId,
    required Map<String, (int x, int y)> seaZoneToTile,
    required List<WarpLink>? warpLinks,
  }) => InitGameMapViewLandMarkers.buildWarpMarkers(
    regionId: regionId,
    seaZoneToTile: seaZoneToTile,
    warpLinks: warpLinks,
  );

  static void applyInPortFleetShipCounts({
    required List<Fleet> fleets,
    required String regionId,
    required Map<String, ProvinceUnitPresenceView> provincePresenceById,
  }) => InitGameMapViewFleetMarkers.applyInPortFleetShipCounts(
    fleets: fleets,
    regionId: regionId,
    provincePresenceById: provincePresenceById,
  );

  static List<ArmyTileMarkerView> buildArmyTileMarkersForRegion({
    required Game game,
    required String regionId,
    required List<TownMarkerView> towns,
  }) => InitGameMapViewArmyMarkers.buildArmyTileMarkersForRegion(
    game: game,
    regionId: regionId,
    towns: towns,
  );
}
