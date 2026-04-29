part of 'app_localizations_en.dart';

mixin _AppLocalizationsEnStrings3 on AppLocalizations {
  String get provinceOverlay_tileImprovementUnknown => 'Improvement: ???';

  @override
  String get provinceOverlay_tileRoadUnknown => 'Road / railroad: ???';

  @override
  String get provinceOverlay_tileCivilianUnitsUnknown =>
      'Civilian units (province): ???';

  @override
  String provinceOverlay_tileCoordinates(int x, int y) {
    return 'Coordinates: ($x, $y)';
  }

  @override
  String provinceOverlay_tileTerrain(String terrain) {
    return 'Terrain: $terrain';
  }

  @override
  String get provinceOverlay_tileResourcePrefix => 'Resource: ';

  @override
  String provinceOverlay_tileProspected(String value) {
    return 'Prospected: $value';
  }

  @override
  String provinceOverlay_tileImprovement(String value) {
    return 'Improvement: $value';
  }

  @override
  String get provinceOverlay_tileRoadNone => 'Road / railroad: -';

  @override
  String provinceOverlay_tileCivilianUnits(int count) {
    return 'Civilian units (province): $count';
  }

  @override
  String provinceOverlay_seaZone(String name) {
    return 'Sea zone: $name';
  }

  @override
  String provinceOverlay_name(String name) {
    return 'Name: $name';
  }

  @override
  String provinceOverlay_owner(String owner) {
    return 'Owner: $owner';
  }

  @override
  String provinceOverlay_indentedCount(String label, int count) {
    return '  $label: $count';
  }

  @override
  String provinceOverlay_unitTarget(String type, String id, String target) {
    return '$type ($id): $target';
  }

  @override
  String provinceOverlay_foreignUnitStatus(
    String owner,
    String type,
    String id,
    String status,
  ) {
    return '$owner — $type ($id): $status';
  }

  @override
  String provinceOverlay_fleetSummary(
    String owner,
    String fleetLabel,
    String shipParts,
  ) {
    return '$owner — $fleetLabel: $shipParts';
  }

  @override
  String get provinceOverlay_sectionPolitical => 'Political';

  @override
  String get provinceOverlay_sectionTile => 'Tile';

  @override
  String get provinceOverlay_sectionEconomic => 'Economic';

  @override
  String get provinceOverlay_sectionMilitary => 'Military';

  @override
  String get provinceOverlay_sectionCivilian => 'Civilian';

  @override
  String get provinceOverlay_sectionNaval => 'Naval';

  @override
  String get gameSetup_title => 'Game Setup';

  @override
  String get gameSetup_starting => 'Starting…';

  @override
  String get gameSetup_startGame => 'Start Game';

  @override
  String get gameSetup_back => 'Back';

  @override
  String get gameSetup_player1You => 'Player 1 (You)';

  @override
  String gameSetup_playerAiSlot(int n) {
    return 'Player $n (AI)';
  }

  @override
  String get gameSetup_selectNation => 'Select nation';

  @override
  String get gameSetup_selectLeader => 'Select leader';

  @override
  String get mapCorner_tooltipBaseLayer =>
      'Base layer: terrain / +resources / +improvements';

  @override
  String get mapCorner_tooltipCenterCapital => 'Center on capital';

  @override
  String get mapCorner_tooltipMapDisplayOptions => 'Map display options';

  @override
  String mapControls_cargoHold(String used, String capacity) {
    return '$used/$capacity';
  }

  @override
  String common_percent(int value) {
    return '$value%';
  }

  @override
  String get regionMinimap_mapZoom => 'Map zoom';

  @override
  String regionMinimap_zoomSemanticsValue(int pct) {
    return '$pct percent';
  }

  @override
  String province_economic_resourceRow(
    String terrain,
    String resourceId,
    String detail,
  ) {
    return '$terrain/$resourceId $detail';
  }

  @override
  String get diplomacy_detail_historyTitle => 'Diplomatic history';

  @override
  String get diplomacy_detail_noEvents =>
      'No recorded events with this faction.';

  @override
  String diplomacy_detail_yearTurn(int year, int turn) {
    return '$year (Turn $turn)';
  }

  @override
  String get diplomacy_detail_dossierTitle => 'Dossier';

  @override
  String get diplomacy_detail_currentRelation => 'Current relation';

  @override
  String get diplomacy_detail_noDossier => 'No dossier evidence yet.';

  @override
  String diplomacy_detail_turnEvidence(int turn) {
    return 'Turn $turn:';
  }

  @override
  String get diplomacy_panel_noFactions => 'No other factions discovered yet.';

  @override
  String diplomacy_panel_powerScore(int score) {
    return 'Power: $score';
  }

  @override
  String diplomacy_panel_outgoingSubsidy(int amount, String target) {
    return 'Outgoing subsidy: £$amount/turn to $target';
  }

  @override
  String diplomacy_panel_pendingGrant(int amount) {
    return 'Pending grant aid: £$amount (resolves end of turn)';
  }

  @override
  String diplomacy_panel_pendingSubsidy(int amount) {
    return 'Pending subsidy: £$amount/turn (resolves end of turn)';
  }

  @override
  String production_commodityStock(String name, int qty, String change) {
    return '$name: $qty$change';
  }

  @override
  String production_effectiveLabour(int n) {
    return 'Effective labour: $n';
  }

  @override
  String production_recipeAffordance(int max, String limiting) {
    return '$max · $limiting';
  }

  @override
  String production_totalLabour(int required, int effective) {
    return 'Total labour: $required / $effective';
  }

  @override
  String get production_labourInsufficient =>
      'Insufficient labour — production will be capped next turn';

  @override
  String production_workerCount(String name, int count) {
    return '$name: $count';
  }

  @override
  String naval_units_shipTypeCount(String typeName, int count) {
    return '$typeName: $count';
  }

  @override
  String civilian_assignWorkTitle(String unitType) {
    return 'Assign work: $unitType';
  }

  @override
  String trainMilitary_commodityAmount(String name, int qty) {
    return '$name: $qty';
  }

  @override
  String trainCivilians_costLine(String treasury, String paper) {
    return '$treasury + $paper Paper';
  }

  @override
  String techTree_prerequisiteBullet(String name) {
    return '• $name';
  }

  @override
  String techEffect_unlocksRegiment(String name) {
    return 'Unlocks regiment: $name';
  }

  @override
  String techEffect_unlocksShip(String name) {
    return 'Unlocks ship: $name';
  }

  @override
  String techEffect_fallbackCategoryImprovement(String category) {
    return 'Improves $category capabilities';
  }

  @override
  String get techTree_categoryGathering => 'Gathering';

  @override
  String get techTree_categoryTransport => 'Transport';

  @override
  String get techTree_categoryLabour => 'Labour';

  @override
  String get techTree_categoryCivilian => 'Civilian';

  @override
  String get techTree_categoryDiplomacy => 'Diplomacy';

  @override
  String get techTree_categoryNaval => 'Naval';

  @override
  String get techTree_categoryMilitary => 'Military';

  @override
  String get techTree_categoryNewWorld => 'New World';

  @override
  String transferList_rowCount(String name, int count) {
    return '$name ($count)';
  }

  @override
  String get widgetbook_openPanelHint => 'Tap button to open panel from bottom';

  @override
  String naval_fleetLabel(String id) {
    return 'Fleet $id';
  }

  @override
  String get naval_homeFleetLabel => 'Home Fleet';

  @override
  String locationSection_headerLine(String label, String region) {
    return '$label — $region';
  }

  @override
  String get splitFleet_dialogTitle => 'Split Fleet';

  @override
  String get splitFleet_newFleetTitle => 'New Fleet';

  @override
  String get splitFleet_noShips => 'No ships';

  @override
  String get splitFleet_confirm => 'Confirm Split';

  @override
  String splitFleet_totalShips(int total) {
    return 'Total: $total ships';
  }

  @override
  String get diplomacy_section_greatPowers => 'Great Powers';

  @override
  String get diplomacy_section_minorNations => 'Minor Nations';

  @override
  String get diplomacy_section_tribes => 'Tribes';

  @override
  String get diplomacy_relationState_war => 'War';

  @override
  String get diplomacy_relationState_peace => 'Peace';

  @override
  String get techEffectSummary_advanced_hull_design_0 =>
      'Improves: Frigate — high intercept, moderate flee (patrol/blockade)';

  @override
  String get techEffectSummary_advanced_hull_design_1 =>
      'Unlocks: Clipper Ships and Paddlewheels hull paths';

  @override
  String get techEffectSummary_advanced_iron_working_0 =>
      'Improves: Ironclad armored steam combat hull';

  @override
  String get techEffectSummary_amalgamation_process_0 =>
      'Improves: Gold/silver extraction cap to 4';

  @override
  String get techEffectSummary_amalgamation_process_1 =>
      'Prerequisite-only: catalog leaf; extraction-cap increase is the active benefit';

  @override
  String get techEffectSummary_animal_husbandry_0 =>
      'Improves: Meat extraction cap to 3';

  @override
  String get techEffectSummary_animal_husbandry_1 =>
      'Unlocks: Scientific Cattle Breeding (with University)';

  @override
  String get techEffectSummary_animal_husbandry_2 =>
      'Enables: Military branches that require this tech';

  @override
  String get techEffectSummary_apprentice_workers_0 =>
      'Enables: Apprentice tier (4x labour; consumes refined sugar)';

  @override
  String get techEffectSummary_apprentice_workers_1 =>
      'Unlocks: University and Master Artisans';

  @override
  String get techEffectSummary_banking_0 =>
      'Unlocks: Dynamite, Empire Building, Modern Military Funding';

  @override
  String get techEffectSummary_banking_1 =>
      'With Money Lending: extends research-phase treasury floor to −£1000';

  @override
  String get techEffectSummary_bayonet_0 =>
      'Unlocks: Needle Guns (with Industrial Funding + Early Rifles)';

  @override
  String get techEffectSummary_cigar_production_0 =>
      'Enables: Cigar luxury production for Journeyman-tier worker consumption';

  @override
  String get techEffectSummary_cigar_production_1 =>
      'Unlocks: Trained Journeymen';

  @override
  String get techEffectSummary_circular_saw_0 =>
      'Improves: Timber extraction cap to 4';

  @override
  String get techEffectSummary_circular_saw_1 =>
      'Unlocks: Clipper Ships (with Advanced Hull Design)';

  @override
  String get techEffectSummary_clipper_ships_0 =>
      'Improves: Late-era fast merchant Clipper cargo line';

  @override
  String get techEffectSummary_coal_mining_0 =>
      'Enables: Coal extraction (cap 1)';

  @override
  String get techEffectSummary_coal_mining_1 => 'Unlocks: Square-set Timbering';

  @override
  String get techEffectSummary_convoying_0 =>
      'Unlocks: Large Hulls (with Wind Saw Mill + Navigation)';

  @override
  String get techEffectSummary_copper_and_tin_mining_0 =>
      'Improves: Copper/Tin extraction cap to 2';

  @override
  String get techEffectSummary_copper_and_tin_mining_1 =>
      'Unlocks: Large Copper and Tin Mines';

  @override
  String get techEffectSummary_copper_and_tin_mining_2 =>
      'Enables: Military branches that require this tech';

  @override
  String get techEffectSummary_cotton_gin_0 =>
      'Improves: Cotton extraction cap to 4';

  @override
  String get techEffectSummary_cotton_gin_1 =>
      'Prerequisite-only: catalog leaf; extraction-cap increase is the active benefit';

  @override
  String get techEffectSummary_cotton_planting_0 =>
      'Improves: Cotton extraction cap to 2';

  @override
  String get techEffectSummary_cotton_planting_1 =>
      'Unlocks: Large Cotton Plantations';

  @override
  String get techEffectSummary_cotton_weaving_0 =>
      'Enables: Cloth production from cotton';

  @override
  String get techEffectSummary_cotton_weaving_1 =>
      'Prerequisite-only: catalog leaf; recipe unlock is the active benefit';

  @override
  String get techEffectSummary_crop_rotation_0 =>
      'Unlocks: Sheep Ranching, Animal Husbandry, and Steppe Horsemen research paths';

  @override
  String get techEffectSummary_crucible_process_0 =>
      'Prerequisite-only: Steel chain for Bayonet, rifles, steam, and cannons';

  @override
  String get techEffectSummary_crucible_process_1 =>
      'Unlocks: No regiment from this tech alone';

  @override
  String get techEffectSummary_diplomatic_expertise_0 =>
      'Enables: Embassy overtures with Minor Nations';

  @override
  String get techEffectSummary_diplomatic_expertise_1 =>
      'Enables: civilian work in embassy-linked Minor Nations';

  @override
  String get techEffectSummary_diplomatic_expertise_2 =>
      'Unlocks: National Bureaucracy';

  @override
  String get techEffectSummary_discovery_of_cotton_0 =>
      'Enables: Research when player has revealed cotton (discovery rule)';

  @override
  String get techEffectSummary_discovery_of_cotton_1 =>
      'Unlocks: Cotton Planting and Cotton Weaving';

  @override
  String get techEffectSummary_discovery_of_furs_0 =>
      'Enables: Research when player has revealed furs (discovery rule)';

  @override
  String get techEffectSummary_discovery_of_furs_1 =>
      'Unlocks: Improved Trapping Techniques and Hat Production';

  @override
  String get techEffectSummary_discovery_of_gems_or_diamonds_0 =>
      'Enables: Research when player has revealed and prospected gems/diamonds';

  @override
  String get techEffectSummary_discovery_of_gems_or_diamonds_1 =>
      'Unlocks: Precious Stone Mining';

  @override
  String get techEffectSummary_discovery_of_gold_or_silver_0 =>
      'Enables: Research when player has revealed and prospected gold/silver';

}
