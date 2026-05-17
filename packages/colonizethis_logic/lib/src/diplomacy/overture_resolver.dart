import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../constants.dart';
import '../dossier/evidence_rules.dart';
import '../turn/turn_resolution_result.dart';
import 'diplomacy_resolver.dart';
import 'overture_stage_helpers.dart';

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

OvertureState? _findOvertureForGpTarget(
  List<OvertureState> overtures,
  String gpId,
  String targetId,
) {
  for (final o in overtures) {
    if (o.gpId == gpId && o.targetId == targetId) return o;
  }
  return null;
}

int? _overtureCostForStage(OvertureStage stage) {
  if (stage == OvertureStage.tradeConsulate) return overtureConsulateCost;
  if (stage == OvertureStage.embassy) return overtureEmbassyCost;
  if (stage == OvertureStage.nap) return 0;
  return null;
}

/// Returns pending result when human GP must respond; otherwise acceptance flag.
({bool accepted, OverturePaymentsResult? pending}) _resolveOvertureAcceptance({
  required Game state,
  required String gpId,
  required String targetId,
  required OvertureStage stage,
  required bool targetIsMinorOrTribe,
  required List<Player> players,
  required List<OvertureState> overtures,
  List<OvertureDecision>? overtureDecisions,
}) {
  if (targetIsMinorOrTribe) {
    return (accepted: _minorOrTribeAcceptsByRule(stage), pending: null);
  }
  final decision = _findDecision(overtureDecisions, gpId, targetId, stage);
  if (decision != null) {
    return (accepted: decision.accepted, pending: null);
  }
  if (_isTargetHumanGp(state, targetId)) {
    final pending = [
      OvertureOffer(offererGpId: gpId, targetFactionId: targetId, stage: stage),
    ];
    final wrapped = state.copyWith(players: players, overtureStates: overtures);
    return (accepted: false, pending: OverturePaymentsResult(wrapped, pending));
  }
  return (accepted: _aiGpAccepts(state, gpId, targetId), pending: null);
}

