// Shared lightweight, hand-built [Game] fixtures for app panel widget tests.
//
// Split into focused modules under `panel_fixtures/`; import via
// `panel_test_fixtures.dart` barrel (Refs #3847).

import 'package:colonizethis_models/colonizethis_models.dart';

import 'core.dart';

/// Lightweight game shaped for `grant_or_subsidy_listener_test`.
///
/// `GrantOrSubsidyListener` reads only `game.playerById(targetFactionId)` (and
/// `minorNations` / `tribes` fallbacks) for the confirmation-dialog target name,
/// plus `game.worldState.turnState.turnNumber` and `game.globalGameSeed` for the
/// negotiation-mood event seed — never any generated map/topology data. The
/// fixture provides one human ([kPanelTestHumanPlayerId]) and one AI great power
/// so the suite can resolve a human payer and a non-human grant/subsidy target.
Game buildGrantOrSubsidyListenerTestGame() => buildPanelTestGame(
  id: 'grant-subsidy-listener-widget-test',
  players: [
    panelTestHumanPlayer(),
    const Player(id: 'gp2', displayName: 'Rival Power', isHuman: false),
  ],
);
