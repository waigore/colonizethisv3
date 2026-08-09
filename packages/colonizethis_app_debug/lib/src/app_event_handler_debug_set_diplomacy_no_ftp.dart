import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'debug_set_diplomacy_common.dart';

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
