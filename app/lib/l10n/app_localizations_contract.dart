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

  /// Pause menu option label to resume the game.
  String get game_pauseMenu_resume;

  /// Tooltip for the pause menu button in the in-game UI.
  String get game_pauseMenu_tooltip;

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

  /// Title of the dialog asking the user to confirm ending the current turn.
  String get game_nextTurnConfirm_title;

  /// Body text of the end-turn confirmation dialog.
  String game_nextTurnConfirm_body(int turn);

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

  /// Generic Cancel button label.
  String get common_cancel;

  /// Prompt overlay text while map work-target tile selection mode is active.
  String get map_selectionMode_prompt;

  /// Lowercase inline cancel action label in the map work-target selection prompt overlay.
  String get map_selectionMode_cancel;

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

  /// Checkbox label for infinite campaign mode in the new-game leader dialog.
  String get shell_leaderDialog_infiniteModeLabel;

  /// Helper text for infinite mode in the new-game leader dialog.
  String get shell_leaderDialog_infiniteModeHelper;

  /// Slider label for terrain noise variation in the new-game leader dialog,
  /// including the current percent value.
  String shell_leaderDialog_terrainVariationLabel(int percent);

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
  String game_intervention_situation(String aggressor, String defender, String intervening);

  /// Button: military intervention on behalf of the defender.
  String get game_intervention_intervene;

  /// Button: decline to intervene.
  String get game_intervention_doNothing;

  /// Button: formal protest without military action.
  String get game_intervention_protest;

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

  /// Label for home army.
  String get military_units_homeArmy;

  /// Label for numbered army.
  String military_units_army(String armyId);

  /// Army subtitle showing regiment count and location.
  String military_units_armySubtitle(int regiments, String location);

  /// Army subtitle showing regiment count, location, and a draft move line.
  String military_units_armySubtitleWithDraft(int regiments, String location, String draftLine);

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

  /// Empty-state line for fleet with no ships.
  String get naval_units_noShipsInFleet;

  /// Cargo capacity line for home fleet.
  String naval_units_cargoCapacity(int capacity);

  /// Cargo capacity line for non-home fleet.
  String naval_units_cargoCapacityIfAssigned(int capacity);

  /// Diplomacy dialog title for setting subsidy amount.
  String get diplomacy_setSubsidy;

  /// Diplomacy dialog title for granting aid amount.
  String get diplomacy_grantAid;

  /// Treasury and step line in diplomacy amount dialog.
  String diplomacy_treasuryStep(int treasury, int step);

  /// Currency amount display in diplomacy amount dialog.
  String diplomacy_currencyAmount(int amount);

  /// Validation text when treasury is below minimum adjustable amount.
  String diplomacy_treasuryBelowMinimum(int step);

  /// Train civilians dialog title.
  String get trainCivilians_title;

  /// Train military dialog title.
  String get trainMilitary_title;

  /// Error text when player has no capital in train dialogs.
  String get trainUnits_noCapital;

  /// Treasury summary line in train dialogs.
  String trainUnits_treasury(String value);

  /// Paper summary line in civilian train dialog.
  String trainUnits_paper(int value);

  /// Peasants summary line in military train dialog.
  String trainUnits_peasants(int value);

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
  String technologyPanel_slotSubtitle(String name, int progress, String costLabel);

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

  /// Snackbar shown when a research slot assignment is removed.
  String get technologyPanel_slotCancelled;

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

  /// Tile section resource label prefix before inline icon/name.
  String get provinceOverlay_tileResourcePrefix;

  /// Tile section prospecting state row.
  String provinceOverlay_tileProspected(String value);

  /// Tooltip and semantics label for province tile prospect shortcut action.
  String get provinceOverlay_tileProspectWithExplorerTooltip;

  /// Tooltip and semantics label for province tile explore shortcut action.
  String get provinceOverlay_tileExploreWithExplorerTooltip;

  /// Tooltip and semantics label for province tile build-improvement shortcut action.
  String get provinceOverlay_tileBuildImprovementTooltip;

  /// Tile section improvement row.
  String provinceOverlay_tileImprovement(String value);

  /// Tile section road/rail row when not applicable.
  String get provinceOverlay_tileRoadNone;

  /// Tile section civilian unit count row.
  String provinceOverlay_tileCivilianUnits(int count);

  /// Political section row for a sea-zone overlay.
  String provinceOverlay_seaZone(String name);

  /// Political section province name row.
  String provinceOverlay_name(String name);

  /// Political section owner row.
  String provinceOverlay_owner(String owner);

  /// Indented count line used in military summary lists.
  String provinceOverlay_indentedCount(String label, int count);

  /// Civilian section line for unit target or status (no internal unit id).
  String provinceOverlay_unitTarget(String type, String target);

  /// Civilian section line for foreign-unit status (no internal unit id).
  String provinceOverlay_foreignUnitStatus(String owner, String type, String status);

  /// Naval section fleet summary line.
  String provinceOverlay_fleetSummary(String owner, String fleetLabel, String shipParts);

  /// Province overlay section heading for political details.
  String get provinceOverlay_sectionPolitical;

  /// Province overlay section heading for tile details.
  String get provinceOverlay_sectionTile;

  /// Province overlay section heading for economic details.
  String get provinceOverlay_sectionEconomic;

  /// Province overlay section heading for military details.
  String get provinceOverlay_sectionMilitary;

  /// Province overlay section heading for civilian details.
  String get provinceOverlay_sectionCivilian;

  /// Province overlay section heading for naval details.
  String get provinceOverlay_sectionNaval;

  /// Game setup screen title.
  String get gameSetup_title;

  /// Eyebrow text rendered uppercased above the Game Setup title in the dark editorial-monocle pixelArt variant.
  String get gameSetup_eyebrow;

  /// Italic intro line shown below the Game Setup title in the dark editorial-monocle pixelArt variant.
  String get gameSetup_intro;

  /// Loading state label while starting a game from setup (retained for backward compatibility; the in-screen dim overlay now uses gameSetup_loadingGeneratingWorld per #2868 R15).
  String get gameSetup_starting;

  /// Loading overlay label shown beneath the spinner while the Game Setup screen is generating a new world (Refs #2868 R15).
  String get gameSetup_loadingGeneratingWorld;

  /// Primary button to begin play from game setup.
  String get gameSetup_startGame;

  /// Back button on game setup screen.
  String get gameSetup_back;

  /// Cancel affordance in the Game Setup action row (Refs #2868 R12; pixelArt variant). Returns the user to the main menu by invoking onBack.
  String get gameSetup_cancel;

  /// Label rendered beside the CtBackButton glyph below the action row in the Game Setup pixelArt variant (Refs #2868 R14). Both the glyph and the label tap target invoke onBack.
  String get gameSetup_backToMainMenu;

  /// Label for the human player slot on game setup.
  String get gameSetup_player1You;

  /// Label for an AI-controlled player slot (n is 2-based index for display).
  String gameSetup_playerAiSlot(int n);

  /// Dropdown hint when choosing a great power nation.
  String get gameSetup_selectNation;

  /// Dropdown hint when choosing a leader variant.
  String get gameSetup_selectLeader;

  /// Tooltip for cycling map base layer display.
  String get mapCorner_tooltipBaseLayer;

  /// Tooltip for centering the map on the home capital.
  String get mapCorner_tooltipCenterCapital;

  /// Tooltip for opening map display options.
  String get mapCorner_tooltipMapDisplayOptions;

  /// Cargo hold usage label on map controls (used and capacity are pre-formatted numbers or em dash).
  String mapControls_cargoHold(String used, String capacity);

  /// Percentage label with no space before percent sign.
  String common_percent(int value);

  /// Accessibility label and tooltip for region minimap zoom slider.
  String get regionMinimap_mapZoom;

  /// Semantics value for zoom slider (spoken).
  String regionMinimap_zoomSemanticsValue(int pct);

  /// Economic row in province overlay: terrain, resource id, and localized detail suffix.
  String province_economic_resourceRow(String terrain, String resourceId, String detail);

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

  /// Great power military/economic score label in diplomacy row.
  String diplomacy_panel_powerScore(int score);

  /// Line showing active subsidy to another faction.
  String diplomacy_panel_outgoingSubsidy(int amount, String target);

  /// Pending grant aid line in diplomacy row.
  String diplomacy_panel_pendingGrant(int amount);

  /// Pending subsidy line in diplomacy row.
  String diplomacy_panel_pendingSubsidy(int amount);

  /// Stock line for a commodity; change is empty or parenthesized delta.
  String production_commodityStock(String name, int qty, String change);

  /// Shows effective labour total in production panel.
  String production_effectiveLabour(int n);

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

  /// Worker type and count in production panel.
  String production_workerCount(String name, int count);

  /// Ship type and hull count in fleet expansion tile.
  String naval_units_shipTypeCount(String typeName, int count);

  /// Bottom sheet title for assigning civilian work.
  String civilian_assignWorkTitle(String unitType);

  /// Commodity name and stock quantity in train military dialog.
  String trainMilitary_commodityAmount(String name, int qty);

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
}
