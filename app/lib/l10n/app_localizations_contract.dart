import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart' as intl;

// ignore_for_file: type=lint

abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('en')];

  /// Window title / application title.
  ///
  /// In en, this message translates to:
  /// **'Colonize This'**
  String get app_title;

  /// Top-level platform menu label for View menu.
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get menu_view;

  /// Platform menu item label that navigates to the debug log viewer.
  ///
  /// In en, this message translates to:
  /// **'Debug log'**
  String get menu_debugLog;

  /// Main menu title text when not using the pixel-art logo.
  ///
  /// In en, this message translates to:
  /// **'ColonizeThis V3'**
  String get mainMenu_title;

  /// Subtitle shown on the main menu after the player has won their last game.
  ///
  /// In en, this message translates to:
  /// **'Congratulations, you won your last game.'**
  String get mainMenu_subtitleAfterVictory;

  /// Main menu button label to start a new game.
  ///
  /// In en, this message translates to:
  /// **'New Game'**
  String get mainMenu_newGame;

  /// Main menu button label to continue from the auto-save slot.
  ///
  /// In en, this message translates to:
  /// **'Resume game'**
  String get mainMenu_resumeGame;

  /// Main menu button label to load an existing game.
  ///
  /// In en, this message translates to:
  /// **'Load Game'**
  String get mainMenu_loadGame;

  /// Main menu button label to open settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get mainMenu_settings;

  /// Main menu button label to quit the app.
  ///
  /// In en, this message translates to:
  /// **'Quit'**
  String get mainMenu_quit;

  /// Tooltip explaining why Load Game is disabled when there are no saves.
  ///
  /// In en, this message translates to:
  /// **'No saved games. Start a new game first.'**
  String get mainMenu_noSavesTooltip;

  /// Pause menu option label to open the debug log screen.
  ///
  /// In en, this message translates to:
  /// **'Debug log'**
  String get game_pauseMenu_debugLog;

  /// Pause menu option label to resume the game.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get game_pauseMenu_resume;

  /// Tooltip for the pause menu button in the in-game UI.
  ///
  /// In en, this message translates to:
  /// **'Pause menu'**
  String get game_pauseMenu_tooltip;

  /// Title used for the main game screen shell.
  ///
  /// In en, this message translates to:
  /// **'Game'**
  String get game_screenTitle;

  /// Title of the dialog asking for confirmation before leaving the in-game shell.
  ///
  /// In en, this message translates to:
  /// **'Exit game?'**
  String get game_exitConfirm_title;

  /// Body text warning the player before exiting to main menu from in-game shell.
  ///
  /// In en, this message translates to:
  /// **'Your current progress will be lost if not saved.'**
  String get game_exitConfirm_body;

  /// Button label that confirms leaving the in-game shell and navigating to main menu.
  ///
  /// In en, this message translates to:
  /// **'Exit'**
  String get game_exitConfirm_exit;

  /// Label for the Next Turn button showing current turn and year.
  ///
  /// In en, this message translates to:
  /// **'Next turn ({turn} / {year})'**
  String game_nextTurnButton(int turn, int year);

  /// Title of the dialog asking the user to confirm ending the current turn.
  ///
  /// In en, this message translates to:
  /// **'End turn?'**
  String get game_nextTurnConfirm_title;

  /// Body text of the end-turn confirmation dialog.
  ///
  /// In en, this message translates to:
  /// **'Turn {turn} will end. Continue?'**
  String game_nextTurnConfirm_body(int turn);

  /// Generic 'No' button label.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get common_no;

  /// Generic 'Yes' button label.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get common_yes;

  /// Generic confirm button label.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get common_confirm;

  /// Generic combine action label.
  ///
  /// In en, this message translates to:
  /// **'Combine'**
  String get common_combine;

  /// Generic train action label.
  ///
  /// In en, this message translates to:
  /// **'Train'**
  String get common_train;

  /// Generic move action label.
  ///
  /// In en, this message translates to:
  /// **'Move'**
  String get common_move;

  /// Generic split action label.
  ///
  /// In en, this message translates to:
  /// **'Split'**
  String get common_split;

  /// Generic locate action label.
  ///
  /// In en, this message translates to:
  /// **'Locate'**
  String get common_locate;

  /// Generic reset action label.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get common_reset;

  /// Dialog title for map display options.
  ///
  /// In en, this message translates to:
  /// **'Map display options'**
  String get map_displayOptions_title;

  /// Toggle for province and sea-zone boundary strokes on the map (no ownership tint).
  ///
  /// In en, this message translates to:
  /// **'Show province overlay'**
  String get map_displayOptions_showProvinceOverlay;

  /// Toggle for Great Power land ownership colour tint on the map.
  ///
  /// In en, this message translates to:
  /// **'Show province ownership'**
  String get map_displayOptions_showProvinceOwnership;

  /// Toggle label for showing land province names on the map.
  ///
  /// In en, this message translates to:
  /// **'Show province names'**
  String get map_displayOptions_showProvinceNames;

  /// Generic Close button label or tooltip.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get common_close;

  /// Tooltip for the side menu button in the map controls.
  ///
  /// In en, this message translates to:
  /// **'Menu'**
  String get gameMap_menuTooltip;

  /// Label for the Old World region tab.
  ///
  /// In en, this message translates to:
  /// **'Old World'**
  String get region_oldWorld;

  /// Label for the New World region tab.
  ///
  /// In en, this message translates to:
  /// **'New World'**
  String get region_newWorld;

  /// Title of the debug log viewer screen and related actions.
  ///
  /// In en, this message translates to:
  /// **'Debug log'**
  String get debugLog_title;

  /// Label for the package filter section in the debug log viewer.
  ///
  /// In en, this message translates to:
  /// **'Package:'**
  String get debugLog_filter_package;

  /// Label for the log level filter section in the debug log viewer.
  ///
  /// In en, this message translates to:
  /// **'Level:'**
  String get debugLog_filter_level;

  /// Intro text for the new-game setup dialog (nations + leaders).
  ///
  /// In en, this message translates to:
  /// **'Assign each player slot a Great Power and leader. Default map colours appear beside each nation in the nation picker.'**
  String get shell_leaderDialog_intro;

  /// Hint text for the leader dropdown in the leader selection dialog.
  ///
  /// In en, this message translates to:
  /// **'Select leader'**
  String get shell_leaderDialog_selectLeaderHint;

  /// Generic Cancel button label.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get common_cancel;

  /// Generic Start button label used when beginning a flow.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get common_start;

  /// Title of the new-game setup dialog (nations + leaders).
  ///
  /// In en, this message translates to:
  /// **'New game — Setup'**
  String get shell_leaderDialog_title;

  /// Hint / picker title for the Great Power nation dropdown in the new-game setup dialog.
  ///
  /// In en, this message translates to:
  /// **'Select nation'**
  String get shell_newGame_selectNation;

  /// Slot label for the human player in the new-game setup dialog.
  ///
  /// In en, this message translates to:
  /// **'Player {slotNumber} (You)'**
  String shell_newGame_playerYou(int slotNumber);

  /// Slot label for an AI player in the new-game setup dialog.
  ///
  /// In en, this message translates to:
  /// **'Player {slotNumber} (AI)'**
  String shell_newGame_playerAi(int slotNumber);

  /// Label for the numeric seed field in the new-game leader dialog.
  ///
  /// In en, this message translates to:
  /// **'Game / world seed'**
  String get shell_leaderDialog_seedLabel;

  /// Helper text explaining 0 vs fixed seed for the new-game leader dialog.
  ///
  /// In en, this message translates to:
  /// **'Use 0 for a random world (a new time-based seed each time setup runs). Any other number reproduces the same world for the same settings.'**
  String get shell_leaderDialog_seedHelper;

  /// Title of the modal shown while a new game is being generated.
  ///
  /// In en, this message translates to:
  /// **'Creating game'**
  String get shell_newGameProgress_title;

  /// Coarse progress step: Old World tile map.
  ///
  /// In en, this message translates to:
  /// **'Generating Old World map…'**
  String get shell_newGameProgress_stepOldWorld;

  /// Coarse progress step: New World tile map.
  ///
  /// In en, this message translates to:
  /// **'Generating New World map…'**
  String get shell_newGameProgress_stepNewWorld;

  /// Coarse progress step: warp zones between regions.
  ///
  /// In en, this message translates to:
  /// **'Linking Old World and New World…'**
  String get shell_newGameProgress_stepWarp;

  /// Coarse progress step: province assignment, capitals, units.
  ///
  /// In en, this message translates to:
  /// **'Building world…'**
  String get shell_newGameProgress_stepBuildWorld;

  /// Coarse progress step: persisting game and map data.
  ///
  /// In en, this message translates to:
  /// **'Saving game…'**
  String get shell_newGameProgress_stepSave;

  /// Title of the error dialog when new-game setup fails.
  ///
  /// In en, this message translates to:
  /// **'Could not create game'**
  String get shell_newGameError_title;

  /// Button to retry new-game setup with a different random seed.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get shell_newGameError_retry;

  /// Title when the human must respond to an ally's call to arms.
  ///
  /// In en, this message translates to:
  /// **'Call to arms'**
  String get game_callToArms_title;

  /// Short explanation above the list of call-to-arms choices.
  ///
  /// In en, this message translates to:
  /// **'An allied power is at war. Join their war or refuse (alliance ends, relations worsen).'**
  String get game_callToArms_intro;

  /// One line per pending call to arms.
  ///
  /// In en, this message translates to:
  /// **'{defender} is attacked by {aggressor}.'**
  String game_callToArms_prompt(String defender, String aggressor);

  /// Button: accept call to arms and enter war with the aggressor.
  ///
  /// In en, this message translates to:
  /// **'Join'**
  String get game_callToArms_join;

  /// Button: refuse call to arms.
  ///
  /// In en, this message translates to:
  /// **'Refuse'**
  String get game_callToArms_refuse;

  /// Submit all call-to-arms choices.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get game_callToArms_submit;

  /// Error banner when intervention Yarn fails to load.
  ///
  /// In en, this message translates to:
  /// **'Could not load intervention dialogue: {error}'**
  String game_intervention_loadError(String error);

  /// Explains degraded intervention flow when dialogue asset is missing.
  ///
  /// In en, this message translates to:
  /// **'Submit all responses as \"Do naught\" to continue.'**
  String get game_intervention_degradedHint;

  /// Advance intervention Yarn line or exit degraded error dialog.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get game_intervention_continue;

  /// Header showing which intervention prompt is active.
  ///
  /// In en, this message translates to:
  /// **'Thy resolution ({current} of {total})'**
  String game_intervention_resolutionProgress(int current, int total);

  /// One-line summary of the war and which GP the player decides for.
  ///
  /// In en, this message translates to:
  /// **'{aggressor} against {defender}. Thou speakest for {intervening}.'**
  String game_intervention_situation(
    String aggressor,
    String defender,
    String intervening,
  );

  /// Button: military intervention on behalf of the defender.
  ///
  /// In en, this message translates to:
  /// **'Intervene with force'**
  String get game_intervention_intervene;

  /// Button: decline to intervene.
  ///
  /// In en, this message translates to:
  /// **'Do naught'**
  String get game_intervention_doNothing;

  /// Button: formal protest without military action.
  ///
  /// In en, this message translates to:
  /// **'Diplomatic protest'**
  String get game_intervention_protest;

  /// Turn-start news dialog title; turn is the current turn after resolution.
  ///
  /// In en, this message translates to:
  /// **'Turn {turn}'**
  String turnNews_title(int turn);

  /// Shown when the prior-turn digest has no lines.
  ///
  /// In en, this message translates to:
  /// **'No major events last turn.'**
  String get turnNews_empty;

  /// Button to dismiss the turn news dialog.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get turnNews_close;

  /// No description provided for @turnNews_capture.
  ///
  /// In en, this message translates to:
  /// **'{province}: ownership changed from {prevOwner} to {newOwner}.'**
  String turnNews_capture(String province, String prevOwner, String newOwner);

  /// No description provided for @turnNews_war.
  ///
  /// In en, this message translates to:
  /// **'{a} and {b} are now at war.'**
  String turnNews_war(String a, String b);

  /// No description provided for @turnNews_peace.
  ///
  /// In en, this message translates to:
  /// **'{a} and {b} are now at peace.'**
  String turnNews_peace(String a, String b);

  /// No description provided for @turnNews_overture.
  ///
  /// In en, this message translates to:
  /// **'{offerer} advanced relations with {target} ({stage}).'**
  String turnNews_overture(String offerer, String target, String stage);

  /// No description provided for @turnNews_provinceDiscovered.
  ///
  /// In en, this message translates to:
  /// **'New reports chart {province}.'**
  String turnNews_provinceDiscovered(String province);

  /// No description provided for @turnNews_seaDiscovered.
  ///
  /// In en, this message translates to:
  /// **'A fleet has entered {zone}.'**
  String turnNews_seaDiscovered(String zone);

  /// Overture stage label.
  ///
  /// In en, this message translates to:
  /// **'trade consulate'**
  String get turnNews_stage_tradeConsulate;

  /// Overture stage label.
  ///
  /// In en, this message translates to:
  /// **'embassy'**
  String get turnNews_stage_embassy;

  /// Overture stage label.
  ///
  /// In en, this message translates to:
  /// **'non-aggression pact'**
  String get turnNews_stage_nap;

  /// Overture stage label.
  ///
  /// In en, this message translates to:
  /// **'join empire'**
  String get turnNews_stage_joinEmpire;

  /// Province panel: unit has no pending orders this turn.
  ///
  /// In en, this message translates to:
  /// **'idle'**
  String get province_unitStatus_idle;

  /// Province panel: unit work in progress in world state.
  ///
  /// In en, this message translates to:
  /// **'working'**
  String get province_unitStatus_working;

  /// Work order target label in province panel.
  ///
  /// In en, this message translates to:
  /// **'explore'**
  String get province_workOrder_explore;

  /// Work order target label in province panel.
  ///
  /// In en, this message translates to:
  /// **'prospect'**
  String get province_workOrder_prospect;

  /// Work order target label in province panel.
  ///
  /// In en, this message translates to:
  /// **'build improvement'**
  String get province_workOrder_build_improvement;

  /// Work order target label in province panel.
  ///
  /// In en, this message translates to:
  /// **'upgrade town'**
  String get province_workOrder_upgrade_town;

  /// Work order target label in province panel.
  ///
  /// In en, this message translates to:
  /// **'build road'**
  String get province_workOrder_build_road;

  /// Work order target label in province panel.
  ///
  /// In en, this message translates to:
  /// **'build port'**
  String get province_workOrder_build_port;

  /// Work order target label in province panel.
  ///
  /// In en, this message translates to:
  /// **'build fort'**
  String get province_workOrder_build_fort;

  /// Work order target label in province panel.
  ///
  /// In en, this message translates to:
  /// **'build rail'**
  String get province_workOrder_build_rail;

  /// Work order target label in province panel.
  ///
  /// In en, this message translates to:
  /// **'steal technology'**
  String get province_workOrder_steal_tech;

  /// Work order target label in province panel.
  ///
  /// In en, this message translates to:
  /// **'counter-espionage'**
  String get province_workOrder_counter_spy;

  /// Work order target label in province panel.
  ///
  /// In en, this message translates to:
  /// **'purchase land'**
  String get province_workOrder_purchase_land;

  /// No description provided for @province_pending_armyMove.
  ///
  /// In en, this message translates to:
  /// **'Ordered: move army to {destination}'**
  String province_pending_armyMove(String destination);

  /// No description provided for @province_pending_regimentMove.
  ///
  /// In en, this message translates to:
  /// **'Ordered: move regiment to {destination}'**
  String province_pending_regimentMove(String destination);

  /// No description provided for @province_pending_fleetMoveSea.
  ///
  /// In en, this message translates to:
  /// **'Ordered: move fleet to sea {zone}'**
  String province_pending_fleetMoveSea(String zone);

  /// No description provided for @province_pending_fleetMovePort.
  ///
  /// In en, this message translates to:
  /// **'Ordered: dock fleet at {province}'**
  String province_pending_fleetMovePort(String province);

  /// No description provided for @province_pending_fleetMission.
  ///
  /// In en, this message translates to:
  /// **'Ordered: fleet mission — {mission}'**
  String province_pending_fleetMission(String mission);

  /// Naval mission label.
  ///
  /// In en, this message translates to:
  /// **'none'**
  String get province_fleetMission_none;

  /// Naval mission label.
  ///
  /// In en, this message translates to:
  /// **'patrol'**
  String get province_fleetMission_patrol;

  /// Naval mission label.
  ///
  /// In en, this message translates to:
  /// **'blockade'**
  String get province_fleetMission_blockade;

  /// Naval mission label.
  ///
  /// In en, this message translates to:
  /// **'beachhead'**
  String get province_fleetMission_beachhead;

  /// Naval mission label.
  ///
  /// In en, this message translates to:
  /// **'defend'**
  String get province_fleetMission_defend;

  /// Economic row suffix when tile can be improved.
  ///
  /// In en, this message translates to:
  /// **'(improvable)'**
  String get province_economic_improvableSuffix;

  /// No description provided for @province_economic_withImprovement.
  ///
  /// In en, this message translates to:
  /// **'with {improvement}'**
  String province_economic_withImprovement(String improvement);

  /// Regiment type display name.
  ///
  /// In en, this message translates to:
  /// **'Peasant levies'**
  String get province_regiment_peasant_levies;

  /// Regiment type display name.
  ///
  /// In en, this message translates to:
  /// **'Pikemen'**
  String get province_regiment_pikemen;

  /// Regiment type display name.
  ///
  /// In en, this message translates to:
  /// **'Arquebusiers'**
  String get province_regiment_arquebusiers;

  /// Regiment type display name.
  ///
  /// In en, this message translates to:
  /// **'Bowmen'**
  String get province_regiment_bowmen;

  /// Regiment type display name.
  ///
  /// In en, this message translates to:
  /// **'Squires'**
  String get province_regiment_squires;

  /// Regiment type display name.
  ///
  /// In en, this message translates to:
  /// **'Knights'**
  String get province_regiment_knights;

  /// Regiment type display name.
  ///
  /// In en, this message translates to:
  /// **'Culverin'**
  String get province_regiment_culverin;

  /// Regiment type display name.
  ///
  /// In en, this message translates to:
  /// **'Calivermen'**
  String get province_regiment_calivermen;

  /// Regiment type display name.
  ///
  /// In en, this message translates to:
  /// **'Halberdiers'**
  String get province_regiment_halberdiers;

  /// Regiment type display name.
  ///
  /// In en, this message translates to:
  /// **'Musketeers'**
  String get province_regiment_musketeers;

  /// Regiment type display name.
  ///
  /// In en, this message translates to:
  /// **'Cossacks'**
  String get province_regiment_cossacks;

  /// Regiment type display name.
  ///
  /// In en, this message translates to:
  /// **'Lancers'**
  String get province_regiment_lancers;

  /// Regiment type display name.
  ///
  /// In en, this message translates to:
  /// **'Harquebusiers'**
  String get province_regiment_harquebusiers;

  /// Regiment type display name.
  ///
  /// In en, this message translates to:
  /// **'Horse artillery'**
  String get province_regiment_horse_artillery;

  /// Regiment type display name.
  ///
  /// In en, this message translates to:
  /// **'Royal artillery'**
  String get province_regiment_royal_artillery;

  /// Regiment type display name.
  ///
  /// In en, this message translates to:
  /// **'Skirmishers'**
  String get province_regiment_skirmishers;

  /// Regiment type display name.
  ///
  /// In en, this message translates to:
  /// **'Regulars'**
  String get province_regiment_regulars;

  /// Regiment type display name.
  ///
  /// In en, this message translates to:
  /// **'Grenadiers'**
  String get province_regiment_grenadiers;

  /// Regiment type display name.
  ///
  /// In en, this message translates to:
  /// **'Hussars'**
  String get province_regiment_hussars;

  /// Regiment type display name.
  ///
  /// In en, this message translates to:
  /// **'Cuirassiers'**
  String get province_regiment_cuirassiers;

  /// Regiment type display name.
  ///
  /// In en, this message translates to:
  /// **'Light artillery'**
  String get province_regiment_light_artillery;

  /// Regiment type display name.
  ///
  /// In en, this message translates to:
  /// **'Heavy artillery'**
  String get province_regiment_heavy_artillery;

  /// Regiment type display name.
  ///
  /// In en, this message translates to:
  /// **'Sharpshooters'**
  String get province_regiment_sharpshooters;

  /// Regiment type display name.
  ///
  /// In en, this message translates to:
  /// **'Rifle infantry'**
  String get province_regiment_rifle_infantry;

  /// Regiment type display name.
  ///
  /// In en, this message translates to:
  /// **'Guards'**
  String get province_regiment_guards;

  /// Regiment type display name.
  ///
  /// In en, this message translates to:
  /// **'Scouts'**
  String get province_regiment_scouts;

  /// Regiment type display name.
  ///
  /// In en, this message translates to:
  /// **'Carbine cavalry'**
  String get province_regiment_carbine_cavalry;

  /// Regiment type display name.
  ///
  /// In en, this message translates to:
  /// **'Field artillery'**
  String get province_regiment_field_artillery;

  /// Regiment type display name.
  ///
  /// In en, this message translates to:
  /// **'Siege guns'**
  String get province_regiment_siege_guns;

  /// Ship type display name.
  ///
  /// In en, this message translates to:
  /// **'Carrack'**
  String get province_ship_carrack;

  /// Ship type display name.
  ///
  /// In en, this message translates to:
  /// **'Fluyte'**
  String get province_ship_fluyte;

  /// Ship type display name.
  ///
  /// In en, this message translates to:
  /// **'Sloop'**
  String get province_ship_sloop;

  /// Ship type display name.
  ///
  /// In en, this message translates to:
  /// **'Trader'**
  String get province_ship_trader;

  /// Ship type display name.
  ///
  /// In en, this message translates to:
  /// **'Galleon'**
  String get province_ship_galleon;

  /// Ship type display name.
  ///
  /// In en, this message translates to:
  /// **'Indiaman'**
  String get province_ship_indiaman;

  /// Ship type display name.
  ///
  /// In en, this message translates to:
  /// **'Frigate'**
  String get province_ship_frigate;

  /// Ship type display name.
  ///
  /// In en, this message translates to:
  /// **'Raider'**
  String get province_ship_raider;

  /// Ship type display name.
  ///
  /// In en, this message translates to:
  /// **'Ship of the Line'**
  String get province_ship_ship_of_the_line;

  /// Ship type display name.
  ///
  /// In en, this message translates to:
  /// **'Clipper'**
  String get province_ship_clipper;

  /// Ship type display name.
  ///
  /// In en, this message translates to:
  /// **'Merchant Steamship'**
  String get province_ship_merchant_steamship;

  /// Ship type display name.
  ///
  /// In en, this message translates to:
  /// **'Ironclad'**
  String get province_ship_ironclad;

  /// Quick battle action selector command points header.
  ///
  /// In en, this message translates to:
  /// **'Command Points: {cp}'**
  String quickBattle_commandPoints(int cp);

  /// Quick battle action label.
  ///
  /// In en, this message translates to:
  /// **'Volley Fire'**
  String get quickBattle_action_volleyFire;

  /// Quick battle action label.
  ///
  /// In en, this message translates to:
  /// **'Defend'**
  String get quickBattle_action_defend;

  /// Quick battle action label.
  ///
  /// In en, this message translates to:
  /// **'Maneuver'**
  String get quickBattle_action_maneuver;

  /// Quick battle action label.
  ///
  /// In en, this message translates to:
  /// **'Fall Back'**
  String get quickBattle_action_fallBack;

  /// Quick battle action label.
  ///
  /// In en, this message translates to:
  /// **'Assault'**
  String get quickBattle_action_assault;

  /// Quick battle action button label with command point cost.
  ///
  /// In en, this message translates to:
  /// **'{label} ({cost} CP)'**
  String quickBattle_actionWithCost(String label, int cost);

  /// Combat mode dialog title for a province.
  ///
  /// In en, this message translates to:
  /// **'Combat at {provinceName}'**
  String quickBattle_combatAt(String provinceName);

  /// Combat mode guidance for capital sieges.
  ///
  /// In en, this message translates to:
  /// **'Capital siege — Quick Battle only (no auto-resolve).'**
  String get quickBattle_capitalSiegeQuickBattleOnly;

  /// Combat mode choice prompt.
  ///
  /// In en, this message translates to:
  /// **'Choose combat mode:'**
  String get quickBattle_chooseCombatMode;

  /// Combat mode button label.
  ///
  /// In en, this message translates to:
  /// **'Auto-Resolve'**
  String get quickBattle_autoResolve;

  /// Combat mode button label.
  ///
  /// In en, this message translates to:
  /// **'Quick Battle'**
  String get quickBattle_quickBattle;

  /// Quick battle winner line when attacker wins.
  ///
  /// In en, this message translates to:
  /// **'{name} wins'**
  String quickBattle_attackerWins(String name);

  /// Quick battle winner line when defender holds.
  ///
  /// In en, this message translates to:
  /// **'{name} holds'**
  String quickBattle_defenderHolds(String name);

  /// Quick battle winner line for tie exhaustion state.
  ///
  /// In en, this message translates to:
  /// **'Mutual exhaustion'**
  String get quickBattle_mutualExhaustion;

  /// Quick battle result heading.
  ///
  /// In en, this message translates to:
  /// **'Battle Result: {winnerText}'**
  String quickBattle_battleResult(String winnerText);

  /// Quick battle note when province ownership flips.
  ///
  /// In en, this message translates to:
  /// **'Province captured.'**
  String get quickBattle_provinceCaptured;

  /// Quick battle casualties summary line.
  ///
  /// In en, this message translates to:
  /// **'{name} casualties: {count}'**
  String quickBattle_casualties(String name, int count);

  /// Quick battle result dialog close button label.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get quickBattle_ok;

  /// Quick battle screen heading with current and max rounds.
  ///
  /// In en, this message translates to:
  /// **'Quick Battle — Round {round} / {maxRounds}'**
  String quickBattle_round(int round, int maxRounds);

  /// Quick battle auto resolve button label.
  ///
  /// In en, this message translates to:
  /// **'Resolve (Auto)'**
  String get quickBattle_resolveAuto;

  /// Fallback attacker label in quick battle UI.
  ///
  /// In en, this message translates to:
  /// **'Attacker'**
  String get quickBattle_attackerDefaultName;

  /// Fallback defender label in quick battle UI.
  ///
  /// In en, this message translates to:
  /// **'Defender'**
  String get quickBattle_defenderDefaultName;

  /// Error shown when intro dialogue fails to load.
  ///
  /// In en, this message translates to:
  /// **'Could not load intro dialogue: {error}'**
  String game_intro_loadError(String error);

  /// Error shown when overture dialogue fails to load.
  ///
  /// In en, this message translates to:
  /// **'Could not load overture dialogue: {error}'**
  String game_overture_loadError(String error);

  /// Title for overture decisions panel.
  ///
  /// In en, this message translates to:
  /// **'Diplomatic overtures'**
  String get game_overture_title;

  /// Overture panel intro text.
  ///
  /// In en, this message translates to:
  /// **'Accept or reject each offer.'**
  String get game_overture_intro;

  /// One-line overture offer summary.
  ///
  /// In en, this message translates to:
  /// **'{offerer}: {stage}'**
  String game_overture_offerLine(String offerer, String stage);

  /// Accept overture button label.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get game_overture_accept;

  /// Reject overture button label.
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get game_overture_reject;

  /// Victory type label.
  ///
  /// In en, this message translates to:
  /// **'Military victory'**
  String get victory_military;

  /// Victory sentence with winner and turn number.
  ///
  /// In en, this message translates to:
  /// **'{winner} wins on turn {turn}.'**
  String victory_winnerOnTurn(String winner, int turn);

  /// Victory overlay button label.
  ///
  /// In en, this message translates to:
  /// **'Return to main menu'**
  String get victory_returnToMainMenu;

  /// Victory overlay button label.
  ///
  /// In en, this message translates to:
  /// **'View final state'**
  String get victory_viewFinalState;

  /// Header label for player-owned province destinations in move army dialog.
  ///
  /// In en, this message translates to:
  /// **'Your provinces'**
  String get moveArmy_groupYourProvinces;

  /// Header label for unowned province destinations in move army dialog.
  ///
  /// In en, this message translates to:
  /// **'Unowned'**
  String get moveArmy_groupUnowned;

  /// Confirm dialog title for entering hostile territory with army movement.
  ///
  /// In en, this message translates to:
  /// **'Invade province?'**
  String get moveArmy_invadeProvinceTitle;

  /// Confirm dialog text for hostile army movement.
  ///
  /// In en, this message translates to:
  /// **'Moving into {ownerLabel} territory will declare war this turn and then move the army. Continue?'**
  String moveArmy_invadeProvinceBody(String ownerLabel);

  /// Confirm action label for hostile army movement.
  ///
  /// In en, this message translates to:
  /// **'Declare war and move'**
  String get moveArmy_declareWarAndMove;

  /// Move army dialog title with army id.
  ///
  /// In en, this message translates to:
  /// **'Move army {armyId}'**
  String moveArmy_title(String armyId);

  /// Empty-state text for move army dialog.
  ///
  /// In en, this message translates to:
  /// **'No valid destinations.'**
  String get moveArmy_noValidDestinations;

  /// Field label for destination province picker in move army dialog.
  ///
  /// In en, this message translates to:
  /// **'Destination province'**
  String get moveArmy_destinationProvince;

  /// Move fleet dialog title.
  ///
  /// In en, this message translates to:
  /// **'Move fleet — {fleetLabel}'**
  String moveFleet_title(String fleetLabel);

  /// Move fleet dialog title with destination count.
  ///
  /// In en, this message translates to:
  /// **'Move fleet — {fleetLabel} ({count} destinations)'**
  String moveFleet_titleWithDestinations(String fleetLabel, int count);

  /// Empty-state message in move fleet dialog.
  ///
  /// In en, this message translates to:
  /// **'No adjacent sea zones (check map topology).'**
  String get moveFleet_noAdjacentSeaZones;

  /// Section heading for sea zone destinations in move fleet dialog.
  ///
  /// In en, this message translates to:
  /// **'Sea zones'**
  String get moveFleet_seaZonesSection;

  /// Section heading for dock destinations in move fleet dialog.
  ///
  /// In en, this message translates to:
  /// **'Provinces (dock)'**
  String get moveFleet_provincesDockSection;

  /// Tooltip for locate action in move fleet dialog.
  ///
  /// In en, this message translates to:
  /// **'Locate on map'**
  String get moveFleet_locateOnMap;

  /// Suffix appended to same-region warp-zone sea destinations in move fleet dialog.
  ///
  /// In en, this message translates to:
  /// **'links'**
  String get moveFleet_warpLink;

  /// Suffix appended to cross-region sea-zone destinations in move fleet dialog.
  ///
  /// In en, this message translates to:
  /// **'links to {region}'**
  String moveFleet_warpLinkToRegion(String region);

  /// Military units panel title.
  ///
  /// In en, this message translates to:
  /// **'Military Units'**
  String get military_units_title;

  /// Tooltip for deselecting all armies in military panel.
  ///
  /// In en, this message translates to:
  /// **'Deselect all armies'**
  String get military_units_deselectAllArmies;

  /// Tooltip for selecting all armies in military panel.
  ///
  /// In en, this message translates to:
  /// **'Select all armies'**
  String get military_units_selectAllArmies;

  /// Empty message in military units panel.
  ///
  /// In en, this message translates to:
  /// **'No military units'**
  String get military_units_empty;

  /// Label for home army.
  ///
  /// In en, this message translates to:
  /// **'Home Army'**
  String get military_units_homeArmy;

  /// Label for numbered army.
  ///
  /// In en, this message translates to:
  /// **'Army {armyId}'**
  String military_units_army(String armyId);

  /// Army subtitle showing regiment count and location.
  ///
  /// In en, this message translates to:
  /// **'{regiments} regiments · {location}'**
  String military_units_armySubtitle(int regiments, String location);

  /// Army subtitle showing regiment count, location, and a draft move line.
  ///
  /// In en, this message translates to:
  /// **'{regiments} regiments · {location}\n{draftLine}'**
  String military_units_armySubtitleWithDraft(
    int regiments,
    String location,
    String draftLine,
  );

  /// Empty-state line for army with no regiments.
  ///
  /// In en, this message translates to:
  /// **'No regiments assigned'**
  String get military_units_noRegimentsAssigned;

  /// Type/count line used in military/naval row labels.
  ///
  /// In en, this message translates to:
  /// **'{typeName}: {count}'**
  String military_units_typeCount(String typeName, int count);

  /// Regiment subtitle row.
  ///
  /// In en, this message translates to:
  /// **'Medals: {medals} · Status: {status}'**
  String military_units_regimentSubtitle(String medals, String status);

  /// Status line label.
  ///
  /// In en, this message translates to:
  /// **'Status: {status}'**
  String military_units_status(String status);

  /// Naval units panel title.
  ///
  /// In en, this message translates to:
  /// **'Naval Units'**
  String get naval_units_title;

  /// Tile-scoped naval units panel title.
  ///
  /// In en, this message translates to:
  /// **'Naval Units (Tile)'**
  String get naval_units_title_tile;

  /// Tooltip for deselecting all fleets in naval panel.
  ///
  /// In en, this message translates to:
  /// **'Deselect all fleets'**
  String get naval_units_deselectAllFleets;

  /// Tooltip for selecting all fleets in naval panel.
  ///
  /// In en, this message translates to:
  /// **'Select all fleets'**
  String get naval_units_selectAllFleets;

  /// Empty message in naval units panel.
  ///
  /// In en, this message translates to:
  /// **'No naval units'**
  String get naval_units_empty;

  /// Fleet summary total ships.
  ///
  /// In en, this message translates to:
  /// **'Total ships: {count}'**
  String naval_units_totalShips(int count);

  /// Fleet strength summary line.
  ///
  /// In en, this message translates to:
  /// **'Strength: {value}'**
  String naval_units_strength(String value);

  /// Fleet summary warship count.
  ///
  /// In en, this message translates to:
  /// **'{count} warships'**
  String naval_units_warships(int count);

  /// Fleet summary merchant count.
  ///
  /// In en, this message translates to:
  /// **'{count} merchants'**
  String naval_units_merchants(int count);

  /// Tooltip for fleet locate action.
  ///
  /// In en, this message translates to:
  /// **'Locate fleet'**
  String get naval_units_locateFleet;

  /// Fleet mission label.
  ///
  /// In en, this message translates to:
  /// **'Mission: {mission}'**
  String naval_units_mission(String mission);

  /// Empty-state line for fleet with no ships.
  ///
  /// In en, this message translates to:
  /// **'No ships in this fleet'**
  String get naval_units_noShipsInFleet;

  /// Cargo capacity line for home fleet.
  ///
  /// In en, this message translates to:
  /// **'Cargo capacity: {capacity}'**
  String naval_units_cargoCapacity(int capacity);

  /// Cargo capacity line for non-home fleet.
  ///
  /// In en, this message translates to:
  /// **'Cargo capacity (if assigned): {capacity}'**
  String naval_units_cargoCapacityIfAssigned(int capacity);

  /// Diplomacy dialog title for setting subsidy amount.
  ///
  /// In en, this message translates to:
  /// **'Set subsidy'**
  String get diplomacy_setSubsidy;

  /// Diplomacy dialog title for granting aid amount.
  ///
  /// In en, this message translates to:
  /// **'Grant aid'**
  String get diplomacy_grantAid;

  /// Treasury and step line in diplomacy amount dialog.
  ///
  /// In en, this message translates to:
  /// **'Treasury: £{treasury}. Step: £{step}.'**
  String diplomacy_treasuryStep(int treasury, int step);

  /// Currency amount display in diplomacy amount dialog.
  ///
  /// In en, this message translates to:
  /// **'£{amount}'**
  String diplomacy_currencyAmount(int amount);

  /// Validation text when treasury is below minimum adjustable amount.
  ///
  /// In en, this message translates to:
  /// **'Treasury is below the minimum valid amount (£{step}).'**
  String diplomacy_treasuryBelowMinimum(int step);

  /// Train civilians dialog title.
  ///
  /// In en, this message translates to:
  /// **'Train Civilians'**
  String get trainCivilians_title;

  /// Train military dialog title.
  ///
  /// In en, this message translates to:
  /// **'Train Military'**
  String get trainMilitary_title;

  /// Error text when player has no capital in train dialogs.
  ///
  /// In en, this message translates to:
  /// **'No capital set — cannot train units'**
  String get trainUnits_noCapital;

  /// Treasury summary line in train dialogs.
  ///
  /// In en, this message translates to:
  /// **'Treasury: {value}'**
  String trainUnits_treasury(String value);

  /// Paper summary line in civilian train dialog.
  ///
  /// In en, this message translates to:
  /// **'Paper: {value}'**
  String trainUnits_paper(int value);

  /// Peasants summary line in military train dialog.
  ///
  /// In en, this message translates to:
  /// **'Peasants: {value}'**
  String trainUnits_peasants(int value);

  /// Civilian units panel title.
  ///
  /// In en, this message translates to:
  /// **'Civilian Units'**
  String get civilian_units_title;

  /// Tile-scoped civilian units panel title.
  ///
  /// In en, this message translates to:
  /// **'Civilian Units (Tile)'**
  String get civilian_units_title_tile;

  /// Action label for opening tile details from civilian panel.
  ///
  /// In en, this message translates to:
  /// **'Tile'**
  String get civilian_units_tile;

  /// Empty message in civilian units panel.
  ///
  /// In en, this message translates to:
  /// **'No civilian units'**
  String get civilian_units_empty;

  /// Unit status line in civilian unit row.
  ///
  /// In en, this message translates to:
  /// **'Status: {status}'**
  String civilian_units_status(String status);

  /// Unit location line in civilian unit row.
  ///
  /// In en, this message translates to:
  /// **'Location: {location}'**
  String civilian_units_location(String location);

  /// Assigned-work line in civilian unit row.
  ///
  /// In en, this message translates to:
  /// **'Assigned to: {target}'**
  String civilian_units_assignedTo(String target);

  /// Assign action button in civilian units panel.
  ///
  /// In en, this message translates to:
  /// **'Assign'**
  String get civilian_units_assign;

  /// Production commodity breakdown dialog title.
  ///
  /// In en, this message translates to:
  /// **'Commodity breakdown'**
  String get production_breakdown_title;

  /// Commodity column heading in breakdown table.
  ///
  /// In en, this message translates to:
  /// **'Commodity'**
  String get production_breakdown_commodity;

  /// Total column heading in breakdown table.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get production_breakdown_total;

  /// Phase heading in production breakdown table.
  ///
  /// In en, this message translates to:
  /// **'Pending build costs'**
  String get production_breakdown_phase_pendingBuildCosts;

  /// Phase heading in production breakdown table.
  ///
  /// In en, this message translates to:
  /// **'Extraction'**
  String get production_breakdown_phase_extraction;

  /// Phase heading in production breakdown table.
  ///
  /// In en, this message translates to:
  /// **'Riches to treasury'**
  String get production_breakdown_phase_richesToTreasury;

  /// Phase heading in production breakdown table.
  ///
  /// In en, this message translates to:
  /// **'Consumption'**
  String get production_breakdown_phase_consumption;

  /// Phase heading in production breakdown table.
  ///
  /// In en, this message translates to:
  /// **'Production'**
  String get production_breakdown_phase_production;

  /// Button label to open production commodity breakdown.
  ///
  /// In en, this message translates to:
  /// **'Breakdown'**
  String get production_breakdown;

  /// Production panel subheader for available resources.
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get production_available;

  /// Production panel category heading.
  ///
  /// In en, this message translates to:
  /// **'Food'**
  String get production_food;

  /// Production panel category heading.
  ///
  /// In en, this message translates to:
  /// **'Raw Materials'**
  String get production_rawMaterials;

  /// Production panel category heading.
  ///
  /// In en, this message translates to:
  /// **'Manufactured'**
  String get production_manufactured;

  /// Production panel category heading.
  ///
  /// In en, this message translates to:
  /// **'Workers'**
  String get production_workers;

  /// Worker label in production panel.
  ///
  /// In en, this message translates to:
  /// **'Peasants'**
  String get production_workers_peasants;

  /// Worker label in production panel.
  ///
  /// In en, this message translates to:
  /// **'Apprentices'**
  String get production_workers_apprentices;

  /// Worker label in production panel.
  ///
  /// In en, this message translates to:
  /// **'Journeymen'**
  String get production_workers_journeymen;

  /// Worker label in production panel.
  ///
  /// In en, this message translates to:
  /// **'Masters'**
  String get production_workers_masters;

  /// Production panel subheader for allocation controls.
  ///
  /// In en, this message translates to:
  /// **'Allocation'**
  String get production_allocation;

  /// Semantics and tooltip for production allocation minus control.
  ///
  /// In en, this message translates to:
  /// **'Decrease desired output for this recipe'**
  String get production_allocationDecrementRecipe;

  /// Semantics and tooltip for production allocation plus control.
  ///
  /// In en, this message translates to:
  /// **'Increase desired output for this recipe'**
  String get production_allocationIncrementRecipe;

  /// Semantics and tooltip for production allocation maximize control.
  ///
  /// In en, this message translates to:
  /// **'Set this recipe to maximum desired output'**
  String get production_allocationMaximizeRecipe;

  /// Semantics and tooltip for production allocation clear control.
  ///
  /// In en, this message translates to:
  /// **'Clear desired output for this recipe'**
  String get production_allocationClearRecipe;

  /// Split army dialog title.
  ///
  /// In en, this message translates to:
  /// **'Split Army'**
  String get splitArmy_title;

  /// Technology panel title with player display name.
  ///
  /// In en, this message translates to:
  /// **'Technology - {playerName}'**
  String technologyPanel_title(String playerName);

  /// Research slot count line in technology panel.
  ///
  /// In en, this message translates to:
  /// **'Research slots: {slots}'**
  String technologyPanel_researchSlotsCount(int slots);

  /// Technology panel section label for slot list.
  ///
  /// In en, this message translates to:
  /// **'Research slots'**
  String get technologyPanel_researchSlots;

  /// Placeholder label for an empty research slot.
  ///
  /// In en, this message translates to:
  /// **'Empty'**
  String get technologyPanel_empty;

  /// Research slot title label.
  ///
  /// In en, this message translates to:
  /// **'Slot {slot}'**
  String technologyPanel_slot(int slot);

  /// Research slot subtitle with tech name, progress, and cost label.
  ///
  /// In en, this message translates to:
  /// **'{name} - {progress}/{costLabel} RP'**
  String technologyPanel_slotSubtitle(
    String name,
    int progress,
    String costLabel,
  );

  /// Empty-state subtitle when no tech is assigned to a slot.
  ///
  /// In en, this message translates to:
  /// **'No tech assigned'**
  String get technologyPanel_noTechAssigned;

  /// Action label to open tech selection for a research slot.
  ///
  /// In en, this message translates to:
  /// **'Choose tech'**
  String get technologyPanel_chooseTech;

  /// Technology panel heading for researched techs.
  ///
  /// In en, this message translates to:
  /// **'Researched ({count}):'**
  String technologyPanel_researched(int count);

  /// Technology panel empty-state text when no techs are researched.
  ///
  /// In en, this message translates to:
  /// **'None yet'**
  String get technologyPanel_noneYet;

  /// Technology panel section heading for active progress entries.
  ///
  /// In en, this message translates to:
  /// **'In progress:'**
  String get technologyPanel_inProgress;

  /// Technology panel progress line for one tech.
  ///
  /// In en, this message translates to:
  /// **'{name}: {points} RP'**
  String technologyPanel_progressLine(String name, int points);

  /// Bottom-sheet empty-state when no selectable technologies exist.
  ///
  /// In en, this message translates to:
  /// **'No techs available to research'**
  String get technologyPanel_noTechsAvailable;

  /// Bottom-sheet row subtitle for selectable technology.
  ///
  /// In en, this message translates to:
  /// **'Era {era} - {category} - {cost} RP'**
  String technologyPanel_pickSubtitle(String era, String category, int cost);

  /// Snackbar shown when a research slot assignment is removed.
  ///
  /// In en, this message translates to:
  /// **'Research slot cancelled'**
  String get technologyPanel_slotCancelled;

  /// Tech tree empty-state text.
  ///
  /// In en, this message translates to:
  /// **'No techs in catalog'**
  String get techTree_noTechsInCatalog;

  /// Tech dialog subtitle showing era and category.
  ///
  /// In en, this message translates to:
  /// **'Era {era} - {category}'**
  String techTree_eraCategory(String era, String category);

  /// Tech cost display in research points.
  ///
  /// In en, this message translates to:
  /// **'{points} RP'**
  String techTree_researchPoints(int points);

  /// Tech dialog section heading for prerequisites.
  ///
  /// In en, this message translates to:
  /// **'Prerequisites'**
  String get techTree_prerequisites;

  /// Tech dialog section heading for effects.
  ///
  /// In en, this message translates to:
  /// **'Effects'**
  String get techTree_effects;

  /// Tech tree legend title.
  ///
  /// In en, this message translates to:
  /// **'Technology tree legend'**
  String get techTree_legendTitle;

  /// Legend state label for researched techs.
  ///
  /// In en, this message translates to:
  /// **'Researched'**
  String get techTree_stateResearched;

  /// Legend state label for in-progress techs.
  ///
  /// In en, this message translates to:
  /// **'In progress'**
  String get techTree_stateInProgress;

  /// Legend state label for available techs.
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get techTree_stateAvailable;

  /// Legend state label for locked techs.
  ///
  /// In en, this message translates to:
  /// **'Locked'**
  String get techTree_stateLocked;

  /// Map debug/story toggle label for full map visibility.
  ///
  /// In en, this message translates to:
  /// **'Full visibility'**
  String get mapDebug_fullVisibility;

  /// Map debug/story toggle label for player-constrained visibility.
  ///
  /// In en, this message translates to:
  /// **'Player-constrained'**
  String get mapDebug_playerConstrained;

  /// Map debug/story toggle label to hide province names.
  ///
  /// In en, this message translates to:
  /// **'No province names'**
  String get mapDebug_hideProvinceNames;

  /// Map debug/story compact toggle label to hide names.
  ///
  /// In en, this message translates to:
  /// **'No names'**
  String get mapDebug_noNames;

  /// Widgetbook button label for enabled primary action sample.
  ///
  /// In en, this message translates to:
  /// **'Primary action'**
  String get widgetbook_primaryAction;

  /// Widgetbook button label for disabled sample.
  ///
  /// In en, this message translates to:
  /// **'Disabled'**
  String get widgetbook_disabled;

  /// Widgetbook button label for fixed-width sample.
  ///
  /// In en, this message translates to:
  /// **'Fixed width'**
  String get widgetbook_fixedWidth;

  /// Widgetbook placeholder when sample game has no players.
  ///
  /// In en, this message translates to:
  /// **'No players'**
  String get widgetbook_noPlayers;

  /// Widgetbook app bar title for tech tree story.
  ///
  /// In en, this message translates to:
  /// **'Tech Tree'**
  String get widgetbook_techTreeTitle;

  /// Widgetbook action label to open production breakdown demo dialog.
  ///
  /// In en, this message translates to:
  /// **'Open breakdown dialog'**
  String get widgetbook_openBreakdownDialog;

  /// Widgetbook placeholder text for game shell container in dialogue stories.
  ///
  /// In en, this message translates to:
  /// **'Game shell'**
  String get widgetbook_gameShell;

  /// Bullet line item in tech-tree detail dialog.
  ///
  /// In en, this message translates to:
  /// **'- {text}'**
  String techTree_bulletItem(String text);

  /// Obfuscated placeholder text shown when section intel is unavailable.
  ///
  /// In en, this message translates to:
  /// **'???'**
  String get provinceOverlay_unknown;

  /// Tile section prompt when no map tile is selected.
  ///
  /// In en, this message translates to:
  /// **'Click a tile to see details.'**
  String get provinceOverlay_clickTileForDetails;

  /// Tile section obfuscated coordinates row.
  ///
  /// In en, this message translates to:
  /// **'Coordinates: ???'**
  String get provinceOverlay_tileCoordinatesUnknown;

  /// Tile section obfuscated terrain row.
  ///
  /// In en, this message translates to:
  /// **'Terrain: ???'**
  String get provinceOverlay_tileTerrainUnknown;

  /// Tile section obfuscated resource row.
  ///
  /// In en, this message translates to:
  /// **'Resource: ???'**
  String get provinceOverlay_tileResourceUnknown;

  /// Tile section obfuscated prospecting row.
  ///
  /// In en, this message translates to:
  /// **'Prospected: ???'**
  String get provinceOverlay_tileProspectedUnknown;

  /// Tile section obfuscated improvement row.
  ///
  /// In en, this message translates to:
  /// **'Improvement: ???'**
  String get provinceOverlay_tileImprovementUnknown;

  /// Tile section obfuscated road/rail row.
  ///
  /// In en, this message translates to:
  /// **'Road / railroad: ???'**
  String get provinceOverlay_tileRoadUnknown;

  /// Tile section obfuscated civilian units row.
  ///
  /// In en, this message translates to:
  /// **'Civilian units (province): ???'**
  String get provinceOverlay_tileCivilianUnitsUnknown;

  /// Tile section coordinates row.
  ///
  /// In en, this message translates to:
  /// **'Coordinates: ({x}, {y})'**
  String provinceOverlay_tileCoordinates(int x, int y);

  /// Tile section terrain row.
  ///
  /// In en, this message translates to:
  /// **'Terrain: {terrain}'**
  String provinceOverlay_tileTerrain(String terrain);

  /// Tile section resource label prefix before inline icon/name.
  ///
  /// In en, this message translates to:
  /// **'Resource: '**
  String get provinceOverlay_tileResourcePrefix;

  /// Tile section prospecting state row.
  ///
  /// In en, this message translates to:
  /// **'Prospected: {value}'**
  String provinceOverlay_tileProspected(String value);

  /// Tile section improvement row.
  ///
  /// In en, this message translates to:
  /// **'Improvement: {value}'**
  String provinceOverlay_tileImprovement(String value);

  /// Tile section road/rail row when not applicable.
  ///
  /// In en, this message translates to:
  /// **'Road / railroad: -'**
  String get provinceOverlay_tileRoadNone;

  /// Tile section civilian unit count row.
  ///
  /// In en, this message translates to:
  /// **'Civilian units (province): {count}'**
  String provinceOverlay_tileCivilianUnits(int count);

  /// Political section row for a sea-zone overlay.
  ///
  /// In en, this message translates to:
  /// **'Sea zone: {name}'**
  String provinceOverlay_seaZone(String name);

  /// Political section province name row.
  ///
  /// In en, this message translates to:
  /// **'Name: {name}'**
  String provinceOverlay_name(String name);

  /// Political section owner row.
  ///
  /// In en, this message translates to:
  /// **'Owner: {owner}'**
  String provinceOverlay_owner(String owner);

  /// Indented count line used in military summary lists.
  ///
  /// In en, this message translates to:
  /// **'  {label}: {count}'**
  String provinceOverlay_indentedCount(String label, int count);

  /// Civilian section line for unit target or status.
  ///
  /// In en, this message translates to:
  /// **'{type} ({id}): {target}'**
  String provinceOverlay_unitTarget(String type, String id, String target);

  /// Civilian section line for foreign-unit status.
  ///
  /// In en, this message translates to:
  /// **'{owner} — {type} ({id}): {status}'**
  String provinceOverlay_foreignUnitStatus(
    String owner,
    String type,
    String id,
    String status,
  );

  /// Naval section fleet summary line.
  ///
  /// In en, this message translates to:
  /// **'{owner} — {fleetLabel}: {shipParts}'**
  String provinceOverlay_fleetSummary(
    String owner,
    String fleetLabel,
    String shipParts,
  );

  /// Province overlay section heading for political details.
  ///
  /// In en, this message translates to:
  /// **'Political'**
  String get provinceOverlay_sectionPolitical;

  /// Province overlay section heading for tile details.
  ///
  /// In en, this message translates to:
  /// **'Tile'**
  String get provinceOverlay_sectionTile;

  /// Province overlay section heading for economic details.
  ///
  /// In en, this message translates to:
  /// **'Economic'**
  String get provinceOverlay_sectionEconomic;

  /// Province overlay section heading for military details.
  ///
  /// In en, this message translates to:
  /// **'Military'**
  String get provinceOverlay_sectionMilitary;

  /// Province overlay section heading for civilian details.
  ///
  /// In en, this message translates to:
  /// **'Civilian'**
  String get provinceOverlay_sectionCivilian;

  /// Province overlay section heading for naval details.
  ///
  /// In en, this message translates to:
  /// **'Naval'**
  String get provinceOverlay_sectionNaval;

  /// Game setup screen title.
  ///
  /// In en, this message translates to:
  /// **'Game Setup'**
  String get gameSetup_title;

  /// Loading state label while starting a game from setup.
  ///
  /// In en, this message translates to:
  /// **'Starting…'**
  String get gameSetup_starting;

  /// Primary button to begin play from game setup.
  ///
  /// In en, this message translates to:
  /// **'Start Game'**
  String get gameSetup_startGame;

  /// Back button on game setup screen.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get gameSetup_back;

  /// Label for the human player slot on game setup.
  ///
  /// In en, this message translates to:
  /// **'Player 1 (You)'**
  String get gameSetup_player1You;

  /// Label for an AI-controlled player slot (n is 2-based index for display).
  ///
  /// In en, this message translates to:
  /// **'Player {n} (AI)'**
  String gameSetup_playerAiSlot(int n);

  /// Dropdown hint when choosing a great power nation.
  ///
  /// In en, this message translates to:
  /// **'Select nation'**
  String get gameSetup_selectNation;

  /// Dropdown hint when choosing a leader variant.
  ///
  /// In en, this message translates to:
  /// **'Select leader'**
  String get gameSetup_selectLeader;

  /// Tooltip for cycling map base layer display.
  ///
  /// In en, this message translates to:
  /// **'Base layer: terrain / +resources / +improvements'**
  String get mapCorner_tooltipBaseLayer;

  /// Tooltip for centering the map on the home capital.
  ///
  /// In en, this message translates to:
  /// **'Center on capital'**
  String get mapCorner_tooltipCenterCapital;

  /// Tooltip for opening map display options.
  ///
  /// In en, this message translates to:
  /// **'Map display options'**
  String get mapCorner_tooltipMapDisplayOptions;

  /// Cargo hold usage label on map controls (used and capacity are pre-formatted numbers or em dash).
  ///
  /// In en, this message translates to:
  /// **'{used}/{capacity}'**
  String mapControls_cargoHold(String used, String capacity);

  /// Percentage label with no space before percent sign.
  ///
  /// In en, this message translates to:
  /// **'{value}%'**
  String common_percent(int value);

  /// Accessibility label and tooltip for region minimap zoom slider.
  ///
  /// In en, this message translates to:
  /// **'Map zoom'**
  String get regionMinimap_mapZoom;

  /// Semantics value for zoom slider (spoken).
  ///
  /// In en, this message translates to:
  /// **'{pct} percent'**
  String regionMinimap_zoomSemanticsValue(int pct);

  /// Economic row in province overlay: terrain, resource id, and localized detail suffix.
  ///
  /// In en, this message translates to:
  /// **'{terrain}/{resourceId} {detail}'**
  String province_economic_resourceRow(
    String terrain,
    String resourceId,
    String detail,
  );

  /// Heading for diplomatic event history on detail screen.
  ///
  /// In en, this message translates to:
  /// **'Diplomatic history'**
  String get diplomacy_detail_historyTitle;

  /// Empty state when there is no diplomatic history.
  ///
  /// In en, this message translates to:
  /// **'No recorded events with this faction.'**
  String get diplomacy_detail_noEvents;

  /// History card subtitle with calendar year and turn number.
  ///
  /// In en, this message translates to:
  /// **'{year} (Turn {turn})'**
  String diplomacy_detail_yearTurn(int year, int turn);

  /// Heading for dossier section on diplomacy detail.
  ///
  /// In en, this message translates to:
  /// **'Dossier'**
  String get diplomacy_detail_dossierTitle;

  /// Label above current diplomatic relation summary.
  ///
  /// In en, this message translates to:
  /// **'Current relation'**
  String get diplomacy_detail_currentRelation;

  /// Empty state for dossier evidence list.
  ///
  /// In en, this message translates to:
  /// **'No dossier evidence yet.'**
  String get diplomacy_detail_noDossier;

  /// Prefix for a dossier evidence line.
  ///
  /// In en, this message translates to:
  /// **'Turn {turn}:'**
  String diplomacy_detail_turnEvidence(int turn);

  /// Empty diplomacy list before any factions are discovered.
  ///
  /// In en, this message translates to:
  /// **'No other factions discovered yet.'**
  String get diplomacy_panel_noFactions;

  /// Great power military/economic score label in diplomacy row.
  ///
  /// In en, this message translates to:
  /// **'Power: {score}'**
  String diplomacy_panel_powerScore(int score);

  /// Line showing active subsidy to another faction.
  ///
  /// In en, this message translates to:
  /// **'Outgoing subsidy: £{amount}/turn to {target}'**
  String diplomacy_panel_outgoingSubsidy(int amount, String target);

  /// Pending grant aid line in diplomacy row.
  ///
  /// In en, this message translates to:
  /// **'Pending grant aid: £{amount} (resolves end of turn)'**
  String diplomacy_panel_pendingGrant(int amount);

  /// Pending subsidy line in diplomacy row.
  ///
  /// In en, this message translates to:
  /// **'Pending subsidy: £{amount}/turn (resolves end of turn)'**
  String diplomacy_panel_pendingSubsidy(int amount);

  /// Stock line for a commodity; change is empty or parenthesized delta.
  ///
  /// In en, this message translates to:
  /// **'{name}: {qty}{change}'**
  String production_commodityStock(String name, int qty, String change);

  /// Shows effective labour total in production panel.
  ///
  /// In en, this message translates to:
  /// **'Effective labour: {n}'**
  String production_effectiveLabour(int n);

  /// Recipe affordance line (max output and limiting factor label).
  ///
  /// In en, this message translates to:
  /// **'{max} · {limiting}'**
  String production_recipeAffordance(int max, String limiting);

  /// Total labour required vs effective in allocation panel.
  ///
  /// In en, this message translates to:
  /// **'Total labour: {required} / {effective}'**
  String production_totalLabour(int required, int effective);

  /// Warning when allocated labour exceeds effective labour.
  ///
  /// In en, this message translates to:
  /// **'Insufficient labour — production will be capped next turn'**
  String get production_labourInsufficient;

  /// Worker type and count in production panel.
  ///
  /// In en, this message translates to:
  /// **'{name}: {count}'**
  String production_workerCount(String name, int count);

  /// Ship type and hull count in fleet expansion tile.
  ///
  /// In en, this message translates to:
  /// **'{typeName}: {count}'**
  String naval_units_shipTypeCount(String typeName, int count);

  /// Bottom sheet title for assigning civilian work.
  ///
  /// In en, this message translates to:
  /// **'Assign work: {unitType}'**
  String civilian_assignWorkTitle(String unitType);

  /// Commodity name and stock quantity in train military dialog.
  ///
  /// In en, this message translates to:
  /// **'{name}: {qty}'**
  String trainMilitary_commodityAmount(String name, int qty);

  /// Treasury cost plus paper requirement for training civilians.
  ///
  /// In en, this message translates to:
  /// **'{treasury} + {paper} Paper'**
  String trainCivilians_costLine(String treasury, String paper);

  /// Bullet line for a tech prerequisite name.
  ///
  /// In en, this message translates to:
  /// **'• {name}'**
  String techTree_prerequisiteBullet(String name);

  /// Tech tree effect line for a regiment unlock from catalog data.
  ///
  /// In en, this message translates to:
  /// **'Unlocks regiment: {name}'**
  String techEffect_unlocksRegiment(String name);

  /// Tech tree effect line for a ship unlock from catalog data.
  ///
  /// In en, this message translates to:
  /// **'Unlocks ship: {name}'**
  String techEffect_unlocksShip(String name);

  /// Generic tech effect when no specific summary lines exist.
  ///
  /// In en, this message translates to:
  /// **'Improves {category} capabilities'**
  String techEffect_fallbackCategoryImprovement(String category);

  /// Tech tree category label (gathering).
  ///
  /// In en, this message translates to:
  /// **'Gathering'**
  String get techTree_categoryGathering;

  /// Tech tree category label (transport).
  ///
  /// In en, this message translates to:
  /// **'Transport'**
  String get techTree_categoryTransport;

  /// Tech tree category label (labour).
  ///
  /// In en, this message translates to:
  /// **'Labour'**
  String get techTree_categoryLabour;

  /// Tech tree category label (civilian).
  ///
  /// In en, this message translates to:
  /// **'Civilian'**
  String get techTree_categoryCivilian;

  /// Tech tree category label (diplomacy).
  ///
  /// In en, this message translates to:
  /// **'Diplomacy'**
  String get techTree_categoryDiplomacy;

  /// Tech tree category label (naval).
  ///
  /// In en, this message translates to:
  /// **'Naval'**
  String get techTree_categoryNaval;

  /// Tech tree category label (military).
  ///
  /// In en, this message translates to:
  /// **'Military'**
  String get techTree_categoryMilitary;

  /// Tech tree category label (new-world).
  ///
  /// In en, this message translates to:
  /// **'New World'**
  String get techTree_categoryNewWorld;

  /// Transfer list row showing item name and quantity.
  ///
  /// In en, this message translates to:
  /// **'{name} ({count})'**
  String transferList_rowCount(String name, int count);

  /// Placeholder hint in Widgetbook civilian panel story.
  ///
  /// In en, this message translates to:
  /// **'Tap button to open panel from bottom'**
  String get widgetbook_openPanelHint;

  /// Fleet row label with fleet id.
  ///
  /// In en, this message translates to:
  /// **'Fleet {id}'**
  String naval_fleetLabel(String id);

  /// Label for the player's home fleet.
  ///
  /// In en, this message translates to:
  /// **'Home Fleet'**
  String get naval_homeFleetLabel;

  /// Location sub-header combining local and region labels.
  ///
  /// In en, this message translates to:
  /// **'{label} — {region}'**
  String locationSection_headerLine(String label, String region);

  /// Title for split fleet dialog.
  ///
  /// In en, this message translates to:
  /// **'Split Fleet'**
  String get splitFleet_dialogTitle;

  /// Right column title in split fleet transfer list.
  ///
  /// In en, this message translates to:
  /// **'New Fleet'**
  String get splitFleet_newFleetTitle;

  /// Empty column label in split fleet transfer list.
  ///
  /// In en, this message translates to:
  /// **'No ships'**
  String get splitFleet_noShips;

  /// Confirm button label for split fleet dialog.
  ///
  /// In en, this message translates to:
  /// **'Confirm Split'**
  String get splitFleet_confirm;

  /// Footer total ship count in split fleet transfer list.
  ///
  /// In en, this message translates to:
  /// **'Total: {total} ships'**
  String splitFleet_totalShips(int total);

  /// Diplomacy list section heading.
  ///
  /// In en, this message translates to:
  /// **'Great Powers'**
  String get diplomacy_section_greatPowers;

  /// Diplomacy list section heading.
  ///
  /// In en, this message translates to:
  /// **'Minor Nations'**
  String get diplomacy_section_minorNations;

  /// Diplomacy list section heading.
  ///
  /// In en, this message translates to:
  /// **'Tribes'**
  String get diplomacy_section_tribes;

  /// One-word war state in diplomacy UI.
  ///
  /// In en, this message translates to:
  /// **'War'**
  String get diplomacy_relationState_war;

  /// One-word peace state in diplomacy UI.
  ///
  /// In en, this message translates to:
  /// **'Peace'**
  String get diplomacy_relationState_peace;

  /// Tech tree dialog effect line (techEffectSummary_advanced_hull_design_0).
  ///
  /// In en, this message translates to:
  /// **'Improves: Frigate — high intercept, moderate flee (patrol/blockade)'**
  String get techEffectSummary_advanced_hull_design_0;

  /// Tech tree dialog effect line (techEffectSummary_advanced_hull_design_1).
  ///
  /// In en, this message translates to:
  /// **'Unlocks: Clipper Ships and Paddlewheels hull paths'**
  String get techEffectSummary_advanced_hull_design_1;

  /// Tech tree dialog effect line (techEffectSummary_advanced_iron_working_0).
  ///
  /// In en, this message translates to:
  /// **'Improves: Ironclad armored steam combat hull'**
  String get techEffectSummary_advanced_iron_working_0;

  /// Tech tree dialog effect line (techEffectSummary_amalgamation_process_0).
  ///
  /// In en, this message translates to:
  /// **'Improves: Gold/silver extraction cap to 4'**
  String get techEffectSummary_amalgamation_process_0;

  /// Tech tree dialog effect line (techEffectSummary_amalgamation_process_1).
  ///
  /// In en, this message translates to:
  /// **'Prerequisite-only: catalog leaf; extraction-cap increase is the active benefit'**
  String get techEffectSummary_amalgamation_process_1;

  /// Tech tree dialog effect line (techEffectSummary_animal_husbandry_0).
  ///
  /// In en, this message translates to:
  /// **'Improves: Meat extraction cap to 3'**
  String get techEffectSummary_animal_husbandry_0;

  /// Tech tree dialog effect line (techEffectSummary_animal_husbandry_1).
  ///
  /// In en, this message translates to:
  /// **'Unlocks: Scientific Cattle Breeding (with University)'**
  String get techEffectSummary_animal_husbandry_1;

  /// Tech tree dialog effect line (techEffectSummary_animal_husbandry_2).
  ///
  /// In en, this message translates to:
  /// **'Enables: Military branches that require this tech'**
  String get techEffectSummary_animal_husbandry_2;

  /// Tech tree dialog effect line (techEffectSummary_apprentice_workers_0).
  ///
  /// In en, this message translates to:
  /// **'Enables: Apprentice tier (4x labour; consumes refined sugar)'**
  String get techEffectSummary_apprentice_workers_0;

  /// Tech tree dialog effect line (techEffectSummary_apprentice_workers_1).
  ///
  /// In en, this message translates to:
  /// **'Unlocks: University and Master Artisans'**
  String get techEffectSummary_apprentice_workers_1;

  /// Tech tree dialog effect line (techEffectSummary_banking_0).
  ///
  /// In en, this message translates to:
  /// **'Unlocks: Dynamite, Empire Building, Modern Military Funding'**
  String get techEffectSummary_banking_0;

  /// Tech tree dialog effect line (techEffectSummary_banking_1).
  ///
  /// In en, this message translates to:
  /// **'With Money Lending: extends research-phase treasury floor to −£1000'**
  String get techEffectSummary_banking_1;

  /// Tech tree dialog effect line (techEffectSummary_bayonet_0).
  ///
  /// In en, this message translates to:
  /// **'Unlocks: Needle Guns (with Industrial Funding + Early Rifles)'**
  String get techEffectSummary_bayonet_0;

  /// Tech tree dialog effect line (techEffectSummary_cigar_production_0).
  ///
  /// In en, this message translates to:
  /// **'Enables: Cigar luxury production for Journeyman-tier worker consumption'**
  String get techEffectSummary_cigar_production_0;

  /// Tech tree dialog effect line (techEffectSummary_cigar_production_1).
  ///
  /// In en, this message translates to:
  /// **'Unlocks: Trained Journeymen'**
  String get techEffectSummary_cigar_production_1;

  /// Tech tree dialog effect line (techEffectSummary_circular_saw_0).
  ///
  /// In en, this message translates to:
  /// **'Improves: Timber extraction cap to 4'**
  String get techEffectSummary_circular_saw_0;

  /// Tech tree dialog effect line (techEffectSummary_circular_saw_1).
  ///
  /// In en, this message translates to:
  /// **'Unlocks: Clipper Ships (with Advanced Hull Design)'**
  String get techEffectSummary_circular_saw_1;

  /// Tech tree dialog effect line (techEffectSummary_clipper_ships_0).
  ///
  /// In en, this message translates to:
  /// **'Improves: Late-era fast merchant Clipper cargo line'**
  String get techEffectSummary_clipper_ships_0;

  /// Tech tree dialog effect line (techEffectSummary_coal_mining_0).
  ///
  /// In en, this message translates to:
  /// **'Enables: Coal extraction (cap 1)'**
  String get techEffectSummary_coal_mining_0;

  /// Tech tree dialog effect line (techEffectSummary_coal_mining_1).
  ///
  /// In en, this message translates to:
  /// **'Unlocks: Square-set Timbering'**
  String get techEffectSummary_coal_mining_1;

  /// Tech tree dialog effect line (techEffectSummary_convoying_0).
  ///
  /// In en, this message translates to:
  /// **'Unlocks: Large Hulls (with Wind Saw Mill + Navigation)'**
  String get techEffectSummary_convoying_0;

  /// Tech tree dialog effect line (techEffectSummary_copper_and_tin_mining_0).
  ///
  /// In en, this message translates to:
  /// **'Improves: Copper/Tin extraction cap to 2'**
  String get techEffectSummary_copper_and_tin_mining_0;

  /// Tech tree dialog effect line (techEffectSummary_copper_and_tin_mining_1).
  ///
  /// In en, this message translates to:
  /// **'Unlocks: Large Copper and Tin Mines'**
  String get techEffectSummary_copper_and_tin_mining_1;

  /// Tech tree dialog effect line (techEffectSummary_copper_and_tin_mining_2).
  ///
  /// In en, this message translates to:
  /// **'Enables: Military branches that require this tech'**
  String get techEffectSummary_copper_and_tin_mining_2;

  /// Tech tree dialog effect line (techEffectSummary_cotton_gin_0).
  ///
  /// In en, this message translates to:
  /// **'Improves: Cotton extraction cap to 4'**
  String get techEffectSummary_cotton_gin_0;

  /// Tech tree dialog effect line (techEffectSummary_cotton_gin_1).
  ///
  /// In en, this message translates to:
  /// **'Prerequisite-only: catalog leaf; extraction-cap increase is the active benefit'**
  String get techEffectSummary_cotton_gin_1;

  /// Tech tree dialog effect line (techEffectSummary_cotton_planting_0).
  ///
  /// In en, this message translates to:
  /// **'Improves: Cotton extraction cap to 2'**
  String get techEffectSummary_cotton_planting_0;

  /// Tech tree dialog effect line (techEffectSummary_cotton_planting_1).
  ///
  /// In en, this message translates to:
  /// **'Unlocks: Large Cotton Plantations'**
  String get techEffectSummary_cotton_planting_1;

  /// Tech tree dialog effect line (techEffectSummary_cotton_weaving_0).
  ///
  /// In en, this message translates to:
  /// **'Enables: Cloth production from cotton'**
  String get techEffectSummary_cotton_weaving_0;

  /// Tech tree dialog effect line (techEffectSummary_cotton_weaving_1).
  ///
  /// In en, this message translates to:
  /// **'Prerequisite-only: catalog leaf; recipe unlock is the active benefit'**
  String get techEffectSummary_cotton_weaving_1;

  /// Tech tree dialog effect line (techEffectSummary_crop_rotation_0).
  ///
  /// In en, this message translates to:
  /// **'Unlocks: Sheep Ranching, Animal Husbandry, and Steppe Horsemen research paths'**
  String get techEffectSummary_crop_rotation_0;

  /// Tech tree dialog effect line (techEffectSummary_crucible_process_0).
  ///
  /// In en, this message translates to:
  /// **'Prerequisite-only: Steel chain for Bayonet, rifles, steam, and cannons'**
  String get techEffectSummary_crucible_process_0;

  /// Tech tree dialog effect line (techEffectSummary_crucible_process_1).
  ///
  /// In en, this message translates to:
  /// **'Unlocks: No regiment from this tech alone'**
  String get techEffectSummary_crucible_process_1;

  /// Tech tree dialog effect line (techEffectSummary_diplomatic_expertise_0).
  ///
  /// In en, this message translates to:
  /// **'Enables: Embassy overtures with Minor Nations'**
  String get techEffectSummary_diplomatic_expertise_0;

  /// Tech tree dialog effect line (techEffectSummary_diplomatic_expertise_1).
  ///
  /// In en, this message translates to:
  /// **'Enables: civilian work in embassy-linked Minor Nations'**
  String get techEffectSummary_diplomatic_expertise_1;

  /// Tech tree dialog effect line (techEffectSummary_diplomatic_expertise_2).
  ///
  /// In en, this message translates to:
  /// **'Unlocks: National Bureaucracy'**
  String get techEffectSummary_diplomatic_expertise_2;

  /// Tech tree dialog effect line (techEffectSummary_discovery_of_cotton_0).
  ///
  /// In en, this message translates to:
  /// **'Enables: Research when player has revealed cotton (discovery rule)'**
  String get techEffectSummary_discovery_of_cotton_0;

  /// Tech tree dialog effect line (techEffectSummary_discovery_of_cotton_1).
  ///
  /// In en, this message translates to:
  /// **'Unlocks: Cotton Planting and Cotton Weaving'**
  String get techEffectSummary_discovery_of_cotton_1;

  /// Tech tree dialog effect line (techEffectSummary_discovery_of_furs_0).
  ///
  /// In en, this message translates to:
  /// **'Enables: Research when player has revealed furs (discovery rule)'**
  String get techEffectSummary_discovery_of_furs_0;

  /// Tech tree dialog effect line (techEffectSummary_discovery_of_furs_1).
  ///
  /// In en, this message translates to:
  /// **'Unlocks: Improved Trapping Techniques and Hat Production'**
  String get techEffectSummary_discovery_of_furs_1;

  /// Tech tree dialog effect line (techEffectSummary_discovery_of_gems_or_diamonds_0).
  ///
  /// In en, this message translates to:
  /// **'Enables: Research when player has revealed and prospected gems/diamonds'**
  String get techEffectSummary_discovery_of_gems_or_diamonds_0;

  /// Tech tree dialog effect line (techEffectSummary_discovery_of_gems_or_diamonds_1).
  ///
  /// In en, this message translates to:
  /// **'Unlocks: Precious Stone Mining'**
  String get techEffectSummary_discovery_of_gems_or_diamonds_1;

  /// Tech tree dialog effect line (techEffectSummary_discovery_of_gold_or_silver_0).
  ///
  /// In en, this message translates to:
  /// **'Enables: Research when player has revealed and prospected gold/silver'**
  String get techEffectSummary_discovery_of_gold_or_silver_0;

  /// Tech tree dialog effect line (techEffectSummary_discovery_of_gold_or_silver_1).
  ///
  /// In en, this message translates to:
  /// **'Unlocks: Precious Metals Mining'**
  String get techEffectSummary_discovery_of_gold_or_silver_1;

  /// Tech tree dialog effect line (techEffectSummary_discovery_of_spices_0).
  ///
  /// In en, this message translates to:
  /// **'Enables: Research when player has revealed spices (discovery rule)'**
  String get techEffectSummary_discovery_of_spices_0;

  /// Tech tree dialog effect line (techEffectSummary_discovery_of_spices_1).
  ///
  /// In en, this message translates to:
  /// **'Unlocks: Improved Sea Routes'**
  String get techEffectSummary_discovery_of_spices_1;

  /// Tech tree dialog effect line (techEffectSummary_discovery_of_sugar_0).
  ///
  /// In en, this message translates to:
  /// **'Enables: Research when player has revealed sugar cane (discovery rule)'**
  String get techEffectSummary_discovery_of_sugar_0;

  /// Tech tree dialog effect line (techEffectSummary_discovery_of_sugar_1).
  ///
  /// In en, this message translates to:
  /// **'Unlocks: Sugar Planting and Sugar Refining'**
  String get techEffectSummary_discovery_of_sugar_1;

  /// Tech tree dialog effect line (techEffectSummary_discovery_of_tobacco_0).
  ///
  /// In en, this message translates to:
  /// **'Enables: Research when player has revealed tobacco (discovery rule)'**
  String get techEffectSummary_discovery_of_tobacco_0;

  /// Tech tree dialog effect line (techEffectSummary_discovery_of_tobacco_1).
  ///
  /// In en, this message translates to:
  /// **'Unlocks: Tobacco Planting and Cigar Production'**
  String get techEffectSummary_discovery_of_tobacco_1;

  /// Tech tree dialog effect line (techEffectSummary_dynamite_0).
  ///
  /// In en, this message translates to:
  /// **'Enables: Railroads on mountains'**
  String get techEffectSummary_dynamite_0;

  /// Tech tree dialog effect line (techEffectSummary_dynamite_1).
  ///
  /// In en, this message translates to:
  /// **'Unlocks: Safety Lamp, Geological Prospecting, Amalgamation Process'**
  String get techEffectSummary_dynamite_1;

  /// Tech tree dialog effect line (techEffectSummary_early_rifles_0).
  ///
  /// In en, this message translates to:
  /// **'Improves: Calivermen regiment upgrade path'**
  String get techEffectSummary_early_rifles_0;

  /// Tech tree dialog effect line (techEffectSummary_early_rifles_1).
  ///
  /// In en, this message translates to:
  /// **'Prerequisite for: Long Range Rifles, Scouting, and Needle Guns'**
  String get techEffectSummary_early_rifles_1;

  /// Tech tree dialog effect line (techEffectSummary_early_steam_engine_0).
  ///
  /// In en, this message translates to:
  /// **'Enables: Rail Builder and railroads on flat terrain'**
  String get techEffectSummary_early_steam_engine_0;

  /// Tech tree dialog effect line (techEffectSummary_early_steam_engine_1).
  ///
  /// In en, this message translates to:
  /// **'Unlocks: Later Steam Engine, Riverboats, Tobacco Industry'**
  String get techEffectSummary_early_steam_engine_1;

  /// Tech tree dialog effect line (techEffectSummary_efficient_extraction_of_copper_and_tin_0).
  ///
  /// In en, this message translates to:
  /// **'Improves: Copper/Tin extraction cap to 4'**
  String get techEffectSummary_efficient_extraction_of_copper_and_tin_0;

  /// Tech tree dialog effect line (techEffectSummary_efficient_extraction_of_copper_and_tin_1).
  ///
  /// In en, this message translates to:
  /// **'Prerequisite-only: catalog leaf; extraction-cap increase is the active benefit'**
  String get techEffectSummary_efficient_extraction_of_copper_and_tin_1;

  /// Tech tree dialog effect line (techEffectSummary_elite_military_training_0).
  ///
  /// In en, this message translates to:
  /// **'Improves: Grenadiers regiment upgrade path'**
  String get techEffectSummary_elite_military_training_0;

  /// Tech tree dialog effect line (techEffectSummary_empire_building_0).
  ///
  /// In en, this message translates to:
  /// **'Enables: Join Empire overture toward nearly-defeated Great Powers'**
  String get techEffectSummary_empire_building_0;

  /// Tech tree dialog effect line (techEffectSummary_empire_building_1).
  ///
  /// In en, this message translates to:
  /// **'Requires: Target owns ≤3 provinces and lost original capital'**
  String get techEffectSummary_empire_building_1;

  /// Tech tree dialog effect line (techEffectSummary_emplaced_siege_guns_0).
  ///
  /// In en, this message translates to:
  /// **'Improves: defender emplaced fort batteries to Siege Gun quality (final emplaced tier)'**
  String get techEffectSummary_emplaced_siege_guns_0;

  /// Tech tree dialog effect line (techEffectSummary_excessive_fur_harvesting_0).
  ///
  /// In en, this message translates to:
  /// **'Improves: Furs extraction cap to 4'**
  String get techEffectSummary_excessive_fur_harvesting_0;

  /// Tech tree dialog effect line (techEffectSummary_excessive_fur_harvesting_1).
  ///
  /// In en, this message translates to:
  /// **'Prerequisite-only: catalog leaf; extraction-cap increase is the active benefit'**
  String get techEffectSummary_excessive_fur_harvesting_1;

  /// Tech tree dialog effect line (techEffectSummary_explosives_0).
  ///
  /// In en, this message translates to:
  /// **'Improves: Musketeers regiment upgrade path'**
  String get techEffectSummary_explosives_0;

  /// Tech tree dialog effect line (techEffectSummary_explosives_1).
  ///
  /// In en, this message translates to:
  /// **'Prerequisite for: Elite Military Training'**
  String get techEffectSummary_explosives_1;

  /// Tech tree dialog effect line (techEffectSummary_extraction_of_precious_metals_0).
  ///
  /// In en, this message translates to:
  /// **'Improves: Gold/silver extraction cap to 3'**
  String get techEffectSummary_extraction_of_precious_metals_0;

  /// Tech tree dialog effect line (techEffectSummary_extraction_of_precious_metals_1).
  ///
  /// In en, this message translates to:
  /// **'Unlocks: Amalgamation Process (with Dynamite)'**
  String get techEffectSummary_extraction_of_precious_metals_1;

  /// Tech tree dialog effect line (techEffectSummary_field_artillery_tactics_0).
  ///
  /// In en, this message translates to:
  /// **'Improves: Light Artillery regiment upgrade path'**
  String get techEffectSummary_field_artillery_tactics_0;

  /// Tech tree dialog effect line (techEffectSummary_geological_prospecting_0).
  ///
  /// In en, this message translates to:
  /// **'Improves: Gems/diamonds extraction cap to 4'**
  String get techEffectSummary_geological_prospecting_0;

  /// Tech tree dialog effect line (techEffectSummary_geological_prospecting_1).
  ///
  /// In en, this message translates to:
  /// **'Prerequisite-only: catalog leaf; extraction-cap increase is the active benefit'**
  String get techEffectSummary_geological_prospecting_1;

  /// Tech tree dialog effect line (techEffectSummary_hat_production_0).
  ///
  /// In en, this message translates to:
  /// **'Enables: Fur hats luxury production for Master-tier worker consumption'**
  String get techEffectSummary_hat_production_0;

  /// Tech tree dialog effect line (techEffectSummary_hat_production_1).
  ///
  /// In en, this message translates to:
  /// **'Unlocks: Master Artisans'**
  String get techEffectSummary_hat_production_1;

  /// Tech tree dialog effect line (techEffectSummary_heavy_artillery_0).
  ///
  /// In en, this message translates to:
  /// **'Improves: Royal Artillery regiment upgrade path'**
  String get techEffectSummary_heavy_artillery_0;

  /// Tech tree dialog effect line (techEffectSummary_heavy_artillery_1).
  ///
  /// In en, this message translates to:
  /// **'Prerequisite for: High Grade Steel and Emplaced Siege Guns'**
  String get techEffectSummary_heavy_artillery_1;

  /// Tech tree dialog effect line (techEffectSummary_heavy_emplaced_artillery_0).
  ///
  /// In en, this message translates to:
  /// **'Improves: defender emplaced fort batteries to Heavy quality (Royal → Heavy line)'**
  String get techEffectSummary_heavy_emplaced_artillery_0;

  /// Tech tree dialog effect line (techEffectSummary_heavy_emplaced_artillery_1).
  ///
  /// In en, this message translates to:
  /// **'Prerequisite for: Emplaced Siege Guns'**
  String get techEffectSummary_heavy_emplaced_artillery_1;

  /// Tech tree dialog effect line (techEffectSummary_high_grade_steel_0).
  ///
  /// In en, this message translates to:
  /// **'Improves: Heavy Artillery regiment upgrade path'**
  String get techEffectSummary_high_grade_steel_0;

  /// Tech tree dialog effect line (techEffectSummary_horse_artillery_0).
  ///
  /// In en, this message translates to:
  /// **'Prerequisite for: Light Artillery Tactics'**
  String get techEffectSummary_horse_artillery_0;

  /// Tech tree dialog effect line (techEffectSummary_hussars_0).
  ///
  /// In en, this message translates to:
  /// **'Improves: Cossacks regiment upgrade path'**
  String get techEffectSummary_hussars_0;

  /// Tech tree dialog effect line (techEffectSummary_hussars_1).
  ///
  /// In en, this message translates to:
  /// **'Prerequisite for: Scouting'**
  String get techEffectSummary_hussars_1;

  /// Tech tree dialog effect line (techEffectSummary_improved_cavalry_tactics_0).
  ///
  /// In en, this message translates to:
  /// **'Prerequisite for: Hussars and Improved Cavalry Weapons'**
  String get techEffectSummary_improved_cavalry_tactics_0;

  /// Tech tree dialog effect line (techEffectSummary_improved_cavalry_weapons_0).
  ///
  /// In en, this message translates to:
  /// **'Improves: Harquebusiers regiment upgrade path'**
  String get techEffectSummary_improved_cavalry_weapons_0;

  /// Tech tree dialog effect line (techEffectSummary_improved_cavalry_weapons_1).
  ///
  /// In en, this message translates to:
  /// **'Prerequisite for: Repeating Cavalry Carbine'**
  String get techEffectSummary_improved_cavalry_weapons_1;

  /// Tech tree dialog effect line (techEffectSummary_improved_food_preservation_0).
  ///
  /// In en, this message translates to:
  /// **'Improves: Spices extraction cap to 4'**
  String get techEffectSummary_improved_food_preservation_0;

  /// Tech tree dialog effect line (techEffectSummary_improved_food_preservation_1).
  ///
  /// In en, this message translates to:
  /// **'Prerequisite-only: catalog leaf; extraction-cap increase is the active benefit'**
  String get techEffectSummary_improved_food_preservation_1;

  /// Tech tree dialog effect line (techEffectSummary_improved_infantry_tactics_0).
  ///
  /// In en, this message translates to:
  /// **'Improves: General cap floor to at least 3 (or National Bureaucracy)'**
  String get techEffectSummary_improved_infantry_tactics_0;

  /// Tech tree dialog effect line (techEffectSummary_improved_infantry_tactics_1).
  ///
  /// In en, this message translates to:
  /// **'Unlocks: Early Rifles (with Crucible Process)'**
  String get techEffectSummary_improved_infantry_tactics_1;

  /// Tech tree dialog effect line (techEffectSummary_improved_iron_weapons_0).
  ///
  /// In en, this message translates to:
  /// **'Unlocks: Bayonet (with Crucible Process)'**
  String get techEffectSummary_improved_iron_weapons_0;

  /// Tech tree dialog effect line (techEffectSummary_improved_sail_design_0).
  ///
  /// In en, this message translates to:
  /// **'Unlocks: Advanced Hull Design path (University + Privateering)'**
  String get techEffectSummary_improved_sail_design_0;

  /// Tech tree dialog effect line (techEffectSummary_improved_sea_routes_0).
  ///
  /// In en, this message translates to:
  /// **'Improves: Spices extraction cap to 2'**
  String get techEffectSummary_improved_sea_routes_0;

  /// Tech tree dialog effect line (techEffectSummary_improved_sea_routes_1).
  ///
  /// In en, this message translates to:
  /// **'Unlocks: Large Spice Plantations'**
  String get techEffectSummary_improved_sea_routes_1;

  /// Tech tree dialog effect line (techEffectSummary_improved_trapping_techniques_0).
  ///
  /// In en, this message translates to:
  /// **'Improves: Furs extraction cap to 2'**
  String get techEffectSummary_improved_trapping_techniques_0;

  /// Tech tree dialog effect line (techEffectSummary_improved_trapping_techniques_1).
  ///
  /// In en, this message translates to:
  /// **'Unlocks: Riverboats'**
  String get techEffectSummary_improved_trapping_techniques_1;

  /// Tech tree dialog effect line (techEffectSummary_industrial_funding_of_research_0).
  ///
  /// In en, this message translates to:
  /// **'Unlocks: Needle Guns, Repeating Cavalry Carbine, High Grade Steel, Advanced Iron Working (as prerequisite)'**
  String get techEffectSummary_industrial_funding_of_research_0;

  /// Tech tree dialog effect line (techEffectSummary_industrial_funding_of_research_1).
  ///
  /// In en, this message translates to:
  /// **'Improves: +20% effective RP (floor) for military and naval category research allocations'**
  String get techEffectSummary_industrial_funding_of_research_1;

  /// Tech tree dialog effect line (techEffectSummary_industrial_iron_mining_0).
  ///
  /// In en, this message translates to:
  /// **'Improves: Iron extraction cap to 4'**
  String get techEffectSummary_industrial_iron_mining_0;

  /// Tech tree dialog effect line (techEffectSummary_industrial_iron_mining_1).
  ///
  /// In en, this message translates to:
  /// **'Prerequisite-only: catalog leaf; extraction-cap increase is the active benefit'**
  String get techEffectSummary_industrial_iron_mining_1;

  /// Tech tree dialog effect line (techEffectSummary_industrial_machinery_0).
  ///
  /// In en, this message translates to:
  /// **'Unlocks: Explosives, Improved Cavalry Weapons, Industrial Funding of Research (as prerequisite)'**
  String get techEffectSummary_industrial_machinery_0;

  /// Tech tree dialog effect line (techEffectSummary_industrial_machinery_1).
  ///
  /// In en, this message translates to:
  /// **'Improves: ×0.75 multiplicative on per-land-battle attack treasury cost at combat resolution'**
  String get techEffectSummary_industrial_machinery_1;

  /// Tech tree dialog effect line (techEffectSummary_iron_mining_0).
  ///
  /// In en, this message translates to:
  /// **'Improves: Iron extraction cap to 2'**
  String get techEffectSummary_iron_mining_0;

  /// Tech tree dialog effect line (techEffectSummary_iron_mining_1).
  ///
  /// In en, this message translates to:
  /// **'Unlocks: Steam in Mining'**
  String get techEffectSummary_iron_mining_1;

  /// Tech tree dialog effect line (techEffectSummary_land_enclosure_0).
  ///
  /// In en, this message translates to:
  /// **'Improves: Grain extraction cap to 2'**
  String get techEffectSummary_land_enclosure_0;

  /// Tech tree dialog effect line (techEffectSummary_land_enclosure_1).
  ///
  /// In en, this message translates to:
  /// **'Unlocks: Seed Drill, Money Lending, and Organised Regiments'**
  String get techEffectSummary_land_enclosure_1;

  /// Tech tree dialog effect line (techEffectSummary_large_coal_mines_0).
  ///
  /// In en, this message translates to:
  /// **'Improves: Coal extraction cap to 3'**
  String get techEffectSummary_large_coal_mines_0;

  /// Tech tree dialog effect line (techEffectSummary_large_coal_mines_1).
  ///
  /// In en, this message translates to:
  /// **'Unlocks: Safety Lamp (with Dynamite)'**
  String get techEffectSummary_large_coal_mines_1;

  /// Tech tree dialog effect line (techEffectSummary_large_coal_mines_2).
  ///
  /// In en, this message translates to:
  /// **'Unlocks: Efficient Extraction of Copper & Tin'**
  String get techEffectSummary_large_coal_mines_2;

  /// Tech tree dialog effect line (techEffectSummary_large_copper_and_tin_mines_0).
  ///
  /// In en, this message translates to:
  /// **'Improves: Copper/Tin extraction cap to 3'**
  String get techEffectSummary_large_copper_and_tin_mines_0;

  /// Tech tree dialog effect line (techEffectSummary_large_copper_and_tin_mines_1).
  ///
  /// In en, this message translates to:
  /// **'Unlocks: Efficient Extraction of Copper & Tin (with Large Coal Mines)'**
  String get techEffectSummary_large_copper_and_tin_mines_1;

  /// Tech tree dialog effect line (techEffectSummary_large_copper_and_tin_mines_2).
  ///
  /// In en, this message translates to:
  /// **'Prerequisite for: Ship of the Line'**
  String get techEffectSummary_large_copper_and_tin_mines_2;

  /// Tech tree dialog effect line (techEffectSummary_large_cotton_plantations_0).
  ///
  /// In en, this message translates to:
  /// **'Improves: Cotton extraction cap to 3'**
  String get techEffectSummary_large_cotton_plantations_0;

  /// Tech tree dialog effect line (techEffectSummary_large_cotton_plantations_1).
  ///
  /// In en, this message translates to:
  /// **'Unlocks: Cotton Gin'**
  String get techEffectSummary_large_cotton_plantations_1;

  /// Tech tree dialog effect line (techEffectSummary_large_hulls_0).
  ///
  /// In en, this message translates to:
  /// **'Unlocks: Ship of the Line (with Large Copper and Tin Mines)'**
  String get techEffectSummary_large_hulls_0;

  /// Tech tree dialog effect line (techEffectSummary_large_precious_stone_mines_0).
  ///
  /// In en, this message translates to:
  /// **'Improves: Gems/diamonds extraction cap to 3'**
  String get techEffectSummary_large_precious_stone_mines_0;

  /// Tech tree dialog effect line (techEffectSummary_large_precious_stone_mines_1).
  ///
  /// In en, this message translates to:
  /// **'Unlocks: Geological Prospecting (with Dynamite); Modern Military Funding (with Banking and Modern Forts)'**
  String get techEffectSummary_large_precious_stone_mines_1;

  /// Tech tree dialog effect line (techEffectSummary_large_spice_plantations_0).
  ///
  /// In en, this message translates to:
  /// **'Improves: Spices extraction cap to 3'**
  String get techEffectSummary_large_spice_plantations_0;

  /// Tech tree dialog effect line (techEffectSummary_large_spice_plantations_1).
  ///
  /// In en, this message translates to:
  /// **'Unlocks: Improved Food Preservation'**
  String get techEffectSummary_large_spice_plantations_1;

  /// Tech tree dialog effect line (techEffectSummary_large_sugar_plantations_0).
  ///
  /// In en, this message translates to:
  /// **'Improves: Sugar cane extraction cap to 3'**
  String get techEffectSummary_large_sugar_plantations_0;

  /// Tech tree dialog effect line (techEffectSummary_large_sugar_plantations_1).
  ///
  /// In en, this message translates to:
  /// **'Unlocks: Sugar Industry'**
  String get techEffectSummary_large_sugar_plantations_1;

  /// Tech tree dialog effect line (techEffectSummary_large_tobacco_plantations_0).
  ///
  /// In en, this message translates to:
  /// **'Improves: Tobacco extraction cap to 3'**
  String get techEffectSummary_large_tobacco_plantations_0;

  /// Tech tree dialog effect line (techEffectSummary_large_tobacco_plantations_1).
  ///
  /// In en, this message translates to:
  /// **'Unlocks: Tobacco Industry'**
  String get techEffectSummary_large_tobacco_plantations_1;

  /// Tech tree dialog effect line (techEffectSummary_later_steam_engine_0).
  ///
  /// In en, this message translates to:
  /// **'Enables: Railroads on hills and swamps'**
  String get techEffectSummary_later_steam_engine_0;

  /// Tech tree dialog effect line (techEffectSummary_later_steam_engine_1).
  ///
  /// In en, this message translates to:
  /// **'Unlocks: Dynamite and Excessive Fur Harvesting'**
  String get techEffectSummary_later_steam_engine_1;

  /// Tech tree dialog effect line (techEffectSummary_light_artillery_tactics_0).
  ///
  /// In en, this message translates to:
  /// **'Improves: Horse Artillery regiment upgrade path'**
  String get techEffectSummary_light_artillery_tactics_0;

  /// Tech tree dialog effect line (techEffectSummary_light_artillery_tactics_1).
  ///
  /// In en, this message translates to:
  /// **'Prerequisite for: Field Artillery Tactics'**
  String get techEffectSummary_light_artillery_tactics_1;

  /// Tech tree dialog effect line (techEffectSummary_long_range_rifles_0).
  ///
  /// In en, this message translates to:
  /// **'Improves: Skirmishers regiment upgrade path'**
  String get techEffectSummary_long_range_rifles_0;

  /// Tech tree dialog effect line (techEffectSummary_master_artisans_0).
  ///
  /// In en, this message translates to:
  /// **'Enables: Master tier (8x labour; consumes fur hats)'**
  String get techEffectSummary_master_artisans_0;

  /// Tech tree dialog effect line (techEffectSummary_master_artisans_1).
  ///
  /// In en, this message translates to:
  /// **'Unlocks: Banking, Nationalism, Scientific Cattle Breeding'**
  String get techEffectSummary_master_artisans_1;

  /// Tech tree dialog effect line (techEffectSummary_merchant_companies_0).
  ///
  /// In en, this message translates to:
  /// **'Enables: Merchant civilian unit construction'**
  String get techEffectSummary_merchant_companies_0;

  /// Tech tree dialog effect line (techEffectSummary_merchant_companies_1).
  ///
  /// In en, this message translates to:
  /// **'Enables: purchase_land in Minor Nations/Tribes (requires embassy, not at war)'**
  String get techEffectSummary_merchant_companies_1;

  /// Tech tree dialog effect line (techEffectSummary_merchant_companies_2).
  ///
  /// In en, this message translates to:
  /// **'Unlocks: Trade Fairs'**
  String get techEffectSummary_merchant_companies_2;

  /// Tech tree dialog effect line (techEffectSummary_merchant_steamships_0).
  ///
  /// In en, this message translates to:
  /// **'Enables: Steam-powered merchant hull for seagoing trade'**
  String get techEffectSummary_merchant_steamships_0;

  /// Tech tree dialog effect line (techEffectSummary_mine_engineering_0).
  ///
  /// In en, this message translates to:
  /// **'Enables: Builder upgrades to Fort Level 2'**
  String get techEffectSummary_mine_engineering_0;

  /// Tech tree dialog effect line (techEffectSummary_mine_engineering_1).
  ///
  /// In en, this message translates to:
  /// **'Unlocks: Iron Mining, Copper and Tin Mining, and Coal Mining'**
  String get techEffectSummary_mine_engineering_1;

  /// Tech tree dialog effect line (techEffectSummary_modern_forts_0).
  ///
  /// In en, this message translates to:
  /// **'Enables: Builder fort upgrades to level 3 (Modern: 3 emplaced guns, strongest walls)'**
  String get techEffectSummary_modern_forts_0;

  /// Tech tree dialog effect line (techEffectSummary_modern_forts_1).
  ///
  /// In en, this message translates to:
  /// **'Unlocks: Heavy Artillery and Modern Military Funding (as prerequisite)'**
  String get techEffectSummary_modern_forts_1;

  /// Tech tree dialog effect line (techEffectSummary_modern_military_funding_0).
  ///
  /// In en, this message translates to:
  /// **'Unlocks: Field Artillery Tactics, High Grade Steel, Elite Military Training stack'**
  String get techEffectSummary_modern_military_funding_0;

  /// Tech tree dialog effect line (techEffectSummary_modern_military_funding_1).
  ///
  /// In en, this message translates to:
  /// **'Improves: ×0.85 multiplicative on per-land-battle attack treasury cost (stacks with Industrial Machinery)'**
  String get techEffectSummary_modern_military_funding_1;

  /// Tech tree dialog effect line (techEffectSummary_moldboard_plow_0).
  ///
  /// In en, this message translates to:
  /// **'Improves: Grain extraction cap to 4'**
  String get techEffectSummary_moldboard_plow_0;

  /// Tech tree dialog effect line (techEffectSummary_moldboard_plow_1).
  ///
  /// In en, this message translates to:
  /// **'Terminal tech: nothing else in the catalog requires this'**
  String get techEffectSummary_moldboard_plow_1;

  /// Tech tree dialog effect line (techEffectSummary_money_lending_0).
  ///
  /// In en, this message translates to:
  /// **'Enables: Research-phase treasury floor to -500'**
  String get techEffectSummary_money_lending_0;

  /// Tech tree dialog effect line (techEffectSummary_money_lending_1).
  ///
  /// In en, this message translates to:
  /// **'Prerequisite for: University, National Bureaucracy'**
  String get techEffectSummary_money_lending_1;

  /// Tech tree dialog effect line (techEffectSummary_money_lending_2).
  ///
  /// In en, this message translates to:
  /// **'Deferred: General borrowing/interest not simulated yet'**
  String get techEffectSummary_money_lending_2;

  /// Tech tree dialog effect line (techEffectSummary_national_bureaucracy_0).
  ///
  /// In en, this message translates to:
  /// **'Enables: Builder upgrade_town work order'**
  String get techEffectSummary_national_bureaucracy_0;

  /// Tech tree dialog effect line (techEffectSummary_national_bureaucracy_1).
  ///
  /// In en, this message translates to:
  /// **'Improves: General cap floor to at least 3'**
  String get techEffectSummary_national_bureaucracy_1;

  /// Tech tree dialog effect line (techEffectSummary_national_bureaucracy_2).
  ///
  /// In en, this message translates to:
  /// **'Unlocks: Propaganda'**
  String get techEffectSummary_national_bureaucracy_2;

  /// Tech tree dialog effect line (techEffectSummary_nationalism_0).
  ///
  /// In en, this message translates to:
  /// **'Improves: Battle deployment base limit to 12 regiments (vs 10)'**
  String get techEffectSummary_nationalism_0;

  /// Tech tree dialog effect line (techEffectSummary_nationalism_1).
  ///
  /// In en, this message translates to:
  /// **'Improves: General cap floor to at least 4'**
  String get techEffectSummary_nationalism_1;

  /// Tech tree dialog effect line (techEffectSummary_nationalism_2).
  ///
  /// In en, this message translates to:
  /// **'Unlocks: Empire Building (with Banking)'**
  String get techEffectSummary_nationalism_2;

  /// Tech tree dialog effect line (techEffectSummary_navigation_0).
  ///
  /// In en, this message translates to:
  /// **'Unlocks: Large Hulls and Privateering Companies'**
  String get techEffectSummary_navigation_0;

  /// Tech tree dialog effect line (techEffectSummary_needle_guns_0).
  ///
  /// In en, this message translates to:
  /// **'Improves: Regulars regiment upgrade path'**
  String get techEffectSummary_needle_guns_0;

  /// Tech tree dialog effect line (techEffectSummary_needle_guns_1).
  ///
  /// In en, this message translates to:
  /// **'Prerequisite for: Elite Military Training'**
  String get techEffectSummary_needle_guns_1;

  /// Tech tree dialog effect line (techEffectSummary_organised_regiments_0).
  ///
  /// In en, this message translates to:
  /// **'Improves: General cap floor to at least 2'**
  String get techEffectSummary_organised_regiments_0;

  /// Tech tree dialog effect line (techEffectSummary_organised_regiments_1).
  ///
  /// In en, this message translates to:
  /// **'Unlocks: Improved Iron/Infantry/Weapon Craftsmanship doctrine paths'**
  String get techEffectSummary_organised_regiments_1;

  /// Tech tree dialog effect line (techEffectSummary_paddlewheels_0).
  ///
  /// In en, this message translates to:
  /// **'Unlocks: Merchant Steamships (with Riverboats)'**
  String get techEffectSummary_paddlewheels_0;

  /// Tech tree dialog effect line (techEffectSummary_precious_metals_mining_0).
  ///
  /// In en, this message translates to:
  /// **'Improves: Gold/silver extraction cap to 2'**
  String get techEffectSummary_precious_metals_mining_0;

  /// Tech tree dialog effect line (techEffectSummary_precious_metals_mining_1).
  ///
  /// In en, this message translates to:
  /// **'Unlocks: Extraction of Precious Metals'**
  String get techEffectSummary_precious_metals_mining_1;

  /// Tech tree dialog effect line (techEffectSummary_precious_stone_mining_0).
  ///
  /// In en, this message translates to:
  /// **'Improves: Gems/diamonds extraction cap to 2'**
  String get techEffectSummary_precious_stone_mining_0;

  /// Tech tree dialog effect line (techEffectSummary_precious_stone_mining_1).
  ///
  /// In en, this message translates to:
  /// **'Unlocks: Large Precious Stone Mines (with Modern Forts)'**
  String get techEffectSummary_precious_stone_mining_1;

  /// Tech tree dialog effect line (techEffectSummary_printing_press_0).
  ///
  /// In en, this message translates to:
  /// **'Unlocks: Trained Journeymen, University, and military doctrine paths'**
  String get techEffectSummary_printing_press_0;

  /// Tech tree dialog effect line (techEffectSummary_printing_press_1).
  ///
  /// In en, this message translates to:
  /// **'Prerequisite-only: unlock paths only; no direct economy modifier'**
  String get techEffectSummary_printing_press_1;

  /// Tech tree dialog effect line (techEffectSummary_privateering_companies_0).
  ///
  /// In en, this message translates to:
  /// **'Improves: Patrol/Blockade interception and trade-raid effectiveness'**
  String get techEffectSummary_privateering_companies_0;

  /// Tech tree dialog effect line (techEffectSummary_privateering_companies_1).
  ///
  /// In en, this message translates to:
  /// **'Unlocks: Advanced Hull Design (frigate doctrine prerequisite)'**
  String get techEffectSummary_privateering_companies_1;

  /// Tech tree dialog effect line (techEffectSummary_propaganda_0).
  ///
  /// In en, this message translates to:
  /// **'Improves: Diplomatic protest war penalty against aggressor (-10 -> -5)'**
  String get techEffectSummary_propaganda_0;

  /// Tech tree dialog effect line (techEffectSummary_propaganda_1).
  ///
  /// In en, this message translates to:
  /// **'Unlocks: Nationalism'**
  String get techEffectSummary_propaganda_1;

  /// Tech tree dialog effect line (techEffectSummary_recruit_steppe_horsemen_0).
  ///
  /// In en, this message translates to:
  /// **'Improves: Squires regiment upgrade path'**
  String get techEffectSummary_recruit_steppe_horsemen_0;

  /// Tech tree dialog effect line (techEffectSummary_recruit_steppe_horsemen_1).
  ///
  /// In en, this message translates to:
  /// **'Prerequisite for: Hussars'**
  String get techEffectSummary_recruit_steppe_horsemen_1;

  /// Tech tree dialog effect line (techEffectSummary_repeating_cavalry_carbine_0).
  ///
  /// In en, this message translates to:
  /// **'Improves: Cuirassiers regiment upgrade path'**
  String get techEffectSummary_repeating_cavalry_carbine_0;

  /// Tech tree dialog effect line (techEffectSummary_riverboats_0).
  ///
  /// In en, this message translates to:
  /// **'Improves: Furs extraction cap to 3'**
  String get techEffectSummary_riverboats_0;

  /// Tech tree dialog effect line (techEffectSummary_riverboats_1).
  ///
  /// In en, this message translates to:
  /// **'Unlocks: Excessive Fur Harvesting and Merchant Steamships research paths'**
  String get techEffectSummary_riverboats_1;

  /// Tech tree dialog effect line (techEffectSummary_road_construction_0).
  ///
  /// In en, this message translates to:
  /// **'Enables: Engineer road upgrades to transport level 2'**
  String get techEffectSummary_road_construction_0;

  /// Tech tree dialog effect line (techEffectSummary_road_construction_1).
  ///
  /// In en, this message translates to:
  /// **'Unlocks: Early Steam Engine'**
  String get techEffectSummary_road_construction_1;

  /// Tech tree dialog effect line (techEffectSummary_safety_lamp_0).
  ///
  /// In en, this message translates to:
  /// **'Improves: Coal extraction cap to 4'**
  String get techEffectSummary_safety_lamp_0;

  /// Tech tree dialog effect line (techEffectSummary_safety_lamp_1).
  ///
  /// In en, this message translates to:
  /// **'Terminal tech: nothing else in the catalog requires this'**
  String get techEffectSummary_safety_lamp_1;

  /// Tech tree dialog effect line (techEffectSummary_saw_mill_0).
  ///
  /// In en, this message translates to:
  /// **'Improves: Timber extraction cap to 2 (forested provinces)'**
  String get techEffectSummary_saw_mill_0;

  /// Tech tree dialog effect line (techEffectSummary_saw_mill_1).
  ///
  /// In en, this message translates to:
  /// **'Unlocks: Wind Saw Mill'**
  String get techEffectSummary_saw_mill_1;

  /// Tech tree dialog effect line (techEffectSummary_scientific_cattle_breeding_0).
  ///
  /// In en, this message translates to:
  /// **'Improves: Meat extraction cap to 4'**
  String get techEffectSummary_scientific_cattle_breeding_0;

  /// Tech tree dialog effect line (techEffectSummary_scientific_cattle_breeding_1).
  ///
  /// In en, this message translates to:
  /// **'Terminal tech: nothing else in the catalog requires this'**
  String get techEffectSummary_scientific_cattle_breeding_1;

  /// Tech tree dialog effect line (techEffectSummary_scientific_sheep_breeding_0).
  ///
  /// In en, this message translates to:
  /// **'Improves: Wool extraction cap to 3'**
  String get techEffectSummary_scientific_sheep_breeding_0;

  /// Tech tree dialog effect line (techEffectSummary_scientific_sheep_breeding_1).
  ///
  /// In en, this message translates to:
  /// **'Terminal tech: nothing else in the catalog requires this'**
  String get techEffectSummary_scientific_sheep_breeding_1;

  /// Tech tree dialog effect line (techEffectSummary_scouting_0).
  ///
  /// In en, this message translates to:
  /// **'Improves: Hussars regiment upgrade path'**
  String get techEffectSummary_scouting_0;

  /// Tech tree dialog effect line (techEffectSummary_seed_drill_0).
  ///
  /// In en, this message translates to:
  /// **'Improves: Grain extraction cap to 3'**
  String get techEffectSummary_seed_drill_0;

  /// Tech tree dialog effect line (techEffectSummary_seed_drill_1).
  ///
  /// In en, this message translates to:
  /// **'Unlocks: Moldboard Plow'**
  String get techEffectSummary_seed_drill_1;

  /// Tech tree dialog effect line (techEffectSummary_sheep_ranching_0).
  ///
  /// In en, this message translates to:
  /// **'Improves: Wool extraction cap to 2'**
  String get techEffectSummary_sheep_ranching_0;

  /// Tech tree dialog effect line (techEffectSummary_sheep_ranching_1).
  ///
  /// In en, this message translates to:
  /// **'Unlocks: Scientific Sheep Breeding'**
  String get techEffectSummary_sheep_ranching_1;

  /// Tech tree dialog effect line (techEffectSummary_ship_of_the_line_0).
  ///
  /// In en, this message translates to:
  /// **'Improves: Battle-line capital ship for decisive fleet engagements'**
  String get techEffectSummary_ship_of_the_line_0;

  /// Tech tree dialog effect line (techEffectSummary_ship_of_the_line_1).
  ///
  /// In en, this message translates to:
  /// **'Unlocks: Advanced Iron Working (with Industrial Funding + Paddlewheels)'**
  String get techEffectSummary_ship_of_the_line_1;

  /// Tech tree dialog effect line (techEffectSummary_siege_engineering_0).
  ///
  /// In en, this message translates to:
  /// **'Improves: Culverin regiment upgrade path'**
  String get techEffectSummary_siege_engineering_0;

  /// Tech tree dialog effect line (techEffectSummary_siege_engineering_1).
  ///
  /// In en, this message translates to:
  /// **'Prerequisite for: Modern Forts and Heavy Emplaced Artillery'**
  String get techEffectSummary_siege_engineering_1;

  /// Tech tree dialog effect line (techEffectSummary_square_set_timbering_0).
  ///
  /// In en, this message translates to:
  /// **'Improves: Coal extraction cap to 2'**
  String get techEffectSummary_square_set_timbering_0;

  /// Tech tree dialog effect line (techEffectSummary_square_set_timbering_1).
  ///
  /// In en, this message translates to:
  /// **'Unlocks: Large Coal Mines (requires Steam in Mining)'**
  String get techEffectSummary_square_set_timbering_1;

  /// Tech tree dialog effect line (techEffectSummary_square_set_timbering_2).
  ///
  /// In en, this message translates to:
  /// **'Prerequisite for: Early Steam Engine and Crucible Process'**
  String get techEffectSummary_square_set_timbering_2;

  /// Tech tree dialog effect line (techEffectSummary_steam_in_mining_0).
  ///
  /// In en, this message translates to:
  /// **'Improves: Iron extraction cap to 3'**
  String get techEffectSummary_steam_in_mining_0;

  /// Tech tree dialog effect line (techEffectSummary_steam_in_mining_1).
  ///
  /// In en, this message translates to:
  /// **'Unlocks: Large Coal Mines (with Square-set Timbering)'**
  String get techEffectSummary_steam_in_mining_1;

  /// Tech tree dialog effect line (techEffectSummary_steam_in_mining_2).
  ///
  /// In en, this message translates to:
  /// **'Prerequisite for: Industrial Iron Mining, Early Steam Engine, Crucible Process, Industrial Machinery'**
  String get techEffectSummary_steam_in_mining_2;

  /// Tech tree dialog effect line (techEffectSummary_sugar_industry_0).
  ///
  /// In en, this message translates to:
  /// **'Improves: Sugar cane extraction cap to 4'**
  String get techEffectSummary_sugar_industry_0;

  /// Tech tree dialog effect line (techEffectSummary_sugar_industry_1).
  ///
  /// In en, this message translates to:
  /// **'Prerequisite-only: catalog leaf; extraction-cap increase is the active benefit'**
  String get techEffectSummary_sugar_industry_1;

  /// Tech tree dialog effect line (techEffectSummary_sugar_planting_0).
  ///
  /// In en, this message translates to:
  /// **'Improves: Sugar cane extraction cap to 2'**
  String get techEffectSummary_sugar_planting_0;

  /// Tech tree dialog effect line (techEffectSummary_sugar_planting_1).
  ///
  /// In en, this message translates to:
  /// **'Unlocks: Large Sugar Plantations'**
  String get techEffectSummary_sugar_planting_1;

  /// Tech tree dialog effect line (techEffectSummary_sugar_refining_0).
  ///
  /// In en, this message translates to:
  /// **'Enables: Refined sugar luxury for Apprentice-tier worker consumption'**
  String get techEffectSummary_sugar_refining_0;

  /// Tech tree dialog effect line (techEffectSummary_sugar_refining_1).
  ///
  /// In en, this message translates to:
  /// **'Unlocks: Apprentice Workers (with Land Enclosure); Trade Fairs (with Merchant Companies)'**
  String get techEffectSummary_sugar_refining_1;

  /// Tech tree dialog effect line (techEffectSummary_superior_hull_design_0).
  ///
  /// In en, this message translates to:
  /// **'Unlocks: Improved Sail Design and Navigation hull paths'**
  String get techEffectSummary_superior_hull_design_0;

  /// Tech tree dialog effect line (techEffectSummary_tobacco_industry_0).
  ///
  /// In en, this message translates to:
  /// **'Improves: Tobacco extraction cap to 4'**
  String get techEffectSummary_tobacco_industry_0;

  /// Tech tree dialog effect line (techEffectSummary_tobacco_industry_1).
  ///
  /// In en, this message translates to:
  /// **'Prerequisite-only: catalog leaf; extraction-cap increase is the active benefit'**
  String get techEffectSummary_tobacco_industry_1;

  /// Tech tree dialog effect line (techEffectSummary_tobacco_planting_0).
  ///
  /// In en, this message translates to:
  /// **'Improves: Tobacco extraction cap to 2'**
  String get techEffectSummary_tobacco_planting_0;

  /// Tech tree dialog effect line (techEffectSummary_tobacco_planting_1).
  ///
  /// In en, this message translates to:
  /// **'Unlocks: Large Tobacco Plantations'**
  String get techEffectSummary_tobacco_planting_1;

  /// Tech tree dialog effect line (techEffectSummary_trade_fairs_0).
  ///
  /// In en, this message translates to:
  /// **'Enables: 6 commodity slots per embassy trade agreement (3 baseline without this tech)'**
  String get techEffectSummary_trade_fairs_0;

  /// Tech tree dialog effect line (techEffectSummary_trade_fairs_1).
  ///
  /// In en, this message translates to:
  /// **'Unlocks: Banking'**
  String get techEffectSummary_trade_fairs_1;

  /// Tech tree dialog effect line (techEffectSummary_trained_journeymen_0).
  ///
  /// In en, this message translates to:
  /// **'Enables: Journeyman tier (6x labour; consumes cigars)'**
  String get techEffectSummary_trained_journeymen_0;

  /// Tech tree dialog effect line (techEffectSummary_trained_journeymen_1).
  ///
  /// In en, this message translates to:
  /// **'Unlocks: Cotton Gin and Recruit Steppe Horsemen'**
  String get techEffectSummary_trained_journeymen_1;

  /// Tech tree dialog effect line (techEffectSummary_university_0).
  ///
  /// In en, this message translates to:
  /// **'Enables: Fourth active research slot (3 -> 4)'**
  String get techEffectSummary_university_0;

  /// Tech tree dialog effect line (techEffectSummary_university_1).
  ///
  /// In en, this message translates to:
  /// **'Unlocks: Master Artisans, Propaganda, Scientific Cattle Breeding'**
  String get techEffectSummary_university_1;

  /// Tech tree dialog effect line (techEffectSummary_weapon_craftsmanship_0).
  ///
  /// In en, this message translates to:
  /// **'Unlocks: Explosives and Grenadiers (with Industrial Machinery)'**
  String get techEffectSummary_weapon_craftsmanship_0;

  /// Tech tree dialog effect line (techEffectSummary_wind_saw_mill_0).
  ///
  /// In en, this message translates to:
  /// **'Improves: Timber extraction cap to 3'**
  String get techEffectSummary_wind_saw_mill_0;

  /// Tech tree dialog effect line (techEffectSummary_wind_saw_mill_1).
  ///
  /// In en, this message translates to:
  /// **'Unlocks: Circular Saw'**
  String get techEffectSummary_wind_saw_mill_1;

  /// Label for narrow-layout player turn event feed chip.
  ///
  /// In en, this message translates to:
  /// **'Events ({count})'**
  String playerTurnFeed_eventsChip(int count);

  /// Title for the narrow-layout player turn events dialog.
  ///
  /// In en, this message translates to:
  /// **'Events'**
  String get playerTurnFeed_eventsTitle;
}
