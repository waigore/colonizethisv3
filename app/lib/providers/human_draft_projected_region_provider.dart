import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/game/flame/game_map_area_state_logic.dart';
import '../features/game/shell_player_context.dart';
import 'game_service_provider.dart';
import 'games_provider.dart';
import 'map_view_provider.dart';

RegionMapViewData _baseRegionForId(InitGameMapViewData mapView, String regionId) {
  if (mapView.oldWorld.regionId == regionId) {
    return mapView.oldWorld;
  }
  if (mapView.newWorld.regionId == regionId) {
    return mapView.newWorld;
  }
  throw ArgumentError.value(regionId, 'regionId', 'unknown map region');
}

/// Human draft civilian/fleet marker projection for one map region.
///
/// Recomputes only when game, orders, map view, or region change — not every
/// [GameMapArea] frame build. Refs #2575 phase 2.
final humanDraftProjectedRegionProvider =
    Provider.family<RegionMapViewData?, String>((ref, regionId) {
      final game = ref.watch(currentGameProvider);
      final mapView = ref.watch(mapViewDataProvider);
      if (game == null || mapView == null) {
        return null;
      }

      final orders = ref.watch(currentOrdersProvider);
      final shell = ref.watch(shellPlayerContextProvider);
      final humanPlayerId = shell.mapPlayerIdFor(game);
      final mapData = ref.watch(gameServiceProvider).getMapData(game.id);

      return GameMapAreaStateLogic.projectHumanDraftMarkersForRegion(
        baseRegion: _baseRegionForId(mapView, regionId),
        game: game,
        orders: orders,
        humanPlayerId: humanPlayerId,
        tileMapByRegion: mapData?.tileMapByRegion,
        topologyByRegion: mapData?.topologyByRegion,
        combinedTopology: mapData?.combinedTopology,
      );
    });
