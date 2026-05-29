part of 'app_localizations_en.dart';

mixin _AppLocalizationsEnStrings1 on AppLocalizations {


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
  String get mainMenu_eyebrow => 'A Game of Empire & Discovery';

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
  String get game_pauseMenu_title => 'Game Paused';

  @override
  String get game_pauseMenu_resume => 'Resume';

  @override
  String get game_pauseMenu_saveGame => 'Save Game';

  @override
  String get game_pauseMenu_loadGame => 'Load Game';

  @override
  String get game_pauseMenu_settings => 'Settings';

  @override
  String get game_pauseMenu_exitToMainMenu => 'Exit to Main Menu';

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
  String get game_turnResolutionProcessingTitle => 'Processing Turn';

  @override
  String get game_turnResolutionFailedMessage => 'Turn resolution failed.';

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
  String get shell_leaderDialog_infiniteModeLabel =>
      'Infinite mode (turns progress past 1800)';

  @override
  String get shell_leaderDialog_infiniteModeHelper =>
      'When enabled, the campaign continues past calendar year 1800 until a military victory.';

  @override
  String shell_leaderDialog_terrainVariationLabel(int percent) =>
      'Terrain variation ($percent%)';

  @override
  String get shell_leaderDialog_terrainVariationHelper =>
      'Higher values produce more mixed terrain (0 keeps legacy clumps).';

  @override
  String get gameParameters_title => 'Game Parameters';

  @override
  String get gameParameters_menuEntry => 'Game Parameters';

  @override
  String get gameParameters_infiniteModeHeading => 'Infinite mode';

  @override
  String get gameParameters_infiniteModeOn => 'On';

  @override
  String get gameParameters_infiniteModeOff => 'Off';

  @override
  String gameParameters_infiniteModeLine(String value) {
    return 'Infinite mode: $value';
  }

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

}
