// Main-menu visual variant and content-state enums.
//
// SPEC/ui/main-menu.md; UXD 03a. Shared by the de-parted main-menu libraries
// (Refs #4117).

/// Visual variant of the main menu. SPEC/ui/main-menu.md; UXD 03a.
enum MainMenuVariant {
  /// Theme-scaffold only fallback: standard Flutter widgets with the
  /// running app theme; no SVG collage, no compass rose, no fleur-de-lis,
  /// no brass divider, no scroll brackets, no wood-panel chrome. See
  /// `SPEC/ui/main-menu.md` § Variant rendering.
  plain,

  /// Dark editorial-monocle layout per
  /// `SPEC/ui/mockups/SHEL10002-main-menu.html`: [CtMainMenuCollage]
  /// background, [CtCompassRose] above the title row, title flanked by two
  /// [CtFleurDeLisOrnament]s, [CtBrassDivider] between the logo region and
  /// the buttons region. Rendered under [AppThemes.editorialMonocle] and
  /// [EditorialMonoclePalette] tokens.
  pixelArt,
}

/// Content state of the main menu. SPEC/ui/main-menu.md; UXD 03a.
enum MainMenuState {
  /// Default: no subtitle; Load Game always enabled (empty dialog when no saves).
  default_,

  /// After victory: show subtitle "Congratulations, you won your last game."
  afterVictory,

  /// Legacy Widgetbook variant; Load Game remains enabled on the product path.
  noSaves,
}
