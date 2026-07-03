import 'package:colonizethis_models/colonizethis_models.dart';

import 'package:colonizethis_world/colonizethis_world.dart';
import 'diplomacy_event_logging.dart';
import 'diplomacy_phase_result.dart';
import 'diplomacy_relation_lookup.dart';
import 'diplomacy_shared_helpers.dart';

/// Result of processing FTP proposals in the Diplomacy phase.
class FtpProposalsResult {
  FtpProposalsResult(this.game, [this.pendingFtpOffers]);

  final Game game;
  final List<FtpOffer>? pendingFtpOffers;
}

/// AI target accepts FTP when relation score ≥ [relationScoreMinFtp] and the
/// target holds an embassy-tier overture toward the proposer.
bool aiGpAcceptsFtp(Game game, String proposerGpId, String targetGpId) {
  final rel = getRelation(game, proposerGpId, targetGpId);
  final score = rel?.score ?? relationScoreNeutral;
  if (score < relationScoreMinFtp) return false;
  if (!hasEmbassyOverture(game, targetGpId, proposerGpId)) return false;
  return true;
}

bool _canFormFtp(Game game, String proposerGpId, String targetGpId) {
  if (hasFtpPartnership(game, proposerGpId, targetGpId)) return false;
  if (factionsAtWar(game, proposerGpId, targetGpId)) return false;
  if (!hasEmbassyOverture(game, proposerGpId, targetGpId)) return false;
  if (!hasEmbassyOverture(game, targetGpId, proposerGpId)) return false;
  final rel = getRelation(game, proposerGpId, targetGpId);
  final score = rel?.score ?? relationScoreNeutral;
  return score >= relationScoreMinFtp;
}

Game _addFtpPartnership(
  Game game,
  String proposerGpId,
  String targetGpId,
  int turn, {
  IntraTurnEventTally? eventTally,
}) {
  final key = pairKey(proposerGpId, targetGpId);
  if (game.ftpPartnershipKeys.contains(key)) return game;
  final nextKeys = {...game.ftpPartnershipKeys, key};
  var next = game.copyWith(ftpPartnershipKeys: nextKeys);
  next = logDiplomaticEvent(
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
  return next;
}

/// Removes FTP between warring faction pairs and when embassy is lost.
Game clearFtpPartnerships(
  Game game,
  Set<String> keysToRemove,
  int turn, {
  String reason = 'agreement_ended',
  IntraTurnEventTally? eventTally,
}) {
  if (keysToRemove.isEmpty) return game;
  var next = game;
  final remaining = Set<String>.from(game.ftpPartnershipKeys)
    ..removeAll(keysToRemove);
  if (remaining.length == game.ftpPartnershipKeys.length) return game;
  next = next.copyWith(ftpPartnershipKeys: remaining);
  for (final key in keysToRemove) {
    final parts = key.split('|');
    if (parts.length != 2) continue;
    final id1 = parts[0];
    final id2 = parts[1];
    next = logDiplomaticEvent(
      next,
      turn,
      DiplomaticEventType.ftpBroken,
      {id1, id2},
      fromFactionId: id1,
      toFactionId: id2,
      reason: reason,
      eventTally: eventTally,
      logMessage: 'diplomacy ftp broken $id1-$id2 reason=$reason',
    );
  }
  return next;
}

/// Break FTP when either side loses embassy-tier overture toward the other.
Game breakFtpOnEmbassyLoss(
  Game game,
  int turn, {
  IntraTurnEventTally? eventTally,
}) {
  final toRemove = <String>{};
  for (final key in game.ftpPartnershipKeys) {
    final parts = key.split('|');
    if (parts.length != 2) continue;
    final a = parts[0];
    final b = parts[1];
    if (!hasEmbassyOverture(game, a, b) || !hasEmbassyOverture(game, b, a)) {
      toRemove.add(key);
    }
  }
  return clearFtpPartnerships(
    game,
    toRemove,
    turn,
    reason: 'embassy_lost',
    eventTally: eventTally,
  );
}

/// Break FTP between factions currently at war.
Game breakFtpOnWar(Game game, int turn, {IntraTurnEventTally? eventTally}) {
  final toRemove = <String>{};
  for (final key in game.ftpPartnershipKeys) {
    final parts = key.split('|');
    if (parts.length != 2) continue;
    if (factionsAtWar(game, parts[0], parts[1])) {
      toRemove.add(key);
    }
  }
  return clearFtpPartnerships(
    game,
    toRemove,
    turn,
    reason: 'war',
    eventTally: eventTally,
  );
}

({Game state, FtpOffer? pendingOffer}) _resolveEstablishFtpOrder({
  required Game state,
  required String proposerId,
  required DiplomaticOrder order,
  required int turn,
  required DiplomacyFactionMembership factionMembership,
  List<FtpDecision>? ftpDecisions,
  IntraTurnEventTally? eventTally,
}) {
  if (order.type != DiplomaticOrderType.establishFtp) {
    return (state: state, pendingOffer: null);
  }

  final targetId = order.targetFactionId;
  if (!factionMembership.isGreatPower(targetId) ||
      !_canFormFtp(state, proposerId, targetId)) {
    return (state: state, pendingOffer: null);
  }

  // Canonical pending-human-decision flow (diplomacy_shared_helpers.dart):
  // human target applies a supplied decision or suspends pending; otherwise the
  // AI rule resolves immediately.
  return resolveHumanGatedDecision<
    FtpDecision,
    ({Game state, FtpOffer? pendingOffer})
  >(
    isHumanControlled: isTargetHumanGp(state, targetId),
    decisions: ftpDecisions,
    matches: (d) => d.proposerGpId == proposerId && d.targetGpId == targetId,
    onAiResolve: () {
      var next = state;
      if (aiGpAcceptsFtp(next, proposerId, targetId)) {
        next = _addFtpPartnership(
          next,
          proposerId,
          targetId,
          turn,
          eventTally: eventTally,
        );
      }
      return (state: next, pendingOffer: null);
    },
    onPending: () => (
      state: state,
      pendingOffer: FtpOffer(proposerGpId: proposerId, targetGpId: targetId),
    ),
    onHumanDecision: (decision) {
      var next = state;
      if (decision.accepted) {
        next = _addFtpPartnership(
          next,
          proposerId,
          targetId,
          turn,
          eventTally: eventTally,
        );
      }
      return (state: next, pendingOffer: null);
    },
  );
}

/// Processes [DiplomaticOrderType.establishFtp] proposals (GP–GP, two-way).
/// SPEC/game/world-market.md § Favored Trading Partner.
FtpProposalsResult processFtpProposals(
  Game game,
  Map<String, List<DiplomaticOrder>> diploByPlayer,
  int turn, {
  required DiplomacyFactionMembership factionMembership,
  List<FtpDecision>? ftpDecisions,
  IntraTurnEventTally? eventTally,
}) {
  var state = game;
  final pending = <FtpOffer>[];

  for (final entry in diploByPlayer.entries) {
    final proposerId = entry.key;
    for (final order in entry.value) {
      final resolved = _resolveEstablishFtpOrder(
        state: state,
        proposerId: proposerId,
        order: order,
        turn: turn,
        factionMembership: factionMembership,
        ftpDecisions: ftpDecisions,
        eventTally: eventTally,
      );
      state = resolved.state;
      final offer = resolved.pendingOffer;
      if (offer != null) {
        pending.add(offer);
      }
    }
  }

  if (pending.isNotEmpty) {
    return FtpProposalsResult(state, pending);
  }
  return FtpProposalsResult(state);
}
