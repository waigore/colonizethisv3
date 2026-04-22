import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../ai/ai_control.dart';
import '../constants.dart';
import '../dossier/evidence_rules.dart';
import '../turn/turn_resolution_result.dart';
import 'diplomacy_relation_lookup.dart';
import 'diplomacy_resolver.dart';

Game appendDiplomaticEvent(
  Game game,
  int turn,
  DiplomaticEventType type,
  Set<String> participants, {
  String? fromFactionId,
  String? toFactionId,
  OvertureStage? overtureStage,
  int? amount,
  String? reason,
  bool wasAiInitiator = false,
}) {
  final events = game.diplomaticHistoryEvents;
  final intraTurnIndex = events.where((e) => e.turn == turn).length;
  final event = DiplomaticEvent(
    turn: turn,
    intraTurnIndex: intraTurnIndex,
    type: type,
    participants: participants,
    fromFactionId: fromFactionId,
    toFactionId: toFactionId,
    overtureStage: overtureStage,
    amount: amount,
    reason: reason,
    wasAiInitiator: wasAiInitiator,
  );
  return game.copyWith(diplomaticHistoryEvents: [...events, event]);
}

bool _isTargetHumanGp(Game game, String factionId) {
  final p = game.playerById(factionId);
  return p != null && p.isHuman;
}

OvertureDecision? _findDecision(
  List<OvertureDecision>? decisions,
  String offererGpId,
  String targetFactionId,
  OvertureStage stage,
) {
  if (decisions == null) return null;
  for (final d in decisions) {
    if (d.offererGpId == offererGpId &&
        d.targetFactionId == targetFactionId &&
        d.stage == stage) {
      return d;
    }
  }
  return null;
}

class OverturePaymentsResult {
  OverturePaymentsResult(this.game, [this.pendingOvertures]);
  final Game game;
  final List<OvertureOffer>? pendingOvertures;
}

/// Accept by rule for Minor/Tribe: Consulate/Embassy/NAP always accepted. SPEC/game/diplomacy.md.
bool _minorOrTribeAcceptsByRule(OvertureStage stage) {
  return stage == OvertureStage.tradeConsulate ||
      stage == OvertureStage.embassy ||
      stage == OvertureStage.nap;
}

/// AI GP target: accept if relation score >= neutral (Neutral or better). Current product rule.
bool _aiGpAccepts(Game game, String offererGpId, String targetGpId) {
  final rel = getRelation(game, offererGpId, targetGpId);
  final score = rel?.score ?? relationScoreNeutral;
  return score >= relationScoreNeutral;
}

