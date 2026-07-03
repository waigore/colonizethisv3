// Shared lightweight, hand-built [Game] fixtures for app panel widget tests.
//
// Split into focused modules under `panel_fixtures/`; import via
// `panel_test_fixtures.dart` barrel (Refs #3847).

import 'package:colonizethis_models/colonizethis_models.dart';

import 'core.dart';

/// Lightweight game shaped for the `technology_panel_*` family
/// (`technology_panel_test`, `technology_panel_dark_chrome_test`,
/// `technology_panel_funding_toggles_test`,
/// `technology_panel_choose_tech_dialog_test`,
/// `technology_panel_interaction_test`).
///
/// `TechnologyPanel` reads only `game.players` — its `player` argument and the
/// `game.copyWith(players: …)` overrides each suite applies. Research slots,
/// researched chips, and the choose-tech options derive from `player` tech state
/// plus the static `techCatalog`; no generated map/topology data is consumed.
///
/// The single human starts with no researched tech and the default research-slot
/// count (`player.researchSlots ?? 3` → three active + one locked), so the base
/// "None yet" / all-techs-available assertions hold. Suites override
/// `techUnlocked`, `researchSlots`, `researchProgressByTechId`, etc. via
/// `copyWith`; `game.players.skip(1)` is empty for the single-player shape, which
/// the panel handles since it only renders the supplied `player`.
Game buildTechnologyPanelTestGame() {
  return buildPanelTestGame(
    id: 'technology-panel-widget-test',
    players: [panelTestHumanPlayer()],
  );
}
