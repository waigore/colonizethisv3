import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'debug_command_helpers.dart';

/// Outcome of one `/set_diplomacy` action: a mutated [game] + success [message],
/// or an [error] message when the action is rejected. Exactly one of
/// ([game]+[message]) or [error] is populated.
typedef _DiplomacyActionOutcome = ({Game? game, String? message, String? error});

const _kPrefix = 'Debug set_diplomacy';

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
  final game = currentGame;
  if (game == null) {
    return (game: null, message: '$_kPrefix ignored: no active game.');
  }
  if (game.worldState.turnState.phase != TurnPhase.orders) {
    return (
      game: null,
      message: '$_kPrefix rejected: command is allowed only during human '
          'Orders phase.',
    );
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

_DiplomacyActionOutcome _applyWar(
  Game game,
  String factionA,
  String factionB,
  int turn,
) {
  final rel = getRelation(game, factionA, factionB);
  if (rel?.formalAlliance ?? false) {
    return (
      game: null,
      message: null,
      error: '$_kPrefix rejected: a formal alliance exists between $factionA '
          'and $factionB. Use no_alliance before declaring war.',
    );
  }
  if (rel?.atWar ?? false) {
    return (
      game: null,
      message: null,
      error:
          '$_kPrefix rejected: $factionA and $factionB are already at war.',
    );
  }

  final nextRelations = upsertRelation(
    game.diplomacyRelations,
    factionA,
    factionB,
    (existing) =>
        (existing ?? DiplomacyRelation(factionId1: factionA, factionId2: factionB))
            .copyWith(state: RelationState.atWar, sinceTurn: turn),
  );

  final clearedOvertures = _overturesBetween(game, factionA, factionB);
  final keptOvertures = game.overtureStates
      .where((o) => !_isBetween(o, factionA, factionB))
      .toList(growable: false);

  final ftpWasPresent = hasFtpPartnership(game, factionA, factionB);
  final nextFtpKeys = ftpWasPresent
      ? (Set<String>.from(game.ftpPartnershipKeys)
        ..remove(pairKey(factionA, factionB)))
      : game.ftpPartnershipKeys;

  var nextGame = game.copyWith(
    diplomacyRelations: nextRelations,
    overtureStates: keptOvertures,
    ftpPartnershipKeys: nextFtpKeys,
  );

  final events = <_PendingEvent>[
    (type: DiplomaticEventType.declareWar, from: factionA, to: factionB),
    for (final _ in clearedOvertures)
      (
        type: DiplomaticEventType.agreementsClearedOnWar,
        from: factionA,
        to: factionB,
      ),
    if (ftpWasPresent)
      (type: DiplomaticEventType.ftpBroken, from: factionA, to: factionB),
  ];
  nextGame = _appendEvents(nextGame, turn, events);

  return (
    game: nextGame,
    message: 'War set between $factionA and $factionB '
        '(cleared ${clearedOvertures.length} overture(s)'
        '${ftpWasPresent ? ', removed FTP' : ''}).',
    error: null,
  );
}

_DiplomacyActionOutcome _applyPeace(
  Game game,
  String factionA,
  String factionB,
  int turn,
) {
  final rel = getRelation(game, factionA, factionB);
  if (rel == null || rel.atPeace) {
    return (
      game: null,
      message: null,
      error:
          '$_kPrefix rejected: $factionA and $factionB are already at peace.',
    );
  }
  final nextRelations = upsertRelation(
    game.diplomacyRelations,
    factionA,
    factionB,
    (existing) =>
        (existing ?? DiplomacyRelation(factionId1: factionA, factionId2: factionB))
            .copyWith(state: RelationState.atPeace, sinceTurn: turn),
  );
  final nextGame = _appendEvents(
    game.copyWith(diplomacyRelations: nextRelations),
    turn,
    [(type: DiplomaticEventType.peace, from: factionA, to: factionB)],
  );
  return (
    game: nextGame,
    message: 'Peace set between $factionA and $factionB.',
    error: null,
  );
}

_DiplomacyActionOutcome _applyAlliance(
  Game game,
  String factionA,
  String factionB,
  int turn,
) {
  if (!isGreatPower(game, factionA) || !isGreatPower(game, factionB)) {
    return (
      game: null,
      message: null,
      error: '$_kPrefix rejected: alliance requires both factions to be '
          'Great Powers.',
    );
  }
  final rel = getRelation(game, factionA, factionB);
  if (rel?.atWar ?? false) {
    return (
      game: null,
      message: null,
      error: '$_kPrefix rejected: cannot form an alliance while $factionA and '
          '$factionB are at war.',
    );
  }
  final nextRelations = upsertRelation(
    game.diplomacyRelations,
    factionA,
    factionB,
    (existing) =>
        (existing ?? DiplomacyRelation(factionId1: factionA, factionId2: factionB))
            .copyWith(formalAlliance: true, sinceTurn: turn),
  );
  final nextGame = _appendEvents(
    game.copyWith(diplomacyRelations: nextRelations),
    turn,
    [(type: DiplomaticEventType.allianceFormed, from: factionA, to: factionB)],
  );
  return (
    game: nextGame,
    message: 'Formal alliance set between $factionA and $factionB.',
    error: null,
  );
}

_DiplomacyActionOutcome _applyNoAlliance(
  Game game,
  String factionA,
  String factionB,
  int turn,
) {
  final rel = getRelation(game, factionA, factionB);
  if (!(rel?.formalAlliance ?? false)) {
    return (
      game: game,
      message: 'No alliance to break between $factionA and $factionB '
          '(no change).',
      error: null,
    );
  }
  final nextRelations = upsertRelation(
    game.diplomacyRelations,
    factionA,
    factionB,
    (existing) => existing!.copyWith(formalAlliance: false, sinceTurn: turn),
  );
  final nextGame = _appendEvents(
    game.copyWith(diplomacyRelations: nextRelations),
    turn,
    [(type: DiplomaticEventType.allianceBroken, from: factionA, to: factionB)],
  );
  return (
    game: nextGame,
    message: 'Formal alliance broken between $factionA and $factionB.',
    error: null,
  );
}

_DiplomacyActionOutcome _applyOverture(
  Game game,
  String factionA,
  String factionB,
  int turn,
  OvertureStage stage,
) {
  final rel = getRelation(game, factionA, factionB);
  if (rel?.atWar ?? false) {
    return (
      game: null,
      message: null,
      error: '$_kPrefix rejected: cannot set an overture while $factionA and '
          '$factionB are at war.',
    );
  }
  final existing = getOverture(game, factionA, factionB);
  final List<OvertureState> nextOvertures;
  if (existing == null) {
    nextOvertures = [
      ...game.overtureStates,
      OvertureState(
        gpId: factionA,
        targetId: factionB,
        stage: stage,
        sinceTurn: turn,
      ),
    ];
  } else {
    nextOvertures = game.overtureStates
        .map(
          (o) => o.gpId == factionA && o.targetId == factionB
              ? o.copyWith(stage: stage, sinceTurn: turn)
              : o,
        )
        .toList(growable: false);
  }
  return (
    game: game.copyWith(overtureStates: nextOvertures),
    message: 'Overture ${stage.name} set from $factionA toward $factionB.',
    error: null,
  );
}

_DiplomacyActionOutcome _applyClearOverture(
  Game game,
  String factionA,
  String factionB,
) {
  final existing = getOverture(game, factionA, factionB);
  if (existing == null || existing.stage == OvertureStage.none) {
    return (
      game: game,
      message: 'No overture to clear from $factionA toward $factionB '
          '(no change).',
      error: null,
    );
  }
  final nextOvertures = game.overtureStates
      .where((o) => !(o.gpId == factionA && o.targetId == factionB))
      .toList(growable: false);
  return (
    game: game.copyWith(overtureStates: nextOvertures),
    message: 'Overture cleared from $factionA toward $factionB.',
    error: null,
  );
}

_DiplomacyActionOutcome _applyFtp(
  Game game,
  String factionA,
  String factionB,
  int turn,
) {
  final rel = getRelation(game, factionA, factionB);
  if (rel?.atWar ?? false) {
    return (
      game: null,
      message: null,
      error: '$_kPrefix rejected: cannot establish FTP while $factionA and '
          '$factionB are at war.',
    );
  }
  final mutualEmbassy = hasEmbassyOverture(game, factionA, factionB) &&
      hasEmbassyOverture(game, factionB, factionA);
  if (!mutualEmbassy) {
    return (
      game: null,
      message: null,
      error: '$_kPrefix rejected: FTP requires a mutual embassy-tier overture '
          'between $factionA and $factionB.',
    );
  }
  if (hasFtpPartnership(game, factionA, factionB)) {
    return (
      game: game,
      message: 'FTP already active between $factionA and $factionB '
          '(no change).',
      error: null,
    );
  }
  final nextFtpKeys = Set<String>.from(game.ftpPartnershipKeys)
    ..add(pairKey(factionA, factionB));
  final nextGame = _appendEvents(
    game.copyWith(ftpPartnershipKeys: nextFtpKeys),
    turn,
    [(type: DiplomaticEventType.ftpFormed, from: factionA, to: factionB)],
  );
  return (
    game: nextGame,
    message: 'FTP set between $factionA and $factionB.',
    error: null,
  );
}

_DiplomacyActionOutcome _applyNoFtp(
  Game game,
  String factionA,
  String factionB,
  int turn,
) {
  if (!hasFtpPartnership(game, factionA, factionB)) {
    return (
      game: game,
      message: 'No FTP to remove between $factionA and $factionB (no change).',
      error: null,
    );
  }
  final nextFtpKeys = Set<String>.from(game.ftpPartnershipKeys)
    ..remove(pairKey(factionA, factionB));
  final nextGame = _appendEvents(
    game.copyWith(ftpPartnershipKeys: nextFtpKeys),
    turn,
    [(type: DiplomaticEventType.ftpBroken, from: factionA, to: factionB)],
  );
  return (
    game: nextGame,
    message: 'FTP removed between $factionA and $factionB.',
    error: null,
  );
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
