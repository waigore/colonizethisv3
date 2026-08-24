import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_data/colonizethis_data.dart' show MapTopology;
import 'package:colonizethis_models/colonizethis_models.dart' as ct_models;
import 'package:colonizethis_world/colonizethis_world.dart';
import 'package:flutter/material.dart';

import '../../../../core/services/game_service/game_service.dart'
    show GameMapData;
import '../../../../core/utils/prefixed_id.dart';
import '../../../../providers/home_fleet_cargo_provider.dart';
import '../../widgets/unit_orders/overlay_transfer_to_home_fleet_flow.dart';
import '../../widgets/units/naval/home_fleet_transfer_eligibility.dart';
import '../map_state/province_transfer_to_home_fleet_overlay_controls.dart';

export '../map_state/province_transfer_to_home_fleet_overlay_controls.dart';

/// Resolves MAP20001 Naval Transfer to Home Fleet enablement (Refs #4625).
ProvinceTransferToHomeFleetOverlayControls
buildProvinceTransferToHomeFleetOverlayControls({
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
  if (!canMutateViaUi) {
    return ProvinceTransferToHomeFleetOverlayControls.hidden;
  }
  final player = game.playerById(humanPlayerId);
  final capitalProvinceId = player?.capitalProvinceId;
  if (player == null || capitalProvinceId == null) {
    return ProvinceTransferToHomeFleetOverlayControls.hidden;
  }
  final home = game.fleetById(homeFleetIdFor(humanPlayerId));
  if (home == null || home.ownerId != humanPlayerId) {
    return ProvinceTransferToHomeFleetOverlayControls.hidden;
  }

  final topology = mapData?.combinedTopology ?? const MapTopology();
  if (isSeaZone) {
    if (!seaZoneAdjacentToCapital(
      topology: topology,
      sourceSeaZoneId: displayId,
      sourceRegionId: prefixedIdRegionSegment(displayId) ?? home.regionId,
      capitalProvinceId: capitalProvinceId,
    )) {
      return ProvinceTransferToHomeFleetOverlayControls.hidden;
    }
  } else {
    if (capitalProvinceId != displayId &&
        !provinceIdMatchesCapital(displayId, capitalProvinceId)) {
      return ProvinceTransferToHomeFleetOverlayControls.hidden;
    }
    final province = game.worldState.tryGetProvince(displayId);
    if (province != null && province.ownerId != humanPlayerId) {
      return ProvinceTransferToHomeFleetOverlayControls.hidden;
    }
  }

  final sources = overlayTransferToHomeSourceFleets(
    game: game,
    humanPlayerId: humanPlayerId,
    displayId: displayId,
    isSeaZone: isSeaZone,
    topology: topology,
  );
  final l10n = appL10n(context);
  final enabled = sources.isNotEmpty;
  return ProvinceTransferToHomeFleetOverlayControls(
    showTransferToHomeFleet: true,
    transferToHomeFleetEnabled: enabled,
    transferToHomeFleetTooltip: enabled
        ? l10n.provinceOverlay_transferToHomeFleetTooltip
        : l10n.provinceOverlay_transferToHomeFleetDisabledTooltip,
    onTransferToHomeFleetTap: enabled
        ? () {
            showOverlayTransferToHomeFleetFlow(
              context: context,
              game: game,
              humanPlayerId: humanPlayerId,
              bus: bus,
              homeFleet: home,
              sourceFleets: sources,
              cargo: cargo,
            );
          }
        : null,
  );
}
