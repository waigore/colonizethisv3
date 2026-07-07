part of 'app_event_handler_debug_set_diplomacy.dart';

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
