/// Stable screen identifiers for player-app UI.
///
/// Format: 3-letter category + 1 sub-flow digit + 4 screen digits.
/// Variants use a lowercase suffix in specs (e.g. [gameScreen] + `a` → `GAME10001a`).
/// Registry: SPEC/ui/screen-registry.md. Rule: .cursor/rules/colonizethis-ui-documentation.mdc.
abstract final class UiScreenIds {
  // SHEL — shell, menu, setup
  static const String shellScreen = 'SHEL10001';
  static const String mainMenu = 'SHEL10002';
  static const String gameSetup = 'SHEL20001';

  // GAME — in-game route hosts
  static const String gameScreen = 'GAME10001';
  static const String productionScreen = 'GAME20001';
  static const String diplomacyScreen = 'GAME30001';
  static const String technologyScreen = 'GAME40001';

  // MAP — map surfaces
  static const String empireOverviewMapArea = 'MAP10001';
  static const String provinceSeaZoneOverlay = 'MAP20001';

  // OVL — overlays
  static const String gameStartIntroOverlay = 'OVL10001';
  static const String victoryOverlay = 'OVL20001';
  static const String overtureDialogueOverlay = 'OVL30001';
}
