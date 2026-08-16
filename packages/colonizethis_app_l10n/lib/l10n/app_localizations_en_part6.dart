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
  String get mapExtractionDisc_legendGold => 'Reaches capital';

  @override
  String get mapExtractionDisc_legendBrown => 'Blocked — will not extract';

  @override
  String get mapExtractionDisc_legendSemantics => 'Extraction disc colours';

  @override
  String get mapExtractionDisc_detailsGold =>
      'Gold: yield that reaches your capital this turn.';

  @override
  String get mapExtractionDisc_detailsBrown =>
      'Brown: improved yield that does not reach the stockpile (no capital link, or the road/port/town path is capped).';

  @override
  String get mapExtractionDisc_detailsCounsel =>
      'Restore roads, towns, or ports toward your capital before treating a brown-disc tile as productive.';

  @override
  String get mapImprovementHeadroom_legendHeadroom => 'Can still raise';

  @override
  String get mapImprovementHeadroom_legendAtCap => "At this court's limit";

  @override
  String get mapImprovementHeadroom_legendSemantics =>
      "Improvement level versus this court's extraction limit";

  @override
  String get mapImprovementHeadroom_detailsMeaning =>
      'The corner mark is improvement level versus what this court can extract now (for example 1 of 1 or 1 of 2).';

  @override
  String get mapImprovementHeadroom_detailsMuted =>
      'Muted marks are already at the current limit; raising them further wastes materials.';

  @override
  String get mapImprovementHeadroom_detailsCounsel =>
      'Empty farms stay on Development and the province overlay — the map only marks tiles that already have an improvement.';

  @override
  String get provinceOverlay_moveArmyAction => 'Move';

  @override
  String get provinceOverlay_stationSpyAction => 'Station spy';

  @override
  String get provinceOverlay_stationSpyDisabledNoIdleSpyTooltip =>
      'No idle Spy can relocate here.';

  @override
  String get provinceOverlay_stationSpyDisabledNotOccupiableTooltip =>
      'This tile cannot be occupied.';

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
  String get provinceOverlay_blockadeAction => 'Blockade';

  @override
  String get provinceOverlay_beachheadAction => 'Beachhead';

  @override
  String get provinceOverlay_blockadeBeachheadDisabledNotAtSeaTooltip =>
      'A fleet must be at sea beside this coast. Fleets in port cannot take missions.';

  @override
  String get provinceOverlay_detachAndSailAction => 'Detach and sail';

  @override
  String get provinceOverlay_detachAndSailTooltip =>
      'Detach a squadron from the Home Fleet, then choose an adjacent sea.';

  @override
  String get provinceOverlay_selectArmyTitle => 'Select army';

  @override
  String provinceOverlay_sight(String phrase) {
    return 'Sight: $phrase';
  }

  @override
  String get mapSight_fullyVisible => 'Fully visible';

  @override
  String get mapSight_foggedTerrainOnly => 'Fogged — terrain only';

  @override
  String get mapSight_unknownNoIntel => 'Unknown — no intel yet';

  @override
  String mapHover_place(String name) {
    return 'Place: $name';
  }

  @override
  String get mapHover_seaZoneIdentity => 'Sea zone';

  @override
  String get mapHover_warpPassage =>
      'This water is the passage to the other world';

  @override
  String mapHover_semantics(String summary) {
    return summary;
  }

  @override
  String get tileRadial_explore => 'Explore';

  @override
  String get tileRadial_prospect => 'Prospect';

  @override
  String get tileRadial_buildImprovement => 'Build improvement';

  @override
  String get tileRadial_more => 'More';

  @override
  String get tileRadial_moreTitle => 'More tile actions';

  @override
  String get tileRadial_provinceDetails => 'Province details';

  @override
  String get splitArmy_detachTitle => 'Detach a field army';

  @override
  String get splitArmy_detachConfirm => 'Detach and choose destination';

  @override
  String get tradeDealBook_unfilledHeading => 'Still open';

  @override
  String get tradeDealBook_unfilledEmpty => 'None still open.';

  @override
  String tradeDealBook_filledRow(
    String commodity,
    int quantity,
    int unitPrice,
    int notional,
  ) => '$commodity — $quantity at £$unitPrice = £$notional';

  @override
  String tradeDealBook_unfilledRow(String commodity, int quantity) =>
      '$commodity — $quantity';

  @override
  String tradeDealBook_totalsLine(String label, int amount) =>
      '$label: £$amount';
}
