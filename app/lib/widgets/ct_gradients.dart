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
}
