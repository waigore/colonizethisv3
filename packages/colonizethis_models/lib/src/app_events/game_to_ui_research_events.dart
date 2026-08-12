/// Research mirror Game-to-UI events (Refs #4334 wave 3).
/// SPEC/program/game-event-bridge.md

import 'game_to_ui_event_base.dart';

/// Technology research completed. Mirrors colonizethis_logic ResearchCompleteEvent.
class AppResearchCompleteEvent extends GameToUIEvent {
  const AppResearchCompleteEvent({
    required this.playerId,
    required this.techId,
    required this.turnNumber,
  });
  final String playerId;
  final String techId;
  final int turnNumber;
}

/// Victory condition set. Mirrors colonizethis_logic VictorySetEvent.
class AppVictorySetEvent extends GameToUIEvent {
  const AppVictorySetEvent({
    required this.winnerPlayerId,
    required this.victoryType,
    required this.turnNumber,
  });
  final String winnerPlayerId;
  final String victoryType;
  final int turnNumber;
}
