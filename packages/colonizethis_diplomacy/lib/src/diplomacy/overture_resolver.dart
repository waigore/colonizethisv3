import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'package:colonizethis_world/colonizethis_world.dart';
import 'diplomacy_phase_result.dart';
import 'diplomacy_resolver.dart';
import 'diplomacy_shared_helpers.dart';
import 'overture_stage_helpers.dart';

/// Mutable per-turn tally for [appendDiplomaticEvent] `intraTurnIndex` assignment.
///
/// Built once from existing history at phase start; each [nextIndex] is O(1)
/// instead of filtering `diplomaticHistoryEvents` on every append (Refs #3419
/// step 7).
class IntraTurnEventTally {
  IntraTurnEventTally._(Map<int, int> countByTurn)
    : _countByTurn = Map<int, int>.from(countByTurn);

  factory IntraTurnEventTally.fromEvents(List<DiplomaticEvent> events) {
    final counts = <int, int>{};
    for (final e in events) {
      counts[e.turn] = (counts[e.turn] ?? 0) + 1;
    }
    return IntraTurnEventTally._(counts);
  }

  factory IntraTurnEventTally.fromGame(Game game) =>
      IntraTurnEventTally.fromEvents(game.diplomaticHistoryEvents);

  final Map<int, int> _countByTurn;

