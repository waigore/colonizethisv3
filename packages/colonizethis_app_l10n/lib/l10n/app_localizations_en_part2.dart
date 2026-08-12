part of 'app_localizations_en.dart';

mixin _AppLocalizationsEnStrings2 on AppLocalizations {
  @override
  String get province_regiment_cossacks => 'Cossacks';

  @override
  String get province_regiment_lancers => 'Lancers';

  @override
  String get province_regiment_harquebusiers => 'Harquebusiers';

  @override
  String get province_regiment_horse_artillery => 'Horse artillery';

  @override
  String get province_regiment_royal_artillery => 'Royal artillery';

  @override
  String get province_regiment_skirmishers => 'Skirmishers';

  @override
  String get province_regiment_regulars => 'Regulars';

  @override
  String get province_regiment_grenadiers => 'Grenadiers';

  @override
  String get province_regiment_hussars => 'Hussars';

  @override
  String get province_regiment_cuirassiers => 'Cuirassiers';

  @override
  String get province_regiment_light_artillery => 'Light artillery';

  @override
  String get province_regiment_heavy_artillery => 'Heavy artillery';

  @override
  String get province_regiment_sharpshooters => 'Sharpshooters';

  @override
  String get province_regiment_rifle_infantry => 'Rifle infantry';

  @override
  String get province_regiment_guards => 'Guards';

  @override
  String get province_regiment_scouts => 'Scouts';

  @override
  String get province_regiment_carbine_cavalry => 'Carbine cavalry';

  @override
  String get province_regiment_field_artillery => 'Field artillery';

  @override
  String get province_regiment_siege_guns => 'Siege guns';

  @override
  String get province_ship_carrack => 'Carrack';

  @override
  String get province_ship_fluyte => 'Fluyte';

  @override
  String get province_ship_sloop => 'Sloop';

  @override
  String get province_ship_trader => 'Trader';

  @override
  String get province_ship_galleon => 'Galleon';

  @override
  String get province_ship_indiaman => 'Indiaman';

  @override
  String get province_ship_frigate => 'Frigate';

  @override
  String get province_ship_raider => 'Raider';

  @override
  String get province_ship_ship_of_the_line => 'Ship of the Line';

  @override
  String get province_ship_clipper => 'Clipper';

  @override
  String get province_ship_merchant_steamship => 'Merchant Steamship';

  @override
  String get province_ship_ironclad => 'Ironclad';

  @override
  String quickBattle_commandPoints(int cp) {
    return 'Command Points: $cp';
  }

  @override
  String get quickBattle_action_volleyFire => 'Volley Fire';

  @override
  String get quickBattle_action_defend => 'Defend';

  @override
  String get quickBattle_action_maneuver => 'Maneuver';

  @override
  String get quickBattle_action_fallBack => 'Fall Back';

  @override
  String get quickBattle_action_assault => 'Assault';

  @override
  String quickBattle_actionWithCost(String label, int cost) {
    return '$label ($cost CP)';
  }

  @override
  String quickBattle_combatAt(String provinceName) {
    return 'Combat at $provinceName';
  }

  @override
  String get quickBattle_capitalSiegeQuickBattleOnly =>
      'Capital siege — Quick Battle only (no auto-resolve).';

  @override
  String get quickBattle_chooseCombatMode => 'Choose combat mode:';

  @override
  String get quickBattle_autoResolve => 'Auto-Resolve';

  @override
  String get quickBattle_quickBattle => 'Quick Battle';

  @override
  String quickBattle_attackerWins(String name) {
    return '$name wins';
  }

  @override
  String quickBattle_defenderHolds(String name) {
    return '$name holds';
  }

  @override
  String get quickBattle_mutualExhaustion => 'Mutual exhaustion';

  @override
  String quickBattle_battleResult(String winnerText) {
    return 'Battle Result: $winnerText';
  }

  @override
  String get quickBattle_provinceCaptured => 'Province captured.';

  @override
  String quickBattle_casualties(String name, int count) {
    return '$name casualties: $count';
  }

  @override
  String get quickBattle_ok => 'OK';

  @override
  String quickBattle_round(int round, int maxRounds) {
    return 'Quick Battle — Round $round / $maxRounds';
  }

  @override
  String get quickBattle_resolveAuto => 'Resolve (Auto)';

  @override
  String get quickBattle_attackerDefaultName => 'Attacker';

  @override
  String get quickBattle_defenderDefaultName => 'Defender';

  @override
  String game_intro_loadError(String error) {
    return 'Could not load intro dialogue: $error';
  }

  @override
  String get gameStartIntroOverlay_title => 'A New World Awaits';

  @override
  String get tribeFirstContactOverlay_title => 'First Contact';

  @override
  String tribeFirstContactOverlay_loadError(String error) {
    return 'Could not load first-contact dialogue: $error';
  }

  @override
  String game_overture_loadError(String error) {
    return 'Could not load overture dialogue: $error';
  }

  @override
  String get game_overture_title => 'Diplomatic overtures';

  @override
  String get game_overture_intro => 'Accept or reject each offer.';

  @override
  String game_overture_offerLine(String offerer, String stage) {
    return '$offerer: $stage';
  }

  @override
  String get game_overture_accept => 'Accept';

  @override
  String get game_overture_reject => 'Reject';

  @override
  String get victory_military => 'Military victory';

  @override
  String victory_winnerOnTurn(String winner, int turn) {
    return '$winner wins on turn $turn.';
  }

  @override
  String get victory_returnToMainMenu => 'Return to main menu';

  @override
  String get victory_viewFinalState => 'View final state';

  @override
  String victory_conditionsMilitaryThreshold(int threshold) {
    return 'Control $threshold or more Old World provinces to win.';
  }

  @override
  String get victory_conditionsCalendarEnd =>
      'If no one wins by province count, the campaign can halt near 1800 '
      '(turn 201 under the default calendar). The Great Power with the '
      'strongest overall realm may be named the declared winner; a tie names '
      'no one.';

  @override
  String get victory_conditionsInfiniteMode =>
      'Infinite mode is on: the calendar halt is bypassed. Only reaching the '
      'province win or leaving the campaign ends play.';

  @override
  String victory_endProvinceCountWin(String winner, int turn) {
    return '$winner won on turn $turn by controlling enough Old World provinces.';
  }

  @override
  String victory_endCalendarDeclaredWinner(String winner) {
    return 'Calendar campaign ended. $winner had the strongest overall realm '
        'when play stopped.';
  }

  @override
  String get victory_endCalendarNoWinner =>
      'Calendar campaign ended with no declared winner (tied overall strength).';

  @override
  String get victory_powerBreakdownIntro =>
      'These totals matter only if the campaign runs to the calendar end '
      'without a province-count winner.';

  @override
  String victory_powerBreakdownProvinces(int count) =>
      'Provinces (all worlds): $count';

  @override
  String victory_powerBreakdownRegiments(int strength) =>
      'Regiment strength: $strength';

  @override
  String victory_powerBreakdownShips(int count) => 'Ships: $count';

  @override
  String victory_powerBreakdownTotal(int total) =>
      'Overall strength total: $total';

  @override
  String victory_standingOwCount(int count) => '$count OW';

  @override
  String victory_standingOwProgress(int count, int threshold) =>
      '$count / $threshold Old World provinces';

  @override
  String get victory_standingsHelper =>
      'Colours match the map. Select a Great Power to see their Old World lands.';

  @override
  String get moveArmy_groupYourProvinces => 'Your provinces';

  @override
  String get moveArmy_groupUnowned => 'Unowned';

  @override
  String get moveArmy_groupInvasionTargets => 'Invasion targets';

  @override
  String moveArmy_declareWarOnTrigger(String ownerLabel) {
    return 'declare war on $ownerLabel';
  }

  @override
  String get moveArmy_invadeProvinceTitle => 'Declare war?';

  @override
  String moveArmy_invadeProvinceBody(String ownerLabel) {
    return 'Moving into $ownerLabel territory will declare war this turn and then move the army. Continue?';
  }

  @override
  String get moveArmy_declareWarAndMove => 'Declare war and move';

  @override
  String moveArmy_title(String armyId) {
    return 'Move army — Army $armyId';
  }

  @override
  String get moveArmy_noValidDestinations => 'No valid destinations.';

  @override
  String get moveArmy_destinationProvince => 'Destination province';

  @override
  String moveArmy_yourArmyRegiments(int count) {
    return 'Your army: $count regiments';
  }

  @override
  String moveArmy_invasionsThisTurn(int invasions, int generals) {
    return 'Invasions this turn: $invasions · Generals: $generals';
  }

  @override
  String get moveArmy_invasionOverGeneralCapacityWarning =>
      'More invasions than generals — extra armies fight with weaker command.';

  @override
  String moveArmy_defendersRegiments(int count) {
    return 'Defenders: $count regiments';
  }

  @override
  String get moveArmy_unopposedCapture => 'Unopposed capture';

  @override
  String get moveArmy_defendersUnknown => 'Defenders unknown';

  @override
  String get moveArmy_fortOpenField => 'Open field';

  @override
  String get moveArmy_fortWoodSiege => 'Wood fort siege';

  @override
  String get moveArmy_fortStoneSiege => 'Stone fort siege';

  @override
  String get moveArmy_fortModernSiege => 'Modern fort siege';

  @override
  String moveFleet_title(String fleetLabel) {
    return 'Move fleet — $fleetLabel';
  }

  @override
  String moveFleet_titleWithDestinations(String fleetLabel, int count) {
    return 'Move fleet — $fleetLabel ($count destinations)';
  }

  @override
  String get moveFleet_noAdjacentSeaZones =>
      'No adjacent sea zones (check map topology).';

  @override
  String get moveFleet_seaZonesSection => 'Sea zones';

  @override
  String get moveFleet_provincesDockSection => 'Provinces (dock)';

  @override
  String get moveFleet_locateOnMap => 'Locate on map';

  @override
  String get moveFleet_warpLink => 'links';

  @override
  String moveFleet_warpLinkToRegion(String region) {
    return 'links to $region';
  }

  @override
  String get military_units_title => 'Military Units';

  @override
  String get military_units_counsel => 'Counsel';

  @override
  String get military_units_deselectAllArmies => 'Deselect all armies';

  @override
  String get military_units_selectAllArmies => 'Select all armies';

  @override
  String get military_units_empty => 'No military units';

  @override
  String military_units_generalsCount(int count, int cap) {
    return 'Generals: $count of $cap';
  }

  @override
  String military_units_generalMedals(int index, int medals) {
    return 'General $index: $medals medals';
  }

  @override
  String get military_units_generalsPlainSummary =>
      'Each general can lead one invasion this turn. More medals mean a stronger fight.';

  @override
  String get military_units_generalsMedalGloss =>
      'Medals let more regiments fight, help troops hold the line, and can decide who strikes first.';

  @override
  String get military_units_generalsDetails => 'Details';

  @override
  String get military_units_generalsHideDetails => 'Hide';

  @override
  String get military_units_homeArmy => 'Home Army';

  @override
  String military_units_army(String armyId) {
    return 'Army $armyId';
  }

  @override
  String military_units_armySubtitle(int regiments, String location) {
    return '$regiments regiments · $location';
  }

  @override
  String military_units_armySubtitleWithDraft(
    int regiments,
    String location,
    String draftLine,
  ) {
    return '$regiments regiments · $location\n$draftLine';
  }

  @override
  String get military_units_noRegimentsAssigned => 'No regiments assigned';

  @override
  String military_units_typeCount(String typeName, int count) {
    return '$typeName: $count';
  }

  @override
  String military_units_regimentSubtitle(String medals, String status) {
    return 'Medals: $medals · Status: $status';
  }

  @override
  String military_units_status(String status) {
    return 'Status: $status';
  }

  @override
  String get naval_units_title => 'Naval Units';

  @override
  String get naval_units_title_tile => 'Naval Units (Tile)';

  @override
  String get naval_units_deselectAllFleets => 'Deselect all fleets';

  @override
  String get naval_units_selectAllFleets => 'Select all fleets';

  @override
  String get naval_units_empty => 'No naval units';

  @override
  String naval_units_totalShips(int count) {
    return 'Total ships: $count';
  }

  @override
  String naval_units_strength(String value) {
    return 'Strength: $value';
  }

  @override
  String naval_units_warships(int count) {
    return '$count warships';
  }

  @override
  String naval_units_merchants(int count) {
    return '$count merchants';
  }

  @override
  String get naval_units_locateFleet => 'Locate fleet';

  @override
  String naval_units_mission(String mission) {
    return 'Mission: $mission';
  }

  @override
  String get naval_mission_assign => 'Mission';

  @override
  String naval_mission_menuTitle(String fleet) {
    return 'Assign mission — $fleet';
  }

  @override
  String get naval_mission_selectFleetTitle => 'Select fleet';

  @override
  String get naval_mission_cancelPending => 'Cancel pending mission';

  @override
  String naval_mission_pendingLine(String mission) {
    return 'On mission: $mission';
  }

  @override
  String naval_mission_pendingLineWithTarget(String mission, String target) {
    return 'On mission: $mission → $target';
  }

  @override
  String naval_mission_selectTargetTitle(String mission) {
    return 'Select target — $mission';
  }

  @override
  String get naval_mission_noMissionsAvailable =>
      'No missions available for this fleet.';

  @override
  String get naval_mission_noTargetsAvailable =>
      'No legal targets for this mission.';

  @override
  String get naval_mission_effect_patrol =>
      'Stay here and try to intercept hostile fleets moving through this sea zone.';

  @override
  String get naval_mission_effect_defend =>
      'Stay in place without seeking combat; you can still be attacked or pulled into a fight.';

  @override
  String get naval_mission_effect_blockade =>
      'Stronger intercept chance on fleets entering this zone, including ships leaving the target port.';

  @override
  String get naval_mission_effect_beachhead =>
      'Stage a landing site so your armies can invade that coast next turn; marker then expires.';

  @override
  String get naval_mission_targetCaption_blockade =>
      'Pressures the target port approaches with stronger interception than Patrol.';

  @override
  String get naval_mission_targetCaption_beachhead =>
      'Landing site supports invasion on the following turn and expires after that turn if unused.';

  @override
  String get naval_units_noShipsInFleet => 'No ships in this fleet';

  @override
  String naval_units_cargoCapacity(int capacity) {
    return 'Cargo capacity: $capacity';
  }

  @override
  String naval_units_cargoCapacityIfAssigned(int capacity) {
    return 'Cargo capacity (if assigned): $capacity';
  }

  @override
  String get naval_units_locInPort => '(in port)';

  @override
  String get naval_units_locAtSea => '(at sea)';

  @override
  String get naval_units_homeFleetChip => 'HOME';

  @override
  String get naval_units_compositionRoleWarship => 'Warship';

  @override
  String get naval_units_compositionRoleMerchant => 'Merchant';

  @override
  String naval_units_compositionCount(int count) {
    return '\u00d7$count';
  }

  @override
  String naval_units_compositionSummary(
    int total,
    int warships,
    int merchants,
  ) {
    return 'Total ships: $total \u00b7 Warships: $warships \u00b7 Merchants: $merchants';
  }

  @override
  String naval_units_cargoCapacityHolds(int capacity) {
    return 'Cargo capacity: $capacity holds';
  }

  @override
  String get diplomacy_setSubsidy => 'Set subsidy';

  @override
  String get diplomacy_grantAid => 'Grant aid';

  @override
  String diplomacy_treasuryStep(int treasury, int step) {
    return 'Treasury: £$treasury. Step: £$step.';
  }

  @override
  String diplomacy_subsidyStep(int step) {
    return 'Subsidy step: $step% (5–20%).';
  }

  @override
  String diplomacy_currencyAmount(int amount) {
    return '£$amount';
  }

  @override
  String diplomacy_treasuryBelowMinimum(int step) {
    return 'Treasury is below the minimum valid amount (£$step).';
  }

  @override
  String get trainCivilians_title => 'Train Civilians';

  @override
  String get trainMilitary_title => 'Train Military';

  @override
  String get trainMilitary_categoryLightInfantry => 'Light infantry';

  @override
  String get trainMilitary_categoryRegularInfantry => 'Regular infantry';

  @override
  String get trainMilitary_categoryHeavyInfantry => 'Heavy infantry';

  @override
  String get trainMilitary_categoryBowmen => 'Bowmen';

  @override
  String get trainMilitary_categoryLightCavalry => 'Light cavalry';

  @override
  String get trainMilitary_categorySpearCavalry => 'Spear cavalry';

  @override
  String get trainMilitary_categoryHeavyCavalry => 'Heavy cavalry';

  @override
  String get trainMilitary_categoryLightArtillery => 'Light artillery';

  @override
  String get trainMilitary_categoryHeavyArtillery => 'Heavy artillery';

  @override
  String get trainMilitary_combatGistLightInfantry => 'Melee skirmishers';

  @override
  String get trainMilitary_combatGistRegularInfantry => 'Melee line';

  @override
  String get trainMilitary_combatGistHeavyInfantry => 'Ranged firepower';

  @override
  String get trainMilitary_combatGistBowmen => 'Ranged volleys';

  @override
  String get trainMilitary_combatGistLightCavalry => 'Fast harassers';

  @override
  String get trainMilitary_combatGistSpearCavalry => 'Shock cavalry';

  @override
  String get trainMilitary_combatGistHeavyCavalry => 'Armored charge';

  @override
  String get trainMilitary_combatGistLightArtillery => 'Field guns';

  @override
  String get trainMilitary_combatGistHeavyArtillery => 'Siege guns';

  @override
  String trainMilitary_foodUpkeepPerTurn(int count) {
    return '$count food / turn';
  }

  @override
  String get trainNaval_title => 'Train Naval';

  @override
  String trainNaval_merchantCargoHolds(int count) {
    return '+$count cargo holds';
  }

  @override
  String get trainNaval_warshipRoleFastInterceptor => 'Fast interceptor';

  @override
  String get trainNaval_warshipRoleBattleShip => 'Battle ship';

  @override
  String trainNaval_roleCapabilityGist(String role, String capability) {
    return '$role · $capability';
  }

  @override
  String get trainUnits_noCapital => 'No capital set — cannot train units';

  @override
  String trainUnits_treasury(String value) {
    return 'Treasury: $value';
  }

  @override
  String trainUnits_paper(int value) {
    return 'Paper: $value';
  }

  @override
  String get trainUnits_treasuryLabel => 'Treasury:';

  @override
  String get trainUnits_paperLabel => 'Paper:';

  @override
  String trainUnits_peasants(int value) {
    return 'Peasants: $value';
  }

  @override
  String trainUnits_peasantsValue(String value) {
    return 'Peasants: $value';
  }

  @override
  String get trainDialog_costTreasuryTooltip => 'Treasury';

  @override
  String get trainDialog_costPeasantsTooltip => 'Peasants';

  @override
  String trainDialog_costCommodityTooltip(String name, String category) {
    return '$name ($category)';
  }

  @override
  String get commodityCategory_food => 'food';

  @override
  String get commodityCategory_rawMaterial => 'raw material';

  @override
  String get commodityCategory_manufactured => 'manufactured';

  @override
  String get commodityCategory_luxury => 'luxury';

  @override
  String get commodityCategory_riches => 'riches';

  @override
  String get commodityCategory_advanced => 'advanced';

  @override
  String get civilian_units_title => 'Civilian Units';

  @override
  String get civilian_units_title_tile => 'Civilian Units (Tile)';

  @override
  String get civilian_units_tile => 'Tile';

  @override
  String get civilian_units_empty => 'No civilian units';

  @override
  String civilian_units_status(String status) {
    return 'Status: $status';
  }

  @override
  String civilian_units_location(String location) {
    return 'Location: $location';
  }

  @override
  String civilian_units_assignedTo(String target) {
    return 'Assigned to: $target';
  }

  @override
  String civilian_units_turns(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count turns',
      one: '$count turn',
    );
    return '$_temp0';
  }

  @override
  String civilian_units_turnProgress(String remaining, String total) {
    return '$remaining/$total turns';
  }

  @override
  String get civilian_units_assign => 'Assign';

  @override
  String get civilian_units_relocate => 'Relocate';

  @override
  String civilian_units_spyStatus_holdingIntel(String province) {
    return 'Holding intel: $province';
  }

  @override
  String get civilian_units_spyStatus_counterEspionage => 'Counter-espionage';

  @override
  String get civilian_units_spyStatus_reserve => 'Reserve';

  @override
  String civilian_units_pendingRelocate(String location) {
    return 'Relocating to: $location';
  }
}
