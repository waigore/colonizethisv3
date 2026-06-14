/// Viewport width threshold in **logical pixels** below which the in-game shell uses
/// narrow layout (side menu, reduced top bar). SPEC/ui/in-game-shell-narrow.md.
const double kNarrowBreakpoint = 600;

/// Viewport width threshold in **logical pixels** below which Game Setup uses stacked
/// slot rows. Intentionally lower than [kNarrowBreakpoint] so setup can stay multi-column
/// on widths where the in-game shell is already narrow. SPEC/ui/mobile-adaptation.md;
/// Narrow-viewport breakpoint for new-game leader selection slot rows.
/// SPEC/ui/new-game-leader-selection-dialog.md.
const double kGameSetupNarrowBreakpoint = 500;

/// Minimum supported viewport width in **logical pixels**. Every screen covered
/// by `SPEC/ui/mobile-adaptation.md` must render at this width without
/// horizontal overflow or `RenderFlex` overflow exceptions.
///
/// Source: `SPEC/ui/mobile-adaptation.md` § Scope (Target min ~320 dp width)
/// and issue #2870 § Acceptance criteria (320 dp no horizontal overflow,
/// 44 dp touch targets).
const double kMinViewportWidth = 320;

/// Minimum touch-target size in **logical pixels** for any interactive
/// element (button, list tile, dropdown, chip). Mirrors UXD 03 and
/// `SPEC/ui/mobile-adaptation.md` § 1 Touch targets.
const double kMinTouchTargetSize = 44;

/// App and Hive constants. TDD 15 Local Storage box names.
abstract final class HiveBoxNames {
  static const String settings = 'settings';
  static const String games = 'games';
  static const String offlineQueue = 'offline_queue';
}

/// Desktop window minimum width in logical pixels.
const double kDesktopWindowMinWidth = 800;

/// Desktop window minimum height in logical pixels.
const double kDesktopWindowMinHeight = 600;

/// Desktop window fallback width in logical pixels.
const double kDesktopWindowDefaultWidth = 1280;

/// Desktop window fallback height in logical pixels.
const double kDesktopWindowDefaultHeight = 720;
