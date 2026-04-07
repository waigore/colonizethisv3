import 'package:colonizethis_models/colonizethis_models.dart' show UnitStatus;

import '../../../l10n/app_localizations.dart';

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
    'horse_artillery' => l10n.province_regiment_horse_artillery,
    'royal_artillery' => l10n.province_regiment_royal_artillery,
    'skirmishers' => l10n.province_regiment_skirmishers,
    'regulars' => l10n.province_regiment_regulars,
    'grenadiers' => l10n.province_regiment_grenadiers,
    'hussars' => l10n.province_regiment_hussars,
    'cuirassiers' => l10n.province_regiment_cuirassiers,
    'light_artillery' => l10n.province_regiment_light_artillery,
    'heavy_artillery' => l10n.province_regiment_heavy_artillery,
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
    'ship_of_the_line' => l10n.province_ship_ship_of_the_line,
    'clipper' => l10n.province_ship_clipper,
    'merchant_steamship' => l10n.province_ship_merchant_steamship,
    'ironclad' => l10n.province_ship_ironclad,
    _ => shipTypeId,
  };
}

/// Localized work-order target string for province Civilian lines.
String workOrderTargetDisplayLabel(AppLocalizations l10n, String target) {
  return switch (target) {
    'explore' => l10n.province_workOrder_explore,
    'prospect' => l10n.province_workOrder_prospect,
    'build_improvement' => l10n.province_workOrder_build_improvement,
    'upgrade_town' => l10n.province_workOrder_upgrade_town,
    'build_road' => l10n.province_workOrder_build_road,
    'build_port' => l10n.province_workOrder_build_port,
    'build_fort' => l10n.province_workOrder_build_fort,
    'build_rail' => l10n.province_workOrder_build_rail,
    'steal_tech' => l10n.province_workOrder_steal_tech,
    'counter_spy' => l10n.province_workOrder_counter_spy,
    'purchase_land' => l10n.province_workOrder_purchase_land,
    _ => target,
  };
}

String unitStatusDisplayLabel(AppLocalizations l10n, UnitStatus status) {
  return switch (status) {
    UnitStatus.idle => l10n.province_unitStatus_idle,
    UnitStatus.working => l10n.province_unitStatus_working,
    UnitStatus.done => l10n.province_unitStatus_done,
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
