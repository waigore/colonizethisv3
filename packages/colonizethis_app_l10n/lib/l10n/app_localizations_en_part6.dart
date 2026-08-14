part of 'app_localizations_en.dart';

mixin _AppLocalizationsEnStrings6 on AppLocalizations {
  @override
  String get commodity_grain => 'Grain';

  @override
  String get commodity_meat => 'Meat';

  @override
  String get commodity_timber => 'Timber';

  @override
  String get commodity_iron => 'Iron';

  @override
  String get commodity_wool => 'Wool';

  @override
  String get commodity_cotton => 'Cotton';

  @override
  String get commodity_coal => 'Coal';

  @override
  String get commodity_sugarCane => 'Sugar cane';

  @override
  String get commodity_tobacco => 'Tobacco';

  @override
  String get commodity_furs => 'Furs';

  @override
  String get commodity_copper => 'Copper';

  @override
  String get commodity_tin => 'Tin';

  @override
  String get commodity_horses => 'Horses';

  @override
  String get commodity_lumber => 'Lumber';

  @override
  String get commodity_castIron => 'Cast iron';

  @override
  String get commodity_fabric => 'Fabric';

  @override
  String get commodity_refinedSugar => 'Refined sugar';

  @override
  String get commodity_cigars => 'Cigars';

  @override
  String get commodity_furHats => 'Fur hats';

  @override
  String get commodity_steel => 'Steel';

  @override
  String get commodity_paper => 'Paper';

  @override
  String get commodity_bronze => 'Bronze';

  @override
  String get commodity_gold => 'Gold';

  @override
  String get commodity_silver => 'Silver';

  @override
  String get commodity_gems => 'Gems';

  @override
  String get commodity_diamonds => 'Diamonds';

  @override
  String get commodity_spices => 'Spices';

  @override
  String get provinceOverlay_tileBuildPortTooltip => 'Build port';

  @override
  String provinceOverlay_tileBuildPortTooltipWithCost(String costs) {
    return 'Build port ($costs)';
  }

  @override
  String get provinceOverlay_tileBuildPortDisabledNoEngineerTooltip =>
      'No Engineer available to build port';

  @override
  String get provinceOverlay_tileBuildPortDisabledTooltip =>
      'No Engineer can assign port work here this turn';

  @override
  String provinceOverlay_tileBuildPortDisabledMaterialsTooltip(String reason) {
    return reason;
  }

  @override
  String get provinceOverlay_tileBuildRailroadTooltip => 'Build railroad';

  @override
  String provinceOverlay_tileBuildRailroadTooltipWithCost(String costs) {
    return 'Build railroad ($costs)';
  }

  @override
  String get provinceOverlay_tileBuildRailroadDisabledNoRailBuilderTooltip =>
      'No Rail Builder available to build railroad';

  @override
  String get provinceOverlay_tileBuildRailroadDisabledTooltip =>
      'No Rail Builder can assign railroad work here this turn';

  @override
  String provinceOverlay_tileBuildRailroadDisabledMaterialsTooltip(
    String reason,
  ) {
    return reason;
  }

  @override
  String get provinceOverlay_tilePortStatusNone => 'Port: None';

  @override
  String get provinceOverlay_tilePortStatusPresent => 'Port: Present';

  @override
  String get provinceOverlay_tileDetailsAction => 'Tile details';

  @override
  String get provinceOverlay_tileDetailsTitle => 'Tile details';

  @override
  String get developmentCounsel_tabDevelopment => 'Development';

  @override
  String get developmentCounsel_empty =>
      'No pressing development advice this turn.';

  @override
  String get developmentCounsel_action_agree => 'Agree';

  @override
  String get developmentCounsel_agreeFailed =>
      'Cannot stage that port work right now — check Engineer availability, materials, and the target tile.';

  @override
  String get developmentCounsel_title_buildPort => 'Build port';

  @override
  String developmentCounsel_title_buildPortAt(String location) {
    return 'Build port · $location';
  }

  @override
  String get developmentCounsel_reason_coastalPort_brief =>
      'A seaboard port would serve this coast.';

  @override
  String get developmentCounsel_reason_resourceCoast_brief =>
      'Resource coast — a port would move extraction overseas.';

  @override
  String get developmentCounsel_reason_newWorldCoast_brief =>
      'New World coast — a port opens overseas linkage.';

  @override
  String get developmentCounsel_reason_overseasLinkage_brief =>
      'Overseas linkage — a port would reconnect unlinked development.';

  @override
  String get development_counsel => 'Counsel';

  @override
  String get provinceOverlay_sectionMilitary => 'Military';

  @override
  String get provinceOverlay_sectionCivilian => 'Civilian';

  @override
  String get provinceOverlay_sectionNaval => 'Naval';

  @override
  String get provinceOverlay_titleProvince => 'Province';

  @override
  String get provinceOverlay_titleSeaZone => 'Sea zone';

  @override
  String get provinceOverlay_moveArmyAction => 'Move';

  @override
  String provinceOverlay_invadeArmyAction(String provinceName) {
    return 'Invade $provinceName';
  }

  @override
  String get provinceOverlay_moveArmyDisabledHomeArmyTooltip =>
      'The Home Army cannot leave the capital. Split a field army first.';

  @override
  String get provinceOverlay_moveArmyDisabledNoDestinationsTooltip =>
      'No legal destinations for field armies stationed here.';

  @override
  String get provinceOverlay_invadeArmyDisabledCannotReachTooltip =>
      'No field army can reach this province this turn.';

  @override
  String get provinceOverlay_selectArmyTitle => 'Select army';
}
