import 'package:colonizethis_models/colonizethis_models.dart';

import 'diplomacy_event_logging.dart';
import 'diplomacy_relation_lookup.dart';
import 'diplomacy_relation_updates.dart';
import 'diplomacy_shared_helpers.dart';

Game addFtpPartnership(
  Game game,
  String proposerGpId,
  String targetGpId,
  int turn, {
  IntraTurnEventTally? eventTally,
}) {
  final key = pairKey(proposerGpId, targetGpId);
  if (game.ftpPartnershipKeys.contains(key)) return game;
  var next = game.copyWith(
    ftpPartnershipKeys: {...game.ftpPartnershipKeys, key},
  );
  return logDiplomaticEvent(
    next,
    turn,
    DiplomaticEventType.ftpFormed,
    {proposerGpId, targetGpId},
    fromFactionId: proposerGpId,
    toFactionId: targetGpId,
    wasAiInitiator: isAiControlledForEvidence(next, proposerGpId),
    eventTally: eventTally,
    logMessage: 'diplomacy ftp formed $proposerGpId-$targetGpId',
  );
}

Game clearFtpPartnerships(
  Game game,
  Set<String> keysToRemove,
  int turn, {
  String reason = 'agreement_ended',
  IntraTurnEventTally? eventTally,
}) {
  if (keysToRemove.isEmpty) return game;
  final remaining = Set<String>.from(game.ftpPartnershipKeys)
    ..removeAll(keysToRemove);
  if (remaining.length == game.ftpPartnershipKeys.length) return game;
  var next = game.copyWith(ftpPartnershipKeys: remaining);
  for (final key in keysToRemove) {
    final ids = pairIdsFromKey(key);
    if (ids == null) continue;
    next = logDiplomaticEvent(
      next,
      turn,
      DiplomaticEventType.ftpBroken,
      {ids.id1, ids.id2},
      fromFactionId: ids.id1,
      toFactionId: ids.id2,
      reason: reason,
      eventTally: eventTally,
      logMessage: 'diplomacy ftp broken ${ids.id1}-${ids.id2} reason=$reason',
    );
  }
  return next;
}

Game breakFtpOnEmbassyLoss(
  Game game,
  int turn, {
  IntraTurnEventTally? eventTally,
}) {
  final remove = <String>{};
  for (final key in game.ftpPartnershipKeys) {
    final ids = pairIdsFromKey(key);
    if (ids == null) continue;
    if (!hasEmbassyOverture(game, ids.id1, ids.id2) ||
        !hasEmbassyOverture(game, ids.id2, ids.id1)) {
      remove.add(key);
    }
  }
  return clearFtpPartnerships(
    game,
    remove,
    turn,
    reason: 'embassy_lost',
    eventTally: eventTally,
  );
}

Game breakFtpOnWar(Game game, int turn, {IntraTurnEventTally? eventTally}) {
  final remove = <String>{};
  for (final key in game.ftpPartnershipKeys) {
    final ids = pairIdsFromKey(key);
    if (ids != null && factionsAtWar(game, ids.id1, ids.id2)) remove.add(key);
  }
  return clearFtpPartnerships(
    game,
    remove,
    turn,
    reason: 'war',
    eventTally: eventTally,
  );
}
