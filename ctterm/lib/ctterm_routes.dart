// Route enum for ctterm navigation. SPEC/tui/ctterm.md.

/// All top-level routes (main menu + stubs). In-game shell has its own sub-routes.
enum CttermRoute {
  mainMenu,
  gameSetup,
  loadGame,
  generatingWorld,
  settings,
  inGameShell,
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
}
