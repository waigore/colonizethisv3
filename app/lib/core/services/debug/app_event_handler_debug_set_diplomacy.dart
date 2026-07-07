import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'debug_command_helpers.dart';

part 'app_event_handler_debug_set_diplomacy_alliance.dart';
part 'app_event_handler_debug_set_diplomacy_ftp.dart';
part 'app_event_handler_debug_set_diplomacy_overtures.dart';
part 'app_event_handler_debug_set_diplomacy_war_peace.dart';

/// Outcome of one `/set_diplomacy` action: a mutated [game] + success [message],
/// or an [error] message when the action is rejected. Exactly one of
/// ([game]+[message]) or [error] is populated.
typedef _DiplomacyActionOutcome = ({Game? game, String? message, String? error});

const _kPrefix = 'Debug ${DebugCommandLabel.setDiplomacy}';

/// Applies an immediate, direct diplomacy-relation mutation between two factions
/// from the debug console (`/set_diplomacy`).
///
/// Bypasses normal diplomacy resolution: it mutates `Game` state directly,
/// enforces hard-incompatibility validation, a per-pair-per-turn quota, the
/// `TurnPhase.orders` gate, `war` side effects (clearing overtures + FTP), and
/// appends [DiplomaticEvent] history. Debug tool only.
/// SPEC/ui/debug-console-panel.md, SPEC/program/debug-console-internals.md.
DebugCommandResult applyDebugSetDiplomacyRelation({
  required Game? currentGame,
  required SetDebugDiplomacyRelationEvent event,
}) {
  if (currentGame == null) {
    return debugNoActiveGame(DebugCommandLabel.setDiplomacy);
  }
  final game = currentGame;
  if (game.worldState.turnState.phase != TurnPhase.orders) {
    return debugOrdersPhaseRejected(DebugCommandLabel.setDiplomacy);
  }

  final resolvedA = _resolveFaction(game, event.factionA ?? event.humanPlayerId);
  if (resolvedA.error != null) {
    return (game: null, message: resolvedA.error!);
  }
  final resolvedB = _resolveFaction(game, event.factionB);
  if (resolvedB.error != null) {
    return (game: null, message: resolvedB.error!);
  }
  final factionA = resolvedA.id!;
  final factionB = resolvedB.id!;

  if (factionA == factionB) {
    return (
      game: null,
      message: '$_kPrefix rejected: a faction cannot set a relation with '
          'itself.',
    );
  }

  final key = pairKey(factionA, factionB);
  if (game.debugDiplomacyUsedPairKeys.contains(key)) {
    return (
      game: null,
      message: '$_kPrefix rejected: already used debug diplomacy for this pair '
          'this turn.',
    );
  }

  final outcome = _applyAction(
    game: game,
    factionA: factionA,
    factionB: factionB,
    action: event.action,
  );
  if (outcome.error != null) {
    return (game: null, message: outcome.error!);
  }
  final mutated = outcome.game!;
  final nextGame = mutated.copyWith(
    debugDiplomacyUsedPairKeys: {...mutated.debugDiplomacyUsedPairKeys, key},
  );
  return (game: nextGame, message: outcome.message!);
}

_DiplomacyActionOutcome _applyAction({
  required Game game,
  required String factionA,
  required String factionB,
  required DebugDiplomacyAction action,
}) {
  final turn = game.worldState.turnState.turnNumber;
  return switch (action) {
    DebugDiplomacyAction.war => _applyWar(game, factionA, factionB, turn),
    DebugDiplomacyAction.peace => _applyPeace(game, factionA, factionB, turn),
    DebugDiplomacyAction.alliance =>
      _applyAlliance(game, factionA, factionB, turn),
    DebugDiplomacyAction.noAlliance =>
      _applyNoAlliance(game, factionA, factionB, turn),
    DebugDiplomacyAction.consulate => _applyOverture(
      game,
      factionA,
      factionB,
      turn,
      OvertureStage.tradeConsulate,
    ),
    DebugDiplomacyAction.embassy => _applyOverture(
      game,
      factionA,
      factionB,
      turn,
      OvertureStage.embassy,
    ),
    DebugDiplomacyAction.nap => _applyOverture(
      game,
      factionA,
      factionB,
      turn,
      OvertureStage.nap,
    ),
    DebugDiplomacyAction.joinEmpire => _applyOverture(
      game,
      factionA,
      factionB,
      turn,
      OvertureStage.joinEmpire,
    ),
    DebugDiplomacyAction.clearOverture =>
      _applyClearOverture(game, factionA, factionB),
    DebugDiplomacyAction.ftp => _applyFtp(game, factionA, factionB, turn),
    DebugDiplomacyAction.noFtp => _applyNoFtp(game, factionA, factionB, turn),
  };
}

typedef _PendingEvent = ({
  DiplomaticEventType type,
  String from,
  String to,
});

/// Appends [pending] diplomatic events to [game], assigning sequential
/// `intraTurnIndex` values after any existing events for [turn].
Game _appendEvents(Game game, int turn, List<_PendingEvent> pending) {
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

List<OvertureState> _overturesBetween(Game game, String factionA, String factionB) =>
    game.overtureStates
        .where((o) => _isBetween(o, factionA, factionB))
        .toList(growable: false);

bool _isBetween(OvertureState o, String factionA, String factionB) =>
    (o.gpId == factionA && o.targetId == factionB) ||
    (o.gpId == factionB && o.targetId == factionA);

/// Resolves a raw faction input (canonical id or display name) to a faction id.
///
/// Exact id match wins (case-sensitive). Otherwise matches a display name
/// case-insensitively across players, minor nations and tribes. Ambiguous
/// display-name matches and unknown inputs return an [error]. Refs #3650.
({String? id, String? error}) _resolveFaction(Game game, String rawInput) {
  final input = rawInput.trim();
  if (input.isEmpty) {
    return (id: null, error: '$_kPrefix rejected: empty faction identifier.');
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
      error: '$_kPrefix rejected: faction "$input" is ambiguous. '
          'Candidates: ${sorted.join(', ')}. Retry with a faction id.',
    );
  }
  return (id: matches.single, error: null);
}
