// Shared lightweight, hand-built [Game] fixtures for app panel widget tests.
//
// Split into focused modules under `panel_fixtures/`; import via
// `panel_test_fixtures.dart` barrel (Refs #3847).

import 'package:colonizethis_models/colonizethis_models.dart';

import 'core.dart';

/// Lightweight game shaped for the `trade_screen_*` scaffold/viewport family
/// (`trade_screen_scaffold_test`, `trade_screen_320dp_min_viewport_test`,
/// `trade_screen_issue_acceptance_criteria_e8_test` route-host tests).
///
/// `TradeScreen` (via `CtGameFeatureScreenShell`) reads only `game.players` for
/// the supplied `player`, the static `CommodityCatalog` for the read-only
/// market table, and `game.worldMarketState` (default-empty here) for the Deal
/// Book panels — no generated map/topology data. With the default empty
/// `WorldMarketState`, the Deal Book renders its empty bids/offers panels and
/// the market table renders its catalog-derived rows, so the scaffold/chrome
/// and minimum-viewport assertions hold without procedural map generation.
Game buildTradePanelTestGame() {
  return buildPanelTestGame(
    id: 'trade-panel-widget-test',
    players: [panelTestHumanPlayer()],
  );
}
