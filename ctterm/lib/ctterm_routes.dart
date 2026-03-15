// Route enum for ctterm navigation. SPEC/tui/ctterm.md.

/// All top-level routes (main menu + stubs). In-game shell has its own sub-routes.
enum CttermRoute {
  mainMenu,
  gameSetup,
  loadGame,
  generatingWorld,
  settings,
  inGameShell,
  mapContext,
  units,
  development,
  production,
  academy,
  shipyard,
  diplomacy,
  technology,
  victoryProgress,
  victory,
  defeat,
  pauseOptions,
  /// Shown when turn resolution blocks on human accept/reject of diplomatic overtures. SPEC/program/turn-resolution-phases.md.
  pendingOvertures,
  /// Debug log viewer. SPEC/program/debug-log-viewer.md.
  debugLogViewer,
}

/// Unique 6-digit screen ID for each route. Displayed at top of each screen for identification.
/// SPEC/tui/ctterm.md § Screen IDs.
extension CttermRouteScreenId on CttermRoute {
  String get screenId {
    switch (this) {
      case CttermRoute.mainMenu:
        return '100001';
      case CttermRoute.gameSetup:
        return '100002';
      case CttermRoute.loadGame:
        return '100003';
      case CttermRoute.generatingWorld:
        return '100004';
      case CttermRoute.settings:
        return '100005';
      case CttermRoute.inGameShell:
        return '100006';
      case CttermRoute.mapContext:
        return '100007';
      case CttermRoute.units:
        return '100008';
      case CttermRoute.development:
        return '100009';
      case CttermRoute.production:
        return '100010';
      case CttermRoute.academy:
        return '100011';
      case CttermRoute.shipyard:
        return '100012';
      case CttermRoute.diplomacy:
        return '100013';
      case CttermRoute.technology:
        return '100014';
      case CttermRoute.victoryProgress:
        return '100015';
      case CttermRoute.victory:
        return '100016';
      case CttermRoute.defeat:
        return '100017';
      case CttermRoute.pauseOptions:
        return '100018';
      case CttermRoute.pendingOvertures:
        return '100019';
      case CttermRoute.debugLogViewer:
        return '100020';
    }
  }
}
