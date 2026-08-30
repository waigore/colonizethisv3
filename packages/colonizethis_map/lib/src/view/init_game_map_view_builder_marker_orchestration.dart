/// Port, town, warp, and fleet marker orchestration for map view assembly.
/// SPEC/program/map-visualization.md § Map view model for tools.
library;

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'init_game_map_view_data.dart';
import 'init_game_map_view_markers.dart';

({
  List<PortMarkerView> ports,
  List<TownMarkerView> towns,
  List<WarpMarkerView> warpMarkers,
  List<FleetTileMarkerView> fleetTileMarkers,
  List<ArmyTileMarkerView> armyTileMarkers,
})
buildMarkerData({
  required Game game,
  required String regionId,
  required TileMapResult tileMap,
  required MapTopology topology,
  required List<Province> provinces,
  required Set<String> seaZoneIds,
  required List<WarpLink>? warpLinks,
  required Map<String, ProvinceUnitPresenceView> provincePresenceById,
}) {
  final ports = InitGameMapViewMarkers.buildPortMarkers(
    regionId: regionId,
    portsByProvinceSeaboard: game.worldState.portsByProvinceSeaboard,
  );
  final towns = InitGameMapViewMarkers.buildTownMarkers(
    game: game,
    regionId: regionId,
    provinces: provinces,
    ports: ports,
    coastalProvinceIds: InitGameMapViewMarkers.buildCoastalProvinceIds(
      topology: topology,
      seaZoneIds: seaZoneIds,
    ),
    tileMap: tileMap,
    seaZoneIds: seaZoneIds,
  );
  final seaZoneToTile = InitGameMapViewMarkers.buildSeaZoneToRepresentativeTile(
    tileMap: tileMap,
    seaZoneIds: seaZoneIds,
  );
  final warpMarkers = InitGameMapViewMarkers.buildWarpMarkers(
    regionId: regionId,
    seaZoneToTile: seaZoneToTile,
    warpLinks: warpLinks,
  );
  InitGameMapViewMarkers.applyInPortFleetShipCounts(
    fleets: game.worldState.fleets,
    regionId: regionId,
    provincePresenceById: provincePresenceById,
  );
  final fleetTileMarkers =
      InitGameMapViewMarkers.buildFleetTileMarkersForRegion(
        game: game,
        regionId: regionId,
        provinces: provinces,
        tileMap: tileMap,
        seaZoneIds: seaZoneIds,
      );
  final armyTileMarkers = InitGameMapViewMarkers.buildArmyTileMarkersForRegion(
    game: game,
    regionId: regionId,
    towns: towns,
  );
  return (
    ports: ports,
    towns: towns,
    warpMarkers: warpMarkers,
    fleetTileMarkers: fleetTileMarkers,
    armyTileMarkers: armyTileMarkers,
  );
}
