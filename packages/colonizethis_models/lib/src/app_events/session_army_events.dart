/// Army session commands (Refs #4136 Slice B).

import '../game.dart';
import '../orders.dart';
import 'session_command_event_base.dart';

/// Military units panel: game state updated after army split/combine.
/// SPEC/program/app-ui-wiring.md.
class LandArmiesUpdatedEvent extends SessionCommandEvent {
  LandArmiesUpdatedEvent({required this.game});

  final Game game;
}

/// Combine selected armies in the same province (shell applies colonizethis_logic).
class ArmyCombineRequestedEvent extends SessionCommandEvent {
  ArmyCombineRequestedEvent({
    required this.humanPlayerId,
    required this.armyIds,
  });

  final String humanPlayerId;
  final List<String> armyIds;
}

/// Split confirmed from split-army dialog (shell applies colonizethis_logic).
class ArmySplitRequestedEvent extends SessionCommandEvent {
  ArmySplitRequestedEvent({
    required this.humanPlayerId,
    required this.sourceArmyId,
    required this.unitIdsToMove,
  });

  final String humanPlayerId;
  final String sourceArmyId;
  final List<String> unitIdsToMove;
}

/// Move army dialog confirm: merges [moveOrder] into current-turn draft orders.
///
/// When [declareWarTargetFactionId] is set, the shell appends a same-turn
/// `declareWar` on that faction before applying [moveOrder] (invasion path).
class ArmyMoveRequestedEvent extends SessionCommandEvent {
  ArmyMoveRequestedEvent({
    required this.humanPlayerId,
    required this.moveOrder,
    this.declareWarTargetFactionId,
  });

  final String humanPlayerId;
  final ArmyMoveOrder moveOrder;

  /// Great Power / Minor / Tribe id to declare war on when the move required
  /// the invasion confirmation flow. Null for normal moves and when already at war.
  final String? declareWarTargetFactionId;
}
