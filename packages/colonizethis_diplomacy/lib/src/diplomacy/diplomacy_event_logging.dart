import 'package:colonizethis_models/colonizethis_models.dart';

import 'diplomacy_logging.dart';

/// Mutable per-turn tally for [appendDiplomaticEvent] `intraTurnIndex` assignment.
///
/// Built once from existing history at phase start; each [nextIndex] is O(1)
/// instead of filtering `diplomaticHistoryEvents` on every append (Refs #3419
/// step 7).
class IntraTurnEventTally {
  IntraTurnEventTally._(Map<int, int> countByTurn)
    : _countByTurn = Map<int, int>.from(countByTurn);

  factory IntraTurnEventTally.fromEvents(List<DiplomaticEvent> events) {
    final counts = <int, int>{};
    for (final e in events) {
      counts[e.turn] = (counts[e.turn] ?? 0) + 1;
    }
    return IntraTurnEventTally._(counts);
  }

  factory IntraTurnEventTally.fromGame(Game game) =>
      IntraTurnEventTally.fromEvents(game.diplomaticHistoryEvents);

  final Map<int, int> _countByTurn;

  /// Returns the next intra-turn index for [turn] and advances the tally.
  int nextIndex(int turn) {
    final idx = _countByTurn[turn] ?? 0;
    _countByTurn[turn] = idx + 1;
    return idx;
  }
}

/// Appends one diplomatic history event to [game] with the next intra-turn index.
Game appendDiplomaticEvent(
  Game game,
  int turn,
  DiplomaticEventType type,
  Set<String> participants, {
  String? fromFactionId,
  String? toFactionId,
  OvertureStage? overtureStage,
  int? amount,
  String? reason,
  bool wasAiInitiator = false,
  IntraTurnEventTally? eventTally,
}) {
  final events = game.diplomaticHistoryEvents;
  final intraTurnIndex = eventTally != null
      ? eventTally.nextIndex(turn)
      : events.where((e) => e.turn == turn).length;
  final event = DiplomaticEvent(
    turn: turn,
    intraTurnIndex: intraTurnIndex,
    type: type,
    participants: participants,
    fromFactionId: fromFactionId,
    toFactionId: toFactionId,
    overtureStage: overtureStage,
    amount: amount,
    reason: reason,
    wasAiInitiator: wasAiInitiator,
  );
  return game.copyWith(diplomaticHistoryEvents: [...events, event]);
}

/// Appends a diplomatic [type] event via [appendDiplomaticEvent] and emits the
/// operator-facing [logMessage] in a single call.
///
/// Collapses the repeated `appendDiplomaticEvent(...)` + `diploLog.i(...)`
/// pairing duplicated across the diplomacy resolvers (Refs #3562, #3825). All
/// event parameters mirror [appendDiplomaticEvent]; the only addition is the
/// required [logMessage], so callers keep their existing per-site log text.
Game logDiplomaticEvent(
  Game game,
  int turn,
  DiplomaticEventType type,
  Set<String> participants, {
  required String logMessage,
  String? fromFactionId,
  String? toFactionId,
  OvertureStage? overtureStage,
  int? amount,
  String? reason,
  bool wasAiInitiator = false,
  IntraTurnEventTally? eventTally,
}) {
  final next = appendDiplomaticEvent(
    game,
    turn,
    type,
    participants,
    fromFactionId: fromFactionId,
    toFactionId: toFactionId,
    overtureStage: overtureStage,
    amount: amount,
    reason: reason,
    wasAiInitiator: wasAiInitiator,
    eventTally: eventTally,
  );
  diploLog.i(logMessage);
  return next;
}
