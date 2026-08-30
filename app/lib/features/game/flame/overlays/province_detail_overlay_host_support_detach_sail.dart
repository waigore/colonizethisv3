import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_data/colonizethis_data.dart' show MapTopology;
import 'package:colonizethis_models/colonizethis_models.dart' as ct_models;
import 'package:colonizethis_world/colonizethis_world.dart';
import 'package:flutter/material.dart';

import '../../../../core/services/game_service/game_service.dart'
    show GameMapData;
import '../../../../providers/home_fleet_cargo_provider.dart';
import '../../widgets/unit_orders/home_fleet_detach_then_sail_flow.dart';
import '../map_state/province_detach_and_sail_overlay_controls.dart';

export '../map_state/province_detach_and_sail_overlay_controls.dart';

/// Resolves MAP20001 Naval Detach and sail enablement and tap handler.
ProvinceDetachAndSailOverlayControls buildProvinceDetachAndSailOverlayControls({
  required BuildContext context,
  required ct_models.Game game,
  required String humanPlayerId,
  required String displayId,
  required GameMapData? mapData,
  required bool canMutateViaUi,
  required ct_models.AppEventBus bus,
  required bool isSeaZone,
  HomeFleetCargoSummary cargo = const HomeFleetCargoSummary(
    used: 0,
    capacity: 0,
  ),
}) {
  if (!canMutateViaUi || isSeaZone) {
    return ProvinceDetachAndSailOverlayControls.hidden;
  }
  final player = game.playerById(humanPlayerId);
  if (player == null || player.capitalProvinceId != displayId) {
    return ProvinceDetachAndSailOverlayControls.hidden;
  }
  final province = game.worldState.tryGetProvince(displayId);
  if (province != null && province.ownerId != humanPlayerId) {
    return ProvinceDetachAndSailOverlayControls.hidden;
  }
  final home = game.fleetById(homeFleetIdFor(humanPlayerId));
  if (home == null ||
      home.ownerId != humanPlayerId ||
      home.ships.isEmpty ||
      home.inPortAtProvinceId != displayId) {
    return ProvinceDetachAndSailOverlayControls.hidden;
  }

  final l10n = appL10n(context);
  final topology = mapData?.combinedTopology ?? const MapTopology();
  return ProvinceDetachAndSailOverlayControls(
    showDetachAndSail: true,
    detachAndSailEnabled: true,
    detachAndSailTooltip: l10n.provinceOverlay_detachAndSailTooltip,
    onDetachAndSailTap: () {
      showHomeFleetDetachThenSailFlow(
        context: context,
        game: game,
        topology: topology,
        humanPlayerId: humanPlayerId,
        bus: bus,
        overseasCargoUsed: cargo.used,
        isCargoUsedReliable: cargo.isCargoUsedReliable,
        cargoNotDefined: cargo.notDefined,
      );
    },
  );
}
