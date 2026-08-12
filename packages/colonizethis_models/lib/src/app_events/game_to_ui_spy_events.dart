/// Spy mirror Game-to-UI events (Refs #4334 wave 3).
/// SPEC/program/game-event-bridge.md

import 'game_to_ui_event_base.dart';

/// Spy killed in foreign territory. Mirrors colonizethis_logic SpyCaughtEvent.
class AppSpyCaughtEvent extends GameToUIEvent {
  const AppSpyCaughtEvent({
    required this.unitId,
    required this.spyOwnerId,
    required this.territoryOwnerId,
    required this.provinceId,
    required this.turnNumber,
  });
  final String unitId;
  final String spyOwnerId;
  final String territoryOwnerId;
  final String provinceId;
  final int turnNumber;
}

/// Spy defected to counter-espionage runner. Mirrors colonizethis_logic SpyDefectedEvent.
class AppSpyDefectedEvent extends GameToUIEvent {
  const AppSpyDefectedEvent({
    required this.unitId,
    required this.previousOwnerId,
    required this.newOwnerId,
    required this.provinceId,
    required this.turnNumber,
  });
  final String unitId;
  final String previousOwnerId;
  final String newOwnerId;
  final String provinceId;
  final int turnNumber;
}
