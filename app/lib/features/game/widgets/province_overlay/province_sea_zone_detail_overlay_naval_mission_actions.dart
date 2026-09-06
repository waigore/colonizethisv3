import 'package:colonizethis_app/widgets/ct_action_text_button.dart';
import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_app/features/game/flame/map_state/province_detach_and_sail_overlay_controls.dart'
    show ProvinceDetachAndSailOverlayControls;
import 'package:colonizethis_app/features/game/flame/map_state/province_naval_combine_overlay_controls.dart'
    show ProvinceNavalCombineOverlayControls;
import 'package:colonizethis_app/features/game/flame/map_state/province_naval_mission_action_state.dart'
    show ProvinceNavalMissionOverlayControls;
import 'package:colonizethis_app/features/game/flame/map_state/province_overlay_sail_move_overlay_controls.dart'
    show ProvinceOverlaySailMoveOverlayControls;
import 'package:colonizethis_app/features/game/flame/map_state/province_transfer_to_home_fleet_overlay_controls.dart'
    show ProvinceTransferToHomeFleetOverlayControls;
import 'package:flutter/material.dart';

List<Widget> navalMissionActionWidgets(
  AppLocalizations l10n,
  ProvinceNavalMissionOverlayControls navalMission,
  ProvinceDetachAndSailOverlayControls detachAndSail,
  ProvinceTransferToHomeFleetOverlayControls transferToHomeFleet,
  ProvinceNavalCombineOverlayControls navalCombine,
  ProvinceOverlaySailMoveOverlayControls sailMove,
) {
  final showDetach = detachAndSail.showDetachAndSail;
  final showTransfer = transferToHomeFleet.showTransferToHomeFleet;
  final showCombine = navalCombine.showCombineFleets;
  final showSail = sailMove.showSailMove;
  if (!navalMission.showBlockade &&
      !navalMission.showBeachhead &&
      !navalMission.showPatrol &&
      !navalMission.showDefend &&
      !showDetach &&
      !showTransfer &&
      !showCombine &&
      !showSail) {
    return const [];
  }
  return [
    Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          if (showCombine)
            CtActionTextButton(
              label: l10n.provinceOverlay_combineFleetsAction,
              tooltip: navalCombine.combineFleetsTooltip,
              enabled: navalCombine.combineFleetsEnabled,
              onPressed: navalCombine.combineFleetsEnabled
                  ? navalCombine.onCombineFleetsTap
                  : null,
            ),
          if (showTransfer)
            CtActionTextButton(
              label: l10n.provinceOverlay_transferToHomeFleetAction,
              tooltip: transferToHomeFleet.transferToHomeFleetTooltip,
              enabled: transferToHomeFleet.transferToHomeFleetEnabled,
              onPressed: transferToHomeFleet.transferToHomeFleetEnabled
                  ? transferToHomeFleet.onTransferToHomeFleetTap
                  : null,
            ),
          if (showDetach)
            CtActionTextButton(
              label: l10n.provinceOverlay_detachAndSailAction,
              tooltip: detachAndSail.detachAndSailTooltip,
              enabled: detachAndSail.detachAndSailEnabled,
              onPressed: detachAndSail.detachAndSailEnabled
                  ? detachAndSail.onDetachAndSailTap
                  : null,
            ),
          if (showSail)
            CtActionTextButton(
              label: l10n.naval_mission_sail,
              tooltip: sailMove.sailMoveTooltip,
              enabled: sailMove.sailMoveEnabled,
              onPressed: sailMove.sailMoveEnabled
                  ? sailMove.onSailMoveTap
                  : null,
            ),
          if (navalMission.showBlockade)
            CtActionTextButton(
              label: l10n.provinceOverlay_blockadeAction,
              tooltip: navalMission.blockadeTooltip,
              enabled: navalMission.blockadeEnabled,
              onPressed: navalMission.blockadeEnabled
                  ? navalMission.onBlockadeTap
                  : null,
            ),
          if (navalMission.showBeachhead)
            CtActionTextButton(
              label: l10n.provinceOverlay_beachheadAction,
              tooltip: navalMission.beachheadTooltip,
              enabled: navalMission.beachheadEnabled,
              onPressed: navalMission.beachheadEnabled
                  ? navalMission.onBeachheadTap
                  : null,
            ),
          if (navalMission.showPatrol)
            CtActionTextButton(
              label: l10n.provinceOverlay_patrolAction,
              tooltip: navalMission.patrolTooltip,
              enabled: navalMission.patrolEnabled,
              onPressed: navalMission.patrolEnabled
                  ? navalMission.onPatrolTap
                  : null,
            ),
          if (navalMission.showDefend)
            CtActionTextButton(
              label: l10n.provinceOverlay_defendAction,
              tooltip: navalMission.defendTooltip,
              enabled: navalMission.defendEnabled,
              onPressed: navalMission.defendEnabled
                  ? navalMission.onDefendTap
                  : null,
            ),
        ],
      ),
    ),
  ];
}
