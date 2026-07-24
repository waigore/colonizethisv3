import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'app_event_handler_debug_set_diplomacy_common.dart';

DebugDiplomacyActionOutcome applyDebugDiplomacyFtp(
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
      error: '$kDebugSetDiplomacyPrefix rejected: cannot establish FTP while $factionA and '
          '$factionB are at war.',
    );
  }
  final mutualEmbassy = hasEmbassyOverture(game, factionA, factionB) &&
      hasEmbassyOverture(game, factionB, factionA);
  if (!mutualEmbassy) {
    return (
      game: null,
      message: null,
      error: '$kDebugSetDiplomacyPrefix rejected: FTP requires a mutual embassy-tier overture '
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
  final nextGame = appendDebugDiplomacyEvents(
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

DebugDiplomacyActionOutcome applyDebugDiplomacyNoFtp(
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
  final nextGame = appendDebugDiplomacyEvents(
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
