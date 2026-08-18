import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_models/colonizethis_models.dart' as ct_models;
import 'package:colonizethis_world/colonizethis_world.dart';
import 'package:flutter/material.dart';

import '../../../../core/services/game_service/game_service.dart'
    show GameMapData;
import '../../../../providers/home_fleet_cargo_provider.dart';
import '../caches/per_player_army_move_picker_cache.dart';
import '../../widgets/province_overlay/province_sea_zone_detail_overlay_support.dart'
    show ProvinceOverlayStationSpyProps;
import '../map_state/province_detach_and_sail_overlay_controls.dart';
import '../map_state/province_naval_mission_action_state.dart';
import 'province_detail_overlay_host_support_army_move.dart';
import 'province_detail_overlay_host_support_detach_sail.dart';
import 'province_detail_overlay_host_support_naval_mission.dart';
import 'province_detail_overlay_host_support_station_spy.dart';

/// Move/invade, naval mission, detach-and-sail, and station-spy overlay props.
({
  ProvinceArmyMoveOverlayControls armyMove,
  ProvinceNavalMissionOverlayControls navalMission,
  ProvinceDetachAndSailOverlayControls detachAndSail,
  ProvinceOverlayStationSpyProps stationSpy,
})
buildProvinceDetailMissionOverlayControls({
  required BuildContext context,
  required ct_models.Game game,
  required RegionMapViewData region,
  required String humanPlayerId,
  required PlayerView playerView,
  required String displayId,
  required String? selectedTileKey,
  required ct_models.Orders draftOrders,
  required GameMapData? mapData,
  required bool canMutateViaUi,
  required bool omniscientDetail,
  required bool isSeaZone,
  PerPlayerArmyMovePickerCache? armyMovePickerCache,
  required ct_models.AppEventBus bus,
  required HomeFleetCargoSummary cargo,
}) {
  return (
    armyMove: buildProvinceArmyMoveOverlayControls(
      context: context,
      game: game,
      region: region,
      humanPlayerId: humanPlayerId,
      playerView: playerView,
      displayId: displayId,
      draftOrders: draftOrders,
      mapData: mapData,
      canMutateViaUi: canMutateViaUi,
      omniscientDetail: omniscientDetail,
      armyMovePickerCache: armyMovePickerCache,
      bus: bus,
      isSeaZone: isSeaZone,
    ),
    navalMission: buildProvinceNavalMissionOverlayControls(
      context: context,
      game: game,
      humanPlayerId: humanPlayerId,
      playerView: playerView,
      displayId: displayId,
      draftOrders: draftOrders,
      mapData: mapData,
      canMutateViaUi: canMutateViaUi,
      bus: bus,
      isSeaZone: isSeaZone,
    ),
    detachAndSail: buildProvinceDetachAndSailOverlayControls(
      context: context,
      game: game,
      humanPlayerId: humanPlayerId,
      displayId: displayId,
      mapData: mapData,
      canMutateViaUi: canMutateViaUi,
      bus: bus,
      isSeaZone: isSeaZone,
      cargo: cargo,
    ),
    stationSpy: buildProvinceStationSpyOverlayProps(
      context: context,
      game: game,
      region: region,
      displayId: displayId,
      humanPlayerId: humanPlayerId,
      playerView: playerView,
      selectedTileKey: selectedTileKey,
      draftOrders: draftOrders,
      canMutateViaUi: canMutateViaUi,
      omniscientDetail: omniscientDetail,
      isSeaZone: isSeaZone,
      bus: bus,
    ),
  );
}
