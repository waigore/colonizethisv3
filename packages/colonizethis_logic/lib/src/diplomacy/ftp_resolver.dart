import 'package:colonizethis_models/colonizethis_models.dart';

import 'package:colonizethis_world/src/game_player_lookup.dart';
import '../dossier/evidence_rules.dart';
import '../logging.dart';
import 'diplomacy_phase_result.dart';
import 'diplomacy_relation_lookup.dart';
import 'diplomacy_resolver.dart' show DiplomacyFactionMembership;
import 'overture_resolver.dart';

/// Result of processing FTP proposals in the Diplomacy phase.
class FtpProposalsResult {
  FtpProposalsResult(this.game, [this.pendingFtpOffers]);

  final Game game;
  final List<FtpOffer>? pendingFtpOffers;
}

bool _isTargetHumanGp(Game game, String factionId) {
  final p = game.playerById(factionId);
  return p != null && p.isHuman;
}

FtpDecision? _findFtpDecision(
  List<FtpDecision>? decisions,
  String proposerGpId,
  String targetGpId,
) {
  if (decisions == null) return null;
  for (final d in decisions) {
    if (d.proposerGpId == proposerGpId && d.targetGpId == targetGpId) {
      return d;
    }
  }
  return null;
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

bool _canFormFtp(
  Game game,
  String proposerGpId,
  String targetGpId,
) {
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
  int turn,
) {
  final key = pairKey(proposerGpId, targetGpId);
  if (game.ftpPartnershipKeys.contains(key)) return game;
  final nextKeys = {...game.ftpPartnershipKeys, key};
  var next = game.copyWith(ftpPartnershipKeys: nextKeys);
  next = appendDiplomaticEvent(
    next,
    turn,
    DiplomaticEventType.ftpFormed,
    {proposerGpId, targetGpId},
    fromFactionId: proposerGpId,
    toFactionId: targetGpId,
    wasAiInitiator: isAiControlledForEvidence(next, proposerGpId),
  );
  logicLog.i('logic: diplomacy ftp formed $proposerGpId-$targetGpId');
  return next;
}

/// Removes FTP between warring faction pairs and when embassy is lost.
Game clearFtpPartnerships(
  Game game,
  Set<String> keysToRemove,
  int turn, {
  String reason = 'agreement_ended',
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
    next = appendDiplomaticEvent(
      next,
      turn,
      DiplomaticEventType.ftpBroken,
      {id1, id2},
      fromFactionId: id1,
      toFactionId: id2,
      reason: reason,
    );
  }
  logicLog.i(
    'logic: diplomacy ftp cleared count=${keysToRemove.length} reason=$reason',
  );
  return next;
}

/// Break FTP when either side loses embassy-tier overture toward the other.
Game breakFtpOnEmbassyLoss(Game game, int turn) {
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
  return clearFtpPartnerships(game, toRemove, turn, reason: 'embassy_lost');
}

/// Break FTP between factions currently at war.
Game breakFtpOnWar(Game game, int turn) {
  final toRemove = <String>{};
  for (final key in game.ftpPartnershipKeys) {
    final parts = key.split('|');
    if (parts.length != 2) continue;
    if (factionsAtWar(game, parts[0], parts[1])) {
      toRemove.add(key);
    }
  }
  return clearFtpPartnerships(game, toRemove, turn, reason: 'war');
}

({Game state, FtpOffer? pendingOffer}) _resolveEstablishFtpOrder({
  required Game state,
  required String proposerId,
  required DiplomaticOrder order,
  required int turn,
  required DiplomacyFactionMembership factionMembership,
  List<FtpDecision>? ftpDecisions,
}) {
  if (order.type != DiplomaticOrderType.establishFtp) {
    return (state: state, pendingOffer: null);
  }

  final targetId = order.targetFactionId;
  if (!factionMembership.isGreatPower(targetId) ||
      !_canFormFtp(state, proposerId, targetId)) {
    return (state: state, pendingOffer: null);
  }

  final decision = _findFtpDecision(ftpDecisions, proposerId, targetId);
  if (decision != null) {
    if (decision.accepted) {
      state = _addFtpPartnership(state, proposerId, targetId, turn);
    }
    return (state: state, pendingOffer: null);
  }

  if (_isTargetHumanGp(state, targetId)) {
    return (
      state: state,
      pendingOffer: FtpOffer(proposerGpId: proposerId, targetGpId: targetId),
    );
  }

  if (aiGpAcceptsFtp(state, proposerId, targetId)) {
    state = _addFtpPartnership(state, proposerId, targetId, turn);
  }
  return (state: state, pendingOffer: null);
}

/// Processes [DiplomaticOrderType.establishFtp] proposals (GP–GP, two-way).
/// SPEC/game/world-market.md § Favored Trading Partner.
FtpProposalsResult processFtpProposals(
  Game game,
  Map<String, List<DiplomaticOrder>> diploByPlayer,
  int turn, {
  required DiplomacyFactionMembership factionMembership,
  List<FtpDecision>? ftpDecisions,
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
