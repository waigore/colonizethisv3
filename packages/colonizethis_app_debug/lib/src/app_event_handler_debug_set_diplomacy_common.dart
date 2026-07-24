import 'package:colonizethis_models/colonizethis_models.dart';

import 'debug_command_helpers.dart';

/// Outcome of one `/set_diplomacy` action: a mutated [game] + success [message],
/// or an [error] message when the action is rejected. Exactly one of
/// ([game]+[message]) or [error] is populated.
typedef DebugDiplomacyActionOutcome = ({
  Game? game,
  String? message,
  String? error,
});

const kDebugSetDiplomacyPrefix = 'Debug ${DebugCommandLabel.setDiplomacy}';

typedef DebugPendingDiplomacyEvent = ({
  DiplomaticEventType type,
  String from,
  String to,
});

/// Appends [pending] diplomatic events to [game], assigning sequential
/// `intraTurnIndex` values after any existing events for [turn].
Game appendDebugDiplomacyEvents(
  Game game,
  int turn,
  List<DebugPendingDiplomacyEvent> pending,
) {
  if (pending.isEmpty) return game;
  var nextIndex =
      game.diplomaticHistoryEvents.where((e) => e.turn == turn).length;
  final appended = <DiplomaticEvent>[];
  for (final p in pending) {
    appended.add(
      DiplomaticEvent(
        turn: turn,
        intraTurnIndex: nextIndex,
        type: p.type,
        participants: {p.from, p.to},
        fromFactionId: p.from,
        toFactionId: p.to,
      ),
    );
    nextIndex++;
  }
  return game.copyWith(
    diplomaticHistoryEvents: [...game.diplomaticHistoryEvents, ...appended],
  );
}

List<OvertureState> debugOverturesBetween(
  Game game,
  String factionA,
  String factionB,
) =>
    game.overtureStates
        .where((o) => debugOvertureIsBetween(o, factionA, factionB))
        .toList(growable: false);

bool debugOvertureIsBetween(OvertureState o, String factionA, String factionB) =>
    (o.gpId == factionA && o.targetId == factionB) ||
    (o.gpId == factionB && o.targetId == factionA);

/// Resolves a raw faction input (canonical id or display name) to a faction id.
///
/// Exact id match wins (case-sensitive). Otherwise matches a display name
/// case-insensitively across players, minor nations and tribes. Ambiguous
/// display-name matches and unknown inputs return an [error]. Refs #3650.
({String? id, String? error}) resolveDebugDiplomacyFaction(
  Game game,
  String rawInput,
) {
  final input = rawInput.trim();
  if (input.isEmpty) {
    return (id: null, error: '$kDebugSetDiplomacyPrefix rejected: empty faction identifier.');
  }

  final ids = <String>{
    ...game.players.map((p) => p.id),
    ...game.minorNations.map((m) => m.id),
    ...game.tribes.map((t) => t.id),
  };
  if (ids.contains(input)) {
    return (id: input, error: null);
  }

  final normalized = input.toLowerCase();
  final matches = <String>{};
  for (final p in game.players) {
    if (p.displayName.trim().toLowerCase() == normalized) matches.add(p.id);
  }
  for (final m in game.minorNations) {
    if ((m.displayName ?? '').trim().toLowerCase() == normalized) {
      matches.add(m.id);
    }
  }
  for (final t in game.tribes) {
    if ((t.displayName ?? '').trim().toLowerCase() == normalized) {
      matches.add(t.id);
    }
  }

  if (matches.isEmpty) {
    return (id: null, error: 'Faction not found: $input');
  }
  if (matches.length > 1) {
    final sorted = matches.toList()..sort();
    return (
      id: null,
      error: '$kDebugSetDiplomacyPrefix rejected: faction "$input" is ambiguous. '
          'Candidates: ${sorted.join(', ')}. Retry with a faction id.',
    );
  }
  return (id: matches.single, error: null);
}
