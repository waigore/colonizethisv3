import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_models/colonizethis_models.dart' as ct_models;

import 'game_map_area_army_draft_projection.dart';
import 'game_map_area_civilian_draft_projection.dart';
import 'game_map_area_fleet_draft_projection.dart';

/// Civilian and fleet draft marker projection helpers for [GameMapAreaStateLogic].
abstract final class GameMapAreaStateLogicDraftProjection {
  /// Projects player-owned civilian markers using current-turn pending orders.
  ///
  /// Thin forwarder to [GameMapAreaCivilianDraftProjection.project] (#2575).
  static RegionMapViewData projectCivilianMarkersForHumanDraft({
    required RegionMapViewData region,
    required ct_models.Game game,
    required ct_models.Orders orders,
    required String humanPlayerId,
    Set<String>? civilianMarkerOwnerIds,
  }) => GameMapAreaCivilianDraftProjection.project(
    region: region,
    game: game,
    orders: orders,
    humanPlayerId: humanPlayerId,
    civilianMarkerOwnerIds: civilianMarkerOwnerIds,
  );

  /// Projects fleet marker tiles using human naval move drafts.
  ///
  /// Thin forwarder to [GameMapAreaFleetDraftProjection.project] (#2575).
  static RegionMapViewData projectFleetMarkersForHumanDraft({
    required RegionMapViewData region,
    required ct_models.Game game,
    required ct_models.Orders orders,
    required String humanPlayerId,
    required Map<String, TileMapResult> tileMapByRegion,
    required Map<String, MapTopology> topologyByRegion,
    required MapTopology combinedTopology,
  }) => GameMapAreaFleetDraftProjection.project(
    region: region,
    game: game,
    orders: orders,
    humanPlayerId: humanPlayerId,
    tileMapByRegion: tileMapByRegion,
    topologyByRegion: topologyByRegion,
    combinedTopology: combinedTopology,
  );

  /// Civilian and fleet draft marker projection for one [RegionMapViewData].
  static RegionMapViewData projectHumanDraftMarkersForRegion({
    required RegionMapViewData baseRegion,
    required ct_models.Game game,
    required ct_models.Orders orders,
    required String humanPlayerId,
    Map<String, TileMapResult>? tileMapByRegion,
    Map<String, MapTopology>? topologyByRegion,
    MapTopology? combinedTopology,
    Set<String>? civilianMarkerOwnerIds,
  }) {
    var projected = GameMapAreaCivilianDraftProjection.project(
      region: baseRegion,
      game: game,
      orders: orders,
      humanPlayerId: humanPlayerId,
      civilianMarkerOwnerIds: civilianMarkerOwnerIds,
    );
    if (tileMapByRegion != null &&
        topologyByRegion != null &&
        combinedTopology != null) {
      projected = GameMapAreaFleetDraftProjection.project(
        region: projected,
        game: game,
        orders: orders,
        humanPlayerId: humanPlayerId,
        tileMapByRegion: tileMapByRegion,
        topologyByRegion: topologyByRegion,
        combinedTopology: combinedTopology,
      );
    }
    return GameMapAreaArmyDraftProjection.project(
      region: projected,
      game: game,
      orders: orders,
      humanPlayerId: humanPlayerId,
    );
  }
}
