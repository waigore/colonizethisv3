import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_data/colonizethis_data.dart' show MapTopology;
import 'package:colonizethis_models/colonizethis_models.dart' as ct_models;
import 'package:colonizethis_world/colonizethis_world.dart';
import 'package:flutter/material.dart';

import '../../../../core/services/game_service/game_service.dart'
    show GameMapData;
import '../../widgets/unit_orders/naval_mission_flow.dart';
import '../map_state/province_naval_mission_action_state.dart';

/// Resolves MAP20001 Naval Blockade/Beachhead enablement and tap handlers.
ProvinceNavalMissionOverlayControls buildProvinceNavalMissionOverlayControls({
  required BuildContext context,
  required ct_models.Game game,
  required String humanPlayerId,
  required PlayerView playerView,
  required String displayId,
  required ct_models.Orders draftOrders,
  required GameMapData? mapData,
  required bool canMutateViaUi,
  required ct_models.AppEventBus bus,
  required bool isSeaZone,
}) {
  if (!canMutateViaUi) return ProvinceNavalMissionOverlayControls.hidden;

  final topology = mapData?.combinedTopology ?? const MapTopology();
  final state = computeProvinceNavalMissionActionState(
    game: game,
    humanPlayerId: humanPlayerId,
    provinceId: displayId,
    topology: topology,
    isSeaZoneContext: isSeaZone,
  );
  if (!state.showControls) return ProvinceNavalMissionOverlayControls.hidden;

  final l10n = appL10n(context);
  final disabledTooltip =
      l10n.provinceOverlay_blockadeBeachheadDisabledNotAtSeaTooltip;
  final blockadeTooltip = state.enabled
      ? l10n.naval_mission_effect_blockade
      : disabledTooltip;
  final beachheadTooltip = state.enabled
      ? l10n.naval_mission_effect_beachhead
      : disabledTooltip;

  VoidCallback? tapFor(ct_models.FleetMission mission) {
    if (!state.enabled) return null;
    return () {
      showNavalMissionFlow(
        context: context,
        game: game,
        topology: topology,
        humanPlayerId: humanPlayerId,
        draftOrders: draftOrders,
        bus: bus,
        fleetIds: state.eligibleFleetIds,
        playerView: playerView,
        initialMission: mission,
        initialTargetProvinceId: displayId,
      );
    };
  }

  return ProvinceNavalMissionOverlayControls(
    showBlockade: true,
    blockadeEnabled: state.enabled,
    blockadeTooltip: blockadeTooltip,
    onBlockadeTap: tapFor(ct_models.FleetMission.blockade),
    showBeachhead: true,
    beachheadEnabled: state.enabled,
    beachheadTooltip: beachheadTooltip,
    onBeachheadTap: tapFor(ct_models.FleetMission.beachhead),
  );
}
