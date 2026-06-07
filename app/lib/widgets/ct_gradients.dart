import 'package:flutter/painting.dart';

import '../config/editorial_monocle_palette.dart';

/// Shared, token-resolved gradient palette for the dark editorial-monocle
/// theme.
///
/// Implements `Refs #2859` S1. Every Ct-* component that paints a gradient
/// surface (`CtNinePatchButton`, `CtPanel`, `CtDialogShell`, `CtScreenShell`,
/// `CtTopBar`, etc.) MUST source its gradient from this utility so the dark
/// theme remains consistent and tweaks land in one place. All colors resolve
/// from [EditorialMonoclePalette] (issue #2858 tokens); no hard-coded hex.
///
/// SPEC: `SPEC/ui/pixel-art-ui-catalog.md` § Editorial-monocle palette.
class CtGradients {
  CtGradients._();

  /// Top-down vertical gradient for tappable surfaces such as
  /// `CtNinePatchButton`: starts at the lighter raised tone `--surface-lite`
  /// and falls to the canonical row surface `--surface`. The gradient lives
  /// above the nine-patch brass overlays so the button's brass corner
  /// brackets remain visually anchored.
  static LinearGradient get buttonGradient => LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: <Color>[
      EditorialMonoclePalette.surfaceLite,
      EditorialMonoclePalette.surface,
    ],
  );

  /// Three-stop wood-panel gradient used by the `pixelArt` main-menu
  /// wood-panel buttons (`SPEC/ui/main-menu.md` § Buttons region; mockup
  /// `SPEC/ui/mockups/SHEL10002-main-menu.html` `.menu-btn` default
  /// background). Mirrors the mockup `linear-gradient(180deg,
  /// var(--surface-lite) 0%, var(--surface) 40%, var(--bg-deep) 100%)`.
  /// Kept distinct from [buttonGradient] so widespread two-stop
  /// `CtNinePatchButton` callers stay on the canonical 2-stop surface.
  static LinearGradient get woodPanelButtonGradient => LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    stops: const <double>[0.0, 0.4, 1.0],
    colors: <Color>[
      EditorialMonoclePalette.surfaceLite,
      EditorialMonoclePalette.surface,
      EditorialMonoclePalette.bgDeep,
    ],
  );

  /// Inverted three-stop wood-panel gradient applied to the `pixelArt`
  /// main-menu wood-panel buttons in the **pressed** (`:active`) state per
  /// the mockup `.menu-btn:active` rule (`linear-gradient(180deg,
  /// var(--bg-deep) 0%, var(--surface) 40%, var(--surface-lite) 100%)`).
  /// Inversion preserves the same three palette tokens but reverses their
  /// vertical order so the top edge reads darker while the button is held —
  /// the visual "pressed" affordance documented by `SPEC/ui/main-menu.md`
  /// AC `Wood-panel button pressed gradient inversion`.
  static LinearGradient get woodPanelButtonGradientPressed => LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    stops: const <double>[0.0, 0.4, 1.0],
    colors: <Color>[
      EditorialMonoclePalette.bgDeep,
      EditorialMonoclePalette.surface,
      EditorialMonoclePalette.surfaceLite,
    ],
  );

  /// Compact gradient for neutral panel-header **action** text buttons
  /// (`CtActionTextButton`), mirroring the mockup `.action-btn` rule
  /// `linear-gradient(180deg, var(--surface-lite), var(--bg-deep))` in
  /// `SPEC/ui/mockups/GAME20001-production-panel.html` (line 39). The bottom
  /// edge sinks to the deeper `--bg-deep` tone (vs [buttonGradient]'s
  /// `--surface`) so the lighter, brass-bracket-free action button still
  /// reads as a pressable surface against the panel header. Refs #2862 S10.
  static LinearGradient get actionButtonGradient => LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: <Color>[
      EditorialMonoclePalette.surfaceLite,
      EditorialMonoclePalette.bgDeep,
    ],
  );

  /// Vertical gradient for framed sections such as `CtPanel` and
  /// `CtDialogShell`. Matches the button gradient for a single canonical
  /// surface family but uses the deeper `--bg` tone at the bottom to set
  /// panels apart from raised buttons.
  static LinearGradient get panelGradient => LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: <Color>[
      EditorialMonoclePalette.surface,
      EditorialMonoclePalette.bg,
    ],
  );

  /// Horizontal gradient for list rows, transfer cells, and other table-like
  /// surfaces. Subtle left-to-right brightening from `--bg` to `--surface`
  /// keeps row chrome readable without competing with the panel frame.
  static LinearGradient get rowGradient => LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: <Color>[
      EditorialMonoclePalette.bg,
      EditorialMonoclePalette.surface,
    ],
  );

  /// Top-bar gradient used by `CtScreenShell` and `CtTopBar`: top edge is the
  /// raised `--surface-lite` tone, bottom edge falls to `--surface` so the
  /// brass accent border underneath reads cleanly.
  static LinearGradient get topBarGradient => LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: <Color>[
      EditorialMonoclePalette.surfaceLite,
      EditorialMonoclePalette.surface,
    ],
  );

  /// Deeper vertical gradient used by ceremonial brass-bordered overlays
  /// such as the `VictoryOverlay`'s panel (SPEC/ui/victory-overlay.md). Top
  /// edge is the raised `--surface-lite` tone; bottom edge sinks to
  /// `--bg-deep` to read as a heavier ceremonial card distinct from the
  /// canonical [panelGradient].
  static LinearGradient get victoryPanelGradient => LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: <Color>[
      EditorialMonoclePalette.surfaceLite,
      EditorialMonoclePalette.bgDeep,
    ],
  );

  /// Vertical gradient for compact icon-only chrome on the in-game map,
  /// notably the [GameMapEmpireLeftRail](../features/game/flame/game_map_empire_left_rail.dart)
  /// dark editorial-monocle buttons (`SPEC/ui/empire-buttons.md` § Styling,
  /// `SPEC/ui/mockups/GAME10001-game-screen.html` `.empire-btn`).
  ///
  /// Mirrors the `victoryPanelGradient` stops (`--surface-lite` → `--bg-deep`)
  /// but is kept as a separate semantic constant so per-surface tweaks land
  /// in one place. The 36 dp rail surface reads as a raised, pressable button
  /// against the deeper map background while the gradient still anchors the
  /// 1 px `--border` outline used at the surface edge.
  static LinearGradient get railButtonGradient => LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: <Color>[
      EditorialMonoclePalette.surfaceLite,
      EditorialMonoclePalette.bgDeep,
    ],
  );
}
