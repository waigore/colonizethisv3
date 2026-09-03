part of 'app_localizations_en.dart';

mixin _AppLocalizationsEnStrings4 on AppLocalizations {
  @override
  String provinceOverlay_indentedCount(String label, int count) {
    return '  $label: $count';
  }

  @override
  String get militaryCounsel_tabMilitary => 'Military';

  @override
  String get militaryCounsel_empty => 'No pressing military advice this turn.';

  @override
  String get militaryCounsel_action_agree => 'Agree';

  @override
  String get militaryCounsel_trainAgreeFailed =>
      'Cannot raise those units right now — check treasury, stockpile, peasants, and queued orders.';

  @override
  String get militaryCounsel_invadeAgreeFailed =>
      'Cannot stage that invasion right now — check army, destination, and diplomacy.';

  @override
  String get militaryCounsel_title_train => 'Raise units';

  @override
  String militaryCounsel_title_trainUnit(String unit, int count) {
    return 'Raise $unit × $count';
  }

  @override
  String get militaryCounsel_title_invade => 'Invade province';

  @override
  String militaryCounsel_title_invadeArmy(String army, String province) {
    return 'Invade with $army → $province';
  }

  @override
  String militaryCounsel_ownerLine(String owner) {
    return 'Owner: $owner';
  }

  @override
  String get militaryCounsel_cost_noMaterials => 'no extra materials';

  @override
  String militaryCounsel_costSummary(
    int treasury,
    String materials,
    int peasants,
  ) {
    return 'Cost: $treasury treasury; $materials; $peasants peasants';
  }

  @override
  String get militaryCounsel_reason_affordableTrain_brief =>
      'Affordable this turn — the planner would raise these units now.';

  @override
  String get militaryCounsel_reason_atWarInvasion_brief =>
      'Already at war — a field army can march on this province.';

  @override
  String get militaryCounsel_reason_declareWarInvasion_brief =>
      'Invasion target — confirm war before the army marches.';

  @override
  String militaryCounsel_trainStarSemantic(String brief) {
    return 'Military counsel: $brief';
  }

  @override
  String get mapCorner_tooltipBaseLayer =>
      'Map marks: resources, improvements, and roads';

  @override
  String mapCorner_tooltipMapMarks(String combination) =>
      'Map marks: $combination';

  @override
  String get mapCorner_mapMarks_terrainOnly => 'terrain only';

  @override
  String get mapCorner_mapMarks_resources => 'resources';

  @override
  String get mapCorner_mapMarks_resourcesAndImprovements =>
      'resources and improvements';

  @override
  String get mapCorner_mapMarks_full => 'resources, improvements, and roads';

  @override
  String get mapCorner_mapMarks_improvements => 'improvements';

  @override
  String get mapCorner_mapMarks_improvementsAndRoads =>
      'improvements and roads';

  @override
  String get mapCorner_tooltipCenterCapital => 'Center on capital';

  @override
  String get mapCorner_tooltipMapDisplayOptions => 'Map display options';

  @override
  String mapControls_cargoHold(String used, String capacity) {
    return '$used/$capacity';
  }

  @override
  String mapControls_cargoHold_tooltip(String used, String capacity) {
    return 'Cargo: $used overseas of $capacity Home Fleet holds';
  }

  @override
  String mapControls_cargoHold_semanticsLabel(String used, String capacity) {
    return 'Cargo hold: $used overseas, $capacity Home Fleet holds';
  }

  @override
  String mapControls_cargoHold_details_overseas(String used) {
    return 'Overseas extraction: $used';
  }

  @override
  String mapControls_cargoHold_details_capacity(String capacity) {
    return 'Home Fleet holds: $capacity';
  }

  @override
  String mapControls_cargoHold_details_free(String free) {
    return 'Free for trade bids: $free';
  }

  @override
  String get mapControls_cargoHold_details_counsel =>
      'Merchant ships in your Home Fleet carry overseas goods; remaining holds are open for trade bids.';

  @override
  String mapControls_labourFeeding(String effective, String capacity) {
    return '$effective/$capacity';
  }

  @override
  String mapControls_labourFeeding_tooltip(String effective, String capacity) {
    return 'Labour this turn: $effective of $capacity';
  }

  @override
  String mapControls_labourFeeding_semanticsLabel(
    String effective,
    String capacity,
  ) {
    return 'Labour this turn: $effective of $capacity. Tap for details.';
  }

  @override
  String mapControls_labourFeeding_details_labour(
    String effective,
    String capacity,
  ) {
    return 'Labour this turn: $effective of $capacity';
  }

  @override
  String get mapControls_labourFeeding_details_emptyPool =>
      'No workers trained yet';

  @override
  String get mapControls_playersBarToggle => 'Players bar';

  @override
  String mapControls_oldWorldRace(String count, String threshold) {
    return '$count / $threshold';
  }

  @override
  String mapControls_oldWorldRace_compact(String count, String threshold) {
    return '$count/$threshold';
  }

  @override
  String mapControls_oldWorldRace_rivalCue(
    String name,
    String count,
    String threshold,
  ) {
    return ' · $name $count / $threshold';
  }

  @override
  String mapControls_oldWorldRace_rivalCueCompact(String name, String count) {
    return ' · $name $count';
  }

  @override
  String get mapControls_oldWorldRace_tooltip =>
      'Old World provinces toward the 31-province win. Tap for full standings.';

  @override
  String mapControls_oldWorldRace_semanticsLabel(
    String count,
    String threshold,
  ) {
    return 'Old World province race: $count of $threshold. Tap to open Victory.';
  }

  @override
  String mapControls_oldWorldRace_semanticsWithRival(
    String count,
    String threshold,
    String name,
    String rivalCount,
  ) {
    return 'Old World province race: $count of $threshold. $name leads with '
        '$rivalCount of $threshold. Tap to open Victory.';
  }

  @override
  String mapControls_playersBar_calendarStrengthTooltip(String score) {
    return 'Calendar-end strength: $score. Used only if the calendar ends '
        'with no province-count winner.';
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
    String resourceName,
    String detail,
  ) {
    return '$terrain/$resourceName $detail';
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
  String diplomacy_detail_formalAllies(String names) {
    return 'Formal allies: $names';
  }

  @override
  String get diplomacy_detail_noDossier => 'No dossier evidence yet.';

  @override
  String diplomacy_detail_turnEvidence(int turn) {
    return 'Turn $turn:';
  }

  @override
  String get diplomacy_panel_noFactions => 'No other factions discovered yet.';

  @override
  String get diplomacy_panel_noGreatPowers => 'No Great Powers discovered yet.';

  @override
  String get diplomacy_panel_noMinorNations =>
      'No Minor Nations discovered yet.';

  @override
  String get diplomacy_panel_noTribes => 'No tribes contacted yet.';

  @override
  String diplomacy_panel_powerScore(int score) {
    return 'Power: $score';
  }

  @override
  String get diplomacy_relativePower_label => 'Relative power:';

  @override
  String get diplomacy_relativePower_tierRoughlyEqual => 'Roughly equal';

  @override
  String get diplomacy_relativePower_tierSuperior => 'Superior';

  @override
  String get diplomacy_relativePower_tierVastlySuperior => 'Vastly superior';

  @override
  String get diplomacy_relativePower_tierInferior => 'Inferior';

  @override
  String get diplomacy_relativePower_tierVastlyInferior => 'Vastly inferior';

  @override
  String get diplomacy_relativePower_tooltip =>
      "Compares this Great Power's military power score "
      '(provinces, army strength, ships) to yours.';

  @override
  String diplomacy_relativePower_semantics(String pct, String tier) {
    return 'Relative power $pct, $tier';
  }

  @override
  String diplomacy_panel_outgoingSubsidy(int amount, String target) {
    return 'Outgoing subsidy: $amount% to $target';
  }

  @override
  String diplomacy_panel_pendingGrant(int amount) {
    return 'Pending grant aid: £$amount (resolves end of turn)';
  }

  @override
  String diplomacy_panel_pendingSubsidy(int amount) {
    return 'Pending subsidy: $amount% (resolves end of turn)';
  }

  @override
  String get diplomacy_panel_moreActions => 'More actions';

  @override
  String get diplomacy_panel_fewerActions => 'Fewer actions';

  @override
  String diplomacy_actionRejection_semanticsLabel(
    String action,
    String reason,
  ) {
    return '$action. $reason';
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
  String production_labourThisTurn(int n) {
    return 'Labour this turn: $n';
  }

  @override
  String get production_labourReasonFood =>
      'Some workers are not working — food is short.';

  @override
  String get production_labourReasonFoodWithMilitary =>
      'Some workers are not working — armies and fleets are fed first, then food runs short.';

  @override
  String production_labourReasonLuxury(String commodity) {
    return 'Some workers are not working — short of $commodity.';
  }

  @override
  String get production_labourDetails => 'Labour details';

  @override
  String production_labourTierDetail(String tier, int working, int notWorking) {
    return '$tier: $working working, $notWorking not working';
  }

  @override
  String get production_forcesFoodArmiesFullyFed =>
      'Armies fully fed this turn.';

  @override
  String get production_forcesFoodArmiesUnderfedModerate =>
      'Armies short on rations — land battles somewhat weaker.';

  @override
  String get production_forcesFoodArmiesUnderfedSevere =>
      'Armies very short on rations — land battles much weaker.';

  @override
  String get production_forcesFoodFleetsFullyFed =>
      'Fleets fully fed this turn.';

  @override
  String get production_forcesFoodFleetsUnderfedModerate =>
      'Fleets short on rations — naval battles somewhat weaker.';

  @override
  String get production_forcesFoodFleetsUnderfedSevere =>
      'Fleets very short on rations — naval battles much weaker.';

  @override
  String get production_forcesFoodDetails => 'Forces food details';

  @override
  String production_forcesFoodDetailsArmies(int fed, int total) {
    return 'Armies: $fed of $total regiments fed';
  }

  @override
  String production_forcesFoodDetailsFleets(int fed, int total) {
    return 'Fleets: $fed of $total ships fed';
  }

  @override
  String production_forcesFoodDetailsDemand(int demand) {
    return 'Forces food demand this turn: $demand';
  }

  @override
  String get production_forcesFoodDetailsPriority =>
      'Armies and fleets eat before workers.';

  @override
  String get forcesFood_landUnderfedModerateWarning =>
      'Your armies are short on rations — they will fight somewhat weaker this turn.';

  @override
  String get forcesFood_landUnderfedSevereWarning =>
      'Your armies are very short on rations — they will fight much weaker this turn.';

  @override
  String production_recipeAffordanceUpToLimitedByCommodity(
    int max,
    String commodity,
  ) {
    return 'Up to $max, limited by $commodity';
  }

  @override
  String production_recipeAffordanceUpToLimitedByLabour(int max) {
    return 'Up to $max, limited by labour this turn';
  }

  @override
  String production_recipeAffordanceUpToLimitedByPanelCap(int max) {
    return 'Up to $max, limited by the per-turn panel cap';
  }

  @override
  String production_recipeAffordanceCannotRunShortOfCommodity(String commodity) {
    return 'Cannot run — short of $commodity';
  }

  @override
  String get production_recipeAffordanceCannotRunNotEnoughLabour =>
      'Cannot run — not enough labour left this turn';

  @override
  String get production_recipeAffordanceTooltip =>
      'How many whole batches you can still ask for this turn after other recipes — not your whole warehouse.';

  @override
  String production_totalLabour(int required, int effective) {
    return 'Total labour: $required / $effective';
  }

  @override
  String get production_labourInsufficient =>
      'Insufficient labour — production will be capped next turn';

  @override
  String production_labourQueued(int count) {
    return 'Queued: $count';
  }

  @override
  String production_labourRecruitTier(String tier) {
    return 'Recruit $tier';
  }

  @override
  String production_labourTrainTier(String tier) {
    return 'Train $tier';
  }

  @override
  String production_labourDequeueTier(String tier) {
    return 'Cancel last queued $tier';
  }

  @override
  String production_labourDisbandTier(String tier) {
    return 'Disband $tier';
  }

  @override
  String get production_labourDisband => 'Disband';

  @override
  String get production_labourTierUnlocked => '(unlocked)';

  @override
  String get production_labourTierLocked => '(locked)';

  @override
  String get production_recipeLocked => '(locked)';

  @override
  String production_labourTierLabel(String tier, String state) {
    return '$tier $state';
  }

  @override
  String get production_labourControlsSectionLabel => 'Labour Controls';

  @override
  String production_labourCostMaterial(String name, int quantity) {
    return '$name ×$quantity';
  }

  @override
  String get production_labourCostPeasantConsume => '1 peasant';

  @override
  String production_labourUpkeepLabour(int n) {
    return '$n labour / turn';
  }

  @override
  String production_labourUpkeepFoodOr(String a, String b) {
    return '$a or $b';
  }

  @override
  String production_labourUpkeepFoodAnd(String a, String b) {
    return '$a + $b';
  }

  @override
  String production_labourRequires(String names) {
    return 'Requires: $names';
  }

  @override
  String get production_labourStaffsNextProduction =>
      'New workers staff next Production';

  @override
  String production_labourAppendEnabledTooltip(String action, String timing) {
    return '$action. $timing';
  }

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
  String trainMilitary_commodityValue(String name, String value) {
    return '$name: $value';
  }

  @override
  String trainCivilians_costLine(String treasury, String paper) {
    return '$treasury + $paper paper';
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
  String get splitFleet_detachTitle => 'Detach a squadron';

  @override
  String get splitFleet_detachConfirm => 'Detach and choose destination';

  @override
  String splitFleet_homeCargoConsequence(int remaining, String used) {
    return 'Cargo holds remaining after this split: $remaining (overseas load this turn: $used).';
  }

  @override
  String splitFleet_totalShips(int total) {
    return 'Total: $total ships';
  }

  @override
  String get naval_transferToHome_dialogTitle => 'Transfer Ships to Home Fleet';

  @override
  String naval_transferToHome_sourceTitle(String id) {
    return 'Fleet $id';
  }

  @override
  String get naval_transferToHome_confirm => 'Transfer';

  @override
  String get diplomacy_section_greatPowers => 'Great Powers';

  @override
  String get diplomacy_section_minorNations => 'Minor Nations';

  @override
  String get diplomacy_section_tribes => 'Tribes';

  @override
  String get diplomacy_filter_all => 'All';

  @override
  String get diplomacy_filter_greatPowersOnly => 'Great Powers only';

  @override
  String get diplomacy_filter_minorsOnly => 'Minors only';

  @override
  String get diplomacy_relationState_war => 'War';

  @override
  String get diplomacy_relationState_peace => 'Peace';

  @override
  String diplomacy_relationMeter_semanticsLabel(String relation) {
    return 'Relation: $relation';
  }

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

  @override
  String get techEffectSummary_discovery_of_gold_or_silver_1 =>
      'Unlocks: Precious Metals Mining';

  @override
  String get techEffectSummary_discovery_of_spices_0 =>
      'Enables: Research when player has revealed spices (discovery rule)';

  @override
  String get techEffectSummary_discovery_of_spices_1 =>
      'Unlocks: Improved Sea Routes';

  @override
  String get techEffectSummary_discovery_of_sugar_0 =>
      'Enables: Research when player has revealed sugar cane (discovery rule)';

  @override
  String get techEffectSummary_discovery_of_sugar_1 =>
      'Unlocks: Sugar Planting and Sugar Refining';

  @override
  String get techEffectSummary_discovery_of_tobacco_0 =>
      'Enables: Research when player has revealed tobacco (discovery rule)';

  @override
  String get techEffectSummary_discovery_of_tobacco_1 =>
      'Unlocks: Tobacco Planting and Cigar Production';

  @override
  String get techEffectSummary_dynamite_0 => 'Enables: Railroads on mountains';

  @override
  String get techEffectSummary_dynamite_1 =>
      'Unlocks: Safety Lamp, Geological Prospecting, Amalgamation Process';

  @override
  String get techEffectSummary_early_rifles_0 =>
      'Improves: Calivermen regiment upgrade path';

  @override
  String get techEffectSummary_early_rifles_1 =>
      'Prerequisite for: Long Range Rifles, Scouting, and Needle Guns';

  @override
  String get techEffectSummary_early_steam_engine_0 =>
      'Enables: Rail Builder and railroads on flat terrain';

  @override
  String get techEffectSummary_early_steam_engine_1 =>
      'Unlocks: Later Steam Engine, Riverboats, Tobacco Industry';

  @override
  String get techEffectSummary_efficient_extraction_of_copper_and_tin_0 =>
      'Improves: Copper/Tin extraction cap to 4';

  @override
  String get techEffectSummary_efficient_extraction_of_copper_and_tin_1 =>
      'Prerequisite-only: catalog leaf; extraction-cap increase is the active benefit';

  @override
  String get techEffectSummary_elite_military_training_0 =>
      'Improves: Grenadiers regiment upgrade path';

  @override
  String get techEffectSummary_empire_building_0 =>
      'Enables: Join Empire overture toward nearly-defeated Great Powers';

  @override
  String get techEffectSummary_empire_building_1 =>
      'Requires: Target owns ≤3 provinces and lost original capital';

  @override
  String get techEffectSummary_emplaced_siege_guns_0 =>
      'Improves: defender emplaced fort batteries to Siege Gun quality (final emplaced tier)';

  @override
  String get techEffectSummary_excessive_fur_harvesting_0 =>
      'Improves: Furs extraction cap to 4';

  @override
  String get techEffectSummary_excessive_fur_harvesting_1 =>
      'Prerequisite-only: catalog leaf; extraction-cap increase is the active benefit';

  @override
  String get techEffectSummary_explosives_0 =>
      'Improves: Musketeers regiment upgrade path';

  @override
  String get techEffectSummary_explosives_1 =>
      'Prerequisite for: Elite Military Training';

  @override
  String get techEffectSummary_extraction_of_precious_metals_0 =>
      'Improves: Gold/silver extraction cap to 3';

  @override
  String get techEffectSummary_extraction_of_precious_metals_1 =>
      'Unlocks: Amalgamation Process (with Dynamite)';

  @override
  String get techEffectSummary_field_artillery_tactics_0 =>
      'Improves: Light Artillery regiment upgrade path';

  @override
  String get techEffectSummary_geological_prospecting_0 =>
      'Improves: Gems/diamonds extraction cap to 4';

  @override
  String get techEffectSummary_geological_prospecting_1 =>
      'Prerequisite-only: catalog leaf; extraction-cap increase is the active benefit';

  @override
  String get techEffectSummary_hat_production_0 =>
      'Enables: Fur hats luxury production for Master-tier worker consumption';

  @override
  String get techEffectSummary_hat_production_1 => 'Unlocks: Master Artisans';
}
