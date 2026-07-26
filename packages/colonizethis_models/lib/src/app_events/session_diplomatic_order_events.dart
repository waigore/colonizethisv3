/// Diplomatic-order session commands (Refs #4136 Slice B).

import '../diplomacy.dart';
import 'session_command_event_base.dart';

/// Request to append one diplomatic order for [playerId] in current-turn draft.
class AppendDiplomaticOrderRequestedEvent extends SessionCommandEvent {
  AppendDiplomaticOrderRequestedEvent({
    required this.playerId,
    required this.order,
  });

  final String playerId;
  final DiplomaticOrder order;
}

/// Request to remove one pending diplomatic order by [type] and [targetFactionId]
/// for [playerId] in current-turn draft.
class RemoveDiplomaticOrderRequestedEvent extends SessionCommandEvent {
  RemoveDiplomaticOrderRequestedEvent({
    required this.playerId,
    required this.type,
    required this.targetFactionId,
  });

  final String playerId;
  final DiplomaticOrderType type;
  final String targetFactionId;
}

/// Immediate voluntary Break Alliance from the diplomacy panel (Refs #3811).
///
/// Applies break penalties inline during Orders phase without queuing a
/// pending `DiplomaticOrder`. SPEC/ui/diplomacy-panel.md § Submitting an action.
class BreakAllianceImmediatelyEvent extends SessionCommandEvent {
  BreakAllianceImmediatelyEvent({
    required this.playerId,
    required this.targetFactionId,
  });

  final String playerId;
  final String targetFactionId;
}

/// Negotiation UI mood input for portrait transitions.
///
/// UI supplies deterministic negotiation inputs; session listeners compute the
/// next mood and emit [PortraitMoodEvent] when the mood changes.
class NegotiationMoodUpdateEvent extends SessionCommandEvent {
  const NegotiationMoodUpdateEvent({
    required this.leaderId,
    required this.currentMood,
    required this.offerQualityDelta,
    required this.stallCounter,
    required this.seed,
    this.durationMs = 1200,
  });

  final String leaderId;
  final String currentMood;
  final double offerQualityDelta;
  final int stallCounter;
  final int seed;
  final int durationMs;
}