({
  List<Player> players,
  List<OvertureState> overtures,
  Game state,
  Player player,
  OverturePaymentsResult? earlyExit,
})
_processEstablishOvertureOrderIfApplicable({
  required Game state,
  required List<Player> players,
  required List<OvertureState> overtures,
  required int playerIdx,
  required Player player,
  required String gpId,
  required DiplomaticOrder order,
  required int turn,
  required DiplomacyFactionMembership factionMembership,
  List<OvertureDecision>? overtureDecisions,
}) {
  if (order.type != DiplomaticOrderType.establishOverture) {
    return (
      players: players,
      overtures: overtures,
      state: state,
      player: player,
      earlyExit: null,
    );
  }
  final stage = order.overtureStage;
  if (stage == null || stage == OvertureStage.none) {
    return (
      players: players,
      overtures: overtures,
      state: state,
      player: player,
      earlyExit: null,
    );
  }

  final targetId = order.targetFactionId;
  final targetIsMinorOrTribe = factionMembership.isMinorOrTribe(targetId);
  final targetIsGp = factionMembership.isGreatPower(targetId);
  if (!targetIsMinorOrTribe && !targetIsGp) {
    return (
      players: players,
      overtures: overtures,
      state: state,
      player: player,
      earlyExit: null,
    );
  }

  final rel = getRelation(state, gpId, targetId);
  if (rel != null && rel.atWar) {
    return (
      players: players,
      overtures: overtures,
      state: state,
      player: player,
      earlyExit: null,
    );
  }

  final existing = _findOvertureForGpTarget(overtures, gpId, targetId);
  final prevStage = stage.previous;
  final atPrevStage =
      (existing == null && prevStage == OvertureStage.none) ||
      (existing != null && existing.stage == prevStage);
  if (!atPrevStage) {
    return (
      players: players,
      overtures: overtures,
      state: state,
      player: player,
      earlyExit: null,
    );
  }

  if (targetIsMinorOrTribe &&
      (stage == OvertureStage.tradeConsulate ||
          stage == OvertureStage.embassy ||
          stage == OvertureStage.nap) &&
      player.techUnlocked?[kTechIdDiplomaticExpertise] != true) {
    return (
      players: players,
      overtures: overtures,
      state: state,
      player: player,
      earlyExit: null,
    );
  }

  final cost = _overtureCostForStage(stage);
  if (cost == null) {
    return (
      players: players,
      overtures: overtures,
      state: state,
      player: player,
      earlyExit: null,
    );
  }

  if (player.treasury < cost && cost > 0) {
    return (
      players: players,
      overtures: overtures,
      state: state,
      player: player,
      earlyExit: null,
    );
  }

  final resolution = _resolveOvertureAcceptance(
    state: state,
    gpId: gpId,
    targetId: targetId,
    stage: stage,
    targetIsMinorOrTribe: targetIsMinorOrTribe,
    players: players,
    overtures: overtures,
    overtureDecisions: overtureDecisions,
  );
  if (resolution.pending != null) {
    return (
      players: players,
      overtures: overtures,
      state: state,
      player: player,
      earlyExit: resolution.pending,
    );
  }
  final accepted = resolution.accepted;

  if (!accepted) {
    var nextState = state;
    if (targetIsGp) {
      nextState = appendDiplomaticEvent(
        nextState,
        turn,
        DiplomaticEventType.overtureRejected,
        {gpId, targetId},
        fromFactionId: gpId,
        toFactionId: targetId,
        overtureStage: stage,
        wasAiInitiator: isAiControlledForEvidence(nextState, gpId),
      );
    }
    return (
      players: players,
      overtures: overtures,
      state: nextState,
      player: player,
      earlyExit: null,
    );
  }

  var nextPlayer = player;
  var nextPlayers = players;
  if (cost > 0) {
    nextPlayer = nextPlayer.copyWith(treasury: nextPlayer.treasury - cost);
    nextPlayers = List<Player>.from(nextPlayers);
    nextPlayers[playerIdx] = nextPlayer;
  }

  var nextOvertures = overtures;
  final osIdx = nextOvertures.indexWhere(
    (o) => o.gpId == gpId && o.targetId == targetId,
  );
  if (osIdx >= 0) {
    nextOvertures = List<OvertureState>.from(nextOvertures);
    nextOvertures[osIdx] = nextOvertures[osIdx].copyWith(
      stage: stage,
      sinceTurn: turn,
    );
  } else {
    nextOvertures = [
      ...nextOvertures,
      OvertureState(
        gpId: gpId,
        targetId: targetId,
        stage: stage,
        sinceTurn: turn,
      ),
    ];
  }
  var nextState = state.copyWith(
    players: nextPlayers,
    overtureStates: nextOvertures,
  );
  nextState = appendDiplomaticEvent(
    nextState,
    turn,
    DiplomaticEventType.overtureAccepted,
    {gpId, targetId},
    fromFactionId: gpId,
    toFactionId: targetId,
    overtureStage: stage,
    wasAiInitiator: isAiControlledForEvidence(nextState, gpId),
  );
  diploLog.i('diplomacy overture $gpId -> $targetId $stage (accepted)');
  return (
    players: nextPlayers,
    overtures: nextOvertures,
    state: nextState,
    player: nextPlayer,
    earlyExit: null,
  );
}

OverturePaymentsResult processOverturePayments(
  Game game,
  Map<String, List<DiplomaticOrder>> diploByPlayer,
  int turn, {
  required DiplomacyFactionMembership factionMembership,
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
      final step = _processEstablishOvertureOrderIfApplicable(
        state: state,
        players: players,
        overtures: overtures,
        playerIdx: playerIdx,
        player: player,
        gpId: gpId,
        order: order,
        turn: turn,
        factionMembership: factionMembership,
        overtureDecisions: overtureDecisions,
      );
      if (step.earlyExit != null) return step.earlyExit!;
      players = step.players;
      overtures = step.overtures;
      state = step.state;
      player = step.player;
    }
  }

  state = state.copyWith(players: players, overtureStates: overtures);
  return OverturePaymentsResult(state);
}

Game advanceOvertures(Game game, int turn) {
  // Spec: "complete the turn after payment" - paid overtures are already advanced in step 1.
  // No additional turn delays in Phase 4 minimal implementation.
  return game;
}