OverturePaymentsResult processOverturePayments(
  Game game,
  Map<String, List<DiplomaticOrder>> diploByPlayer,
  int turn, {
  List<OvertureDecision>? overtureDecisions,
}) {
  var players = List<Player>.from(game.players);
  var overtures = List<OvertureState>.from(game.overtureStates);
  var state = game;

  for (final entry in diploByPlayer.entries) {
    final gpId = entry.key;
    final playerIdx = players.indexWhere((p) => p.id == gpId);
    if (playerIdx < 0) continue;
    var player = players[playerIdx];

    for (final order in entry.value) {
      if (order.type != DiplomaticOrderType.establishOverture) continue;
      final stage = order.overtureStage;
      if (stage == null || stage == OvertureStage.none) continue;

      final targetId = order.targetFactionId;
      final targetIsMinorOrTribe = isMinorOrTribe(state, targetId);
      final targetIsGp = isGreatPower(state, targetId);
      if (!targetIsMinorOrTribe && !targetIsGp) continue;

      // SPEC/game/diplomacy.md: While relationState is AT_WAR, no new overtures.
      final rel = getRelation(state, gpId, targetId);
      if (rel != null && rel.atWar) continue;

      OvertureState? existing;
      for (final o in overtures) {
        if (o.gpId == gpId && o.targetId == targetId) {
          existing = o;
          break;
        }
      }
      final prevStage = previousStage(stage);
      final atPrevStage =
          (existing == null && prevStage == OvertureStage.none) ||
          (existing != null && existing.stage == prevStage);
      if (!atPrevStage) continue;

      if (targetIsMinorOrTribe &&
          (stage == OvertureStage.tradeConsulate ||
              stage == OvertureStage.embassy ||
              stage == OvertureStage.nap) &&
          player.techUnlocked?[kTechIdDiplomaticExpertise] != true) {
        continue;
      }

      int cost;
      if (stage == OvertureStage.tradeConsulate) {
        cost = overtureConsulateCost;
      } else if (stage == OvertureStage.embassy) {
        cost = overtureEmbassyCost;
      } else if (stage == OvertureStage.nap) {
        cost = 0;
      } else {
        continue; // Join Empire in step 3
      }

      if (player.treasury < cost && cost > 0) continue;

      // Two-way: target accepts or rejects.
      bool accepted;
      if (targetIsMinorOrTribe) {
        accepted = _minorOrTribeAcceptsByRule(stage);
      } else {
        // Target is GP.
        final decision = _findDecision(
          overtureDecisions,
          gpId,
          targetId,
          stage,
        );
        if (decision != null) {
          accepted = decision.accepted;
        } else if (_isTargetHumanGp(state, targetId)) {
          // Suspend: need human response.
          final pending = [
            OvertureOffer(
              offererGpId: gpId,
              targetFactionId: targetId,
              stage: stage,
            ),
          ];
          state = state.copyWith(players: players, overtureStates: overtures);
          return OverturePaymentsResult(state, pending);
        } else {
          accepted = _aiGpAccepts(state, gpId, targetId);
        }
      }

      if (!accepted) {
        if (targetIsGp) {
          state = appendDiplomaticEvent(
            state,
            turn,
            DiplomaticEventType.overtureRejected,
            {gpId, targetId},
            fromFactionId: gpId,
            toFactionId: targetId,
            overtureStage: stage,
            wasAiInitiator: isAiControlledForEvidence(state, gpId),
          );
        }
        continue;
      }

      if (cost > 0) {
        player = player.copyWith(treasury: player.treasury - cost);
        players[playerIdx] = player;
      }

      final osIdx = overtures.indexWhere(
        (o) => o.gpId == gpId && o.targetId == targetId,
      );
      if (osIdx >= 0) {
        overtures = List<OvertureState>.from(overtures);
        overtures[osIdx] = overtures[osIdx].copyWith(
          stage: stage,
          sinceTurn: turn,
        );
      } else {
        overtures = [
          ...overtures,
          OvertureState(
            gpId: gpId,
            targetId: targetId,
            stage: stage,
            sinceTurn: turn,
          ),
        ];
      }
      state = state.copyWith(players: players, overtureStates: overtures);
      state = appendDiplomaticEvent(
        state,
        turn,
        DiplomaticEventType.overtureAccepted,
        {gpId, targetId},
        fromFactionId: gpId,
        toFactionId: targetId,
        overtureStage: stage,
        wasAiInitiator: isAiControlledForEvidence(state, gpId),
      );
      diploLog.i('diplomacy overture $gpId -> $targetId $stage (accepted)');
    }
  }

  state = state.copyWith(players: players, overtureStates: overtures);
  return OverturePaymentsResult(state);
}

OvertureStage previousStage(OvertureStage stage) {
  switch (stage) {
    case OvertureStage.tradeConsulate:
      return OvertureStage.none;
    case OvertureStage.embassy:
      return OvertureStage.tradeConsulate;
    case OvertureStage.nap:
      return OvertureStage.embassy;
    case OvertureStage.joinEmpire:
      return OvertureStage.nap;
    case OvertureStage.none:
      return OvertureStage.none;
  }
}

Game advanceOvertures(Game game, int turn) {
  // Spec: "complete the turn after payment" - paid overtures are already advanced in step 1.
  // No additional turn delays in Phase 4 minimal implementation.
  return game;
}
