/// Fleet tile markers and in-port ship-count overlays for map view data.
/// SPEC/program/map-visualization.md § Map view model for tools. Refs #4022, #4654.
library;

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'init_game_map_view_data.dart';
import 'init_game_map_view_fleet_markers_inclusion.dart';
import 'init_game_map_view_fleet_markers_location.dart';
import 'init_game_map_view_human_player_ids.dart';
import 'init_game_map_view_tile_marker_sort.dart';

/// Fleet stacking / in-port placement markers for a single region's view data.
class InitGameMapViewFleetMarkers {
  const InitGameMapViewFleetMarkers._();

  static List<FleetTileMarkerView> buildFleetTileMarkersForRegion({
    required Game game,
    required String regionId,
    required List<Province> provinces,
    required TileMapResult tileMap,
    required Set<String> seaZoneIds,
  }) {
    final humanIds = humanPlayerIds(game);
    if (humanIds.isEmpty) {
      return const [];
    }

    final provinceMap = <String, Province>{
      for (final p in provinces) ...{'${p.regionId}|${p.id}': p, p.id: p},
    };

    final byLocation = <String, List<Fleet>>{};

    for (final f in game.worldState.fleets) {
      if (!includeFleetForTileMarker(game, f, regionId, humanIds)) {
        continue;
      }
      addFleetToLocationBuckets(
        fleet: f,
        regionId: regionId,
        provinceMap: provinceMap,
        byLocation: byLocation,
      );
    }

    final markers = <FleetTileMarkerView>[];
    for (final entry in byLocation.entries) {
      final scopeKey = entry.key;
      final fleets = entry.value.toList()..sort((a, b) => a.id.compareTo(b.id));
      final fleetIds = fleets.map((fl) => fl.id).toList();

      final tileKey = fleetMarkerTileKeyForLocationScope(
        scopeKey: scopeKey,
        regionId: regionId,
        game: game,
        tileMap: tileMap,
        seaZoneIds: seaZoneIds,
        provinceMap: provinceMap,
      );
      if (tileKey == null) {
        continue;
      }
      final xy = xyFromMapTileKey(tileKey);
      final x = xy.$1;
      final y = xy.$2;
      if (x == null || y == null) {
        continue;
      }
      markers.add(
        FleetTileMarkerView(
          tileKey: tileKey,
          x: x,
          y: y,
          locationScopeKey: scopeKey,
          fleetIds: fleetIds,
          stackCount: fleetIds.length,
        ),
      );
    }
    sortTileAnchoredMarkers(
      markers,
      yOf: (m) => m.y,
      xOf: (m) => m.x,
      tileKeyOf: (m) => m.tileKey,
    );
    return markers;
  }

  static void applyInPortFleetShipCounts({
    required List<Fleet> fleets,
    required String regionId,
    required Map<String, ProvinceUnitPresenceView> provincePresenceById,
  }) {
    for (final fleet in fleets) {
      if (fleet.regionId != regionId || !fleet.isInPort) {
        continue;
      }
      final provinceId = fleet.inPortAtProvinceId;
      if (provinceId == null) {
        continue;
      }
      final current = provincePresenceById[provinceId];
      if (current == null) {
        continue;
      }
      provincePresenceById[provinceId] = current.copyWith(
        shipCount: current.shipCount + fleet.ships.length,
      );
    }
  }
}
