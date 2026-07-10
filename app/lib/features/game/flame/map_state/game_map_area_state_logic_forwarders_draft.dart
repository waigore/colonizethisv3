part of 'game_map_area_state_logic.dart';

class _GameMapAreaStateLogicApiDraft {
  static RegionMapViewData projectCivilianMarkersForHumanDraft({
    required RegionMapViewData region,
    required ct_models.Game game,
    required ct_models.Orders orders,
    required String humanPlayerId,
    Set<String>? civilianMarkerOwnerIds,
  }) =>
      GameMapAreaStateLogicDraftProjection.projectCivilianMarkersForHumanDraft(
        region: region,
        game: game,
        orders: orders,
        humanPlayerId: humanPlayerId,
        civilianMarkerOwnerIds: civilianMarkerOwnerIds,
      );

  static RegionMapViewData projectFleetMarkersForHumanDraft({
    required RegionMapViewData region,
    required ct_models.Game game,
    required ct_models.Orders orders,
    required String humanPlayerId,
    required Map<String, TileMapResult> tileMapByRegion,
    required Map<String, MapTopology> topologyByRegion,
    required MapTopology combinedTopology,
  }) =>
      GameMapAreaStateLogicDraftProjection.projectFleetMarkersForHumanDraft(
        region: region,
        game: game,
        orders: orders,
        humanPlayerId: humanPlayerId,
        tileMapByRegion: tileMapByRegion,
        topologyByRegion: topologyByRegion,
        combinedTopology: combinedTopology,
      );

  static RegionMapViewData projectHumanDraftMarkersForRegion({
    required RegionMapViewData baseRegion,
    required ct_models.Game game,
    required ct_models.Orders orders,
    required String humanPlayerId,
    Map<String, TileMapResult>? tileMapByRegion,
    Map<String, MapTopology>? topologyByRegion,
    MapTopology? combinedTopology,
    Set<String>? civilianMarkerOwnerIds,
  }) =>
      GameMapAreaStateLogicDraftProjection.projectHumanDraftMarkersForRegion(
        baseRegion: baseRegion,
        game: game,
        orders: orders,
        humanPlayerId: humanPlayerId,
        tileMapByRegion: tileMapByRegion,
        topologyByRegion: topologyByRegion,
        combinedTopology: combinedTopology,
        civilianMarkerOwnerIds: civilianMarkerOwnerIds,
      );
}
