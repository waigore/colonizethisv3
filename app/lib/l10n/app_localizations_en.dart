// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'package:colonizethis_logic/colonizethis_logic.dart'
    show kWorkTargetExplore, kWorkTargetProspect;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get app_title => 'Colonize This';

  @override
  String get menu_view => 'View';

  @override
  String get menu_debugLog => 'Debug log';

  @override
  String get menu_openMaximizedOnStartup => 'Open maximized on startup';

  @override
  String get mainMenu_title => 'ColonizeThis V3';

  @override
  String get mainMenu_subtitleAfterVictory =>
      'Congratulations, you won your last game.';

  @override
  String get mainMenu_newGame => 'New Game';

  @override
  String get mainMenu_resumeGame => 'Resume game';

  @override
  String get mainMenu_loadGame => 'Load Game';

  @override
  String get mainMenu_settings => 'Settings';

  @override
  String get mainMenu_quit => 'Quit';

  @override
  String get mainMenu_noSavesTooltip =>
      'No saved games. Start a new game first.';

  @override
  String get game_pauseMenu_debugLog => 'Debug log';

  @override
  String get game_pauseMenu_resume => 'Resume';

  @override
  String get game_pauseMenu_tooltip => 'Pause menu';

  @override
  String get game_screenTitle => 'Game';

  @override
  String get game_exitConfirm_title => 'Exit game?';

  @override
  String get game_exitConfirm_body =>
      'Your current progress will be lost if not saved.';

  @override
  String get game_exitConfirm_exit => 'Exit';

  @override
  String game_nextTurnButton(int turn, int year) {
    return 'Next turn ($turn / $year)';
  }

  @override
  String get game_nextTurnConfirm_title => 'End turn?';

  @override
  String game_nextTurnConfirm_body(int turn) {
    return 'Turn $turn will end. Continue?';
  }

  @override
  String get common_no => 'No';

  @override
  String get common_yes => 'Yes';

  @override
  String get common_on => 'On';

  @override
  String get common_off => 'Off';

  @override
  String get common_confirm => 'Confirm';

  @override
  String get common_combine => 'Combine';

  @override
  String get common_train => 'Train';

  @override
  String get common_move => 'Move';

  @override
  String get common_split => 'Split';

  @override
  String get common_locate => 'Locate';

  @override
  String get common_reset => 'Reset';

  @override
  String get map_displayOptions_title => 'Map display options';

  @override
  String get map_displayOptions_showProvinceOverlay => 'Show province overlay';

  @override
  String get map_displayOptions_showProvinceOwnership =>
      'Show province ownership';

  @override
  String get map_displayOptions_showProvinceNames => 'Show province names';

  @override
  String get common_close => 'Close';

  @override
  String get gameMap_menuTooltip => 'Menu';

  @override
  String get region_oldWorld => 'Old World';

  @override
  String get region_newWorld => 'New World';

  @override
  String get debugLog_title => 'Debug log';

  @override
  String get debugLog_filter_package => 'Package:';

  @override
  String get debugLog_filter_level => 'Level:';

  @override
  String get shell_leaderDialog_intro =>
      'Assign each player slot a Great Power and leader. Default map colours appear beside each nation in the nation picker.';

  @override
  String get shell_leaderDialog_selectLeaderHint => 'Select leader';

  @override
  String get common_cancel => 'Cancel';

  @override
  String get map_selectionMode_prompt => 'Select a tile, or click cancel';

  @override
  String get map_selectionMode_cancel => 'cancel';

  @override
  String get common_start => 'Start';

  @override
  String get shell_leaderDialog_title => 'New game — Setup';

  @override
  String get shell_newGame_selectNation => 'Select nation';

  @override
  String shell_newGame_playerYou(int slotNumber) {
    return 'Player $slotNumber (You)';
  }

  @override
  String shell_newGame_playerAi(int slotNumber) {
    return 'Player $slotNumber (AI)';
  }

  @override
  String get shell_leaderDialog_seedLabel => 'Game / world seed';

  @override
  String get shell_leaderDialog_seedHelper =>
      'Use 0 for a random world (a new time-based seed each time setup runs). Any other number reproduces the same world for the same settings.';

  @override
  String get shell_newGameProgress_title => 'Creating game';

  @override
  String get shell_newGameProgress_stepOldWorld => 'Generating Old World map…';

  @override
  String get shell_newGameProgress_stepNewWorld => 'Generating New World map…';

  @override
  String get shell_newGameProgress_stepWarp =>
      'Linking Old World and New World…';

  @override
  String get shell_newGameProgress_stepBuildWorld => 'Building world…';

  @override
  String get shell_newGameProgress_stepSave => 'Saving game…';

  @override
  String get shell_newGameError_title => 'Could not create game';

  @override
  String get shell_newGameError_retry => 'Retry';

  @override
  String get game_callToArms_title => 'Call to arms';

  @override
  String get game_callToArms_intro =>
      'An allied power is at war. Join their war or refuse (alliance ends, relations worsen).';

  @override
  String game_callToArms_prompt(String defender, String aggressor) {
    return '$defender is attacked by $aggressor.';
  }

  @override
  String get game_callToArms_join => 'Join';

  @override
  String get game_callToArms_refuse => 'Refuse';

  @override
  String get game_callToArms_submit => 'Submit';

  @override
  String game_intervention_loadError(String error) {
    return 'Could not load intervention dialogue: $error';
  }

  @override
  String get game_intervention_degradedHint =>
      'Submit all responses as \"Do naught\" to continue.';

  @override
  String get game_intervention_continue => 'Continue';

  @override
  String game_intervention_resolutionProgress(int current, int total) {
    return 'Thy resolution ($current of $total)';
  }

  @override
  String game_intervention_situation(
    String aggressor,
    String defender,
    String intervening,
  ) {
    return '$aggressor against $defender. Thou speakest for $intervening.';
  }

  @override
  String get game_intervention_intervene => 'Intervene with force';

  @override
  String get game_intervention_doNothing => 'Do naught';

  @override
  String get game_intervention_protest => 'Diplomatic protest';

  @override
  String turnNews_title(int turn) {
    return 'Turn $turn';
  }

  @override
  String get turnNews_empty => 'No major events last turn.';

  @override
  String get turnNews_close => 'Close';

  @override
  String turnNews_capture(String province, String prevOwner, String newOwner) {
    return '$province: ownership changed from $prevOwner to $newOwner.';
  }

  @override
  String turnNews_war(String a, String b) {
    return '$a and $b are now at war.';
  }

  @override
  String turnNews_peace(String a, String b) {
    return '$a and $b are now at peace.';
  }

  @override
  String turnNews_overture(String offerer, String target, String stage) {
    return '$offerer advanced relations with $target ($stage).';
  }

  @override
  String turnNews_provinceDiscovered(String province) {
    return 'New reports chart $province.';
  }

  @override
  String turnNews_seaDiscovered(String zone) {
    return 'A fleet has entered $zone.';
  }

  @override
  String get turnNews_stage_tradeConsulate => 'trade consulate';

  @override
  String get turnNews_stage_embassy => 'embassy';

  @override
  String get turnNews_stage_nap => 'non-aggression pact';

  @override
  String get turnNews_stage_joinEmpire => 'join empire';

  @override
  String get province_unitStatus_idle => 'idle';

  @override
  String get province_unitStatus_working => 'working';

  @override
  String get province_workOrder_explore => kWorkTargetExplore;

  @override
  String get province_workOrder_prospect => kWorkTargetProspect;

  @override
  String get province_workOrder_build_improvement => 'build improvement';

  @override
  String get province_workOrder_upgrade_town => 'upgrade town';

  @override
  String get province_workOrder_build_road => 'build road';

  @override
  String get province_workOrder_build_port => 'build port';

  @override
  String get province_workOrder_build_fort => 'build fort';

  @override
  String get province_workOrder_build_rail => 'build rail';

  @override
  String get province_workOrder_steal_tech => 'steal technology';

  @override
  String get province_workOrder_counter_spy => 'counter-espionage';

  @override
  String get province_workOrder_purchase_land => 'purchase land';

  @override
  String province_pending_armyMove(String destination) {
    return 'Ordered: move army to $destination';
  }

  @override
  String province_pending_regimentMove(String destination) {
    return 'Ordered: move regiment to $destination';
  }

  @override
  String province_pending_fleetMoveSea(String zone) {
    return 'Ordered: move fleet to sea $zone';
  }

  @override
  String province_pending_fleetMovePort(String province) {
    return 'Ordered: dock fleet at $province';
  }

  @override
  String province_pending_fleetMission(String mission) {
    return 'Ordered: fleet mission — $mission';
  }

  @override
  String get province_fleetMission_none => 'none';

  @override
  String get province_fleetMission_patrol => 'patrol';

  @override
  String get province_fleetMission_blockade => 'blockade';

  @override
  String get province_fleetMission_beachhead => 'beachhead';

  @override
  String get province_fleetMission_defend => 'defend';

  @override
  String get province_economic_improvableSuffix => '(improvable)';

  @override
  String province_economic_withImprovement(String improvement) {
    return 'with $improvement';
  }

  @override
  String get province_regiment_peasant_levies => 'Peasant levies';

  @override
  String get province_regiment_pikemen => 'Pikemen';

  @override
  String get province_regiment_arquebusiers => 'Arquebusiers';

  @override
  String get province_regiment_bowmen => 'Bowmen';

  @override
  String get province_regiment_squires => 'Squires';

  @override
  String get province_regiment_knights => 'Knights';

  @override
  String get province_regiment_culverin => 'Culverin';

  @override
  String get province_regiment_calivermen => 'Calivermen';

  @override
  String get province_regiment_halberdiers => 'Halberdiers';

  @override
  String get province_regiment_musketeers => 'Musketeers';

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
  String get moveArmy_groupYourProvinces => 'Your provinces';

  @override
  String get moveArmy_groupUnowned => 'Unowned';

  @override
  String get moveArmy_invadeProvinceTitle => 'Invade province?';

  @override
  String moveArmy_invadeProvinceBody(String ownerLabel) {
    return 'Moving into $ownerLabel territory will declare war this turn and then move the army. Continue?';
  }

  @override
  String get moveArmy_declareWarAndMove => 'Declare war and move';

  @override
  String moveArmy_title(String armyId) {
    return 'Move army $armyId';
  }

  @override
  String get moveArmy_noValidDestinations => 'No valid destinations.';

  @override
  String get moveArmy_destinationProvince => 'Destination province';

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
  String get military_units_deselectAllArmies => 'Deselect all armies';

  @override
  String get military_units_selectAllArmies => 'Select all armies';

  @override
  String get military_units_empty => 'No military units';

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
  String get diplomacy_setSubsidy => 'Set subsidy';

  @override
  String get diplomacy_grantAid => 'Grant aid';

  @override
  String diplomacy_treasuryStep(int treasury, int step) {
    return 'Treasury: £$treasury. Step: £$step.';
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
  String trainUnits_peasants(int value) {
    return 'Peasants: $value';
  }

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
  String get production_breakdown_title => 'Commodity breakdown';

  @override
  String get production_breakdown_commodity => 'Commodity';

  @override
  String get production_breakdown_total => 'Total';

  @override
  String get production_breakdown_phase_pendingBuildCosts =>
      'Pending build costs';

  @override
  String get production_breakdown_phase_extraction => 'Extraction';

  @override
  String get production_breakdown_phase_richesToTreasury =>
      'Riches to treasury';

  @override
  String get production_breakdown_phase_consumption => 'Consumption';

  @override
  String get production_breakdown_phase_production => 'Production';

  @override
  String get production_breakdown => 'Breakdown';

  @override
  String get production_available => 'Available';

  @override
  String get production_food => 'Food';

  @override
  String get production_rawMaterials => 'Raw Materials';

  @override
  String get production_manufactured => 'Manufactured';

  @override
  String get production_workers => 'Workers';

  @override
  String get production_workers_peasants => 'Peasants';

  @override
  String get production_workers_apprentices => 'Apprentices';

  @override
  String get production_workers_journeymen => 'Journeymen';

  @override
  String get production_workers_masters => 'Masters';

  @override
  String get production_allocation => 'Allocation';

  @override
  String get production_allocationDecrementRecipe =>
      'Decrease desired output for this recipe';

  @override
  String get production_allocationIncrementRecipe =>
      'Increase desired output for this recipe';

  @override
  String get production_allocationMaximizeRecipe =>
      'Set this recipe to maximum desired output';

  @override
  String get production_allocationClearRecipe =>
      'Clear desired output for this recipe';

  @override
  String get splitArmy_title => 'Split Army';

  @override
  String technologyPanel_title(String playerName) {
    return 'Technology - $playerName';
  }

  @override
  String technologyPanel_researchSlotsCount(int slots) {
    return 'Research slots: $slots';
  }

  @override
  String get technologyPanel_researchSlots => 'Research slots';

  @override
  String get technologyPanel_empty => 'Empty';

  @override
  String technologyPanel_slot(int slot) {
    return 'Slot $slot';
  }

  @override
  String technologyPanel_slotSubtitle(
    String name,
    int progress,
    String costLabel,
  ) {
    return '$name - $progress/$costLabel RP';
  }

  @override
  String get technologyPanel_noTechAssigned => 'No tech assigned';

  @override
  String get technologyPanel_chooseTech => 'Choose tech';

  @override
  String technologyPanel_researched(int count) {
    return 'Researched ($count):';
  }

  @override
  String get technologyPanel_noneYet => 'None yet';

  @override
  String get technologyPanel_inProgress => 'In progress:';

  @override
  String technologyPanel_progressLine(String name, int points) {
    return '$name: $points RP';
  }

  @override
  String get technologyPanel_noTechsAvailable =>
      'No techs available to research';

  @override
  String technologyPanel_pickSubtitle(String era, String category, int cost) {
    return 'Era $era - $category - $cost RP';
  }

  @override
  String get technologyPanel_slotCancelled => 'Research slot cancelled';

  @override
  String get techTree_noTechsInCatalog => 'No techs in catalog';

  @override
  String techTree_eraCategory(String era, String category) {
    return 'Era $era - $category';
  }

  @override
  String techTree_researchPoints(int points) {
    return '$points RP';
  }

  @override
  String get techTree_prerequisites => 'Prerequisites';

  @override
  String get techTree_effects => 'Effects';

  @override
  String get techTree_legendTitle => 'Technology tree legend';

  @override
  String get techTree_stateResearched => 'Researched';

  @override
  String get techTree_stateInProgress => 'In progress';

  @override
  String get techTree_stateAvailable => 'Available';

  @override
  String get techTree_stateLocked => 'Locked';

  @override
  String get mapDebug_fullVisibility => 'Full visibility';

  @override
  String get mapDebug_playerConstrained => 'Player-constrained';

  @override
  String get mapDebug_hideProvinceNames => 'No province names';

  @override
  String get mapDebug_noNames => 'No names';

  @override
  String get widgetbook_primaryAction => 'Primary action';

  @override
  String get widgetbook_disabled => 'Disabled';

  @override
  String get widgetbook_fixedWidth => 'Fixed width';

  @override
  String get widgetbook_noPlayers => 'No players';

  @override
  String get widgetbook_techTreeTitle => 'Tech Tree';

  @override
  String get widgetbook_openBreakdownDialog => 'Open breakdown dialog';

  @override
  String get widgetbook_gameShell => 'Game shell';

  @override
  String techTree_bulletItem(String text) {
    return '- $text';
  }

  @override
  String get provinceOverlay_unknown => '???';

  @override
  String get provinceOverlay_clickTileForDetails =>
      'Click a tile to see details.';

  @override
  String get provinceOverlay_tileCoordinatesUnknown => 'Coordinates: ???';

  @override
  String get provinceOverlay_tileTerrainUnknown => 'Terrain: ???';

  @override
  String get provinceOverlay_tileResourceUnknown => 'Resource: ???';

  @override
  String get provinceOverlay_tileProspectedUnknown => 'Prospected: ???';

  @override
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
  String get provinceOverlay_tileProspectWithExplorerTooltip =>
      'Prospect with explorer';

  @override
  String get provinceOverlay_tileExploreWithExplorerTooltip =>
      'Explore with explorer';

  @override
  String get provinceOverlay_tileBuildImprovementTooltip => 'Build improvement';

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
  String get naval_transferToHome_dialogTitle => 'Transfer Ships to Home Fleet';

  @override
  String naval_transferToHome_sourceTitle(String id) {
    return 'Fleet $id';
  }

  @override
  String get naval_transferToHome_confirm => 'Confirm Transfer';

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

  @override
  String get techEffectSummary_heavy_artillery_0 =>
      'Improves: Royal Artillery regiment upgrade path';

  @override
  String get techEffectSummary_heavy_artillery_1 =>
      'Prerequisite for: High Grade Steel and Emplaced Siege Guns';

  @override
  String get techEffectSummary_heavy_emplaced_artillery_0 =>
      'Improves: defender emplaced fort batteries to Heavy quality (Royal → Heavy line)';

  @override
  String get techEffectSummary_heavy_emplaced_artillery_1 =>
      'Prerequisite for: Emplaced Siege Guns';

  @override
  String get techEffectSummary_high_grade_steel_0 =>
      'Improves: Heavy Artillery regiment upgrade path';

  @override
  String get techEffectSummary_horse_artillery_0 =>
      'Prerequisite for: Light Artillery Tactics';

  @override
  String get techEffectSummary_hussars_0 =>
      'Improves: Cossacks regiment upgrade path';

  @override
  String get techEffectSummary_hussars_1 => 'Prerequisite for: Scouting';

  @override
  String get techEffectSummary_improved_cavalry_tactics_0 =>
      'Prerequisite for: Hussars and Improved Cavalry Weapons';

  @override
  String get techEffectSummary_improved_cavalry_weapons_0 =>
      'Improves: Harquebusiers regiment upgrade path';

  @override
  String get techEffectSummary_improved_cavalry_weapons_1 =>
      'Prerequisite for: Repeating Cavalry Carbine';

  @override
  String get techEffectSummary_improved_food_preservation_0 =>
      'Improves: Spices extraction cap to 4';

  @override
  String get techEffectSummary_improved_food_preservation_1 =>
      'Prerequisite-only: catalog leaf; extraction-cap increase is the active benefit';

  @override
  String get techEffectSummary_improved_infantry_tactics_0 =>
      'Improves: General cap floor to at least 3 (or National Bureaucracy)';

  @override
  String get techEffectSummary_improved_infantry_tactics_1 =>
      'Unlocks: Early Rifles (with Crucible Process)';

  @override
  String get techEffectSummary_improved_iron_weapons_0 =>
      'Unlocks: Bayonet (with Crucible Process)';

  @override
  String get techEffectSummary_improved_sail_design_0 =>
      'Unlocks: Advanced Hull Design path (University + Privateering)';

  @override
  String get techEffectSummary_improved_sea_routes_0 =>
      'Improves: Spices extraction cap to 2';

  @override
  String get techEffectSummary_improved_sea_routes_1 =>
      'Unlocks: Large Spice Plantations';

  @override
  String get techEffectSummary_improved_trapping_techniques_0 =>
      'Improves: Furs extraction cap to 2';

  @override
  String get techEffectSummary_improved_trapping_techniques_1 =>
      'Unlocks: Riverboats';

  @override
  String get techEffectSummary_industrial_funding_of_research_0 =>
      'Unlocks: Needle Guns, Repeating Cavalry Carbine, High Grade Steel, Advanced Iron Working (as prerequisite)';

  @override
  String get techEffectSummary_industrial_funding_of_research_1 =>
      'Improves: +20% effective RP (floor) for military and naval category research allocations';

  @override
  String get techEffectSummary_industrial_iron_mining_0 =>
      'Improves: Iron extraction cap to 4';

  @override
  String get techEffectSummary_industrial_iron_mining_1 =>
      'Prerequisite-only: catalog leaf; extraction-cap increase is the active benefit';

  @override
  String get techEffectSummary_industrial_machinery_0 =>
      'Unlocks: Explosives, Improved Cavalry Weapons, Industrial Funding of Research (as prerequisite)';

  @override
  String get techEffectSummary_industrial_machinery_1 =>
      'Improves: ×0.75 multiplicative on per-land-battle attack treasury cost at combat resolution';

  @override
  String get techEffectSummary_iron_mining_0 =>
      'Improves: Iron extraction cap to 2';

  @override
  String get techEffectSummary_iron_mining_1 => 'Unlocks: Steam in Mining';

  @override
  String get techEffectSummary_land_enclosure_0 =>
      'Improves: Grain extraction cap to 2';

  @override
  String get techEffectSummary_land_enclosure_1 =>
      'Unlocks: Seed Drill, Money Lending, and Organised Regiments';

  @override
  String get techEffectSummary_large_coal_mines_0 =>
      'Improves: Coal extraction cap to 3';

  @override
  String get techEffectSummary_large_coal_mines_1 =>
      'Unlocks: Safety Lamp (with Dynamite)';

  @override
  String get techEffectSummary_large_coal_mines_2 =>
      'Unlocks: Efficient Extraction of Copper & Tin';

  @override
  String get techEffectSummary_large_copper_and_tin_mines_0 =>
      'Improves: Copper/Tin extraction cap to 3';

  @override
  String get techEffectSummary_large_copper_and_tin_mines_1 =>
      'Unlocks: Efficient Extraction of Copper & Tin (with Large Coal Mines)';

  @override
  String get techEffectSummary_large_copper_and_tin_mines_2 =>
      'Prerequisite for: Ship of the Line';

  @override
  String get techEffectSummary_large_cotton_plantations_0 =>
      'Improves: Cotton extraction cap to 3';

  @override
  String get techEffectSummary_large_cotton_plantations_1 =>
      'Unlocks: Cotton Gin';

  @override
  String get techEffectSummary_large_hulls_0 =>
      'Unlocks: Ship of the Line (with Large Copper and Tin Mines)';

  @override
  String get techEffectSummary_large_precious_stone_mines_0 =>
      'Improves: Gems/diamonds extraction cap to 3';

  @override
  String get techEffectSummary_large_precious_stone_mines_1 =>
      'Unlocks: Geological Prospecting (with Dynamite); Modern Military Funding (with Banking and Modern Forts)';

  @override
  String get techEffectSummary_large_spice_plantations_0 =>
      'Improves: Spices extraction cap to 3';

  @override
  String get techEffectSummary_large_spice_plantations_1 =>
      'Unlocks: Improved Food Preservation';

  @override
  String get techEffectSummary_large_sugar_plantations_0 =>
      'Improves: Sugar cane extraction cap to 3';

  @override
  String get techEffectSummary_large_sugar_plantations_1 =>
      'Unlocks: Sugar Industry';

  @override
  String get techEffectSummary_large_tobacco_plantations_0 =>
      'Improves: Tobacco extraction cap to 3';

  @override
  String get techEffectSummary_large_tobacco_plantations_1 =>
      'Unlocks: Tobacco Industry';

  @override
  String get techEffectSummary_later_steam_engine_0 =>
      'Enables: Railroads on hills and swamps';

  @override
  String get techEffectSummary_later_steam_engine_1 =>
      'Unlocks: Dynamite and Excessive Fur Harvesting';

  @override
  String get techEffectSummary_light_artillery_tactics_0 =>
      'Improves: Horse Artillery regiment upgrade path';

  @override
  String get techEffectSummary_light_artillery_tactics_1 =>
      'Prerequisite for: Field Artillery Tactics';

  @override
  String get techEffectSummary_long_range_rifles_0 =>
      'Improves: Skirmishers regiment upgrade path';

  @override
  String get techEffectSummary_master_artisans_0 =>
      'Enables: Master tier (8x labour; consumes fur hats)';

  @override
  String get techEffectSummary_master_artisans_1 =>
      'Unlocks: Banking, Nationalism, Scientific Cattle Breeding';

  @override
  String get techEffectSummary_merchant_companies_0 =>
      'Enables: Merchant civilian unit construction';

  @override
  String get techEffectSummary_merchant_companies_1 =>
      'Enables: purchase_land in Minor Nations/Tribes (requires embassy, not at war)';

  @override
  String get techEffectSummary_merchant_companies_2 => 'Unlocks: Trade Fairs';

  @override
  String get techEffectSummary_merchant_steamships_0 =>
      'Enables: Steam-powered merchant hull for seagoing trade';

  @override
  String get techEffectSummary_mine_engineering_0 =>
      'Enables: Builder upgrades to Fort Level 2';

  @override
  String get techEffectSummary_mine_engineering_1 =>
      'Unlocks: Iron Mining, Copper and Tin Mining, and Coal Mining';

  @override
  String get techEffectSummary_modern_forts_0 =>
      'Enables: Builder fort upgrades to level 3 (Modern: 3 emplaced guns, strongest walls)';

  @override
  String get techEffectSummary_modern_forts_1 =>
      'Unlocks: Heavy Artillery and Modern Military Funding (as prerequisite)';

  @override
  String get techEffectSummary_modern_military_funding_0 =>
      'Unlocks: Field Artillery Tactics, High Grade Steel, Elite Military Training stack';

  @override
  String get techEffectSummary_modern_military_funding_1 =>
      'Improves: ×0.85 multiplicative on per-land-battle attack treasury cost (stacks with Industrial Machinery)';

  @override
  String get techEffectSummary_moldboard_plow_0 =>
      'Improves: Grain extraction cap to 4';

  @override
  String get techEffectSummary_moldboard_plow_1 =>
      'Terminal tech: nothing else in the catalog requires this';

  @override
  String get techEffectSummary_money_lending_0 =>
      'Enables: Research-phase treasury floor to -500';

  @override
  String get techEffectSummary_money_lending_1 =>
      'Prerequisite for: University, National Bureaucracy';

  @override
  String get techEffectSummary_money_lending_2 =>
      'Deferred: General borrowing/interest not simulated yet';

  @override
  String get techEffectSummary_national_bureaucracy_0 =>
      'Enables: Builder upgrade_town work order';

  @override
  String get techEffectSummary_national_bureaucracy_1 =>
      'Improves: General cap floor to at least 3';

  @override
  String get techEffectSummary_national_bureaucracy_2 => 'Unlocks: Propaganda';

  @override
  String get techEffectSummary_nationalism_0 =>
      'Improves: Battle deployment base limit to 12 regiments (vs 10)';

  @override
  String get techEffectSummary_nationalism_1 =>
      'Improves: General cap floor to at least 4';

  @override
  String get techEffectSummary_nationalism_2 =>
      'Unlocks: Empire Building (with Banking)';

  @override
  String get techEffectSummary_navigation_0 =>
      'Unlocks: Large Hulls and Privateering Companies';

  @override
  String get techEffectSummary_needle_guns_0 =>
      'Improves: Regulars regiment upgrade path';

  @override
  String get techEffectSummary_needle_guns_1 =>
      'Prerequisite for: Elite Military Training';

  @override
  String get techEffectSummary_organised_regiments_0 =>
      'Improves: General cap floor to at least 2';

  @override
  String get techEffectSummary_organised_regiments_1 =>
      'Unlocks: Improved Iron/Infantry/Weapon Craftsmanship doctrine paths';

  @override
  String get techEffectSummary_paddlewheels_0 =>
      'Unlocks: Merchant Steamships (with Riverboats)';

  @override
  String get techEffectSummary_precious_metals_mining_0 =>
      'Improves: Gold/silver extraction cap to 2';

  @override
  String get techEffectSummary_precious_metals_mining_1 =>
      'Unlocks: Extraction of Precious Metals';

  @override
  String get techEffectSummary_precious_stone_mining_0 =>
      'Improves: Gems/diamonds extraction cap to 2';

  @override
  String get techEffectSummary_precious_stone_mining_1 =>
      'Unlocks: Large Precious Stone Mines (with Modern Forts)';

  @override
  String get techEffectSummary_printing_press_0 =>
      'Unlocks: Trained Journeymen, University, and military doctrine paths';

  @override
  String get techEffectSummary_printing_press_1 =>
      'Prerequisite-only: unlock paths only; no direct economy modifier';

  @override
  String get techEffectSummary_privateering_companies_0 =>
      'Improves: Patrol/Blockade interception and trade-raid effectiveness';

  @override
  String get techEffectSummary_privateering_companies_1 =>
      'Unlocks: Advanced Hull Design (frigate doctrine prerequisite)';

  @override
  String get techEffectSummary_propaganda_0 =>
      'Improves: Diplomatic protest war penalty against aggressor (-10 -> -5)';

  @override
  String get techEffectSummary_propaganda_1 => 'Unlocks: Nationalism';

  @override
  String get techEffectSummary_recruit_steppe_horsemen_0 =>
      'Improves: Squires regiment upgrade path';

  @override
  String get techEffectSummary_recruit_steppe_horsemen_1 =>
      'Prerequisite for: Hussars';

  @override
  String get techEffectSummary_repeating_cavalry_carbine_0 =>
      'Improves: Cuirassiers regiment upgrade path';

  @override
  String get techEffectSummary_riverboats_0 =>
      'Improves: Furs extraction cap to 3';

  @override
  String get techEffectSummary_riverboats_1 =>
      'Unlocks: Excessive Fur Harvesting and Merchant Steamships research paths';

  @override
  String get techEffectSummary_road_construction_0 =>
      'Enables: Engineer road upgrades to transport level 2';

  @override
  String get techEffectSummary_road_construction_1 =>
      'Unlocks: Early Steam Engine';

  @override
  String get techEffectSummary_safety_lamp_0 =>
      'Improves: Coal extraction cap to 4';

  @override
  String get techEffectSummary_safety_lamp_1 =>
      'Terminal tech: nothing else in the catalog requires this';

  @override
  String get techEffectSummary_saw_mill_0 =>
      'Improves: Timber extraction cap to 2 (forested provinces)';

  @override
  String get techEffectSummary_saw_mill_1 => 'Unlocks: Wind Saw Mill';

  @override
  String get techEffectSummary_scientific_cattle_breeding_0 =>
      'Improves: Meat extraction cap to 4';

  @override
  String get techEffectSummary_scientific_cattle_breeding_1 =>
      'Terminal tech: nothing else in the catalog requires this';

  @override
  String get techEffectSummary_scientific_sheep_breeding_0 =>
      'Improves: Wool extraction cap to 3';

  @override
  String get techEffectSummary_scientific_sheep_breeding_1 =>
      'Terminal tech: nothing else in the catalog requires this';

  @override
  String get techEffectSummary_scouting_0 =>
      'Improves: Hussars regiment upgrade path';

  @override
  String get techEffectSummary_seed_drill_0 =>
      'Improves: Grain extraction cap to 3';

  @override
  String get techEffectSummary_seed_drill_1 => 'Unlocks: Moldboard Plow';

  @override
  String get techEffectSummary_sheep_ranching_0 =>
      'Improves: Wool extraction cap to 2';

  @override
  String get techEffectSummary_sheep_ranching_1 =>
      'Unlocks: Scientific Sheep Breeding';

  @override
  String get techEffectSummary_ship_of_the_line_0 =>
      'Improves: Battle-line capital ship for decisive fleet engagements';

  @override
  String get techEffectSummary_ship_of_the_line_1 =>
      'Unlocks: Advanced Iron Working (with Industrial Funding + Paddlewheels)';

  @override
  String get techEffectSummary_siege_engineering_0 =>
      'Improves: Culverin regiment upgrade path';

  @override
  String get techEffectSummary_siege_engineering_1 =>
      'Prerequisite for: Modern Forts and Heavy Emplaced Artillery';

  @override
  String get techEffectSummary_square_set_timbering_0 =>
      'Improves: Coal extraction cap to 2';

  @override
  String get techEffectSummary_square_set_timbering_1 =>
      'Unlocks: Large Coal Mines (requires Steam in Mining)';

  @override
  String get techEffectSummary_square_set_timbering_2 =>
      'Prerequisite for: Early Steam Engine and Crucible Process';

  @override
  String get techEffectSummary_steam_in_mining_0 =>
      'Improves: Iron extraction cap to 3';

  @override
  String get techEffectSummary_steam_in_mining_1 =>
      'Unlocks: Large Coal Mines (with Square-set Timbering)';

  @override
  String get techEffectSummary_steam_in_mining_2 =>
      'Prerequisite for: Industrial Iron Mining, Early Steam Engine, Crucible Process, Industrial Machinery';

  @override
  String get techEffectSummary_sugar_industry_0 =>
      'Improves: Sugar cane extraction cap to 4';

  @override
  String get techEffectSummary_sugar_industry_1 =>
      'Prerequisite-only: catalog leaf; extraction-cap increase is the active benefit';

  @override
  String get techEffectSummary_sugar_planting_0 =>
      'Improves: Sugar cane extraction cap to 2';

  @override
  String get techEffectSummary_sugar_planting_1 =>
      'Unlocks: Large Sugar Plantations';

  @override
  String get techEffectSummary_sugar_refining_0 =>
      'Enables: Refined sugar luxury for Apprentice-tier worker consumption';

  @override
  String get techEffectSummary_sugar_refining_1 =>
      'Unlocks: Apprentice Workers (with Land Enclosure); Trade Fairs (with Merchant Companies)';

  @override
  String get techEffectSummary_superior_hull_design_0 =>
      'Unlocks: Improved Sail Design and Navigation hull paths';

  @override
  String get techEffectSummary_tobacco_industry_0 =>
      'Improves: Tobacco extraction cap to 4';

  @override
  String get techEffectSummary_tobacco_industry_1 =>
      'Prerequisite-only: catalog leaf; extraction-cap increase is the active benefit';

  @override
  String get techEffectSummary_tobacco_planting_0 =>
      'Improves: Tobacco extraction cap to 2';

  @override
  String get techEffectSummary_tobacco_planting_1 =>
      'Unlocks: Large Tobacco Plantations';

  @override
  String get techEffectSummary_trade_fairs_0 =>
      'Enables: 6 commodity slots per embassy trade agreement (3 baseline without this tech)';

  @override
  String get techEffectSummary_trade_fairs_1 => 'Unlocks: Banking';

  @override
  String get techEffectSummary_trained_journeymen_0 =>
      'Enables: Journeyman tier (6x labour; consumes cigars)';

  @override
  String get techEffectSummary_trained_journeymen_1 =>
      'Unlocks: Cotton Gin and Recruit Steppe Horsemen';

  @override
  String get techEffectSummary_university_0 =>
      'Enables: Fourth active research slot (3 -> 4)';

  @override
  String get techEffectSummary_university_1 =>
      'Unlocks: Master Artisans, Propaganda, Scientific Cattle Breeding';

  @override
  String get techEffectSummary_weapon_craftsmanship_0 =>
      'Unlocks: Explosives and Grenadiers (with Industrial Machinery)';

  @override
  String get techEffectSummary_wind_saw_mill_0 =>
      'Improves: Timber extraction cap to 3';

  @override
  String get techEffectSummary_wind_saw_mill_1 => 'Unlocks: Circular Saw';

  @override
  String playerTurnFeed_eventsChip(int count) {
    return 'Events ($count)';
  }

  @override
  String get playerTurnFeed_eventsTitle => 'Events';

  @override
  String get debugConsole_title => 'Debug Console';

  @override
  String get debugConsole_hintSpawnCivilian => '/spawn_civilian explorer 1';
}
