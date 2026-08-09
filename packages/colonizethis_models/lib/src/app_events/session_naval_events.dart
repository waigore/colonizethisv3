/// Naval session commands (Refs #4136 Slice B).

import '../game.dart';
import '../orders.dart';
import 'session_command_event_base.dart';

/// Naval panel produced an updated [game] (split/combine). Handler updates session game.
class NavalFleetsUpdatedEvent extends SessionCommandEvent {
  NavalFleetsUpdatedEvent({required this.game});

  final Game game;
}

/// Split fleet dialog confirm: shell applies split and emits [NavalFleetsUpdatedEvent]
/// (same pipeline as combine). SPEC/program/app-ui-wiring.md.
class NavalSplitFleetRequestedEvent extends SessionCommandEvent {
  NavalSplitFleetRequestedEvent({
    required this.humanPlayerId,
    required this.originalFleetId,
    required this.shipInstanceIdsToNewFleet,
  });

  final String humanPlayerId;
  final String originalFleetId;
  final List<String> shipInstanceIdsToNewFleet;
}

/// Transfer selected ship instances from one existing fleet into another.
/// Shell listener applies canonical fleet mutation and emits
/// [NavalFleetsUpdatedEvent]. SPEC/program/app-ui-wiring.md.
class NavalTransferShipsRequestedEvent extends SessionCommandEvent {
  NavalTransferShipsRequestedEvent({
    required this.humanPlayerId,
    required this.sourceFleetId,
    required this.targetFleetId,
    required this.shipInstanceIdsToTransfer,
  });

  final String humanPlayerId;
  final String sourceFleetId;
  final String targetFleetId;
  final List<String> shipInstanceIdsToTransfer;
}

/// Move fleet dialog confirm: shell merges [moveOrder] into current-turn draft orders.
/// SPEC/program/app-ui-wiring.md.
class NavalMoveFleetRequestedEvent extends SessionCommandEvent {
  NavalMoveFleetRequestedEvent({
    required this.humanPlayerId,
    required this.moveOrder,
  });

  final String humanPlayerId;
  final NavalMoveOrder moveOrder;
}

/// Naval mission assign: shell merges [missionOrder] into current-turn draft orders.
/// Replaces any prior mission for that fleet and clears pending naval move (xor).
/// SPEC/program/app-ui-wiring.md; Refs #4213.
class NavalMissionRequestedEvent extends SessionCommandEvent {
  NavalMissionRequestedEvent({
    required this.humanPlayerId,
    required this.missionOrder,
  });

  final String humanPlayerId;
  final NavalMissionOrder missionOrder;
}

/// Cancel pending naval mission for [fleetId] in the current-turn draft.
/// SPEC/program/app-ui-wiring.md; Refs #4213.
class NavalMissionCancelRequestedEvent extends SessionCommandEvent {
  NavalMissionCancelRequestedEvent({
    required this.humanPlayerId,
    required this.fleetId,
  });

  final String humanPlayerId;
  final String fleetId;
}
