part of 'app_event_handler_debug_set_diplomacy.dart';

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
