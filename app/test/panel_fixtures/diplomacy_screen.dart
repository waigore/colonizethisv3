// Screen-family diplomacy fixtures (Refs #3847 / #4734 Slice F).

import 'package:colonizethis_models/colonizethis_models.dart';

import 'core.dart';

/// Lightweight game shaped for the in-game Diplomacy *screen* family
/// (`diplomacy_screen_test`, `diplomacy_screen_top_bar_test`,
/// `diplomacy_screen_320dp_min_viewport_test`, `diplomacy_dialogs_test`).
Game buildDiplomacyScreenTestGame() {
  return buildPanelTestGame(
    id: 'diplomacy-screen-widget-test',
    players: const [
      Player(
        id: kPanelTestHumanPlayerId,
        displayName: 'Test Human',
        isHuman: true,
        treasury: 5000,
      ),
      Player(id: 'gp2', displayName: 'Rival Power', isHuman: false),
    ],
  );
}
