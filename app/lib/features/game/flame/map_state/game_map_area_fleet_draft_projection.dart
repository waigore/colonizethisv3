import 'package:colonizethis_app/core/utils/prefixed_id.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_models/colonizethis_models.dart' as ct_models;
import 'package:colonizethis_world/colonizethis_world.dart';

import 'game_map_area_draft_projection_shared.dart';
import 'game_map_area_fleet_draft_location_scope.dart';
import 'game_map_area_fleet_draft_tiles.dart';

/// Fleet-marker draft projection for the human player.
///
/// Extracted from `GameMapAreaStateLogic` (#2575 work item 11) so the
/// fleet projection pipeline lives in a single, separately testable module.
/// Grayscale and halo flags follow issue #1745 / SPEC/ui/map-widget.md.
class GameMapAreaFleetDraftProjection {
  GameMapAreaFleetDraftProjection._();

  /// Projects fleet marker tiles using human naval move drafts.
  static RegionMapViewData project({
    required RegionMapViewData region,
    required ct_models.Game game,
    required ct_models.Orders orders,
    required String humanPlayerId,
    required Map<String, TileMapResult> tileMapByRegion,
    required Map<String, MapTopology> topologyByRegion,
    required MapTopology combinedTopology,
  }) {
    final moves = orders.navalMoveOrdersByPlayerId[humanPlayerId] ?? const [];
    final missions =
        orders.navalMissionOrdersByPlayerId[humanPlayerId] ?? const [];
    final moveByFleetId = <String, ct_models.NavalMoveOrder>{
      for (final m in moves) m.fleetId: m,
    };
    final missionFleetIds = <String>{for (final m in missions) m.fleetId};

    bool hasDraftNaval(String fleetId) =>
        moveByFleetId.containsKey(fleetId) || missionFleetIds.contains(fleetId);

    ct_models.Fleet? lookupFleet(String fleetId) => game.fleetById(fleetId);

    final fleetIdsToProject = <String>{for (final m in moves) m.fleetId};
    for (final marker in region.fleetTileMarkers) {
      for (final fleetId in marker.fleetIds) {
        fleetIdsToProject.add(fleetId);
      }
    }
    if (fleetIdsToProject.isEmpty) {
      return region;
    }

    final groups = <String, _FleetTileProj>{};
    for (final fleetId in fleetIdsToProject) {
      final fleet = lookupFleet(fleetId);
      final mv = moveByFleetId[fleetId];
      if (fleet == null) {
        continue;
      }
      String? tileKey;
      String? locationScopeKey;
      if (mv != null) {
        tileKey = GameMapAreaFleetDraftProjectionTiles.destinationTileForMove(
          move: mv,
          fleetRegionId: fleet.regionId,
          game: game,
          tileMapByRegion: tileMapByRegion,
          topologyByRegion: topologyByRegion,
          combinedTopology: combinedTopology,
        );
        tileKey ??= GameMapAreaFleetDraftProjectionTiles.currentTileForFleet(
          fleet: fleet,
          game: game,
          tileMapByRegion: tileMapByRegion,
          topologyByRegion: topologyByRegion,
        );
        locationScopeKey = GameMapAreaFleetDraftProjectionScope.locationScopeForMove(
          move: mv,
          fleetRegionId: fleet.regionId,
          game: game,
          combinedTopology: combinedTopology,
          topologyByRegion: topologyByRegion,
        );
      } else {
        tileKey = GameMapAreaFleetDraftProjectionTiles.currentTileForFleet(
          fleet: fleet,
          game: game,
          tileMapByRegion: tileMapByRegion,
          topologyByRegion: topologyByRegion,
        );
        locationScopeKey =
            GameMapAreaFleetDraftProjectionScope.currentLocationScopeForFleet(
          fleet: fleet,
          game: game,
          combinedTopology: combinedTopology,
          topologyByRegion: topologyByRegion,
        );
      }
      if (tileKey == null) {
        continue;
      }
      if (!isTileKeyInRegion(tileKey, region.regionId)) {
        continue;
      }

      final g = groups.putIfAbsent(tileKey, _FleetTileProj.new);
      g.fleetIds.add(fleetId);
      g.locationScopeKeys.add(locationScopeKey ?? '');
      if (mv != null) {
        g.anyNavalMoveDraft = true;
      }
    }

    final out = <FleetTileMarkerView>[];
    for (final e in groups.entries) {
      final tk = e.key;
      final g = e.value;
      final sortedIds = g.fleetIds.toList()..sort();
      final parsed = tryParseTileKey(tk);
      if (parsed == null) {
        continue;
      }
      final x = parsed.x;
      final y = parsed.y;
      final scopeCandidates = g.locationScopeKeys.toList()..sort();
      final scope = scopeCandidates.isEmpty ? '' : scopeCandidates.first;
      out.add(
        FleetTileMarkerView(
          tileKey: tk,
          x: x,
          y: y,
          locationScopeKey: scope,
          fleetIds: sortedIds,
          stackCount: sortedIds.length,
          renderGrayscale: sortedIds.every(hasDraftNaval),
          applyFleetRevealHalo: g.anyNavalMoveDraft,
        ),
      );
    }
    GameMapAreaDraftProjectionShared.sortFleetTileMarkersByMapPosition(out);

    return GameMapAreaDraftProjectionShared.copyRegionMapViewDataMarkerLayers(
      region: region,
      fleetTileMarkers: out,
    );
  }
}

class _FleetTileProj {
  _FleetTileProj();

  final Set<String> fleetIds = {};
  final Set<String> locationScopeKeys = {};
  bool anyNavalMoveDraft = false;
}
