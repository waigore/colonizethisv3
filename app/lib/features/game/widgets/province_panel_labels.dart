import 'package:colonizethis_models/colonizethis_models.dart' show UnitStatus;
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_data/colonizethis_data.dart';

import '../../../l10n/l10n.dart';

/// Localized regiment type id for province / military UI. Unknown [regimentTypeId] returns [regimentTypeId].
String regimentTypeDisplayLabel(AppLocalizations l10n, String regimentTypeId) {
  return switch (regimentTypeId) {
    'peasant_levies' => l10n.province_regiment_peasant_levies,
    'pikemen' => l10n.province_regiment_pikemen,
    'arquebusiers' => l10n.province_regiment_arquebusiers,
    'bowmen' => l10n.province_regiment_bowmen,
    'squires' => l10n.province_regiment_squires,
    'knights' => l10n.province_regiment_knights,
    'culverin' => l10n.province_regiment_culverin,
    'calivermen' => l10n.province_regiment_calivermen,
    'halberdiers' => l10n.province_regiment_halberdiers,
    'musketeers' => l10n.province_regiment_musketeers,
    'cossacks' => l10n.province_regiment_cossacks,
    'lancers' => l10n.province_regiment_lancers,
    'harquebusiers' => l10n.province_regiment_harquebusiers,
    kTechIdHorseArtillery => l10n.province_regiment_horse_artillery,
    'royal_artillery' => l10n.province_regiment_royal_artillery,
    'skirmishers' => l10n.province_regiment_skirmishers,
    'regulars' => l10n.province_regiment_regulars,
    'grenadiers' => l10n.province_regiment_grenadiers,
    kTechIdHussars => l10n.province_regiment_hussars,
    'cuirassiers' => l10n.province_regiment_cuirassiers,
    'light_artillery' => l10n.province_regiment_light_artillery,
    kTechIdHeavyArtillery => l10n.province_regiment_heavy_artillery,
    'sharpshooters' => l10n.province_regiment_sharpshooters,
    'rifle_infantry' => l10n.province_regiment_rifle_infantry,
    'guards' => l10n.province_regiment_guards,
    'scouts' => l10n.province_regiment_scouts,
    'carbine_cavalry' => l10n.province_regiment_carbine_cavalry,
    'field_artillery' => l10n.province_regiment_field_artillery,
    'siege_guns' => l10n.province_regiment_siege_guns,
    _ => regimentTypeId,
  };
}

/// Localized ship type id for province / naval UI. Unknown [shipTypeId] returns [shipTypeId].
String shipTypeDisplayLabel(AppLocalizations l10n, String shipTypeId) {
  return switch (shipTypeId) {
    'carrack' => l10n.province_ship_carrack,
    'fluyte' => l10n.province_ship_fluyte,
    'sloop' => l10n.province_ship_sloop,
    'trader' => l10n.province_ship_trader,
    'galleon' => l10n.province_ship_galleon,
    'indiaman' => l10n.province_ship_indiaman,
    'frigate' => l10n.province_ship_frigate,
    'raider' => l10n.province_ship_raider,
    kTechIdShipOfTheLine => l10n.province_ship_ship_of_the_line,
    'clipper' => l10n.province_ship_clipper,
    'merchant_steamship' => l10n.province_ship_merchant_steamship,
    'ironclad' => l10n.province_ship_ironclad,
    _ => shipTypeId,
  };
}

/// Localized work-order target string for province Civilian lines.
String workOrderTargetDisplayLabel(AppLocalizations l10n, String target) {
  return switch (target) {
    kWorkTargetExplore => l10n.province_workOrder_explore,
    kWorkTargetProspect => l10n.province_workOrder_prospect,
    kWorkTargetBuildImprovement => l10n.province_workOrder_build_improvement,
    kWorkTargetUpgradeTown => l10n.province_workOrder_upgrade_town,
    kWorkTargetBuildRoad => l10n.province_workOrder_build_road,
    kWorkTargetBuildPort => l10n.province_workOrder_build_port,
    kWorkTargetBuildFort => l10n.province_workOrder_build_fort,
    kWorkTargetBuildRail => l10n.province_workOrder_build_rail,
    kWorkTargetCounterSpy => l10n.province_workOrder_counter_spy,
    kWorkTargetPurchaseLand => l10n.province_workOrder_purchase_land,
    _ => target,
  };
}

String unitStatusDisplayLabel(AppLocalizations l10n, UnitStatus status) {
  return switch (status) {
    UnitStatus.idle => l10n.province_unitStatus_idle,
    UnitStatus.working => l10n.province_unitStatus_working,
  };
}

String navalMissionDisplayLabel(AppLocalizations l10n, String mission) {
  return switch (mission) {
    'none' => l10n.province_fleetMission_none,
    'patrol' => l10n.province_fleetMission_patrol,
    'blockade' => l10n.province_fleetMission_blockade,
    'beachhead' => l10n.province_fleetMission_beachhead,
    'defend' => l10n.province_fleetMission_defend,
    _ => mission,
  };
}
