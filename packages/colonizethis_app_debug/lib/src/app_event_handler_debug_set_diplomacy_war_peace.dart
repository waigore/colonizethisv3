import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'debug_set_diplomacy_common.dart';

DebugDiplomacyActionOutcome applyDebugDiplomacyWar(
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
      error: '$kDebugSetDiplomacyPrefix rejected: a formal alliance exists between $factionA '
          'and $factionB. Use no_alliance before declaring war.',
    );
  }
  if (rel?.atWar ?? false) {
    return (
      game: null,
      message: null,
      error:
          '$kDebugSetDiplomacyPrefix rejected: $factionA and $factionB are already at war.',
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

  final clearedOvertures = debugOverturesBetween(game, factionA, factionB);
  final keptOvertures = game.overtureStates
      .where((o) => !debugOvertureIsBetween(o, factionA, factionB))
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

  final events = <DebugPendingDiplomacyEvent>[
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
  nextGame = appendDebugDiplomacyEvents(nextGame, turn, events);

  return (
    game: nextGame,
    message: 'War set between $factionA and $factionB '
        '(cleared ${clearedOvertures.length} overture(s)'
        '${ftpWasPresent ? ', removed FTP' : ''}).',
    error: null,
  );
}
