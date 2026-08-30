// Naval mission menu choices, dialog ids, and player-facing labels.
// Refs #4213, #4295. SPEC/program/app-ui-wiring.md.

import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../../../../config/ui_screen_ids.dart';
import '../panels/tree_builders/fleet_mission_label.dart';
import '../province_overlay/province_sea_zone_detail_overlay_designation.dart';

/// Menu selection for [showNavalMissionFlow].
sealed class NavalMissionMenuChoice {
  const NavalMissionMenuChoice();
}

final class NavalMissionMenuChoiceMission extends NavalMissionMenuChoice {
  const NavalMissionMenuChoiceMission(this.mission);
  final FleetMission mission;
}

final class NavalMissionMenuChoiceCancelPending extends NavalMissionMenuChoice {
  const NavalMissionMenuChoiceCancelPending();
}

/// Opens [MoveFleetDialog] from `DLG31001` Sail / Move (Refs #4343).
final class NavalMissionMenuChoiceSail extends NavalMissionMenuChoice {
  const NavalMissionMenuChoiceSail();
}

/// Screen ids for naval mission dialog hosts (Refs #4213).
abstract final class NavalMissionDialogIds {
  static const menuDialog = UiScreenIds.navalMissionMenuDialog;
  static const targetDialog = UiScreenIds.navalMissionTargetDialog;
  static const fleetPickerDialog = UiScreenIds.navalMissionFleetPickerDialog;
}

String navalMissionMenuLabel(FleetMission mission) =>
    fleetMissionDisplayLabel(mission);

/// One-line player-facing effect summary for [mission] (Refs #4295).
String navalMissionEffectLine(AppLocalizations l10n, FleetMission mission) {
  return switch (mission) {
    FleetMission.patrol => l10n.naval_mission_effect_patrol,
    FleetMission.defend => l10n.naval_mission_effect_defend,
    FleetMission.blockade => l10n.naval_mission_effect_blockade,
    FleetMission.beachhead => l10n.naval_mission_effect_beachhead,
    FleetMission.none => '',
  };
}

/// Target-picker caption for Blockade / Beachhead (Refs #4295).
String? navalMissionTargetCaption(AppLocalizations l10n, FleetMission mission) {
  return switch (mission) {
    FleetMission.blockade => l10n.naval_mission_targetCaption_blockade,
    FleetMission.beachhead => l10n.naval_mission_targetCaption_beachhead,
    _ => null,
  };
}

/// Whether [provinceId] is any faction's capital province (Blockade assign).
bool navalMissionBlockadeTargetIsCapital(Game game, String provinceId) =>
    provinceOverlayIsCapital(game, provinceId);