  /// Returns the next intra-turn index for [turn] and advances the tally.
  int nextIndex(int turn) {
    final idx = _countByTurn[turn] ?? 0;
    _countByTurn[turn] = idx + 1;
    return idx;
  }
}

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
  IntraTurnEventTally? eventTally,
}) {
  final events = game.diplomaticHistoryEvents;
  final intraTurnIndex = eventTally != null
      ? eventTally.nextIndex(turn)
      : events.where((e) => e.turn == turn).length;
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

/// Appends a diplomatic [type] event via [appendDiplomaticEvent] and emits the
/// operator-facing [logMessage] in a single call.
///
/// Collapses the repeated `appendDiplomaticEvent(...)` + `diploLog.i(...)`
/// pairing duplicated across the diplomacy resolvers (Refs #3562). All event
/// parameters mirror [appendDiplomaticEvent]; the only addition is the required
/// [logMessage], so callers keep their existing per-site log text.
Game logDiplomaticEvent(
  Game game,
  int turn,
  DiplomaticEventType type,
  Set<String> participants, {
  required String logMessage,
  String? fromFactionId,
  String? toFactionId,
  OvertureStage? overtureStage,
  int? amount,
  String? reason,
  bool wasAiInitiator = false,
  IntraTurnEventTally? eventTally,
}) {
  final next = appendDiplomaticEvent(
    game,
    turn,
    type,
    participants,
    fromFactionId: fromFactionId,
    toFactionId: toFactionId,
    overtureStage: overtureStage,
    amount: amount,
    reason: reason,
    wasAiInitiator: wasAiInitiator,
    eventTally: eventTally,
  );
  diploLog.i(logMessage);
  return next;
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
  // Canonical pending-human-decision flow (diplomacy_shared_helpers.dart):
  // human target applies a supplied decision or suspends pending; otherwise the
  // AI rule resolves immediately.
  if (isTargetHumanGp(state, targetId)) {
    final decision = findHumanDecision<OvertureDecision>(
      overtureDecisions,
      (d) =>
          d.offererGpId == gpId &&
          d.targetFactionId == targetId &&
          d.stage == stage,
    );
    if (decision != null) {
      return (accepted: decision.accepted, pending: null);
    }
    final pending = [
      OvertureOffer(offererGpId: gpId, targetFactionId: targetId, stage: stage),
    ];
    final wrapped = state.copyWith(players: players, overtureStates: overtures);
    return (accepted: false, pending: OverturePaymentsResult(wrapped, pending));
  }
  return (accepted: _aiGpAccepts(state, gpId, targetId), pending: null);
}

/// Result of processing one establish-overture order: the (possibly updated)
/// rolling state, or an [earlyExit] when the phase must suspend for human input.
typedef _OvertureOrderStep = ({
  List<Player> players,
  List<OvertureState> overtures,
  Game state,
  Player player,
  OverturePaymentsResult? earlyExit,
});

/// Validated, applicable establish-overture order: the resolved stage, target
/// classification, and stage cost. Null when the order is not applicable (no
/// state change), letting [_processEstablishOvertureOrderIfApplicable] skip it.
typedef _ValidatedOverture = ({
  OvertureStage stage,
  bool targetIsMinorOrTribe,
  bool targetIsGp,
  int cost,
});

/// Validates an establish-overture [order] against stage progression, target
/// membership, war state, tech prerequisites, and affordability.
///
/// Returns null when the order should be skipped without changing state;
/// otherwise the resolved stage/target/cost for acceptance resolution.
_ValidatedOverture? _validateEstablishOvertureOrder({
  required Game state,
  required Player player,
  required String gpId,
  required DiplomaticOrder order,
  required List<OvertureState> overtures,
  required DiplomacyFactionMembership factionMembership,
}) {
  if (order.type != DiplomaticOrderType.establishOverture) return null;
  final stage = order.overtureStage;
  if (stage == null || stage == OvertureStage.none) return null;

  final targetId = order.targetFactionId;
  final targetIsMinorOrTribe = factionMembership.isMinorOrTribe(targetId);
  final targetIsGp = factionMembership.isGreatPower(targetId);
  if (!targetIsMinorOrTribe && !targetIsGp) return null;

  final rel = getRelation(state, gpId, targetId);
  if (rel != null && rel.atWar) return null;

  final existing = _findOvertureForGpTarget(overtures, gpId, targetId);
  final prevStage = stage.previous;
  final atPrevStage =
      (existing == null && prevStage == OvertureStage.none) ||
      (existing != null && existing.stage == prevStage);
  if (!atPrevStage) return null;

  if (targetIsMinorOrTribe &&
      (stage == OvertureStage.tradeConsulate ||
          stage == OvertureStage.embassy ||
          stage == OvertureStage.nap) &&
      player.techUnlocked?[kTechIdDiplomaticExpertise] != true) {
    return null;
  }

  final cost = _overtureCostForStage(stage);
  if (cost == null) return null;
  if (player.treasury < cost && cost > 0) return null;

  return (
    stage: stage,
    targetIsMinorOrTribe: targetIsMinorOrTribe,
    targetIsGp: targetIsGp,
    cost: cost,
  );
}

/// Applies an accepted overture: debits the offerer, upserts the overture stage,
/// records the acceptance event, and returns the advanced step.
_OvertureOrderStep _applyAcceptedOverture({
  required Game state,
  required List<Player> players,
  required List<OvertureState> overtures,
  required int playerIdx,
  required String gpId,
  required String targetId,
  required OvertureStage stage,
  required int cost,
  required int turn,
  IntraTurnEventTally? eventTally,
}) {
  final nextPlayers = debitPlayerTreasury(players, playerIdx, cost);
  final nextPlayer = nextPlayers[playerIdx];

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
  nextState = logDiplomaticEvent(
    nextState,
    turn,
    DiplomaticEventType.overtureAccepted,
    {gpId, targetId},
    fromFactionId: gpId,
    toFactionId: targetId,
    overtureStage: stage,
    wasAiInitiator: isAiControlledForEvidence(nextState, gpId),
    eventTally: eventTally,
    logMessage: 'diplomacy overture $gpId -> $targetId $stage (accepted)',
  );
  return (
    players: nextPlayers,
    overtures: nextOvertures,
    state: nextState,
    player: nextPlayer,
    earlyExit: null,
  );
}

_OvertureOrderStep _processEstablishOvertureOrderIfApplicable({
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
  IntraTurnEventTally? eventTally,
}) {
  final unchanged = (
    players: players,
    overtures: overtures,
    state: state,
    player: player,
    earlyExit: null,
  );

  final validated = _validateEstablishOvertureOrder(
    state: state,
    player: player,
    gpId: gpId,
    order: order,
    overtures: overtures,
    factionMembership: factionMembership,
  );
  if (validated == null) return unchanged;

  final targetId = order.targetFactionId;
  final resolution = _resolveOvertureAcceptance(
    state: state,
    gpId: gpId,
    targetId: targetId,
    stage: validated.stage,
    targetIsMinorOrTribe: validated.targetIsMinorOrTribe,
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

  if (!resolution.accepted) {
    if (!validated.targetIsGp) return unchanged;
    final nextState = appendDiplomaticEvent(
      state,
      turn,
      DiplomaticEventType.overtureRejected,
      {gpId, targetId},
      fromFactionId: gpId,
      toFactionId: targetId,
      overtureStage: validated.stage,
      wasAiInitiator: isAiControlledForEvidence(state, gpId),
      eventTally: eventTally,
    );
    return (
      players: players,
      overtures: overtures,
      state: nextState,
      player: player,
      earlyExit: null,
    );
  }

  return _applyAcceptedOverture(
    state: state,
    players: players,
    overtures: overtures,
    playerIdx: playerIdx,
    gpId: gpId,
    targetId: targetId,
    stage: validated.stage,
    cost: validated.cost,
    turn: turn,
    eventTally: eventTally,
  );
}

OverturePaymentsResult processOverturePayments(
  Game game,
  Map<String, List<DiplomaticOrder>> diploByPlayer,
  int turn, {
  required DiplomacyFactionMembership factionMembership,
  List<OvertureDecision>? overtureDecisions,
  IntraTurnEventTally? eventTally,
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
        eventTally: eventTally,
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
