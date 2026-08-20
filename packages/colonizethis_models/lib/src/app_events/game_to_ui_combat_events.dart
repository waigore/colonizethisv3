/// Combat mirror Game-to-UI events (Refs #4334 wave 3).
/// SPEC/program/game-event-bridge.md

import 'game_to_ui_event_base.dart';

/// Combat resolved in a province. Mirrors colonizethis_logic CombatResultEvent.
class AppCombatResultEvent extends GameToUIEvent {
  const AppCombatResultEvent({
    required this.provinceId,
    required this.attackerId,
    required this.defenderId,
    required this.outcomeName,
    required this.turnNumber,
    this.winnerId,
    this.attackerCasualtyCount = 0,
    this.defenderCasualtyCount = 0,
    this.casualties = const {},
  });
  final String provinceId;
  final String attackerId;
  final String defenderId;
  final String outcomeName;
  final String? winnerId;
  final int turnNumber;
  final int attackerCasualtyCount;
  final int defenderCasualtyCount;
  final Map<String, int> casualties;
}

/// General medals increased after a land battle win. Mirrors [GeneralMedalGainedEvent].
class AppGeneralMedalGainedEvent extends GameToUIEvent {
  const AppGeneralMedalGainedEvent({
    required this.playerId,
    required this.generalId,
    required this.provinceId,
    required this.newMedals,
    required this.turnNumber,
  });

  final String playerId;
  final String generalId;
  final String provinceId;
  final int newMedals;
  final int turnNumber;
}

/// Naval battle resolved in a sea zone. Mirrors colonizethis_logic NavalCombatResultEvent.
class AppNavalCombatResultEvent extends GameToUIEvent {
  const AppNavalCombatResultEvent({
    required this.seaZoneId,
    required this.side1OwnerId,
    required this.side2OwnerId,
    required this.outcomeName,
    required this.turnNumber,
    this.winnerOwnerId,
    this.side1Retreated = false,
    this.side2Retreated = false,
  });
  final String seaZoneId;
  final String side1OwnerId;
  final String side2OwnerId;
  final String outcomeName;
  final int turnNumber;
  final String? winnerOwnerId;
  final bool side1Retreated;
  final bool side2Retreated;
}
