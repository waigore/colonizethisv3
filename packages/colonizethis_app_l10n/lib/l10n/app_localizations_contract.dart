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
  String get app_title;

  /// Top-level platform menu label for View menu.
  String get menu_view;

  /// Platform menu item label that navigates to the debug log viewer.
  String get menu_debugLog;

  /// Platform menu item label for toggling desktop startup maximization.
  String get menu_openMaximizedOnStartup;

  /// Main menu title text when not using the pixel-art logo.
  String get mainMenu_title;

  /// Small-caps eyebrow tagline shown above the title in the pixel-art editorial-monocle main menu variant.
  String get mainMenu_eyebrow;

  /// Subtitle shown on the main menu after the player has won their last game.
  String get mainMenu_subtitleAfterVictory;

  /// Main menu button label to start a new game.
  String get mainMenu_newGame;

  /// Main menu button label to continue from the auto-save slot.
  String get mainMenu_resumeGame;

  /// Main menu button label to load an existing game.
  String get mainMenu_loadGame;

  /// Main menu button label to open settings.
  String get mainMenu_settings;

  /// Main menu button label to quit the app.
  String get mainMenu_quit;

  /// Tooltip explaining why Load Game is disabled when there are no saves.
  String get mainMenu_noSavesTooltip;

  /// Pause menu option label to open the debug log screen.
  String get game_pauseMenu_debugLog;

  /// Pause menu modal title (SPEC/ui/pause-menu-panel.md, issue #2867 R30).
  String get game_pauseMenu_title;

  /// Pause menu option label to resume the game.
  String get game_pauseMenu_resume;

  /// Pause menu option label to save the current game.
  String get game_pauseMenu_saveGame;

  /// Pause menu option label to load a saved game.
  String get game_pauseMenu_loadGame;

  /// Pause menu option label to open the settings screen (disabled placeholder; backing flow not yet wired).
  String get game_pauseMenu_settings;

  /// Pause menu danger action label to exit the current game and return to the main menu.
  String get game_pauseMenu_exitToMainMenu;

  /// Tooltip for the pause menu button in the in-game UI.
  String get game_pauseMenu_tooltip;

  /// Title of the named save dialog (DLG70001).
  String get saveGameName_title;

  /// Confirm button on the named save dialog.
  String get saveGameName_save;

  /// Error when sanitizeGameId rejects the typed save name.
  String get saveGameName_invalidName;

  /// Overwrite confirmation body when sanitized gameId collides.
  String get saveGameName_overwriteConfirm;

  /// Confirm overwrite button on the named save dialog.
  String get saveGameName_overwrite;

  /// SnackBar message after a successful named save.
  String get saveGameName_gameSaved;

  /// Error when creating a new manual save at the 20-slot cap (Refs #3985).
  String get saveGameName_atCapError;

  /// Title of the load-game list dialog (DLG80001).
  String get loadGameList_title;

  /// Empty-state copy when listLoadableSaves returns no rows.
  String get loadGameList_empty;

  /// Second line of a load-list row: turn, calendar year, human nation.
  String loadGameList_metaLine(int turn, int year, String nation);

  /// Optional turn subtitle under a load-list row when year/nation are missing.
  String loadGameList_turnSubtitle(int turn);

  /// Discard confirmation when loading from an active pause session.
  String get loadGameList_discardConfirm;

  /// Confirm load button after discard confirmation.
  String get loadGameList_load;

  /// Per-row delete control on the load-game list (DLG80001).
  String get loadGameList_delete;

  /// Confirmation body before deleting a save from the load list.
  String get loadGameList_deleteConfirm;

  /// Pager control for the previous page of manual saves.
  String get loadGameList_previous;

  /// Pager control for the next page of manual saves.
  String get loadGameList_next;

  /// Pager label showing current manual-save page (1-based).
  String loadGameList_pageOf(int page, int pageCount);

  /// Badge above the pinned auto-save row in the load list.
  String get loadGameList_autoSaveBadge;

  /// Title used for the main game screen shell.
  String get game_screenTitle;

  /// Title of the dialog asking for confirmation before leaving the in-game shell.
  String get game_exitConfirm_title;

  /// Body text warning the player before exiting to main menu from in-game shell.
  String get game_exitConfirm_body;

  /// Button label that confirms leaving the in-game shell and navigating to main menu.
  String get game_exitConfirm_exit;

  /// Label for the Next Turn button showing current turn and year.
  String game_nextTurnButton(int turn, int year);

  /// Centered turn/year label in the in-game top bar.
  String game_turnDisplay(int turn, int year);

  /// Title of the dialog asking the user to confirm ending the current turn.
  String get game_nextTurnConfirm_title;

  /// Body text of the end-turn confirmation dialog.
  String game_nextTurnConfirm_body(int turn);

  /// Section header in the end-turn warning variant listing idle civilians.
  String get game_nextTurnConfirm_idleCiviliansSection;

  /// Per-row label in the end-turn idle-civilian warning list.
  String get game_nextTurnConfirm_noWorkOrder;

  /// Toggle label in the end-turn idle-civilian warning variant.
  String get game_nextTurnConfirm_dontShowAgain;

  /// Title of the modal shown while next-turn resolution runs.
  String get game_turnResolutionProcessingTitle;

  /// Snackbar text shown when turn resolution fails.
  String get game_turnResolutionFailedMessage;

  /// Generic 'No' button label.
  String get common_no;

  /// Generic 'Yes' button label.
  String get common_yes;

  /// Generic enabled state label.
  String get common_on;

  /// Generic disabled state label.
  String get common_off;

  /// Generic confirm button label.
  String get common_confirm;

  /// Generic combine action label.
  String get common_combine;

  /// Generic train action label.
  String get common_train;

  /// Generic move action label.
  String get common_move;

  /// Generic split action label.
  String get common_split;

  /// Generic locate action label.
  String get common_locate;

  /// Generic reset action label.
  String get common_reset;

  /// Dialog title for map display options.
  String get map_displayOptions_title;

  /// Toggle for province and sea-zone boundary strokes on the map (no ownership tint).
  String get map_displayOptions_showProvinceOverlay;

  /// Toggle for Great Power land ownership colour tint on the map.
  String get map_displayOptions_showProvinceOwnership;

  /// Toggle label for showing land province names on the map.
  String get map_displayOptions_showProvinceNames;

  /// Generic Close button label or tooltip.
  String get common_close;

  /// Tooltip for the side menu button in the map controls.
  String get gameMap_menuTooltip;

  /// Label for the Old World region tab.
  String get region_oldWorld;

  /// Label for the New World region tab.
  String get region_newWorld;

  /// Title of the debug log viewer screen and related actions.
  String get debugLog_title;

  /// Label for the package filter section in the debug log viewer.
  String get debugLog_filter_package;

  /// Label for the log level filter section in the debug log viewer.
  String get debugLog_filter_level;

  /// Intro text for the new-game setup dialog (nations + leaders).
  String get shell_leaderDialog_intro;

  /// Hint text for the leader dropdown in the leader selection dialog.
  String get shell_leaderDialog_selectLeaderHint;

  /// Label / hint for the per-AI-slot tuned AI profile dropdown in the
  /// new-game leader selection dialog.
  String get shell_leaderDialog_aiProfileLabel;

  /// Dropdown option label for the default (hardcoded personality) AI in the
  /// per-AI-slot tuned AI profile dropdown.
  String get shell_leaderDialog_aiProfileNormal;

  /// Inline label rendered beside the per-AI-slot tuned AI profile dropdown
  /// (mockup `.profile-line`).
  String get shell_leaderDialog_aiProfileInlineLabel;

  /// Slot heading for each player slot in the new-game setup dialog
  /// (mockup `.slot-label`).
  String shell_leaderDialog_slotLabel(int slotNumber);

  /// Tag appended to the human player's slot label. Rendered uppercase via
  /// presentation style (mockup `.you-tag` with text-transform:uppercase).
  String get shell_leaderDialog_slotYouTag;

  /// Generic Cancel button label.
  String get common_cancel;

  /// Prompt overlay text while map work-target tile selection mode is active.
  String get map_selectionMode_prompt;

  /// Lowercase inline cancel action label in the map work-target selection prompt overlay.
  String get map_selectionMode_cancel;

  /// Prompt overlay when choosing a Spy relocate destination on the map.
  String get map_selectionMode_relocatePrompt;

  /// Confirm dialog title when relocating the last Spy out of a foreign province.
  String get map_relocate_leaveIntel_title;

  /// Confirm dialog body when relocating the last Spy out of a foreign province.
  String get map_relocate_leaveIntel_message;

  /// Confirm button on leave-intel Spy relocate warning.
  String get map_relocate_leaveIntel_confirm;

  /// Cancel button on leave-intel Spy relocate warning.
  String get map_relocate_leaveIntel_cancel;

  /// Generic Start button label used when beginning a flow.
  String get common_start;

  /// Title of the new-game setup dialog (nations + leaders).
  String get shell_leaderDialog_title;

  /// Hint / picker title for the Great Power nation dropdown in the new-game setup dialog.
  String get shell_newGame_selectNation;

  /// Slot label for the human player in the new-game setup dialog.
  String shell_newGame_playerYou(int slotNumber);

  /// Slot label for an AI player in the new-game setup dialog.
  String shell_newGame_playerAi(int slotNumber);

  /// Label for the numeric seed field in the new-game leader dialog.
  String get shell_leaderDialog_seedLabel;

  /// Helper text explaining 0 vs fixed seed for the new-game leader dialog.
  String get shell_leaderDialog_seedHelper;

  /// Toggle label for infinite campaign mode in the new-game leader dialog.
  String get shell_leaderDialog_infiniteModeLabel;

  /// Helper text for infinite mode in the new-game leader dialog.
  String get shell_leaderDialog_infiniteModeHelper;

  String get shell_leaderDialog_advancedStartLabel;

  String get shell_leaderDialog_advancedStartNone;

  String get shell_leaderDialog_advancedStart50;

  String get shell_leaderDialog_advancedStart100;

  String get shell_leaderDialog_advancedStartDisabledHelper;

  /// Static slider label for terrain noise variation in the new-game leader
  /// dialog. The live percent value is rendered separately via
  /// [shell_leaderDialog_terrainVariationValue].
  String get shell_leaderDialog_terrainVariationLabel;

  /// Live terrain-variation percent value rendered beside the terrain
  /// variation label.
  String shell_leaderDialog_terrainVariationValue(int percent);

  /// Helper text under the terrain variation slider.
  String get shell_leaderDialog_terrainVariationHelper;

  /// Title of the read-only in-game game parameters dialog.
  String get gameParameters_title;

  /// Hamburger menu entry that opens the game parameters dialog.
  String get gameParameters_menuEntry;

  /// Row label prefix for infinite mode in the game parameters dialog.
  String get gameParameters_infiniteModeHeading;

  /// Infinite mode enabled value in the game parameters dialog.
  String get gameParameters_infiniteModeOn;

  /// Infinite mode disabled value in the game parameters dialog.
  String get gameParameters_infiniteModeOff;

  /// Infinite mode row in the game parameters dialog.
  String gameParameters_infiniteModeLine(String value);

  /// Title of the modal shown while a new game is being generated.
  String get shell_newGameProgress_title;

  /// Coarse progress step: Old World tile map.
  String get shell_newGameProgress_stepOldWorld;

  /// Coarse progress step: New World tile map.
  String get shell_newGameProgress_stepNewWorld;

  /// Coarse progress step: warp zones between regions.
  String get shell_newGameProgress_stepWarp;

  /// Coarse progress step: province assignment, capitals, units.
  String get shell_newGameProgress_stepBuildWorld;

  /// Coarse progress step: persisting game and map data.
  String get shell_newGameProgress_stepSave;

  /// Title of the error dialog when new-game setup fails.
  String get shell_newGameError_title;

  /// Button to retry new-game setup with a different random seed.
  String get shell_newGameError_retry;

  /// Title when the human must respond to an ally's call to arms.
  String get game_callToArms_title;

  /// Short explanation above the list of call-to-arms choices.
  String get game_callToArms_intro;

  /// One line per pending call to arms.
  String game_callToArms_prompt(String defender, String aggressor);

  /// Button: accept call to arms and enter war with the aggressor.
  String get game_callToArms_join;

  /// Button: refuse call to arms.
  String get game_callToArms_refuse;

  /// Submit all call-to-arms choices.
  String get game_callToArms_submit;

  /// Error banner when intervention Yarn fails to load.
  String game_intervention_loadError(String error);

  /// Explains degraded intervention flow when dialogue asset is missing.
  String get game_intervention_degradedHint;

  /// Advance intervention Yarn line or exit degraded error dialog.
  String get game_intervention_continue;

  /// Header showing which intervention prompt is active.
  String game_intervention_resolutionProgress(int current, int total);

  /// One-line summary of the war and which GP the player decides for.
  String game_intervention_situation(
    String aggressor,
    String defender,
    String intervening,
  );

  /// Plain situation strip on the intervention choice picker (Refs #4267).
  String game_intervention_choiceSituation(String aggressor, String defender);

  /// Muted hold-reason line when the intervening GP has an Embassy with the defender.
  String get game_intervention_holdReasonEmbassy;

  /// Muted hold-reason line when the intervening GP owns purchased land with the defender.
  String get game_intervention_holdReasonPurchasedLand;

  /// Muted hold-reason line when both Embassy and purchased land apply.
  String get game_intervention_holdReasonEmbassyAndPurchasedLand;

  /// First-order effect for Intervene on the choice picker.
  String game_intervention_effectIntervene(String aggressor, String defender);

  /// First-order effect for Do naught on the choice picker.
  String game_intervention_effectDoNothing(String aggressor, String defender);

  /// First-order effect for Diplomatic protest on the choice picker.
  String game_intervention_effectProtest(String aggressor, String defender);

  /// Button: military intervention on behalf of the defender.
  String get game_intervention_intervene;

  /// Button: decline to intervene.
  String get game_intervention_doNothing;

  /// Button: formal protest without military action.
  String get game_intervention_protest;

  /// Title rendered at the top of the intervention overlay's CtDialogShell on every phase (Yarn intro, situation, choice picker, reaction, and degraded error). Resolved by EditorialMonoclePalette.accent per SPEC/ui/screens/pending-intervention-overlay.md § Dark editorial-monocle chrome and issue #2867 R26b.
  String get game_intervention_overlayTitle;

  /// Turn-start news dialog title; turn is the current turn after resolution.
  String turnNews_title(int turn);

  /// Shown when the prior-turn digest has no lines.
  String get turnNews_empty;

  /// Button to dismiss the turn news dialog.
  String get turnNews_close;

  String turnNews_capture(String province, String prevOwner, String newOwner);

  String turnNews_war(String a, String b);

  String turnNews_peace(String a, String b);

  String turnNews_overture(String offerer, String target, String stage);

  String turnNews_provinceDiscovered(String province);

  String turnNews_seaDiscovered(String zone);

  /// Overture stage label.
  String get turnNews_stage_tradeConsulate;

  /// Overture stage label.
  String get turnNews_stage_embassy;

  /// Overture stage label.
  String get turnNews_stage_nap;

  /// Overture stage label.
  String get turnNews_stage_joinEmpire;

  /// Province panel: unit has no pending orders this turn.
  String get province_unitStatus_idle;

  /// Province panel: unit work in progress in world state.
  String get province_unitStatus_working;

  /// Work order target label in province panel.
  String get province_workOrder_explore;

  /// Work order target label in province panel.
  String get province_workOrder_prospect;

  /// Work order target label in province panel.
  String get province_workOrder_build_improvement;

  /// Work order target label in province panel.
  String get province_workOrder_upgrade_town;

  /// Work order target label in province panel.
  String get province_workOrder_build_road;

  /// Work order target label in province panel.
  String get province_workOrder_build_port;

  /// Work order target label in province panel.
  String get province_workOrder_build_fort;

  /// Work order target label in province panel.
  String get province_workOrder_build_rail;

  /// Work order target label in province panel.
  String get province_workOrder_steal_tech;

  /// Work order target label in province panel.
  String get province_workOrder_counter_spy;

  /// Work order target label in province panel.
  String get province_workOrder_purchase_land;

  String province_pending_armyMove(String destination);

  String province_pending_regimentMove(String destination);

  String province_pending_fleetMoveSea(String zone);

  String province_pending_fleetMovePort(String province);

  String province_pending_fleetMission(String mission);

  /// Naval mission label.
  String get province_fleetMission_none;

  /// Naval mission label.
  String get province_fleetMission_patrol;

  /// Naval mission label.
  String get province_fleetMission_blockade;

  /// Naval mission label.
  String get province_fleetMission_beachhead;

  /// Naval mission label.
  String get province_fleetMission_defend;

  /// Economic row suffix when tile can be improved.
  String get province_economic_improvableSuffix;

  String province_economic_withImprovement(String improvement);

  /// Regiment type display name.
  String get province_regiment_peasant_levies;

  /// Regiment type display name.
  String get province_regiment_pikemen;

  /// Regiment type display name.
  String get province_regiment_arquebusiers;

  /// Regiment type display name.
  String get province_regiment_bowmen;

  /// Regiment type display name.
  String get province_regiment_squires;

  /// Regiment type display name.
  String get province_regiment_knights;

  /// Regiment type display name.
  String get province_regiment_culverin;

  /// Regiment type display name.
  String get province_regiment_calivermen;

  /// Regiment type display name.
  String get province_regiment_halberdiers;

  /// Regiment type display name.
  String get province_regiment_musketeers;

  /// Regiment type display name.
  String get province_regiment_cossacks;

  /// Regiment type display name.
  String get province_regiment_lancers;

  /// Regiment type display name.
  String get province_regiment_harquebusiers;

  /// Regiment type display name.
  String get province_regiment_horse_artillery;

  /// Regiment type display name.
  String get province_regiment_royal_artillery;

  /// Regiment type display name.
  String get province_regiment_skirmishers;

  /// Regiment type display name.
  String get province_regiment_regulars;

  /// Regiment type display name.
  String get province_regiment_grenadiers;

  /// Regiment type display name.
  String get province_regiment_hussars;

  /// Regiment type display name.
  String get province_regiment_cuirassiers;

  /// Regiment type display name.
  String get province_regiment_light_artillery;

  /// Regiment type display name.
  String get province_regiment_heavy_artillery;

  /// Regiment type display name.
  String get province_regiment_sharpshooters;

  /// Regiment type display name.
  String get province_regiment_rifle_infantry;

  /// Regiment type display name.
  String get province_regiment_guards;

  /// Regiment type display name.
  String get province_regiment_scouts;

  /// Regiment type display name.
  String get province_regiment_carbine_cavalry;

  /// Regiment type display name.
  String get province_regiment_field_artillery;

  /// Regiment type display name.
  String get province_regiment_siege_guns;

  /// Ship type display name.
  String get province_ship_carrack;

  /// Ship type display name.
  String get province_ship_fluyte;

  /// Ship type display name.
  String get province_ship_sloop;

  /// Ship type display name.
  String get province_ship_trader;

  /// Ship type display name.
  String get province_ship_galleon;

  /// Ship type display name.
  String get province_ship_indiaman;

  /// Ship type display name.
  String get province_ship_frigate;

  /// Ship type display name.
  String get province_ship_raider;

  /// Ship type display name.
  String get province_ship_ship_of_the_line;

  /// Ship type display name.
  String get province_ship_clipper;

  /// Ship type display name.
  String get province_ship_merchant_steamship;

  /// Ship type display name.
  String get province_ship_ironclad;

  /// Quick battle action selector command points header.
  String quickBattle_commandPoints(int cp);

  /// Quick battle action label.
  String get quickBattle_action_volleyFire;

  /// Quick battle action label.
  String get quickBattle_action_defend;

  /// Quick battle action label.
  String get quickBattle_action_maneuver;

  /// Quick battle action label.
  String get quickBattle_action_fallBack;

  /// Quick battle action label.
  String get quickBattle_action_assault;

  /// Quick battle action button label with command point cost.
  String quickBattle_actionWithCost(String label, int cost);

  /// Combat mode dialog title for a province.
  String quickBattle_combatAt(String provinceName);

  /// Combat mode guidance for capital sieges.
  String get quickBattle_capitalSiegeQuickBattleOnly;

  /// Combat mode choice prompt.
  String get quickBattle_chooseCombatMode;

  /// Combat mode button label.
  String get quickBattle_autoResolve;

  /// Combat mode button label.
  String get quickBattle_quickBattle;

  /// Quick battle winner line when attacker wins.
  String quickBattle_attackerWins(String name);

  /// Quick battle winner line when defender holds.
  String quickBattle_defenderHolds(String name);

  /// Quick battle winner line for tie exhaustion state.
  String get quickBattle_mutualExhaustion;

  /// Quick battle result heading.
  String quickBattle_battleResult(String winnerText);

  /// Quick battle note when province ownership flips.
  String get quickBattle_provinceCaptured;

  /// Quick battle casualties summary line.
  String quickBattle_casualties(String name, int count);

  /// Quick battle result dialog close button label.
  String get quickBattle_ok;

  /// Quick battle screen heading with current and max rounds.
  String quickBattle_round(int round, int maxRounds);

  /// Quick battle auto resolve button label.
  String get quickBattle_resolveAuto;

  /// Fallback attacker label in quick battle UI.
  String get quickBattle_attackerDefaultName;

  /// Fallback defender label in quick battle UI.
  String get quickBattle_defenderDefaultName;

  /// Error shown when intro dialogue fails to load.
  String game_intro_loadError(String error);

  /// Display-font title shown above the brass divider in the dark editorial-monocle game start intro overlay (SHEL/OVL10001).
  String get gameStartIntroOverlay_title;

  /// Display-font title for the tribe first-contact herald overlay (OVL80001).
  String get tribeFirstContactOverlay_title;

  /// Error shown when the tribe first-contact herald (OVL80001) Yarn dialogue fails to load.
  String tribeFirstContactOverlay_loadError(String error);

  /// Error shown when overture dialogue fails to load.
  String game_overture_loadError(String error);

  /// Title for overture decisions panel.
  String get game_overture_title;

  /// Overture panel intro text.
  String get game_overture_intro;

  /// One-line overture offer summary.
  String game_overture_offerLine(String offerer, String stage);

  /// Accept overture button label.
  String get game_overture_accept;

  /// Reject overture button label.
  String get game_overture_reject;

  /// Victory type label.
  String get victory_military;

  /// Victory sentence with winner and turn number.
  String victory_winnerOnTurn(String winner, int turn);

  /// Victory overlay button label.
  String get victory_returnToMainMenu;

  /// Victory overlay button label.
  String get victory_viewFinalState;

  /// Victory panel: Old World province count win condition.
  String victory_conditionsMilitaryThreshold(int threshold);

  /// Victory panel: calendar campaign end condition copy.
  String get victory_conditionsCalendarEnd;

  /// Victory panel: infinite mode condition note.
  String get victory_conditionsInfiniteMode;

  /// Victory panel end banner when a province-count winner is set.
  String victory_endProvinceCountWin(String winner, int turn);

  /// Victory panel end banner when calendar halt names a declared winner.
  String victory_endCalendarDeclaredWinner(String winner);

  /// Victory panel end banner when calendar halt ties declared winner.
  String get victory_endCalendarNoWinner;

  /// Victory panel expanded row: calendar-end comparison intro.
  String get victory_powerBreakdownIntro;

  /// Victory panel expanded row: province component total.
  String victory_powerBreakdownProvinces(int count);

  /// Victory panel expanded row: regiment component total.
  String victory_powerBreakdownRegiments(int strength);

  /// Victory panel expanded row: ship component total.
  String victory_powerBreakdownShips(int count);

  /// Victory panel expanded row: combined calendar-end total.
  String victory_powerBreakdownTotal(int total);

  /// Victory standings row: Old World province count suffix.
  String victory_standingOwCount(int count);

  /// Victory standings row: progress label toward military OW threshold.
  String victory_standingOwProgress(int count, int threshold);

  /// Victory standings section helper linking colours to minimap selection.
  String get victory_standingsHelper;

  /// Header label for player-owned province destinations in move army dialog.
  String get moveArmy_groupYourProvinces;

  /// Header label for unowned province destinations in move army dialog.
  String get moveArmy_groupUnowned;

  /// Section header for other-owned invasion destinations in move army dialog
  /// (#2867 R6).
  String get moveArmy_groupInvasionTargets;

  /// Invasion row trigger label in danger italic (#2867 R8).
  String moveArmy_declareWarOnTrigger(String ownerLabel);

  /// Confirm dialog title for the destructive war-confirmation sub-dialog when
  /// an invasion army move is requested (issue #2867 R9).
  String get moveArmy_invadeProvinceTitle;

  /// Confirm dialog text for hostile army movement.
  String moveArmy_invadeProvinceBody(String ownerLabel);

  /// Confirm action label for hostile army movement.
  String get moveArmy_declareWarAndMove;

  /// Move army dialog title with army id.
  String moveArmy_title(String armyId);

  /// Empty-state text for move army dialog.
  String get moveArmy_noValidDestinations;

  /// Field label for destination province picker in move army dialog.
  String get moveArmy_destinationProvince;

  /// Own force size line on move army dialog body (#4216).
  String moveArmy_yourArmyRegiments(int count);

  /// Draft invasion count vs generals on invasion destinations (#4233).
  String moveArmy_invasionsThisTurn(int invasions, int generals);

  /// Soft warning when staged invasions exceed general count (#4233).
  String get moveArmy_invasionOverGeneralCapacityWarning;

  /// Combat-capable defender total on invasion row when full military intel (#4216).
  String moveArmy_defendersRegiments(int count);

  /// Invasion row cue when full intel shows zero combat-capable defenders (#4216).
  String get moveArmy_unopposedCapture;

  /// Invasion row cue when full military intel is unavailable (#4216).
  String get moveArmy_defendersUnknown;

  /// Fort level 0 label on invasion row under full military intel (#4216).
  String get moveArmy_fortOpenField;

  /// Fort level 1 siege label on invasion row (#4216).
  String get moveArmy_fortWoodSiege;

  /// Fort level 2 siege label on invasion row (#4216).
  String get moveArmy_fortStoneSiege;

  /// Fort level 3 siege label on invasion row (#4216).
  String get moveArmy_fortModernSiege;

  /// Move fleet dialog title.
  String moveFleet_title(String fleetLabel);

  /// Move fleet dialog title with destination count.
  String moveFleet_titleWithDestinations(String fleetLabel, int count);

  /// Empty-state message in move fleet dialog.
  String get moveFleet_noAdjacentSeaZones;

  /// Section heading for sea zone destinations in move fleet dialog.
  String get moveFleet_seaZonesSection;

  /// Section heading for dock destinations in move fleet dialog.
  String get moveFleet_provincesDockSection;

  /// Tooltip for locate action in move fleet dialog.
  String get moveFleet_locateOnMap;

  /// Suffix appended to same-region warp-zone sea destinations in move fleet dialog.
  String get moveFleet_warpLink;

  /// Suffix appended to cross-region sea-zone destinations in move fleet dialog.
  String moveFleet_warpLinkToRegion(String region);

  /// Military units panel title.
  String get military_units_title;

  /// Tooltip for deselecting all armies in military panel.
  String get military_units_deselectAllArmies;

  /// Tooltip for selecting all armies in military panel.
  String get military_units_selectAllArmies;

  /// Empty message in military units panel.
  String get military_units_empty;

  /// Generals roster count vs cap on Military Units panel (#4233).
  String military_units_generalsCount(int count, int cap);

  /// Per-general medal line on Military Units generals strip (#4233).
  String military_units_generalMedals(int index, int medals);

  /// Plain-language generals summary on Military Units panel (#4233).
  String get military_units_generalsPlainSummary;

  /// Details gloss for general medals on Military Units panel (#4233).
  String get military_units_generalsMedalGloss;

  /// Toggle to show general medal gloss on Military Units panel (#4233).
  String get military_units_generalsDetails;

  /// Collapse general medal gloss on Military Units panel (#4233).
  String get military_units_generalsHideDetails;

  /// Label for home army.
  String get military_units_homeArmy;

  /// Label for numbered army.
  String military_units_army(String armyId);

  /// Army subtitle showing regiment count and location.
  String military_units_armySubtitle(int regiments, String location);

  /// Army subtitle showing regiment count, location, and a draft move line.
  String military_units_armySubtitleWithDraft(
    int regiments,
    String location,
    String draftLine,
  );

  /// Empty-state line for army with no regiments.
  String get military_units_noRegimentsAssigned;

  /// Type/count line used in military/naval row labels.
  String military_units_typeCount(String typeName, int count);

  /// Regiment subtitle row.
  String military_units_regimentSubtitle(String medals, String status);

  /// Status line label.
  String military_units_status(String status);

  /// Naval units panel title.
  String get naval_units_title;

  /// Tile-scoped naval units panel title.
  String get naval_units_title_tile;

  /// Tooltip for deselecting all fleets in naval panel.
  String get naval_units_deselectAllFleets;

  /// Tooltip for selecting all fleets in naval panel.
  String get naval_units_selectAllFleets;

  /// Empty message in naval units panel.
  String get naval_units_empty;

  /// Fleet summary total ships.
  String naval_units_totalShips(int count);

  /// Fleet strength summary line.
  String naval_units_strength(String value);

  /// Fleet summary warship count.
  String naval_units_warships(int count);

  /// Fleet summary merchant count.
  String naval_units_merchants(int count);

  /// Tooltip for fleet locate action.
  String get naval_units_locateFleet;

  /// Fleet mission label.
  String naval_units_mission(String mission);

  /// Fleet row and menu label for assigning a naval mission.
  String get naval_mission_assign;

  /// Naval mission context menu title.
  String naval_mission_menuTitle(String fleet);

  /// Title when multiple fleets share a map marker.
  String get naval_mission_selectFleetTitle;

  /// Removes staged naval mission draft for fleet.
  String get naval_mission_cancelPending;

  /// Draft naval mission line without province target.
  String naval_mission_pendingLine(String mission);

  /// Draft naval mission line with province target.
  String naval_mission_pendingLineWithTarget(String mission, String target);

  /// Blockade/beachhead target picker title.
  String naval_mission_selectTargetTitle(String mission);

  /// Empty naval mission menu when base gates fail.
  String get naval_mission_noMissionsAvailable;

  /// Empty target picker for blockade/beachhead.
  String get naval_mission_noTargetsAvailable;

  /// Plain-language effect line for Patrol mission row (DLG31001).
  String get naval_mission_effect_patrol;

  /// Plain-language effect line for Defend mission row (DLG31001).
  String get naval_mission_effect_defend;

  /// Plain-language effect line for Blockade mission row (DLG31001).
  String get naval_mission_effect_blockade;

  /// Plain-language effect line for Beachhead mission row (DLG31001).
  String get naval_mission_effect_beachhead;

  /// DLG31001 Sail / Move row label (Refs #4343).
  String get naval_mission_sail;

  /// Effect line for Sail / Move on DLG31001 (Refs #4343).
  String get naval_mission_effect_sail;

  /// Mission consequence caption on Blockade target picker (DLG31002).
  String get naval_mission_targetCaption_blockade;

  /// Mission consequence caption on Beachhead target picker (DLG31002).
  String get naval_mission_targetCaption_beachhead;

  /// Empty-state line for fleet with no ships.
  String get naval_units_noShipsInFleet;

  /// Cargo capacity line for home fleet.
  String naval_units_cargoCapacity(int capacity);

  /// Cargo capacity line for non-home fleet.
  String naval_units_cargoCapacityIfAssigned(int capacity);

  /// Inline qualifier appended to a fleet's location label when the
  /// fleet is docked at a port province. SPEC/ui/naval-units-panel.md
  /// R28.
  String get naval_units_locInPort;

  /// Inline qualifier appended to a fleet's location label when the
  /// fleet is in a sea zone. SPEC/ui/naval-units-panel.md R28.
  String get naval_units_locAtSea;

  /// Uppercase chip rendered next to the Home Fleet name in the naval
  /// units panel. SPEC/ui/naval-units-panel.md R26.
  String get naval_units_homeFleetChip;

  /// Role tag in the fleet expanded composition table for warship ship
  /// types (cargoHold == 0). SPEC/ui/naval-units-panel.md R29.
  String get naval_units_compositionRoleWarship;

  /// Role tag in the fleet expanded composition table for merchant
  /// ship types (cargoHold > 0). SPEC/ui/naval-units-panel.md R29.
  String get naval_units_compositionRoleMerchant;

  /// Count cell in the fleet expanded composition table, e.g. ×2.
  /// SPEC/ui/naval-units-panel.md R29.
  String naval_units_compositionCount(int count);

  /// Single-line composition summary rendered beneath the expanded
  /// fleet composition table. SPEC/ui/naval-units-panel.md R29.
  String naval_units_compositionSummary(int total, int warships, int merchants);

  /// Home-Fleet cargo capacity line rendered between the composition
  /// table and the summary in the expanded fleet view.
  /// SPEC/ui/naval-units-panel.md R29.
  String naval_units_cargoCapacityHolds(int capacity);

  /// Diplomacy dialog title for setting subsidy amount.
  String get diplomacy_setSubsidy;

  /// Diplomacy dialog title for granting aid amount.
  String get diplomacy_grantAid;

  /// Treasury and step line in diplomacy amount dialog.
  String diplomacy_treasuryStep(int treasury, int step);

  /// Subsidy percentage step line in the diplomacy amount dialog (subsidy mode
  /// is treasury-independent).
  String diplomacy_subsidyStep(int step);

  /// Currency amount display in diplomacy amount dialog.
  String diplomacy_currencyAmount(int amount);

  /// Validation text when treasury is below minimum adjustable amount.
  String diplomacy_treasuryBelowMinimum(int step);

  /// Train civilians dialog title.
  String get trainCivilians_title;

  /// Train military dialog title.
  String get trainMilitary_title;

  /// Regiment category: light infantry.
  String get trainMilitary_categoryLightInfantry;

  /// Regiment category: regular infantry.
  String get trainMilitary_categoryRegularInfantry;

  /// Regiment category: heavy infantry.
  String get trainMilitary_categoryHeavyInfantry;

  /// Regiment category: bowmen.
  String get trainMilitary_categoryBowmen;

  /// Regiment category: light cavalry.
  String get trainMilitary_categoryLightCavalry;

  /// Regiment category: spear cavalry.
  String get trainMilitary_categorySpearCavalry;

  /// Regiment category: heavy cavalry.
  String get trainMilitary_categoryHeavyCavalry;

  /// Regiment category: light artillery.
  String get trainMilitary_categoryLightArtillery;

  /// Regiment category: heavy artillery.
  String get trainMilitary_categoryHeavyArtillery;

  /// Combat-role gist for light infantry.
  String get trainMilitary_combatGistLightInfantry;

  /// Combat-role gist for regular infantry.
  String get trainMilitary_combatGistRegularInfantry;

  /// Combat-role gist for heavy infantry.
  String get trainMilitary_combatGistHeavyInfantry;

  /// Combat-role gist for bowmen.
  String get trainMilitary_combatGistBowmen;

  /// Combat-role gist for light cavalry.
  String get trainMilitary_combatGistLightCavalry;

  /// Combat-role gist for spear cavalry.
  String get trainMilitary_combatGistSpearCavalry;

  /// Combat-role gist for heavy cavalry.
  String get trainMilitary_combatGistHeavyCavalry;

  /// Combat-role gist for light artillery.
  String get trainMilitary_combatGistLightArtillery;

  /// Combat-role gist for heavy artillery.
  String get trainMilitary_combatGistHeavyArtillery;

  /// Ongoing food upkeep per turn on Train Military rows.
  String trainMilitary_foodUpkeepPerTurn(int count);

  /// Train naval dialog title.
  String get trainNaval_title;

  /// Merchant ship capability line on Train Naval rows.
  String trainNaval_merchantCargoHolds(int count);

  /// Warship combat-role gist for sloop, frigate, raider.
  String get trainNaval_warshipRoleFastInterceptor;

  /// Warship combat-role gist for ship_of_the_line, ironclad.
  String get trainNaval_warshipRoleBattleShip;

  /// Muted role and capability gist line on Train Naval rows.
  String trainNaval_roleCapabilityGist(String role, String capability);

  /// Error text when player has no capital in train dialogs.
  String get trainUnits_noCapital;

  /// Treasury summary line in train dialogs.
  String trainUnits_treasury(String value);

  /// Paper summary line in civilian train dialog.
  String trainUnits_paper(int value);

  /// Treasury label in the train-dialog boxed resource bar (value rendered separately in monospace).
  String get trainUnits_treasuryLabel;

  /// Paper label in the civilian train-dialog boxed resource bar (value rendered separately in monospace).
  String get trainUnits_paperLabel;

  /// Peasants summary line in military train dialog.
  String trainUnits_peasants(int value);

  /// Peasants label with a preformatted remaining/total value (e.g. '7 / 8')
  /// in the train military dialog resource bar.
  String trainUnits_peasantsValue(String value);

  /// Tooltip shown when hovering (desktop) or tapping (mobile) the treasury
  /// coin icon in a train-dialog unit-row cost summary.
  String get trainDialog_costTreasuryTooltip;

  /// Tooltip shown when hovering (desktop) or tapping (mobile) the peasant
  /// worker icon in a train-dialog unit-row cost summary.
  String get trainDialog_costPeasantsTooltip;

  /// Tooltip shown for a commodity resource icon in a train-dialog unit-row
  /// cost summary, combining the commodity display name and its category
  /// (e.g. 'Fabric (manufactured)').
  String trainDialog_costCommodityTooltip(String name, String category);

  /// Lowercase commodity-category name used in resource tooltips for
  /// CommodityCategory.food.
  String get commodityCategory_food;

  /// Lowercase commodity-category name used in resource tooltips for
  /// CommodityCategory.rawMaterial.
  String get commodityCategory_rawMaterial;

  /// Lowercase commodity-category name used in resource tooltips for
  /// CommodityCategory.manufactured.
  String get commodityCategory_manufactured;

  /// Lowercase commodity-category name used in resource tooltips for
  /// CommodityCategory.luxury.
  String get commodityCategory_luxury;

  /// Lowercase commodity-category name used in resource tooltips for
  /// CommodityCategory.riches.
  String get commodityCategory_riches;

  /// Lowercase commodity-category name used in resource tooltips for
  /// CommodityCategory.advanced.
  String get commodityCategory_advanced;

  /// Localized display name for commodity id `grain`.
  String get commodity_grain;

  /// Localized display name for commodity id `meat`.
  String get commodity_meat;

  /// Localized display name for commodity id `timber`.
  String get commodity_timber;

  /// Localized display name for commodity id `iron`.
  String get commodity_iron;

  /// Localized display name for commodity id `wool`.
  String get commodity_wool;

  /// Localized display name for commodity id `cotton`.
  String get commodity_cotton;

  /// Localized display name for commodity id `coal`.
  String get commodity_coal;

  /// Localized display name for commodity id `sugarCane`.
  String get commodity_sugarCane;

  /// Localized display name for commodity id `tobacco`.
  String get commodity_tobacco;

  /// Localized display name for commodity id `furs`.
  String get commodity_furs;

  /// Localized display name for commodity id `copper`.
  String get commodity_copper;

  /// Localized display name for commodity id `tin`.
  String get commodity_tin;

  /// Localized display name for commodity id `horses`.
  String get commodity_horses;

  /// Localized display name for commodity id `lumber`.
  String get commodity_lumber;

  /// Localized display name for commodity id `castIron`.
  String get commodity_castIron;

  /// Localized display name for commodity id `fabric`.
  String get commodity_fabric;

  /// Localized display name for commodity id `refinedSugar`.
  String get commodity_refinedSugar;

  /// Localized display name for commodity id `cigars`.
  String get commodity_cigars;

  /// Localized display name for commodity id `furHats`.
  String get commodity_furHats;

  /// Localized display name for commodity id `steel`.
  String get commodity_steel;

  /// Localized display name for commodity id `paper`.
  String get commodity_paper;

  /// Localized display name for commodity id `bronze`.
  String get commodity_bronze;

  /// Localized display name for commodity id `gold`.
  String get commodity_gold;

  /// Localized display name for commodity id `silver`.
  String get commodity_silver;

  /// Localized display name for commodity id `gems`.
  String get commodity_gems;

  /// Localized display name for commodity id `diamonds`.
  String get commodity_diamonds;

  /// Localized display name for commodity id `spices`.
  String get commodity_spices;


  /// Civilian units panel title.
  String get civilian_units_title;

  /// Tile-scoped civilian units panel title.
  String get civilian_units_title_tile;

  /// Action label for opening tile details from civilian panel.
  String get civilian_units_tile;

  /// Empty message in civilian units panel.
  String get civilian_units_empty;

  /// Unit status line in civilian unit row.
  String civilian_units_status(String status);

  /// Unit location line in civilian unit row.
  String civilian_units_location(String location);

  /// Assigned-work line in civilian unit row.
  String civilian_units_assignedTo(String target);

  /// Localized turn-count label for civilian assigned-work rows.
  String civilian_units_turns(int count);

  /// In-progress turn counter for civilian assigned-work rows.
  String civilian_units_turnProgress(String remaining, String total);

  /// Assign action button in civilian units panel.
  String get civilian_units_assign;

  /// Relocate action for idle Spy units in the civilian units panel.
  String get civilian_units_relocate;

  /// Spy status when idle in a foreign province holding presence intel.
  String civilian_units_spyStatus_holdingIntel(String province);

  /// Spy status when assigned or working counter-spy.
  String get civilian_units_spyStatus_counterEspionage;

  /// Spy status when idle on owned land with no mission.
  String get civilian_units_spyStatus_reserve;

  /// Pending Spy move order destination on the civilian units panel.
  String civilian_units_pendingRelocate(String location);

  /// Section header for purchased-land scopes in the Development panel.
  String get development_purchasedLand;

  /// Empty improvable row under a province scope in the Development panel.
  String get development_noImprovableResources;

  /// Overview warning when assign-time material costs cannot be met.
  String get development_materialsShortageForAssign;

  /// Overview idle civilian counts in the Development panel.
  String development_idleCivilians(int builders, int engineers);

  /// Overview section heading for Builders/Engineers with pending or in-progress work.
  String get development_assignedCiviliansHeading;

  /// Fallback when Development panel map data cannot be loaded.
  String get development_mapDataUnavailable;

  /// Disconnected-assign warn dialog title in the Development panel.
  String get development_disconnectedTitle;

  /// Disconnected-assign warn dialog body in the Development panel.
  String get development_disconnectedBody;

  /// Road-first action in the Development disconnected-assign dialog.
  String get development_roadFirst;

  /// Improve-anyway action in the Development disconnected-assign dialog.
  String get development_improveAnyway;

  /// Show-on-map action for an improvable commodity row in the Development panel.
  String get development_show;

  /// Improvable commodity count label in the Development panel.
  String development_improvableCount(int count, String name);

  /// Production commodity breakdown dialog title.
  String get production_breakdown_title;

  /// Commodity column heading in breakdown table.
  String get production_breakdown_commodity;

  /// Total column heading in breakdown table.
  String get production_breakdown_total;

  /// Phase heading in production breakdown table.
  String get production_breakdown_phase_pendingBuildCosts;

  /// Phase heading in production breakdown table.
  String get production_breakdown_phase_extraction;

  /// Phase heading in production breakdown table.
  String get production_breakdown_phase_richesToTreasury;

  /// Phase heading in production breakdown table.
  String get production_breakdown_phase_consumption;

  /// Phase heading in production breakdown table.
  String get production_breakdown_phase_production;

  /// Button label to open production commodity breakdown.
  String get production_breakdown;

  /// Production Allocation header button to open Industry Counsel.
  String get production_counsel;

  /// Accessibility label for allocation row counsel star.
  String production_industryCounselStarSemantic(String brief);

  /// Counsel screen Industry tab label.
  String get industryCounsel_tabIndustry;

  /// Counsel Industry tab empty state.
  String get industryCounsel_empty;

  /// Fallback title for produce counsel card.
  String get industryCounsel_title_produce;

  /// Title for produce recipe counsel card.
  String industryCounsel_title_produceRecipe(String commodity);

  /// Fallback title for train counsel card.
  String get industryCounsel_title_train;

  /// Title for train worker counsel card.
  String industryCounsel_title_trainWorker(String tier);

  /// Fallback title for feedstock counsel card.
  String get industryCounsel_title_feedstock;

  /// Title for feedstock unblock counsel card.
  String industryCounsel_title_unblockFeedstock(String commodity);

  /// Brief industry counsel reason for output shortage.
  String get industryCounsel_reason_outputShortage_brief;

  /// Detail industry counsel reason for output shortage.
  String get industryCounsel_reason_outputShortage_detail;

  /// Brief industry counsel reason for chain/luxury value.
  String get industryCounsel_reason_chainLuxury_brief;

  /// Detail industry counsel reason for chain/luxury value.
  String get industryCounsel_reason_chainLuxury_detail;

  /// Brief industry counsel reason for labour deficit.
  String get industryCounsel_reason_labourDeficit_brief;

  /// Detail industry counsel reason for labour deficit.
  String get industryCounsel_reason_labourDeficit_detail;

  /// Brief industry counsel reason for luxury shortage.
  String get industryCounsel_reason_luxuryShortage_brief;

  /// Detail industry counsel reason for luxury shortage.
  String get industryCounsel_reason_luxuryShortage_detail;

  /// Brief industry counsel reason for feedstock blocked.
  String get industryCounsel_reason_feedstockBlocked_brief;

  /// Detail industry counsel reason for feedstock blocked.
  String get industryCounsel_reason_feedstockBlocked_detail;

  /// Primary action on produce counsel cards.
  String get industryCounsel_action_applyProduceAllocation;

  /// Primary action on train counsel cards.
  String get industryCounsel_action_agreeTrain;

  /// Primary action on feedstock unblock counsel cards.
  String get industryCounsel_action_openDevelopment;

  /// Shown when train Agree fails re-validation.
  String get industryCounsel_trainAgreeFailed;

  /// Counsel screen Trade tab label.
  String get tradeCounsel_tabTrade;

  /// Counsel Trade tab empty state.
  String get tradeCounsel_empty;

  /// Replaces all staged trade orders with the counsel book.
  String get tradeCounsel_action_applyBook;

  /// Stages one counsel trade line.
  String get tradeCounsel_action_agree;

  /// Shown when trade counsel Apply/Agree fails validation.
  String get tradeCounsel_applyFailed;

  /// Trade counsel card title for a bid line.
  String tradeCounsel_title_bid(String commodity, int quantity);

  /// Trade counsel card title for an offer line.
  String tradeCounsel_title_offer(String commodity, int quantity);

  /// Brief trade counsel reason for surplus offers.
  String get tradeCounsel_reason_surplusAboveReserve_brief;

  /// Brief trade counsel reason for deficit bids.
  String get tradeCounsel_reason_industryShortage_brief;

  /// Brief trade counsel reason for F10 speculative bids.
  String get tradeCounsel_reason_speculativeInventory_brief;

  /// Counsel screen Military tab label.
  String get militaryCounsel_tabMilitary;

  /// Counsel Military tab empty state.
  String get militaryCounsel_empty;

  /// Stages one military counsel recommendation.
  String get militaryCounsel_action_agree;

  /// Shown when military train Agree fails re-validation.
  String get militaryCounsel_trainAgreeFailed;

  /// Shown when military invade Agree fails validation.
  String get militaryCounsel_invadeAgreeFailed;

  /// Fallback military train counsel card title.
  String get militaryCounsel_title_train;

  /// Military train counsel card title.
  String militaryCounsel_title_trainUnit(String unit, int count);

  /// Fallback military invade counsel card title.
  String get militaryCounsel_title_invade;

  /// Military invade counsel card title with army id.
  String militaryCounsel_title_invadeArmy(String army, String province);

  /// Owner line on invade counsel cards.
  String militaryCounsel_ownerLine(String owner);

  /// Train counsel cost line when no material inputs.
  String get militaryCounsel_cost_noMaterials;

  /// Train counsel affordability summary.
  String militaryCounsel_costSummary(int treasury, String materials, int peasants);

  /// Brief military counsel reason for train recommendations.
  String get militaryCounsel_reason_affordableTrain_brief;

  /// Brief military counsel reason for at-war invasions.
  String get militaryCounsel_reason_atWarInvasion_brief;

  /// Brief military counsel reason for declare-war invasions.
  String get militaryCounsel_reason_declareWarInvasion_brief;

  /// Accessibility label for Train Military dialog counsel star.
  String militaryCounsel_trainStarSemantic(String brief);

  /// Counsel screen Development tab label.
  String get developmentCounsel_tabDevelopment;

  /// Counsel Development tab empty state.
  String get developmentCounsel_empty;

  /// Stages one development counsel recommendation.
  String get developmentCounsel_action_agree;

  /// Shown when development Build port Agree fails re-validation.
  String get developmentCounsel_agreeFailed;

  /// Fallback development Build port counsel card title.
  String get developmentCounsel_title_buildPort;

  /// Development Build port counsel card title with location.
  String developmentCounsel_title_buildPortAt(String location);

  /// Brief development counsel reason for baseline coastal ports.
  String get developmentCounsel_reason_coastalPort_brief;

  /// Brief development counsel reason for resource-coast ports.
  String get developmentCounsel_reason_resourceCoast_brief;

  /// Brief development counsel reason for New World coastal ports.
  String get developmentCounsel_reason_newWorldCoast_brief;

  /// Brief development counsel reason for overseas-linkage ports.
  String get developmentCounsel_reason_overseasLinkage_brief;

  /// Development panel header button opening Development Counsel.
  String get development_counsel;

  /// Military Units panel header button opening Military Counsel.
  String get military_units_counsel;

  /// Trade Market header button opening Trade Counsel.
  String get tradeMarket_counsel;

  /// Accessibility label for Market row trade counsel star.
  String tradeMarket_tradeCounselStarSemantic(String brief);

  /// Compact chip on Market rows where the human holds first right of refusal.
  String get tradeMarket_firstRightChip;

  /// On-request help for the Market first-right chip.
  String get tradeMarket_firstRightTooltip;

  /// Market row previous-turn aggregate bid/offer volume line.
  String tradeMarket_lastTurnVolume(int bids, int offers);

  /// Tooltip on Market price cluster when a last-turn coin delta is shown.
  String get tradeMarket_priceMovedTooltip;

  /// Deal Book audit tag for first-right-of-refusal matches.
  String get tradeDealBook_matchTagFirstRight;

  /// Deal Book audit tag for favored-trading-partner matches.
  String get tradeDealBook_matchTagFavoredPartner;

  /// Deal Book subsection heading for last-turn overseas-profit credits.
  String get tradeDealBook_overseasProfitHeading;

  /// Single overseas-profit ledger row in Deal Book.
  String tradeDealBook_overseasProfitRow(
    String commodity,
    int quantity,
    int amount,
  );

  /// Player turn event feed line when overseas profit treasury was credited.
  String eventFeed_overseasProfitCredited(int amount, int count);

  /// Production panel subheader for available resources.
  String get production_available;

  /// Production panel category heading.
  String get production_food;

  /// Production panel category heading.
  String get production_rawMaterials;

  /// Production panel category heading.
  String get production_manufactured;

  /// Production panel category heading.
  String get production_workers;

  /// Worker label in production panel.
  String get production_workers_peasants;

  /// Worker label in production panel.
  String get production_workers_apprentices;

  /// Worker label in production panel.
  String get production_workers_journeymen;

  /// Worker label in production panel.
  String get production_workers_masters;

  /// Production panel subheader for allocation controls.
  String get production_allocation;

  /// Semantics and tooltip for production allocation minus control.
  String get production_allocationDecrementRecipe;

  /// Semantics and tooltip for production allocation plus control.
  String get production_allocationIncrementRecipe;

  /// Semantics and tooltip for production allocation maximize control.
  String get production_allocationMaximizeRecipe;

  /// Semantics and tooltip for production allocation clear control.
  String get production_allocationClearRecipe;

  /// Split army dialog title.
  String get splitArmy_title;

  /// Technology panel title with player display name.
  String technologyPanel_title(String playerName);

  /// Research slot count line in technology panel.
  String technologyPanel_researchSlotsCount(int slots);

  /// Technology panel section label for slot list.
  String get technologyPanel_researchSlots;

  /// Placeholder label for an empty research slot.
  String get technologyPanel_empty;

  /// Research slot title label.
  String technologyPanel_slot(int slot);

  /// Research slot subtitle with tech name, progress, and cost label.
  String technologyPanel_slotSubtitle(
    String name,
    int progress,
    String costLabel,
  );

  /// Empty-state subtitle when no tech is assigned to a slot.
  String get technologyPanel_noTechAssigned;

  /// Action label to open tech selection for a research slot.
  String get technologyPanel_chooseTech;

  /// Technology panel heading for researched techs.
  String technologyPanel_researched(int count);

  /// Technology panel empty-state text when no techs are researched.
  String get technologyPanel_noneYet;

  /// Technology panel section heading for active progress entries.
  String get technologyPanel_inProgress;

  /// Technology panel progress line for one tech.
  String technologyPanel_progressLine(String name, int points);

  /// Bottom-sheet empty-state when no selectable technologies exist.
  String get technologyPanel_noTechsAvailable;

  /// Section heading above the researched-techs chip grid (Refs #2864 S2).
  String get technologyPanel_researchedTechsHeading;

  /// Section heading above the slot cards (Refs #2864 S3).
  String get technologyPanel_researchSlotsHeading;

  /// Locked slot card header label (Refs #2864 S0/S3).
  String technologyPanel_lockedSlotLabel(int slot);

  /// Locked slot card body footnote (Refs #2864 S0/S3).
  String get technologyPanel_lockedSlotFootnote;

  /// Monospace RP progress label rendered next to the slot progress bar (Refs #2864 S3).
  String technologyPanel_slotRpProgress(int progress, int cost);

  /// Choose-tech dialog row subtitle (mono / muted) for a selectable technology.
  String technologyPanel_pickSubtitle(String era, String category, int cost);

  /// Title row of the Choose-tech dialog opened from a slot card.
  /// Uses an em dash between 'Choose Tech' and the slot number.
  String technologyPanel_chooseTechDialogTitle(int slot);

  /// Per-row Details control on the Choose-tech dialog (Refs #4222).
  String get technologyPanel_chooseTechDetails;

  /// Snackbar shown when a research slot assignment is removed.
  String get technologyPanel_slotCancelled;

  /// Title of the confirmation dialog shown before cancelling a slot with
  /// accrued research progress (Refs #3512).
  String get technologyPanel_cancelWarningTitle;

  /// Body of the confirmation dialog shown before cancelling a slot with
  /// accrued research progress (Refs #3512).
  String technologyPanel_cancelWarningMessage(String name, int points);

  /// Confirm-button label on the cancel-research forfeiture warning dialog
  /// (Refs #3512).
  String get technologyPanel_cancelWarningConfirm;

  /// Cancel-button label on the cancel-research forfeiture warning dialog
  /// (Refs #3512).
  String get technologyPanel_cancelWarningKeep;

  /// Slot funding toggle label for ResearchFundingLevel.none (Refs #3512).
  String get technologyPanel_fundingNone;

  /// Slot funding toggle label for ResearchFundingLevel.low (Refs #3512).
  String get technologyPanel_fundingLow;

  /// Slot funding toggle label for ResearchFundingLevel.medium (Refs #3512).
  String get technologyPanel_fundingMedium;

  /// Slot funding toggle label for ResearchFundingLevel.high (Refs #3512).
  String get technologyPanel_fundingHigh;

  /// Slot funding toggle label for ResearchFundingLevel.maximum (Refs #3512).
  String get technologyPanel_fundingMaximum;

  /// Green anticipated research-point delta shown on a slot card (Refs #3512).
  String technologyPanel_rpDeltaPreview(int rp);

  /// Treasury (gold) per-turn cost shown on a slot card that will spend gold
  /// next turn (Refs #3512).
  String technologyPanel_goldSpendPerTurn(int gold);

  /// Treasury (gold) per-turn cost shown greyed on a debt-blocked slot card
  /// (no spend occurs) (Refs #3512).
  String technologyPanel_goldNoSpendPerTurn(int gold);

  /// Title of the research-funding breakdown dialog (Refs #3512).
  String get technologyPanel_rpBreakdownTitle;

  /// Breakdown dialog row labelling the base RP for the funding level (Refs #3512).
  String technologyPanel_rpBreakdownBaseLabel(String funding);

  /// Breakdown dialog row labelling the Industrial Funding +20% bonus (Refs #3512).
  String get technologyPanel_rpBreakdownIndustrialLabel;

  /// Breakdown dialog row labelling the effective RP applied this turn (Refs #3512).
  String get technologyPanel_rpBreakdownEffectiveLabel;

  /// Breakdown dialog row labelling the per-turn treasury cost (Refs #3512).
  String get technologyPanel_rpBreakdownTreasuryLabel;

  /// Breakdown dialog note shown when the spend is debt-blocked (Refs #3512).
  String get technologyPanel_rpBreakdownDebtBlocked;

  /// Breakdown dialog note when blocked after earlier slots spent (Refs #4335).
  String get technologyPanel_rpBreakdownSequentialBlocked;

  /// Breakdown dialog residual treasury before this slot (Refs #4335).
  String technologyPanel_rpBreakdownResidualTreasury(int gold);

  /// Empire-wide research funding header when slots will spend (Refs #4335).
  String technologyPanel_researchTurnFundingSummary(int gold, int rp);

  /// Empire-wide research funding header empty state (Refs #4335).
  String get technologyPanel_researchTurnFundingEmpty;

  /// Gold row label when sequential-blocked (Refs #4335).
  String get technologyPanel_goldSequentialBlockedHint;

  /// Secondary gold-row hint on sequential-blocked slots (Refs #4335).
  String technologyPanel_goldCostAfterEarlierSlots(int gold);

  /// Monospace research-point value used in breakdown dialog rows (Refs #3512).
  String technologyPanel_rpValue(int rp);

  /// Treasury (gold) value used in the breakdown dialog treasury row (Refs #3512).
  String technologyPanel_goldValue(int gold);

  /// Tech tree empty-state text.
  String get techTree_noTechsInCatalog;

  /// Tech dialog subtitle showing era and category.
  String techTree_eraCategory(String era, String category);

  /// Tech cost display in research points.
  String techTree_researchPoints(int points);

  /// Tech dialog section heading for prerequisites.
  String get techTree_prerequisites;

  /// Tech dialog section heading for effects.
  String get techTree_effects;

  /// Tech tree legend title.
  String get techTree_legendTitle;

  /// Legend state label for researched techs.
  String get techTree_stateResearched;

  /// Legend state label for in-progress techs.
  String get techTree_stateInProgress;

  /// Legend state label for available techs.
  String get techTree_stateAvailable;

  /// Legend state label for locked techs.
  String get techTree_stateLocked;

  /// Tech description dialog section listing GPs that unlocked the tech.
  String get techTree_researchedBy;

  /// Tech tree legend entry explaining GP nation-color pennant indicators.
  String get techTree_legendGpPennants;

  /// Long-press modal title listing GPs that have unlocked a tech.
  String get techTree_researchersDialogTitle;

  /// Map debug/story toggle label for full map visibility.
  String get mapDebug_fullVisibility;

  /// Map debug/story toggle label for player-constrained visibility.
  String get mapDebug_playerConstrained;

  /// Map debug/story toggle label to hide province names.
  String get mapDebug_hideProvinceNames;

  /// Map debug/story compact toggle label to hide names.
  String get mapDebug_noNames;

  /// Widgetbook button label for enabled primary action sample.
  String get widgetbook_primaryAction;

  /// Widgetbook button label for disabled sample.
  String get widgetbook_disabled;

  /// Widgetbook button label for fixed-width sample.
  String get widgetbook_fixedWidth;

  /// Widgetbook placeholder when sample game has no players.
  String get widgetbook_noPlayers;

  /// Widgetbook app bar title for tech tree story.
  String get widgetbook_techTreeTitle;

  /// Widgetbook action label to open production breakdown demo dialog.
  String get widgetbook_openBreakdownDialog;

  /// Widgetbook placeholder text for game shell container in dialogue stories.
  String get widgetbook_gameShell;

  /// Bullet line item in tech-tree detail dialog.
  String techTree_bulletItem(String text);

  /// Obfuscated placeholder text shown when section intel is unavailable.
  String get provinceOverlay_unknown;

  /// Tile section prompt when no map tile is selected.
  String get provinceOverlay_clickTileForDetails;

  /// Tile section obfuscated coordinates row.
  String get provinceOverlay_tileCoordinatesUnknown;

  /// Tile section obfuscated terrain row.
  String get provinceOverlay_tileTerrainUnknown;

  /// Tile section obfuscated resource row.
  String get provinceOverlay_tileResourceUnknown;

  /// Tile section obfuscated prospecting row.
  String get provinceOverlay_tileProspectedUnknown;

  /// Tile section obfuscated improvement row.
  String get provinceOverlay_tileImprovementUnknown;

  /// Tile section obfuscated road/rail row.
  String get provinceOverlay_tileRoadUnknown;

  /// Tile section obfuscated civilian units row.
  String get provinceOverlay_tileCivilianUnitsUnknown;

  /// Tile section coordinates row.
  String provinceOverlay_tileCoordinates(int x, int y);

  /// Tile section terrain row.
  String provinceOverlay_tileTerrain(String terrain);

  /// Tile section designation line shown when the selected tile is the
  /// province town (and not a capital).
  String provinceOverlay_tileTownOf(String provinceName);

  /// Tile section designation line shown when the selected tile is a
  /// faction's capital tile.
  String provinceOverlay_tileCapitalOf(String provinceName, String factionName);

  /// Tile section resource label prefix before inline icon/name.
  String get provinceOverlay_tileResourcePrefix;

  /// Tile section prospecting state row.
  String provinceOverlay_tileProspected(String value);

  /// Tile section prospecting state value when the tile is prospectable and prospected by the human player.
  String get provinceOverlay_tileProspectedYes;

  /// Tile section prospecting state value when the tile is prospectable but not yet prospected by the human player.
  String get provinceOverlay_tileProspectedNo;

  /// Tooltip and semantics label for province tile prospect shortcut action.
  String get provinceOverlay_tileProspectWithExplorerTooltip;

  /// Tooltip and semantics label for province tile explore shortcut action.
  String get provinceOverlay_tileExploreWithExplorerTooltip;

  /// Tooltip shown on the disabled province tile Explore/Prospect inline actions
  /// when the issuing Great Power holds no Consulate (or higher) with the owning
  /// Minor/Tribe (Refs #3753 R4b).
  String get provinceOverlay_tileConsulateRequiredForExploreTooltip;

  /// Tooltip and semantics label for province tile build-improvement shortcut action.
  String get provinceOverlay_tileBuildImprovementTooltip;

  /// Enabled build-improvement shortcut tooltip with material cost hint (Refs #4262).
  String provinceOverlay_tileBuildImprovementTooltipWithCost(String costs);

  /// Disabled build-improvement shortcut when no Builder units exist.
  String get provinceOverlay_tileBuildImprovementDisabledNoBuilderTooltip;

  /// Disabled build-improvement shortcut when materials/treasury shortfall is primary.
  String provinceOverlay_tileBuildImprovementDisabledMaterialsTooltip(
    String reason,
  );

  /// Plain success copy when projected stockpile/treasury covers work cost (Refs #4262).
  String get workOrderAfford_canAfford;

  /// Material shortfall line for work-order assign previews (Refs #4262).
  String workOrderAfford_shortMaterial(String commodity, int quantity);

  /// Treasury shortfall line for purchase_land assign previews (Refs #4262).
  String workOrderAfford_shortTreasury(int amount);

  /// Tooltip and semantics label for province tile build-road shortcut action when enabled.
  String get provinceOverlay_tileBuildRoadTooltip;

  /// Enabled build-road shortcut tooltip including material cost summary.
  String provinceOverlay_tileBuildRoadTooltipWithCost(String costs);

  /// Disabled build-road shortcut tooltip when the human player has no Engineer units.
  String get provinceOverlay_tileBuildRoadDisabledNoEngineerTooltip;

  /// Disabled build-road shortcut tooltip when Engineers exist but none can legally assign build_road to this tile.
  String get provinceOverlay_tileBuildRoadDisabledTooltip;

  /// Disabled build-road shortcut when materials/treasury shortfall is primary reason.
  String provinceOverlay_tileBuildRoadDisabledMaterialsTooltip(String reason);

  /// Military section fort posture line (Refs #4280).
  String provinceOverlay_militaryFortStatus(String status);

  /// Tooltip for enabled build-fort shortcut on town tile.
  String get provinceOverlay_tileBuildFortTooltip;

  /// Enabled build-fort shortcut tooltip with material cost hint.
  String provinceOverlay_tileBuildFortTooltipWithCost(String costs);

  /// Disabled build-fort shortcut when no Engineer units exist.
  String get provinceOverlay_tileBuildFortDisabledNoEngineerTooltip;

  /// Disabled build-fort shortcut when no valid Engineer assignment exists.
  String get provinceOverlay_tileBuildFortDisabledTooltip;

  /// Disabled build-fort shortcut when materials or treasury are short.
  String provinceOverlay_tileBuildFortDisabledMaterialsTooltip(String reason);

  /// Tooltip for enabled build-port shortcut on coastal tile (Refs #4332).
  String get provinceOverlay_tileBuildPortTooltip;

  /// Enabled build-port shortcut tooltip with material cost hint.
  String provinceOverlay_tileBuildPortTooltipWithCost(String costs);

  /// Disabled build-port shortcut when no Engineer units exist.
  String get provinceOverlay_tileBuildPortDisabledNoEngineerTooltip;

  /// Disabled build-port shortcut when no valid Engineer assignment exists.
  String get provinceOverlay_tileBuildPortDisabledTooltip;

  /// Disabled build-port shortcut when materials or treasury are short.
  String provinceOverlay_tileBuildPortDisabledMaterialsTooltip(String reason);

  /// Plain-language port status when the province has no seaboard port.
  String get provinceOverlay_tilePortStatusNone;

  /// Plain-language port status when the province has a seaboard port.
  String get provinceOverlay_tilePortStatusPresent;

  /// Tooltip and semantics label for province tile purchase-land shortcut action.
  String get provinceOverlay_tilePurchaseLandTooltip;

  /// Enabled purchase-land shortcut tooltip with treasury cost hint (Refs #4274).
  String provinceOverlay_tilePurchaseLandTooltipWithCost(int amount);

  /// Disabled purchase-land shortcut when no Merchant units exist.
  String get provinceOverlay_tilePurchaseLandDisabledNoMerchantTooltip;

  /// Disabled purchase-land shortcut when embassy is missing or at war.
  String get provinceOverlay_tilePurchaseLandDisabledEmbassyTooltip;

  /// Disabled purchase-land shortcut when treasury shortfall is primary.
  String provinceOverlay_tilePurchaseLandDisabledTreasuryTooltip(int amount);

  /// Tile section improvement row.
  String provinceOverlay_tileImprovement(String value);

  /// Tile section road/rail row when not applicable.
  String get provinceOverlay_tileRoadNone;

  /// Tile section capital-link row when capital-connected (Refs #4149).
  String get provinceOverlay_tileCapitalLinkConnected;

  /// Tile section capital-link row when connected with path transport cap.
  String provinceOverlay_tileCapitalLinkConnectedWithPath(int level);

  /// Tile section capital-link row when not capital-connected (Refs #4149).
  String get provinceOverlay_tileCapitalLinkNotConnected;

  /// Tile section per-tile effective vs full extraction (Refs #4149).
  String provinceOverlay_tileExtractionFromTile(int effective, int full);

  /// Tile section road/rail primary numeric line on land tiles.
  String provinceOverlay_tileRoadTransportLevel(int level);

  /// Tile section road/rail supplementary GDD label for transport level 0.
  String get provinceOverlay_tileRoadLabelNone;

  /// Tile section road/rail supplementary GDD label for transport level 1.
  String get provinceOverlay_tileRoadLabelPrimitiveRoad;

  /// Tile section road/rail supplementary GDD label for transport level 2.
  String get provinceOverlay_tileRoadLabelImprovedRoad;

  /// Tile section road/rail supplementary GDD label for transport level 4.
  String get provinceOverlay_tileRoadLabelPortOrRailroad;

  /// Tile section road/rail supplementary GDD label for unexpected levels.
  String get provinceOverlay_tileRoadLabelNonStandard;

  /// Tile section road/rail level-1 gloss clarifying railroads are level 4.
  String get provinceOverlay_tileRoadRailGloss;

  /// Tile/Economic improvement type name for tiles with no resource (generic fallback).
  String get provinceOverlay_improvementGeneric;

  /// Tile/Economic improvement type name for grain resource tiles.
  String get provinceOverlay_improvementFarm;

  /// Tile/Economic improvement type name for meat/horses resource tiles.
  String get provinceOverlay_improvementRanch;

  /// Tile/Economic improvement type name for wool resource tiles.
  String get provinceOverlay_improvementPasture;

  /// Tile/Economic improvement type name for timber resource tiles.
  String get provinceOverlay_improvementLumberCamp;

  /// Tile/Economic improvement type name for plantation-crop resource tiles (sugar cane/tobacco/cotton/spices).
  String get provinceOverlay_improvementPlantation;

  /// Tile/Economic improvement type name for furs resource tiles.
  String get provinceOverlay_improvementFurPost;

  /// Tile/Economic improvement type name for mineral resource tiles (iron/copper/coal/silver/gold/etc.).
  String get provinceOverlay_improvementMine;

  /// Tile section civilian unit count row.
  String provinceOverlay_tileCivilianUnits(int count);

  /// Political section row for a sea-zone overlay.
  String provinceOverlay_seaZone(String name);

  /// Political section province name row.
  String provinceOverlay_name(String name);

  /// Political section owner row.
  String provinceOverlay_owner(String owner);

  /// Political section owner display name when a province/tile is unowned.
  String get provinceOverlay_ownerUnclaimed;

  /// Political section region row (Old World / New World label).
  String provinceOverlay_region(String region);

  /// Political section capital row when the province is the capital of its owning faction.
  String get provinceOverlay_capitalYes;

  /// Political section capital row when the province is not a faction capital.
  String get provinceOverlay_capitalNo;

  /// Political section town development row (integer 1–4). Refs #3870.
  String provinceOverlay_townDevelopment(int level);

  /// Political section town development summary (`N of max`). Refs #4316.
  String provinceOverlay_townDevelopmentOfMax(int level, int max);

  /// Political gist when town development is at maximum. Refs #4316.
  String get provinceOverlay_townDevelopmentGistMax;

  /// Political gist when manufacturing bonus is active (level 2). Refs #4316.
  String get provinceOverlay_townDevelopmentGistBonusActiveNextAt4;

  /// Political gist when next manufacturing bonus is at level 4. Refs #4316.
  String get provinceOverlay_townDevelopmentGistNextAt4;

  /// Political gist when next manufacturing bonus is at level 2. Refs #4316.
  String get provinceOverlay_townDevelopmentGistNextAt2;

  /// Political Upgrade town shortcut label. Refs #4316.
  String get provinceOverlay_upgradeTownAction;

  /// Political Upgrade town enabled tooltip. Refs #4316.
  String get provinceOverlay_politicalUpgradeTownTooltip;

  /// Political Upgrade town enabled tooltip with material cost. Refs #4316.
  String provinceOverlay_politicalUpgradeTownTooltipWithCost(String costs);

  /// Political Upgrade town disabled generic tooltip. Refs #4316.
  String get provinceOverlay_politicalUpgradeTownDisabledTooltip;

  /// Political Upgrade town disabled — no Builder tooltip. Refs #4316.
  String get provinceOverlay_politicalUpgradeTownDisabledNoBuilderTooltip;

  /// Political Upgrade town disabled — tech gate tooltip. Refs #4316.
  String get provinceOverlay_politicalUpgradeTownDisabledTechTooltip;

  /// Political Upgrade town disabled — materials shortfall tooltip. Refs #4316.
  String provinceOverlay_politicalUpgradeTownDisabledMaterialsTooltip(
    String shortfall,
  );

  /// MAP20001 Military Move control label. Refs #4350.
  String get provinceOverlay_moveArmyAction;

  /// MAP20001 Military Invade control label. Refs #4350.
  String provinceOverlay_invadeArmyAction(String provinceName);

  /// Disabled Move — Home Army cannot leave capital. Refs #4350.
  String get provinceOverlay_moveArmyDisabledHomeArmyTooltip;

  /// Disabled Move — no legal destinations for stationed field armies. Refs #4350.
  String get provinceOverlay_moveArmyDisabledNoDestinationsTooltip;

  /// Disabled Invade — no field army can reach this province (cache). Refs #4350.
  String get provinceOverlay_invadeArmyDisabledCannotReachTooltip;

  /// Multi-army picker title for overlay Move/Invade. Refs #4350.
  String get provinceOverlay_selectArmyTitle;

  /// Indented count line used in military summary lists.
  String provinceOverlay_indentedCount(String label, int count);

  /// Civilian section line for unit target or status (no internal unit id).
  String provinceOverlay_unitTarget(String type, String target);

  /// Civilian section line for foreign-unit status (no internal unit id).
  String provinceOverlay_foreignUnitStatus(
    String owner,
    String type,
    String status,
  );

  /// Naval section fleet summary line.
  String provinceOverlay_fleetSummary(
    String owner,
    String fleetLabel,
    String shipParts,
  );

  /// Province overlay section heading for political details.
  String get provinceOverlay_sectionPolitical;

  /// Province overlay section heading for tile details.
  String get provinceOverlay_sectionTile;

  /// Province overlay section heading for economic details.
  String get provinceOverlay_sectionEconomic;

  /// Subheading within the Economic section for town manufacturing bonus preview.
  String get provinceOverlay_townProductionHeading;

  /// Signed quantity for a projected town manufacturing bonus commodity row.
  String provinceOverlay_townProductionQuantity(int quantity);

  /// Subheading for Extraction condensed line (post-resolution projection).
  String get provinceOverlay_extractionHeading;

  /// Subheading for improvable Available condensed line.
  String get provinceOverlay_availableHeading;

  /// Full-yield Extraction commodity segment text.
  String provinceOverlay_extractionQuantity(int quantity, String name);

  /// Partial-yield Extraction commodity segment text.
  String provinceOverlay_extractionQuantityPartial(
    int effective,
    int full,
    String name,
  );

  /// Muted capital grain bonus annotation on the Extraction line.
  String provinceOverlay_extractionCapitalGrainBonus(int bonus);

  /// Muted reason when any Extraction commodity is below full yield (Refs #4150).
  String get provinceOverlay_extractionPartialReason;

  /// Available improvable tile-count commodity segment text.
  String provinceOverlay_availableTileCount(int count, String name);

  /// Province overlay section heading for military details.
  String get provinceOverlay_sectionMilitary;

  /// Province overlay section heading for civilian details.
  String get provinceOverlay_sectionCivilian;

  /// Province overlay section heading for naval details.
  String get provinceOverlay_sectionNaval;

  /// Province overlay header title shown above the tab strip for a province.
  String get provinceOverlay_titleProvince;

  /// Province overlay header title shown above the tab strip for a sea zone.
  String get provinceOverlay_titleSeaZone;

  /// Tooltip for cycling map base layer display.
  String get mapCorner_tooltipBaseLayer;

  /// Tooltip for centering the map on the home capital.
  String get mapCorner_tooltipCenterCapital;

  /// Tooltip for opening map display options.
  String get mapCorner_tooltipMapDisplayOptions;

  /// Cargo hold usage label on map controls (used and capacity are pre-formatted numbers or em dash).
  String mapControls_cargoHold(String used, String capacity);

  /// Hover tooltip for the tab-bar cargo hold indicator.
  String mapControls_cargoHold_tooltip(String used, String capacity);

  /// Semantics label for the tab-bar cargo hold indicator.
  String mapControls_cargoHold_semanticsLabel(String used, String capacity);

  /// Cargo details popover row for overseas extraction load.
  String mapControls_cargoHold_details_overseas(String used);

  /// Cargo details popover row for Home Fleet cargo capacity.
  String mapControls_cargoHold_details_capacity(String capacity);

  /// Cargo details popover row for trade-bid headroom.
  String mapControls_cargoHold_details_free(String free);

  /// Counsel line in the cargo details popover.
  String get mapControls_cargoHold_details_counsel;

  /// Tooltip for the in-game players bar show/hide toggle on the tab bar.
  String get mapControls_playersBarToggle;

  /// Percentage label with no space before percent sign.
  String common_percent(int value);

  /// Accessibility label and tooltip for region minimap zoom slider.
  String get regionMinimap_mapZoom;

  /// Semantics value for zoom slider (spoken).
  String regionMinimap_zoomSemanticsValue(int pct);

  /// Economic row in province overlay: terrain, localized resource name, and detail suffix.
  String province_economic_resourceRow(
    String terrain,
    String resourceName,
    String detail,
  );

  /// Heading for diplomatic event history on detail screen.
  String get diplomacy_detail_historyTitle;

  /// Empty state when there is no diplomatic history.
  String get diplomacy_detail_noEvents;

  /// History card subtitle with calendar year and turn number.
  String diplomacy_detail_yearTurn(int year, int turn);

  /// Heading for dossier section on diplomacy detail.
  String get diplomacy_detail_dossierTitle;

  /// Label above current diplomatic relation summary.
  String get diplomacy_detail_currentRelation;

  /// Empty state for dossier evidence list.
  String get diplomacy_detail_noDossier;

  /// Prefix for a dossier evidence line.
  String diplomacy_detail_turnEvidence(int turn);

  /// Empty diplomacy list before any factions are discovered.
  String get diplomacy_panel_noFactions;

  /// Placeholder copy under the Great Powers section heading when no Great
  /// Power has been discovered yet.
  String get diplomacy_panel_noGreatPowers;

  /// Placeholder copy under the Minor Nations section heading when no Minor
  /// Nation has been discovered yet.
  String get diplomacy_panel_noMinorNations;

  /// Placeholder copy under the Tribes section heading when no tribe has
  /// been contacted yet.
  String get diplomacy_panel_noTribes;

  /// Great power military/economic score label in diplomacy row.
  String diplomacy_panel_powerScore(int score);

  /// Muted prefix for the Great Power relative-power line.
  String get diplomacy_relativePower_label;

  /// Relative-power tier word for `−10 … +10` (roughly equal).
  String get diplomacy_relativePower_tierRoughlyEqual;

  /// Relative-power tier word for `+11 … +30` (superior).
  String get diplomacy_relativePower_tierSuperior;

  /// Relative-power tier word for `>= +31` (vastly superior).
  String get diplomacy_relativePower_tierVastlySuperior;

  /// Relative-power tier word for `−30 … −11` (inferior).
  String get diplomacy_relativePower_tierInferior;

  /// Relative-power tier word for `<= −31` (vastly inferior).
  String get diplomacy_relativePower_tierVastlyInferior;

  /// Tooltip explaining what the relative-power comparison measures.
  String get diplomacy_relativePower_tooltip;

  /// Screen-reader label combining the relative-power percentage and tier.
  String diplomacy_relativePower_semantics(String pct, String tier);

  /// Line showing active subsidy to another faction.
  String diplomacy_panel_outgoingSubsidy(int amount, String target);

  /// Pending grant aid line in diplomacy row.
  String diplomacy_panel_pendingGrant(int amount);

  /// Pending subsidy line in diplomacy row.
  String diplomacy_panel_pendingSubsidy(int amount);

  /// Expands the per-faction diplomacy row to show disabled actions with
  /// inline refusal reasons.
  String get diplomacy_panel_moreActions;

  /// Collapses the expanded per-faction diplomacy action cluster back to the
  /// ready shortlist.
  String get diplomacy_panel_fewerActions;

  /// Accessibility label for a disabled diplomacy action shown under More with
  /// an inline refusal reason.
  String diplomacy_actionRejection_semanticsLabel(String action, String reason);

  /// Stock line for a commodity; change is empty or parenthesized delta.
  String production_commodityStock(String name, int qty, String change);

  /// Shows effective labour total in production panel.
  String production_effectiveLabour(int n);

  /// Labour readiness total on Production Available panel.
  String production_labourThisTurn(int n);

  /// Primary labour-readiness reason when food is the main shortfall.
  String get production_labourReasonFood;

  /// Labour-readiness reason when military/navy food draw contributes.
  String get production_labourReasonFoodWithMilitary;

  /// Primary labour-readiness reason when luxury is the main shortfall.
  String production_labourReasonLuxury(String commodity);

  /// Toggle to expand per-tier labour readiness breakdown.
  String get production_labourDetails;

  /// Per-tier labour readiness detail row.
  String production_labourTierDetail(
    String tier,
    int working,
    int notWorking,
  );

  /// Forces-food default line when land military feeding is complete.
  String get production_forcesFoodArmiesFullyFed;

  /// Forces-food default line when land feeding coverage is in [0.5, 1.0).
  String get production_forcesFoodArmiesUnderfedModerate;

  /// Forces-food default line when land feeding coverage is below 0.5.
  String get production_forcesFoodArmiesUnderfedSevere;

  /// Forces-food default line when naval feeding is complete.
  String get production_forcesFoodFleetsFullyFed;

  /// Forces-food default line when naval feeding coverage is in [0.5, 1.0).
  String get production_forcesFoodFleetsUnderfedModerate;

  /// Forces-food default line when naval feeding coverage is below 0.5.
  String get production_forcesFoodFleetsUnderfedSevere;

  /// Toggle to expand forces-food readiness breakdown on Production Available.
  String get production_forcesFoodDetails;

  /// Forces-food detail row for land military feeding.
  String production_forcesFoodDetailsArmies(int fed, int total);

  /// Forces-food detail row for naval feeding.
  String production_forcesFoodDetailsFleets(int fed, int total);

  /// Forces-food detail row for combined military/navy food demand.
  String production_forcesFoodDetailsDemand(int demand);

  /// Reminder that military/navy food is reserved before worker consumption.
  String get production_forcesFoodDetailsPriority;

  /// Soft warn when land feeding coverage is in [0.5, 1.0) at invasion/combat.
  String get forcesFood_landUnderfedModerateWarning;

  /// Soft warn when land feeding coverage is below 0.5 at invasion/combat.
  String get forcesFood_landUnderfedSevereWarning;

  /// Recipe affordance line (max output and limiting factor label).
  String production_recipeAffordance(int max, String limiting);

  /// Total labour required vs effective in allocation panel.
  String production_totalLabour(int required, int effective);

  /// Warning when allocated labour exceeds effective labour.
  String get production_labourInsufficient;

  /// Pending recruit-worker order count shown on a tier row in the Labour controls.
  String production_labourQueued(int count);

  /// Tooltip and semantics label for the + stepper on the peasant row.
  String production_labourRecruitTier(String tier);

  /// Tooltip and semantics label for the + stepper on a trained-tier row.
  String production_labourTrainTier(String tier);

  /// Tooltip and semantics label for the − stepper on any tier row.
  String production_labourDequeueTier(String tier);

  /// Tooltip and semantics label for the Disband control on a trained-tier row.
  String production_labourDisbandTier(String tier);

  /// Visible label for the Disband button on trained-tier rows.
  String get production_labourDisband;

  /// Parenthetical suffix on a Labour Controls tier label when every
  /// required tech is unlocked for the viewed player (peasant always
  /// renders this).
  String get production_labourTierUnlocked;

  /// Parenthetical suffix on a Labour Controls tier label when one or
  /// more required techs are missing for the viewed player.
  String get production_labourTierLocked;

  /// Parenthetical marker shown after an Allocation recipe name when the
  /// recipe's required technology is not unlocked for the viewed player
  /// (e.g. fabric_from_cotton before cotton_weaving).
  String get production_recipeLocked;

  /// Concatenation of the tier name and the unlock-state parenthetical for
  /// a Labour Controls row (e.g. "Peasants (unlocked)").
  String production_labourTierLabel(String tier, String state);

  /// Title of the Labour Controls subsection in the Production panel
  /// Available subpanel.
  String get production_labourControlsSectionLabel;

  /// Worker type and count in production panel.
  String production_workerCount(String name, int count);

  /// Ship type and hull count in fleet expansion tile.
  String naval_units_shipTypeCount(String typeName, int count);

  /// Bottom sheet title for assigning civilian work.
  String civilian_assignWorkTitle(String unitType);

  /// Commodity name and stock quantity in train military dialog.
  String trainMilitary_commodityAmount(String name, int qty);

  /// Commodity name and a preformatted remaining/total value (e.g. '2 / 5')
  /// in the train military dialog resource bar.
  String trainMilitary_commodityValue(String name, String value);

  /// Treasury cost plus paper requirement for training civilians.
  String trainCivilians_costLine(String treasury, String paper);

  /// Bullet line for a tech prerequisite name.
  String techTree_prerequisiteBullet(String name);

  /// Tech tree effect line for a regiment unlock from catalog data.
  String techEffect_unlocksRegiment(String name);

  /// Tech tree effect line for a ship unlock from catalog data.
  String techEffect_unlocksShip(String name);

  /// Generic tech effect when no specific summary lines exist.
  String techEffect_fallbackCategoryImprovement(String category);

  /// Tech tree category label (gathering).
  String get techTree_categoryGathering;

  /// Tech tree category label (transport).
  String get techTree_categoryTransport;

  /// Tech tree category label (labour).
  String get techTree_categoryLabour;

  /// Tech tree category label (civilian).
  String get techTree_categoryCivilian;

  /// Tech tree category label (diplomacy).
  String get techTree_categoryDiplomacy;

  /// Tech tree category label (naval).
  String get techTree_categoryNaval;

  /// Tech tree category label (military).
  String get techTree_categoryMilitary;

  /// Tech tree category label (new-world).
  String get techTree_categoryNewWorld;

  /// Transfer list row showing item name and quantity.
  String transferList_rowCount(String name, int count);

  /// Placeholder hint in Widgetbook civilian panel story.
  String get widgetbook_openPanelHint;

  /// Fleet row label with fleet id.
  String naval_fleetLabel(String id);

  /// Label for the player's home fleet.
  String get naval_homeFleetLabel;

  /// Location sub-header combining local and region labels.
  String locationSection_headerLine(String label, String region);

  /// Title for split fleet dialog.
  String get splitFleet_dialogTitle;

  /// Right column title in split fleet transfer list.
  String get splitFleet_newFleetTitle;

  /// Empty column label in split fleet transfer list.
  String get splitFleet_noShips;

  /// Confirm button label for split fleet dialog.
  String get splitFleet_confirm;

  /// Footer total ship count in split fleet transfer list.
  String splitFleet_totalShips(int total);

  /// Title for selected-ship transfer into Home Fleet dialog.
  String get naval_transferToHome_dialogTitle;

  /// Source fleet title in transfer-to-home dialog.
  String naval_transferToHome_sourceTitle(String id);

  /// Confirm button label for transfer-to-home dialog.
  String get naval_transferToHome_confirm;

  /// Diplomacy list section heading.
  String get diplomacy_section_greatPowers;

  /// Diplomacy list section heading.
  String get diplomacy_section_minorNations;

  /// Diplomacy list section heading.
  String get diplomacy_section_tribes;

  /// Diplomacy panel mode-bar filter label: show all factions.
  String get diplomacy_filter_all;

  /// Diplomacy panel mode-bar filter label: show only Great Powers.
  String get diplomacy_filter_greatPowersOnly;

  /// Diplomacy panel mode-bar filter label: show Minor Nations and Tribes only (no Great Powers).
  String get diplomacy_filter_minorsOnly;

  /// One-word war state in diplomacy UI.
  String get diplomacy_relationState_war;

  /// One-word peace state in diplomacy UI.
  String get diplomacy_relationState_peace;

  /// Accessibility label for the relation meter; embeds the ladder relation word.
  String diplomacy_relationMeter_semanticsLabel(String relation);

  /// Tech tree dialog effect line (techEffectSummary_advanced_hull_design_0).
  String get techEffectSummary_advanced_hull_design_0;

  /// Tech tree dialog effect line (techEffectSummary_advanced_hull_design_1).
  String get techEffectSummary_advanced_hull_design_1;

  /// Tech tree dialog effect line (techEffectSummary_advanced_iron_working_0).
  String get techEffectSummary_advanced_iron_working_0;

  /// Tech tree dialog effect line (techEffectSummary_amalgamation_process_0).
  String get techEffectSummary_amalgamation_process_0;

  /// Tech tree dialog effect line (techEffectSummary_amalgamation_process_1).
  String get techEffectSummary_amalgamation_process_1;

  /// Tech tree dialog effect line (techEffectSummary_animal_husbandry_0).
  String get techEffectSummary_animal_husbandry_0;

  /// Tech tree dialog effect line (techEffectSummary_animal_husbandry_1).
  String get techEffectSummary_animal_husbandry_1;

  /// Tech tree dialog effect line (techEffectSummary_animal_husbandry_2).
  String get techEffectSummary_animal_husbandry_2;

  /// Tech tree dialog effect line (techEffectSummary_apprentice_workers_0).
  String get techEffectSummary_apprentice_workers_0;

  /// Tech tree dialog effect line (techEffectSummary_apprentice_workers_1).
  String get techEffectSummary_apprentice_workers_1;

  /// Tech tree dialog effect line (techEffectSummary_banking_0).
  String get techEffectSummary_banking_0;

  /// Tech tree dialog effect line (techEffectSummary_banking_1).
  String get techEffectSummary_banking_1;

  /// Tech tree dialog effect line (techEffectSummary_bayonet_0).
  String get techEffectSummary_bayonet_0;

  /// Tech tree dialog effect line (techEffectSummary_cigar_production_0).
  String get techEffectSummary_cigar_production_0;

  /// Tech tree dialog effect line (techEffectSummary_cigar_production_1).
  String get techEffectSummary_cigar_production_1;

  /// Tech tree dialog effect line (techEffectSummary_circular_saw_0).
  String get techEffectSummary_circular_saw_0;

  /// Tech tree dialog effect line (techEffectSummary_circular_saw_1).
  String get techEffectSummary_circular_saw_1;

  /// Tech tree dialog effect line (techEffectSummary_clipper_ships_0).
  String get techEffectSummary_clipper_ships_0;

  /// Tech tree dialog effect line (techEffectSummary_coal_mining_0).
  String get techEffectSummary_coal_mining_0;

  /// Tech tree dialog effect line (techEffectSummary_coal_mining_1).
  String get techEffectSummary_coal_mining_1;

  /// Tech tree dialog effect line (techEffectSummary_convoying_0).
  String get techEffectSummary_convoying_0;

  /// Tech tree dialog effect line (techEffectSummary_copper_and_tin_mining_0).
  String get techEffectSummary_copper_and_tin_mining_0;

  /// Tech tree dialog effect line (techEffectSummary_copper_and_tin_mining_1).
  String get techEffectSummary_copper_and_tin_mining_1;

  /// Tech tree dialog effect line (techEffectSummary_copper_and_tin_mining_2).
  String get techEffectSummary_copper_and_tin_mining_2;

  /// Tech tree dialog effect line (techEffectSummary_cotton_gin_0).
  String get techEffectSummary_cotton_gin_0;

  /// Tech tree dialog effect line (techEffectSummary_cotton_gin_1).
  String get techEffectSummary_cotton_gin_1;

  /// Tech tree dialog effect line (techEffectSummary_cotton_planting_0).
  String get techEffectSummary_cotton_planting_0;

  /// Tech tree dialog effect line (techEffectSummary_cotton_planting_1).
  String get techEffectSummary_cotton_planting_1;

  /// Tech tree dialog effect line (techEffectSummary_cotton_weaving_0).
  String get techEffectSummary_cotton_weaving_0;

  /// Tech tree dialog effect line (techEffectSummary_cotton_weaving_1).
  String get techEffectSummary_cotton_weaving_1;

  /// Tech tree dialog effect line (techEffectSummary_crop_rotation_0).
  String get techEffectSummary_crop_rotation_0;

  /// Tech tree dialog effect line (techEffectSummary_crucible_process_0).
  String get techEffectSummary_crucible_process_0;

  /// Tech tree dialog effect line (techEffectSummary_crucible_process_1).
  String get techEffectSummary_crucible_process_1;

  /// Tech tree dialog effect line (techEffectSummary_diplomatic_expertise_0).
  String get techEffectSummary_diplomatic_expertise_0;

  /// Tech tree dialog effect line (techEffectSummary_diplomatic_expertise_1).
  String get techEffectSummary_diplomatic_expertise_1;

  /// Tech tree dialog effect line (techEffectSummary_diplomatic_expertise_2).
  String get techEffectSummary_diplomatic_expertise_2;

  /// Tech tree dialog effect line (techEffectSummary_discovery_of_cotton_0).
  String get techEffectSummary_discovery_of_cotton_0;

  /// Tech tree dialog effect line (techEffectSummary_discovery_of_cotton_1).
  String get techEffectSummary_discovery_of_cotton_1;

  /// Tech tree dialog effect line (techEffectSummary_discovery_of_furs_0).
  String get techEffectSummary_discovery_of_furs_0;

  /// Tech tree dialog effect line (techEffectSummary_discovery_of_furs_1).
  String get techEffectSummary_discovery_of_furs_1;

  /// Tech tree dialog effect line (techEffectSummary_discovery_of_gems_or_diamonds_0).
  String get techEffectSummary_discovery_of_gems_or_diamonds_0;

  /// Tech tree dialog effect line (techEffectSummary_discovery_of_gems_or_diamonds_1).
  String get techEffectSummary_discovery_of_gems_or_diamonds_1;

  /// Tech tree dialog effect line (techEffectSummary_discovery_of_gold_or_silver_0).
  String get techEffectSummary_discovery_of_gold_or_silver_0;

  /// Tech tree dialog effect line (techEffectSummary_discovery_of_gold_or_silver_1).
  String get techEffectSummary_discovery_of_gold_or_silver_1;

  /// Tech tree dialog effect line (techEffectSummary_discovery_of_spices_0).
  String get techEffectSummary_discovery_of_spices_0;

  /// Tech tree dialog effect line (techEffectSummary_discovery_of_spices_1).
  String get techEffectSummary_discovery_of_spices_1;

  /// Tech tree dialog effect line (techEffectSummary_discovery_of_sugar_0).
  String get techEffectSummary_discovery_of_sugar_0;

  /// Tech tree dialog effect line (techEffectSummary_discovery_of_sugar_1).
  String get techEffectSummary_discovery_of_sugar_1;

  /// Tech tree dialog effect line (techEffectSummary_discovery_of_tobacco_0).
  String get techEffectSummary_discovery_of_tobacco_0;

  /// Tech tree dialog effect line (techEffectSummary_discovery_of_tobacco_1).
  String get techEffectSummary_discovery_of_tobacco_1;

  /// Tech tree dialog effect line (techEffectSummary_dynamite_0).
  String get techEffectSummary_dynamite_0;

  /// Tech tree dialog effect line (techEffectSummary_dynamite_1).
  String get techEffectSummary_dynamite_1;

  /// Tech tree dialog effect line (techEffectSummary_early_rifles_0).
  String get techEffectSummary_early_rifles_0;

  /// Tech tree dialog effect line (techEffectSummary_early_rifles_1).
  String get techEffectSummary_early_rifles_1;

  /// Tech tree dialog effect line (techEffectSummary_early_steam_engine_0).
  String get techEffectSummary_early_steam_engine_0;

  /// Tech tree dialog effect line (techEffectSummary_early_steam_engine_1).
  String get techEffectSummary_early_steam_engine_1;

  /// Tech tree dialog effect line (techEffectSummary_efficient_extraction_of_copper_and_tin_0).
  String get techEffectSummary_efficient_extraction_of_copper_and_tin_0;

  /// Tech tree dialog effect line (techEffectSummary_efficient_extraction_of_copper_and_tin_1).
  String get techEffectSummary_efficient_extraction_of_copper_and_tin_1;

  /// Tech tree dialog effect line (techEffectSummary_elite_military_training_0).
  String get techEffectSummary_elite_military_training_0;

  /// Tech tree dialog effect line (techEffectSummary_empire_building_0).
  String get techEffectSummary_empire_building_0;

  /// Tech tree dialog effect line (techEffectSummary_empire_building_1).
  String get techEffectSummary_empire_building_1;

  /// Tech tree dialog effect line (techEffectSummary_emplaced_siege_guns_0).
  String get techEffectSummary_emplaced_siege_guns_0;

  /// Tech tree dialog effect line (techEffectSummary_excessive_fur_harvesting_0).
  String get techEffectSummary_excessive_fur_harvesting_0;

  /// Tech tree dialog effect line (techEffectSummary_excessive_fur_harvesting_1).
  String get techEffectSummary_excessive_fur_harvesting_1;

  /// Tech tree dialog effect line (techEffectSummary_explosives_0).
  String get techEffectSummary_explosives_0;

  /// Tech tree dialog effect line (techEffectSummary_explosives_1).
  String get techEffectSummary_explosives_1;

  /// Tech tree dialog effect line (techEffectSummary_extraction_of_precious_metals_0).
  String get techEffectSummary_extraction_of_precious_metals_0;

  /// Tech tree dialog effect line (techEffectSummary_extraction_of_precious_metals_1).
  String get techEffectSummary_extraction_of_precious_metals_1;

  /// Tech tree dialog effect line (techEffectSummary_field_artillery_tactics_0).
  String get techEffectSummary_field_artillery_tactics_0;

  /// Tech tree dialog effect line (techEffectSummary_geological_prospecting_0).
  String get techEffectSummary_geological_prospecting_0;

  /// Tech tree dialog effect line (techEffectSummary_geological_prospecting_1).
  String get techEffectSummary_geological_prospecting_1;

  /// Tech tree dialog effect line (techEffectSummary_hat_production_0).
  String get techEffectSummary_hat_production_0;

  /// Tech tree dialog effect line (techEffectSummary_hat_production_1).
  String get techEffectSummary_hat_production_1;

  /// Tech tree dialog effect line (techEffectSummary_heavy_artillery_0).
  String get techEffectSummary_heavy_artillery_0;

  /// Tech tree dialog effect line (techEffectSummary_heavy_artillery_1).
  String get techEffectSummary_heavy_artillery_1;

  /// Tech tree dialog effect line (techEffectSummary_heavy_emplaced_artillery_0).
  String get techEffectSummary_heavy_emplaced_artillery_0;

  /// Tech tree dialog effect line (techEffectSummary_heavy_emplaced_artillery_1).
  String get techEffectSummary_heavy_emplaced_artillery_1;

  /// Tech tree dialog effect line (techEffectSummary_high_grade_steel_0).
  String get techEffectSummary_high_grade_steel_0;

  /// Tech tree dialog effect line (techEffectSummary_horse_artillery_0).
  String get techEffectSummary_horse_artillery_0;

  /// Tech tree dialog effect line (techEffectSummary_hussars_0).
  String get techEffectSummary_hussars_0;

  /// Tech tree dialog effect line (techEffectSummary_hussars_1).
  String get techEffectSummary_hussars_1;

  /// Tech tree dialog effect line (techEffectSummary_improved_cavalry_tactics_0).
  String get techEffectSummary_improved_cavalry_tactics_0;

  /// Tech tree dialog effect line (techEffectSummary_improved_cavalry_weapons_0).
  String get techEffectSummary_improved_cavalry_weapons_0;

  /// Tech tree dialog effect line (techEffectSummary_improved_cavalry_weapons_1).
  String get techEffectSummary_improved_cavalry_weapons_1;

  /// Tech tree dialog effect line (techEffectSummary_improved_food_preservation_0).
  String get techEffectSummary_improved_food_preservation_0;

  /// Tech tree dialog effect line (techEffectSummary_improved_food_preservation_1).
  String get techEffectSummary_improved_food_preservation_1;

  /// Tech tree dialog effect line (techEffectSummary_improved_infantry_tactics_0).
  String get techEffectSummary_improved_infantry_tactics_0;

  /// Tech tree dialog effect line (techEffectSummary_improved_infantry_tactics_1).
  String get techEffectSummary_improved_infantry_tactics_1;

  /// Tech tree dialog effect line (techEffectSummary_improved_iron_weapons_0).
  String get techEffectSummary_improved_iron_weapons_0;

  /// Tech tree dialog effect line (techEffectSummary_improved_sail_design_0).
  String get techEffectSummary_improved_sail_design_0;

  /// Tech tree dialog effect line (techEffectSummary_improved_sea_routes_0).
  String get techEffectSummary_improved_sea_routes_0;

  /// Tech tree dialog effect line (techEffectSummary_improved_sea_routes_1).
  String get techEffectSummary_improved_sea_routes_1;

  /// Tech tree dialog effect line (techEffectSummary_improved_trapping_techniques_0).
  String get techEffectSummary_improved_trapping_techniques_0;

  /// Tech tree dialog effect line (techEffectSummary_improved_trapping_techniques_1).
  String get techEffectSummary_improved_trapping_techniques_1;

  /// Tech tree dialog effect line (techEffectSummary_industrial_funding_of_research_0).
  String get techEffectSummary_industrial_funding_of_research_0;

  /// Tech tree dialog effect line (techEffectSummary_industrial_funding_of_research_1).
  String get techEffectSummary_industrial_funding_of_research_1;

  /// Tech tree dialog effect line (techEffectSummary_industrial_iron_mining_0).
  String get techEffectSummary_industrial_iron_mining_0;

  /// Tech tree dialog effect line (techEffectSummary_industrial_iron_mining_1).
  String get techEffectSummary_industrial_iron_mining_1;

  /// Tech tree dialog effect line (techEffectSummary_industrial_machinery_0).
  String get techEffectSummary_industrial_machinery_0;

  /// Tech tree dialog effect line (techEffectSummary_industrial_machinery_1).
  String get techEffectSummary_industrial_machinery_1;

  /// Tech tree dialog effect line (techEffectSummary_iron_mining_0).
  String get techEffectSummary_iron_mining_0;

  /// Tech tree dialog effect line (techEffectSummary_iron_mining_1).
  String get techEffectSummary_iron_mining_1;

  /// Tech tree dialog effect line (techEffectSummary_land_enclosure_0).
  String get techEffectSummary_land_enclosure_0;

  /// Tech tree dialog effect line (techEffectSummary_land_enclosure_1).
  String get techEffectSummary_land_enclosure_1;

  /// Tech tree dialog effect line (techEffectSummary_large_coal_mines_0).
  String get techEffectSummary_large_coal_mines_0;

  /// Tech tree dialog effect line (techEffectSummary_large_coal_mines_1).
  String get techEffectSummary_large_coal_mines_1;

  /// Tech tree dialog effect line (techEffectSummary_large_coal_mines_2).
  String get techEffectSummary_large_coal_mines_2;

  /// Tech tree dialog effect line (techEffectSummary_large_copper_and_tin_mines_0).
  String get techEffectSummary_large_copper_and_tin_mines_0;

  /// Tech tree dialog effect line (techEffectSummary_large_copper_and_tin_mines_1).
  String get techEffectSummary_large_copper_and_tin_mines_1;

  /// Tech tree dialog effect line (techEffectSummary_large_copper_and_tin_mines_2).
  String get techEffectSummary_large_copper_and_tin_mines_2;

  /// Tech tree dialog effect line (techEffectSummary_large_cotton_plantations_0).
  String get techEffectSummary_large_cotton_plantations_0;

  /// Tech tree dialog effect line (techEffectSummary_large_cotton_plantations_1).
  String get techEffectSummary_large_cotton_plantations_1;

  /// Tech tree dialog effect line (techEffectSummary_large_hulls_0).
  String get techEffectSummary_large_hulls_0;

  /// Tech tree dialog effect line (techEffectSummary_large_precious_stone_mines_0).
  String get techEffectSummary_large_precious_stone_mines_0;

  /// Tech tree dialog effect line (techEffectSummary_large_precious_stone_mines_1).
  String get techEffectSummary_large_precious_stone_mines_1;

  /// Tech tree dialog effect line (techEffectSummary_large_spice_plantations_0).
  String get techEffectSummary_large_spice_plantations_0;

  /// Tech tree dialog effect line (techEffectSummary_large_spice_plantations_1).
  String get techEffectSummary_large_spice_plantations_1;

  /// Tech tree dialog effect line (techEffectSummary_large_sugar_plantations_0).
  String get techEffectSummary_large_sugar_plantations_0;

  /// Tech tree dialog effect line (techEffectSummary_large_sugar_plantations_1).
  String get techEffectSummary_large_sugar_plantations_1;

  /// Tech tree dialog effect line (techEffectSummary_large_tobacco_plantations_0).
  String get techEffectSummary_large_tobacco_plantations_0;

  /// Tech tree dialog effect line (techEffectSummary_large_tobacco_plantations_1).
  String get techEffectSummary_large_tobacco_plantations_1;

  /// Tech tree dialog effect line (techEffectSummary_later_steam_engine_0).
  String get techEffectSummary_later_steam_engine_0;

  /// Tech tree dialog effect line (techEffectSummary_later_steam_engine_1).
  String get techEffectSummary_later_steam_engine_1;

  /// Tech tree dialog effect line (techEffectSummary_light_artillery_tactics_0).
  String get techEffectSummary_light_artillery_tactics_0;

  /// Tech tree dialog effect line (techEffectSummary_light_artillery_tactics_1).
  String get techEffectSummary_light_artillery_tactics_1;

  /// Tech tree dialog effect line (techEffectSummary_long_range_rifles_0).
  String get techEffectSummary_long_range_rifles_0;

  /// Tech tree dialog effect line (techEffectSummary_master_artisans_0).
  String get techEffectSummary_master_artisans_0;

  /// Tech tree dialog effect line (techEffectSummary_master_artisans_1).
  String get techEffectSummary_master_artisans_1;

  /// Tech tree dialog effect line (techEffectSummary_merchant_companies_0).
  String get techEffectSummary_merchant_companies_0;

  /// Tech tree dialog effect line (techEffectSummary_merchant_companies_1).
  String get techEffectSummary_merchant_companies_1;

  /// Tech tree dialog effect line (techEffectSummary_merchant_companies_2).
  String get techEffectSummary_merchant_companies_2;

  /// Tech tree dialog effect line (techEffectSummary_merchant_steamships_0).
  String get techEffectSummary_merchant_steamships_0;

  /// Tech tree dialog effect line (techEffectSummary_mine_engineering_0).
  String get techEffectSummary_mine_engineering_0;

  /// Tech tree dialog effect line (techEffectSummary_mine_engineering_1).
  String get techEffectSummary_mine_engineering_1;

  /// Tech tree dialog effect line (techEffectSummary_modern_forts_0).
  String get techEffectSummary_modern_forts_0;

  /// Tech tree dialog effect line (techEffectSummary_modern_forts_1).
  String get techEffectSummary_modern_forts_1;

  /// Tech tree dialog effect line (techEffectSummary_modern_military_funding_0).
  String get techEffectSummary_modern_military_funding_0;

  /// Tech tree dialog effect line (techEffectSummary_modern_military_funding_1).
  String get techEffectSummary_modern_military_funding_1;

  /// Tech tree dialog effect line (techEffectSummary_moldboard_plow_0).
  String get techEffectSummary_moldboard_plow_0;

  /// Tech tree dialog effect line (techEffectSummary_moldboard_plow_1).
  String get techEffectSummary_moldboard_plow_1;

  /// Tech tree dialog effect line (techEffectSummary_money_lending_0).
  String get techEffectSummary_money_lending_0;

  /// Tech tree dialog effect line (techEffectSummary_money_lending_1).
  String get techEffectSummary_money_lending_1;

  /// Tech tree dialog effect line (techEffectSummary_money_lending_2).
  String get techEffectSummary_money_lending_2;

  /// Tech tree dialog effect line (techEffectSummary_national_bureaucracy_0).
  String get techEffectSummary_national_bureaucracy_0;

  /// Tech tree dialog effect line (techEffectSummary_national_bureaucracy_1).
  String get techEffectSummary_national_bureaucracy_1;

  /// Tech tree dialog effect line (techEffectSummary_national_bureaucracy_2).
  String get techEffectSummary_national_bureaucracy_2;

  /// Tech tree dialog effect line (techEffectSummary_nationalism_0).
  String get techEffectSummary_nationalism_0;

  /// Tech tree dialog effect line (techEffectSummary_nationalism_1).
  String get techEffectSummary_nationalism_1;

  /// Tech tree dialog effect line (techEffectSummary_nationalism_2).
  String get techEffectSummary_nationalism_2;

  /// Tech tree dialog effect line (techEffectSummary_navigation_0).
  String get techEffectSummary_navigation_0;

  /// Tech tree dialog effect line (techEffectSummary_needle_guns_0).
  String get techEffectSummary_needle_guns_0;

  /// Tech tree dialog effect line (techEffectSummary_needle_guns_1).
  String get techEffectSummary_needle_guns_1;

  /// Tech tree dialog effect line (techEffectSummary_organised_regiments_0).
  String get techEffectSummary_organised_regiments_0;

  /// Tech tree dialog effect line (techEffectSummary_organised_regiments_1).
  String get techEffectSummary_organised_regiments_1;

  /// Tech tree dialog effect line (techEffectSummary_paddlewheels_0).
  String get techEffectSummary_paddlewheels_0;

  /// Tech tree dialog effect line (techEffectSummary_precious_metals_mining_0).
  String get techEffectSummary_precious_metals_mining_0;

  /// Tech tree dialog effect line (techEffectSummary_precious_metals_mining_1).
  String get techEffectSummary_precious_metals_mining_1;

  /// Tech tree dialog effect line (techEffectSummary_precious_stone_mining_0).
  String get techEffectSummary_precious_stone_mining_0;

  /// Tech tree dialog effect line (techEffectSummary_precious_stone_mining_1).
  String get techEffectSummary_precious_stone_mining_1;

  /// Tech tree dialog effect line (techEffectSummary_printing_press_0).
  String get techEffectSummary_printing_press_0;

  /// Tech tree dialog effect line (techEffectSummary_printing_press_1).
  String get techEffectSummary_printing_press_1;

  /// Tech tree dialog effect line (techEffectSummary_privateering_companies_0).
  String get techEffectSummary_privateering_companies_0;

  /// Tech tree dialog effect line (techEffectSummary_privateering_companies_1).
  String get techEffectSummary_privateering_companies_1;

  /// Tech tree dialog effect line (techEffectSummary_propaganda_0).
  String get techEffectSummary_propaganda_0;

  /// Tech tree dialog effect line (techEffectSummary_propaganda_1).
  String get techEffectSummary_propaganda_1;

  /// Tech tree dialog effect line (techEffectSummary_recruit_steppe_horsemen_0).
  String get techEffectSummary_recruit_steppe_horsemen_0;

  /// Tech tree dialog effect line (techEffectSummary_recruit_steppe_horsemen_1).
  String get techEffectSummary_recruit_steppe_horsemen_1;

  /// Tech tree dialog effect line (techEffectSummary_repeating_cavalry_carbine_0).
  String get techEffectSummary_repeating_cavalry_carbine_0;

  /// Tech tree dialog effect line (techEffectSummary_riverboats_0).
  String get techEffectSummary_riverboats_0;

  /// Tech tree dialog effect line (techEffectSummary_riverboats_1).
  String get techEffectSummary_riverboats_1;

  /// Tech tree dialog effect line (techEffectSummary_road_construction_0).
  String get techEffectSummary_road_construction_0;

  /// Tech tree dialog effect line (techEffectSummary_road_construction_1).
  String get techEffectSummary_road_construction_1;

  /// Tech tree dialog effect line (techEffectSummary_safety_lamp_0).
  String get techEffectSummary_safety_lamp_0;

  /// Tech tree dialog effect line (techEffectSummary_safety_lamp_1).
  String get techEffectSummary_safety_lamp_1;

  /// Tech tree dialog effect line (techEffectSummary_saw_mill_0).
  String get techEffectSummary_saw_mill_0;

  /// Tech tree dialog effect line (techEffectSummary_saw_mill_1).
  String get techEffectSummary_saw_mill_1;

  /// Tech tree dialog effect line (techEffectSummary_scientific_cattle_breeding_0).
  String get techEffectSummary_scientific_cattle_breeding_0;

  /// Tech tree dialog effect line (techEffectSummary_scientific_cattle_breeding_1).
  String get techEffectSummary_scientific_cattle_breeding_1;

  /// Tech tree dialog effect line (techEffectSummary_scientific_sheep_breeding_0).
  String get techEffectSummary_scientific_sheep_breeding_0;

  /// Tech tree dialog effect line (techEffectSummary_scientific_sheep_breeding_1).
  String get techEffectSummary_scientific_sheep_breeding_1;

  /// Tech tree dialog effect line (techEffectSummary_scouting_0).
  String get techEffectSummary_scouting_0;

  /// Tech tree dialog effect line (techEffectSummary_seed_drill_0).
  String get techEffectSummary_seed_drill_0;

  /// Tech tree dialog effect line (techEffectSummary_seed_drill_1).
  String get techEffectSummary_seed_drill_1;

  /// Tech tree dialog effect line (techEffectSummary_sheep_ranching_0).
  String get techEffectSummary_sheep_ranching_0;

  /// Tech tree dialog effect line (techEffectSummary_sheep_ranching_1).
  String get techEffectSummary_sheep_ranching_1;

  /// Tech tree dialog effect line (techEffectSummary_ship_of_the_line_0).
  String get techEffectSummary_ship_of_the_line_0;

  /// Tech tree dialog effect line (techEffectSummary_ship_of_the_line_1).
  String get techEffectSummary_ship_of_the_line_1;

  /// Tech tree dialog effect line (techEffectSummary_siege_engineering_0).
  String get techEffectSummary_siege_engineering_0;

  /// Tech tree dialog effect line (techEffectSummary_siege_engineering_1).
  String get techEffectSummary_siege_engineering_1;

  /// Tech tree dialog effect line (techEffectSummary_square_set_timbering_0).
  String get techEffectSummary_square_set_timbering_0;

  /// Tech tree dialog effect line (techEffectSummary_square_set_timbering_1).
  String get techEffectSummary_square_set_timbering_1;

  /// Tech tree dialog effect line (techEffectSummary_square_set_timbering_2).
  String get techEffectSummary_square_set_timbering_2;

  /// Tech tree dialog effect line (techEffectSummary_steam_in_mining_0).
  String get techEffectSummary_steam_in_mining_0;

  /// Tech tree dialog effect line (techEffectSummary_steam_in_mining_1).
  String get techEffectSummary_steam_in_mining_1;

  /// Tech tree dialog effect line (techEffectSummary_steam_in_mining_2).
  String get techEffectSummary_steam_in_mining_2;

  /// Tech tree dialog effect line (techEffectSummary_sugar_industry_0).
  String get techEffectSummary_sugar_industry_0;

  /// Tech tree dialog effect line (techEffectSummary_sugar_industry_1).
  String get techEffectSummary_sugar_industry_1;

  /// Tech tree dialog effect line (techEffectSummary_sugar_planting_0).
  String get techEffectSummary_sugar_planting_0;

  /// Tech tree dialog effect line (techEffectSummary_sugar_planting_1).
  String get techEffectSummary_sugar_planting_1;

  /// Tech tree dialog effect line (techEffectSummary_sugar_refining_0).
  String get techEffectSummary_sugar_refining_0;

  /// Tech tree dialog effect line (techEffectSummary_sugar_refining_1).
  String get techEffectSummary_sugar_refining_1;

  /// Tech tree dialog effect line (techEffectSummary_superior_hull_design_0).
  String get techEffectSummary_superior_hull_design_0;

  /// Tech tree dialog effect line (techEffectSummary_tobacco_industry_0).
  String get techEffectSummary_tobacco_industry_0;

  /// Tech tree dialog effect line (techEffectSummary_tobacco_industry_1).
  String get techEffectSummary_tobacco_industry_1;

  /// Tech tree dialog effect line (techEffectSummary_tobacco_planting_0).
  String get techEffectSummary_tobacco_planting_0;

  /// Tech tree dialog effect line (techEffectSummary_tobacco_planting_1).
  String get techEffectSummary_tobacco_planting_1;

  /// Tech tree dialog effect line (techEffectSummary_trade_fairs_0).
  String get techEffectSummary_trade_fairs_0;

  /// Tech tree dialog effect line (techEffectSummary_trade_fairs_1).
  String get techEffectSummary_trade_fairs_1;

  /// Tech tree dialog effect line (techEffectSummary_trained_journeymen_0).
  String get techEffectSummary_trained_journeymen_0;

  /// Tech tree dialog effect line (techEffectSummary_trained_journeymen_1).
  String get techEffectSummary_trained_journeymen_1;

  /// Tech tree dialog effect line (techEffectSummary_university_0).
  String get techEffectSummary_university_0;

  /// Tech tree dialog effect line (techEffectSummary_university_1).
  String get techEffectSummary_university_1;

  /// Tech tree dialog effect line (techEffectSummary_weapon_craftsmanship_0).
  String get techEffectSummary_weapon_craftsmanship_0;

  /// Tech tree dialog effect line (techEffectSummary_wind_saw_mill_0).
  String get techEffectSummary_wind_saw_mill_0;

  /// Tech tree dialog effect line (techEffectSummary_wind_saw_mill_1).
  String get techEffectSummary_wind_saw_mill_1;

  /// Label for narrow-layout player turn event feed chip.
  String playerTurnFeed_eventsChip(int count);

  /// Title for the narrow-layout player turn events dialog.
  String get playerTurnFeed_eventsTitle;

  /// Title label for the in-map debug console overlay panel.
  String get debugConsole_title;

  /// Input hint showing an example slash command in debug console overlay.
  String get debugConsole_hintSpawnCivilian;

  /// Title of the app Settings dialog (DLG90001).
  String get settingsDialog_title;

  /// Section header for immediate-apply gameplay preferences in Settings.
  String get settingsDialog_section_gameplay;

  /// Toggle label for the idle-civilian end-turn warning preference.
  String get settingsDialog_warnIdleCiviliansOnEndTurn;

  /// Section header for map theme pickers in Settings.
  String get settingsDialog_section_themes;

  /// Hint that map theme changes apply after restart.
  String get settingsDialog_restartHint;

  /// Close button on the Settings dialog.
  String get settingsDialog_close;

  /// Shown when the theme catalog is not loaded.
  String get settingsDialog_catalogUnavailable;

  /// Settings dialog group label: terrain.
  String get settingsDialog_group_terrain;

  /// Settings dialog group label: civilian icons.
  String get settingsDialog_group_civilianIcons;

  /// Settings dialog group label: town icons.
  String get settingsDialog_group_townIcons;

  /// Settings dialog group label: resource icons.
  String get settingsDialog_group_resourceIcons;

  /// Settings dialog group label: fleet icons.
  String get settingsDialog_group_fleetIcons;

  /// Settings dialog group label: province label icons.
  String get settingsDialog_group_provinceLabelIcons;

  /// Default terrain theme display name.
  String get mapTheme_terrain_default;

  /// Sepia terrain theme display name.
  String get mapTheme_terrain_sepia;

  /// Default civilian icon theme display name.
  String get mapTheme_civilian_default;

  /// Sepia civilian icon theme display name.
  String get mapTheme_civilian_sepia;

  /// Default town icon theme display name.
  String get mapTheme_town_default;

  /// Default resource icon theme display name.
  String get mapTheme_resource_default;

  /// Default fleet icon theme display name.
  String get mapTheme_fleet_default;

  /// Default province-label icon theme display name.
  String get mapTheme_provinceLabel_default;
}
