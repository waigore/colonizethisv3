/// Viewport width threshold in **logical pixels** below which the in-game shell uses
/// narrow layout (side menu, reduced top bar). SPEC/ui/in-game-shell-narrow.md.
const double kNarrowBreakpoint = 600;

/// Viewport width threshold in **logical pixels** below which Game Setup uses stacked
/// slot rows. Intentionally lower than [kNarrowBreakpoint] so setup can stay multi-column
/// on widths where the in-game shell is already narrow. SPEC/ui/mobile-adaptation.md;
/// SPEC/ui/game-setup.md.
const double kGameSetupNarrowBreakpoint = 500;

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
