/// Stable screen identifiers for player-app UI.
///
/// Format: 3-letter category + 1 sub-flow digit + 4 screen digits.
/// Variants use a lowercase suffix in specs (e.g. [gameScreen] + `a` → `GAME10001a`).
/// Registry: SPEC/ui/screen-registry.md. Rule: .cursor/rules/colonizethis-ui-documentation.mdc.
abstract final class UiScreenIds {
  // SHEL — shell, menu, setup, pause menu
  static const String shellScreen = 'SHEL10001';
  static const String mainMenu = 'SHEL10002';
  static const String gameInitializing = 'SHEL30001';
  static const String pauseMenuPanel = 'SHEL40001';

  // GAME — in-game route hosts and side menu
  static const String gameScreen = 'GAME10001';
  static const String productionScreen = 'GAME20001';
  static const String diplomacyScreen = 'GAME30001';
  static const String diplomacyDetailScreen = 'GAME30002';
  static const String technologyScreen = 'GAME40001';
  static const String gameSideMenu = 'GAME50001';
  static const String tradeScreen = 'GAME60001';

  // MAP — map surfaces
  static const String empireOverviewMapArea = 'MAP10001';
  static const String provinceSeaZoneOverlay = 'MAP20001';

  // UNIT — unit management panels and train dialogs
  static const String civilianUnitsPanel = 'UNIT10001';
  static const String militaryUnitsPanel = 'UNIT20001';
  static const String navalUnitsPanel = 'UNIT30001';
  static const String trainCiviliansDialog = 'UNIT40001';
  static const String trainMilitaryDialog = 'UNIT50001';

  // DIPL — diplomacy auxiliary dialogs
  static const String grantOrSubsidyDialog = 'DIPL20001';

  // PROD — production auxiliary dialogs
  static const String productionCommodityBreakdownDialog = 'PROD20001';

  // CMPT — combat surfaces
  static const String combatModeChoiceDialog = 'CMPT10001';
  static const String quickBattleScreen = 'CMPT20001';
  static const String quickBattleResultDialog = 'CMPT50001';

  // OVL — overlays and narrative UI
  static const String gameStartIntroOverlay = 'OVL10001';
  static const String victoryOverlay = 'OVL20001';
  static const String overtureDialogueOverlay = 'OVL30001';
  static const String callToArmsDialogueOverlay = 'OVL40001';
  static const String pendingInterventionOverlay = 'OVL50001';
  static const String observeModeOverlay = 'OVL60001';
  static const String playerTurnEventFeed = 'OVL70001';
  static const String tribeFirstContactOverlay = 'OVL80001';

  // DLG — modal dialogs (non-route)
  static const String newGameLeaderSelectionDialog = 'DLG10001';
  static const String moveArmyDialog = 'DLG20001';
  static const String moveFleetDialog = 'DLG30001';
  static const String transferToHomeFleetDialog = 'DLG40001';
  static const String turnNewsDialog = 'DLG50001';
  static const String nextTurnConfirmation = 'DLG60001';

  // SYS — system / debug surfaces
  static const String debugLogViewer = 'SYS10001';
  static const String debugConsolePanel = 'SYS20001';
}
