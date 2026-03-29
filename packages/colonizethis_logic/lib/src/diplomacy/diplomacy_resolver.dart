/// Diplomacy phase resolution. SPEC/program/diplomacy-resolution.md.
/// Steps: overture payments (two-way accept/reject), advance overtures,
/// Join Empire/Colony, alliance proposals, Declare War/Peace, intervention
/// (GP embassy or purchased land when a GP declares war on a Minor/Tribe),
/// relation modifiers, score update.

import 'dart:math' show Random;

import 'package:colonizethis_logger/colonizethis_logger.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../ai/ai_control.dart';
import '../constants.dart';
import '../combat/conflict_detection.dart';
import '../dossier/evidence_rules.dart';
import '../turn/turn_resolution_result.dart';
import '../world/province_lookup.dart';
import 'diplomacy_relation_lookup.dart';
import 'diplomacy_relation_updates.dart';

export 'diplomacy_relation_lookup.dart';

final _diploLog = logicLogger();

/// Appends one diplomatic history event. intraTurnIndex = count of events already in this turn.
Game _appendDiplomaticEvent(
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

bool isMinorOrTribe(Game game, String factionId) {
  return game.minorNations.any((m) => m.id == factionId) ||
      game.tribes.any((t) => t.id == factionId);
}

bool isGreatPower(Game game, String factionId) {
  return game.players.any((p) => p.id == factionId);
}

/// True if [factionId] is a GP whose player is human-controlled.
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

/// Resolves Diplomacy phase. Runs before Movement per turn-resolution-phases.
/// When an AI applies declare war or offer peace, [onDialogue] is invoked with
/// a [DialogueEvent] (SPEC/ai/dialogue-and-mood.md).
/// Returns [DiplomacyPhaseResult]: when an overture targets a human GP and
/// [overtureDecisions] does not supply a decision, returns pending so turn
/// resolution can block. When [overtureDecisions] is provided (resume path),
/// applies those decisions and does not suspend.
/// Call to arms: after GP–GP war declarations, allies of the defender may need
/// to join or refuse; [callToArmsDecisions] supplies human responses on resume.
DiplomacyPhaseResult resolveDiplomacyPhase(
  Game game,
  Orders orders, {
  void Function(DialogueEvent)? onDialogue,
  List<OvertureDecision>? overtureDecisions,
  List<InterventionDecision>? interventionDecisions,
  List<CallToArmsDecision>? callToArmsDecisions,
}) {
  _diploLog.d('diplomacy phase start');
  final turn = game.worldState.turnState.turnNumber;
  var state = game;

  final diploByPlayer = orders.diplomaticOrdersByPlayerId;

  // 1. Process overture offers (two-way: target accepts/rejects)
  final overtureResult = _processOverturePayments(
    state,
    diploByPlayer,
    turn,
    overtureDecisions: overtureDecisions,
  );
  state = overtureResult.game;
  if (overtureResult.pendingOvertures != null &&
      overtureResult.pendingOvertures!.isNotEmpty) {
    _diploLog.d(
      'diplomacy phase suspended (pending overture decisions)',
    );
    return DiplomacyPhaseResult(
      state,
      pendingOvertures: overtureResult.pendingOvertures,
    );
  }

  // 2. Advance in-progress overtures (turn delays)
  state = _advanceOvertures(state, turn);

  // 3. Resolve Join Empire/Colony
  state = _resolveJoinEmpireColony(state, diploByPlayer, turn);

  // 4. Process alliance proposals and responses
  state = _processAlliances(state, diploByPlayer, turn);

  // 5. Process Declare War and Peace
  state = _processWarAndPeace(
    state,
    diploByPlayer,
    turn,
    onDialogue: onDialogue,
  );

  // 5b. Intervention (Diplomacy phase, after war declarations on Minor/Tribe)
  final interventionResult = _resolveOutstandingInterventionsForMinorTribeWars(
    state,
    diploByPlayer,
    turn,
    interventionDecisions: interventionDecisions,
  );
  if (interventionResult.pendingInterventions != null &&
      interventionResult.pendingInterventions!.isNotEmpty) {
    return DiplomacyPhaseResult(
      interventionResult.game,
      pendingInterventions: interventionResult.pendingInterventions,
    );
  }
  state = interventionResult.game;

  // 5c. Call to arms (allies of GP declared upon). SPEC/game/diplomacy.md.
  final ctaResult = _processCallToArms(
    state,
    diploByPlayer,
    turn,
    callToArmsDecisions: callToArmsDecisions,
  );
  state = ctaResult.game;
  if (ctaResult.pendingCallToArms != null &&
      ctaResult.pendingCallToArms!.isNotEmpty) {
    _diploLog.d(
      'diplomacy phase suspended (pending call to arms)',
    );
    return DiplomacyPhaseResult(
      state,
      pendingCallToArms: ctaResult.pendingCallToArms,
    );
  }

  // 6. War terminates agreements with target
  state = _terminateAgreementsOnWar(state);

  // 7. Process ongoing subsidies (+2 per 500 ducats, max +8 per turn)
  // Note: Convergence happens AFTER subsidies
  state = _processOngoingSubsidies(state, turn);

  // 8. Apply relation convergence (+/1 toward 50 for all non-war relations)
  state = _applyRelationConvergence(state, turn);

  // 9. Apply relation modifiers (grants, etc.)
  state = _applyRelationModifiersAndUpdateScores(state, diploByPlayer, turn);

  _diploLog.d('diplomacy phase end');
  return DiplomacyPhaseResult(state);
}

/// Result of processing overture payments: game state and optional pending offers (human target).
class _OverturePaymentsResult {
  _OverturePaymentsResult(this.game, [this.pendingOvertures]);
  final Game game;
  final List<OvertureOffer>? pendingOvertures;
}

/// Accept by rule for Minor/Tribe: Consulate/Embassy/NAP always accepted. SPEC/game/diplomacy.md.
bool _minorOrTribeAcceptsByRule(OvertureStage stage) {
  return stage == OvertureStage.tradeConsulate ||
      stage == OvertureStage.embassy ||
      stage == OvertureStage.nap;
}

/// AI GP target: accept if relation score >= neutral (Neutral or better). MVP rule.
bool _aiGpAccepts(Game game, String offererGpId, String targetGpId) {
  final rel = getRelation(game, offererGpId, targetGpId);
  final score = rel?.score ?? relationScoreNeutral;
  return score >= relationScoreNeutral;
}

_OverturePaymentsResult _processOverturePayments(
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
      final prevStage = _previousStage(stage);
      final atPrevStage =
          (existing == null && prevStage == OvertureStage.none) ||
          (existing != null && existing.stage == prevStage);
      if (!atPrevStage) continue;

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
          return _OverturePaymentsResult(state, pending);
        } else {
          accepted = _aiGpAccepts(state, gpId, targetId);
        }
      }

      if (!accepted) {
        if (targetIsGp) {
          state = _appendDiplomaticEvent(
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
      state = _appendDiplomaticEvent(
        state,
        turn,
        DiplomaticEventType.overtureAccepted,
        {gpId, targetId},
        fromFactionId: gpId,
        toFactionId: targetId,
        overtureStage: stage,
        wasAiInitiator: isAiControlledForEvidence(state, gpId),
      );
      _diploLog.i(
        'diplomacy overture $gpId -> $targetId $stage (accepted)',
      );
    }
  }

  state = state.copyWith(players: players, overtureStates: overtures);
  return _OverturePaymentsResult(state);
}

OvertureStage _previousStage(OvertureStage stage) {
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

Game _advanceOvertures(Game game, int turn) {
  // Spec: "complete the turn after payment" - paid overtures are already advanced in step 1.
  // No additional turn delays in Phase 4 minimal implementation.
  return game;
}

Game _resolveJoinEmpireColony(
  Game game,
  Map<String, List<DiplomaticOrder>> diploByPlayer,
  int turn,
) {
  for (final entry in diploByPlayer.entries) {
    final gpId = entry.key;

    for (final order in entry.value) {
      if (order.type != DiplomaticOrderType.establishOverture) continue;
      final stage = order.overtureStage;
      if (stage != OvertureStage.joinEmpire) continue;

      final targetId = order.targetFactionId;
      if (!isMinorOrTribe(game, targetId)) continue;

      final player = game.playerById(gpId);
      if (player == null) continue;

      final existing = getOverture(game, gpId, targetId);
      if (existing == null || existing.stage != OvertureStage.nap) continue;

      final rel = getRelation(game, gpId, targetId);
      final score = rel?.score ?? relationScoreNeutral;
      if (score < relationScoreMinFriendly)
        continue; // Must be Friendly or Allied

      final cost = joinEmpireCostForMinorOrTribe(game, targetId);
      if (player.treasury < cost) continue;

      // Absorb Minor/Tribe: transfer provinces, units, fleets to GP; remove faction.
      game = _absorbMinorOrTribeIntoGp(game, gpId, targetId, turn);
      game = _appendDiplomaticEvent(
        game,
        turn,
        DiplomaticEventType.joinEmpireResolved,
        {gpId, targetId},
        fromFactionId: gpId,
        toFactionId: targetId,
        overtureStage: OvertureStage.joinEmpire,
        amount: cost,
        wasAiInitiator: isAiControlledForEvidence(game, gpId),
      );
      _diploLog.i('diplomacy join empire $gpId $targetId cost=$cost');
    }
  }
  return game;
}

List<Province> _transferProvinceOwnership(
  List<Province> provinces,
  String fromId,
  String toId,
) {
  return provinces
      .map((p) => p.ownerId == fromId ? p.copyWith(ownerId: toId) : p)
      .toList();
}

List<Unit> _transferUnitOwnership(
  List<Unit> units,
  String fromId,
  String toId,
) {
  return units
      .map((u) => u.ownerId == fromId ? u.copyWith(ownerId: toId) : u)
      .toList();
}

/// Transfers all provinces, units, and fleets owned by [targetId] to [gpId],
/// deducts Join Empire cost from GP treasury, removes the Minor/Tribe and
/// cleans overtures/relations. SPEC/game/diplomacy.md.
Game _absorbMinorOrTribeIntoGp(
  Game game,
  String gpId,
  String targetId,
  int turn,
) {
  final cost = joinEmpireCostForMinorOrTribe(game, targetId);
  var players = List<Player>.from(game.players);
  final gpIdx = players.indexWhere((p) => p.id == gpId);
  if (gpIdx >= 0) {
    players = List<Player>.from(players);
    players[gpIdx] = players[gpIdx].copyWith(
      treasury: players[gpIdx].treasury - cost,
    );
  }

  // Transfer provinces: ownerId targetId -> gpId
  final owProvinces = _transferProvinceOwnership(
    game.worldState.oldWorld.provinces,
    targetId,
    gpId,
  );
  final nwProvinces = _transferProvinceOwnership(
    game.worldState.newWorld.provinces,
    targetId,
    gpId,
  );

  // Transfer units: ownerId targetId -> gpId
  final owUnits = _transferUnitOwnership(
    game.worldState.oldWorld.units,
    targetId,
    gpId,
  );
  final nwUnits = _transferUnitOwnership(
    game.worldState.newWorld.units,
    targetId,
    gpId,
  );

  // Transfer fleets
  final fleets = game.worldState.fleets
      .map((f) => f.ownerId == targetId ? f.copyWith(ownerId: gpId) : f)
      .toList();

  final oldWorld = RegionData(provinces: owProvinces, units: owUnits);
  final newWorld = RegionData(provinces: nwProvinces, units: nwUnits);

  // Clear Spy timers for (gpId, province) where gpId now owns the province,
  // so own provinces never decay via Spy timers after absorption.
  final ownedProvinceIds = <String>{
    for (final p in owProvinces)
      if (p.ownerId == gpId) p.id,
    for (final p in nwProvinces)
      if (p.ownerId == gpId) p.id,
  };
  final updatedSpyTimers = <String, Map<String, int>>{};
  game.worldState.spyRevealTurnsByPlayer.forEach((playerId, byProv) {
    final inner = Map<String, int>.from(byProv);
    if (playerId == gpId) {
      for (final provId in ownedProvinceIds) {
        inner.remove(provId);
      }
    }
    if (inner.isNotEmpty) {
      updatedSpyTimers[playerId] = inner;
    }
  });

  var minorNations = game.minorNations;
  var tribes = game.tribes;
  if (game.minorNations.any((m) => m.id == targetId)) {
    minorNations = game.minorNations.where((m) => m.id != targetId).toList();
  }
  if (game.tribes.any((t) => t.id == targetId)) {
    tribes = game.tribes.where((t) => t.id != targetId).toList();
  }

  // Remove overture state involving this target (any GP targeting it)
  final overtures = game.overtureStates
      .where((o) => o.targetId != targetId)
      .toList();

  // Remove diplomacy relations involving this target
  final relations = game.diplomacyRelations
      .where((r) => r.factionId1 != targetId && r.factionId2 != targetId)
      .toList();

  return game.copyWith(
    players: players,
    worldState: game.worldState.copyWith(
      oldWorld: oldWorld,
      newWorld: newWorld,
      fleets: fleets,
      spyRevealTurnsByPlayer: updatedSpyTimers,
    ),
    minorNations: minorNations,
    tribes: tribes,
    overtureStates: overtures,
    diplomacyRelations: relations,
  );
}

Game _processAlliances(
  Game game,
  Map<String, List<DiplomaticOrder>> diploByPlayer,
  int turn,
) {
  for (final entry in diploByPlayer.entries) {
    final gpId = entry.key;
    for (final order in entry.value) {
      if (order.type != DiplomaticOrderType.alliance) continue;

      final targetId = order.targetFactionId;
      if (!isGreatPower(game, targetId)) continue;

      final ids = canonicalPairIds(gpId, targetId);
      final relations = upsertRelation(
        List<DiplomacyRelation>.from(game.diplomacyRelations),
        gpId,
        targetId,
        (existing) => existing == null
            ? DiplomacyRelation(
                factionId1: ids.id1,
                factionId2: ids.id2,
                score: relationScoreMinAllied,
                level: RelationLevel.allied,
                state: RelationState.atPeace,
                sinceTurn: turn,
                lastInteractionTurn: turn,
              )
            : existing.copyWith(
                level: RelationLevel.allied,
                score: existing.score.clamp(
                  relationScoreMinAllied,
                  relationScoreMax,
                ),
                lastInteractionTurn: turn,
              ),
      );
      game = game.copyWith(diplomacyRelations: relations);
      game = _appendDiplomaticEvent(
        game,
        turn,
        DiplomaticEventType.allianceFormed,
        {gpId, targetId},
        fromFactionId: gpId,
        toFactionId: targetId,
        wasAiInitiator: isAiControlledForEvidence(game, gpId),
      );
      _diploLog.i('diplomacy alliance $gpId-$targetId');
    }
  }
  return game;
}

Game _processWarAndPeace(
  Game game,
  Map<String, List<DiplomaticOrder>> diploByPlayer,
  int turn, {
  void Function(DialogueEvent)? onDialogue,
}) {
  var relations = List<DiplomacyRelation>.from(game.diplomacyRelations);

  // Track GP–GP peace offers by unordered faction pair so we can require
  // both sides to offer peace before switching AT_WAR to AT_PEACE.
  final peaceOffersByPairKey = <String, Set<String>>{};
  for (final entry in diploByPlayer.entries) {
    final gpId = entry.key;
    for (final order in entry.value) {
      if (order.type != DiplomaticOrderType.offerPeace) continue;
      final targetId = order.targetFactionId;
      if (!isGreatPower(game, gpId) || !isGreatPower(game, targetId)) continue;
      final key = pairKey(gpId, targetId);
      final offerers = peaceOffersByPairKey.putIfAbsent(key, () => <String>{});
      offerers.add(gpId);
    }
  }

  for (final entry in diploByPlayer.entries) {
    final gpId = entry.key;
    for (final order in entry.value) {
      if (order.type == DiplomaticOrderType.declareWar) {
        final targetId = order.targetFactionId;
        final rel = getRelation(game, gpId, targetId);
        final atPeace = rel == null || rel.atPeace;
        if (atPeace) {
          if (onDialogue != null && isAiControlledForEvidence(game, gpId)) {
            onDialogue(
              DialogueEvent(
                leaderId: gpId,
                category: 'diplomatic',
                situation: 'declare_war',
                era: 'earlyModern',
                variables: {'otherNation': targetId},
              ),
            );
          }
          final evidence = evidenceForDeclareWar(game, gpId, targetId, turn);

          relations = setWarStateForPair(
            relations: relations,
            gpId: gpId,
            targetId: targetId,
            turn: turn,
          );

          game = game.copyWith(
            diplomacyRelations: relations,
            dossierEvidenceEntries: [
              ...game.dossierEvidenceEntries,
              ...evidence,
            ],
          );
          game = _cancelSubsidiesBetweenGps(game, gpId, targetId, turn);
          game = _appendDiplomaticEvent(
            game,
            turn,
            DiplomaticEventType.declareWar,
            {gpId, targetId},
            fromFactionId: gpId,
            toFactionId: targetId,
            wasAiInitiator: isAiControlledForEvidence(game, gpId),
          );
          _diploLog.i(
            'diplomacy war declared $gpId vs $targetId (scores reset to 20)',
          );
        }
      } else if (order.type == DiplomaticOrderType.offerPeace) {
        final targetId = order.targetFactionId;
        final rel = getRelation(game, gpId, targetId);
        final key = pairKey(gpId, targetId);
        final bothGreatPowers =
            isGreatPower(game, gpId) && isGreatPower(game, targetId);
        final hasMutualOffer = bothGreatPowers
            ? (peaceOffersByPairKey[key]?.length ?? 0) >= 2
            : true;
        if (rel != null && rel.atWar) {
          // SPEC/game/diplomacy.md:
          // - GP–GP peace: both sides must agree (both offer peace in this phase).
          // - Minors never refuse peace offers.
          var bothSidesAgreed = true;
          final isGpTarget = isGreatPower(game, targetId);
          if (isGpTarget && isGreatPower(game, gpId)) {
            final key = pairKey(gpId, targetId);
            final offerers = peaceOffersByPairKey[key] ?? const <String>{};
            bothSidesAgreed =
                offerers.contains(gpId) && offerers.contains(targetId);
          }
          if (!bothSidesAgreed) {
            continue;
          }

          if (onDialogue != null && isAiControlledForEvidence(game, gpId)) {
            onDialogue(
              DialogueEvent(
                leaderId: gpId,
                category: 'diplomatic',
                situation: 'peace_offer',
                era: 'earlyModern',
                variables: {'otherNation': targetId},
              ),
            );
          }
          final evidence = evidenceForOfferPeace(game, gpId, targetId, turn);
          if (hasMutualOffer) {
            relations = applyPeaceForPair(
              relations: relations,
              gpId: gpId,
              targetId: targetId,
              turn: turn,
            );
            game = game.copyWith(
              diplomacyRelations: relations,
              dossierEvidenceEntries: [
                ...game.dossierEvidenceEntries,
                ...evidence,
              ],
            );
            game = _appendDiplomaticEvent(
              game,
              turn,
              DiplomaticEventType.peace,
              {gpId, targetId},
              fromFactionId: gpId,
              toFactionId: targetId,
              wasAiInitiator: isAiControlledForEvidence(game, gpId),
            );
            _diploLog.i('diplomacy peace $gpId-$targetId');
          } else {
            game = game.copyWith(
              dossierEvidenceEntries: [
                ...game.dossierEvidenceEntries,
                ...evidence,
              ],
            );
          }
        }
      }
    }
  }
  return game;
}

class _InterventionResolutionResult {
  _InterventionResolutionResult(this.game, {this.pendingInterventions});

  final Game game;
  final List<InterventionPrompt>? pendingInterventions;
}

bool _gpHasEmbassyOrPurchasedLandInMinorTribe(
  Game game,
  String gpId,
  String minorOrTribeId,
) {
  final o = getOverture(game, gpId, minorOrTribeId);
  final hasEmbassy = o != null && o.hasEmbassy;
  final hasInvestment = _gpHasPurchasedLandInFactionProvinces(
    game,
    gpId,
    minorOrTribeId,
  );
  return hasEmbassy || hasInvestment;
}

bool _interventionChoiceRecordedForTurn(
  Game game,
  int turn,
  String interveningGpId,
  String aggressorGpId,
) {
  for (final e in game.diplomaticHistoryEvents) {
    if (e.turn != turn) continue;
    if (e.fromFactionId != interveningGpId || e.toFactionId != aggressorGpId) {
      continue;
    }
    if (e.type == DiplomaticEventType.interventionIntervene ||
        e.type == DiplomaticEventType.interventionDoNothing ||
        e.type == DiplomaticEventType.interventionProtest) {
      return true;
    }
  }
  return false;
}

bool _interventionsOutstanding(
  Game game,
  int turn,
  String aggressorGpId,
  String defenderMinorOrTribeId,
) {
  for (final p in game.players) {
    if (!isGreatPower(game, p.id) || p.id == aggressorGpId) continue;
    if (!_gpHasEmbassyOrPurchasedLandInMinorTribe(
      game,
      p.id,
      defenderMinorOrTribeId,
    )) {
      continue;
    }
    if (!_interventionChoiceRecordedForTurn(game, turn, p.id, aggressorGpId)) {
      return true;
    }
  }
  return false;
}

InterventionDecision? _findInterventionDecision(
  List<InterventionDecision>? list,
  String aggressorGpId,
  String defenderMinorOrTribeId,
  String interveningGpId,
) {
  if (list == null) return null;
  for (final d in list) {
    if (d.aggressorGpId == aggressorGpId &&
        d.defenderMinorOrTribeId == defenderMinorOrTribeId &&
        d.interveningGpId == interveningGpId) {
      return d;
    }
  }
  return null;
}

class _CallToArmsResult {
  _CallToArmsResult(this.game, {this.pendingCallToArms});
  final Game game;
  final List<CallToArmsPending>? pendingCallToArms;
}

CallToArmsDecision? _findCallToArmsDecision(
  List<CallToArmsDecision>? decisions,
  String allyGpId,
  String defenderGpId,
  String aggressorGpId,
) {
  if (decisions == null) return null;
  for (final d in decisions) {
    if (d.allyGpId == allyGpId &&
        d.defenderGpId == defenderGpId &&
        d.aggressorGpId == aggressorGpId) {
      return d;
    }
  }
  return null;
}

/// Relation score 0–25 → 0%, 26–50 → 25%, 51–75 → 50%, 76–100 → 80%.
double _aiInterventionProbability(int relationScore) {
  if (relationScore <= relationScoreLevelHostileMax) return 0;
  if (relationScore <= relationScoreLevelNeutralMax) return 0.25;
  if (relationScore <= relationScoreLevelFriendlyMax) return 0.5;
  return 0.8;
}

InterventionChoice _chooseAiIntervention(
  Game game,
  String aiGpId,
  String aggressorGpId,
  String defenderMinorOrTribeId,
  int turn,
) {
  final rel = getRelation(game, aiGpId, defenderMinorOrTribeId);
  final score = rel?.score ?? relationScoreNeutral;
  final p = _aiInterventionProbability(score);
  final seed = Object.hash(turn, aiGpId, aggressorGpId, defenderMinorOrTribeId);
  final roll = Random(seed).nextDouble();
  return roll < p ? InterventionChoice.intervene : InterventionChoice.doNothing;
}

Game _clearOverturesBetweenGpAndMinorTribe(
  Game game,
  String gpId,
  String minorOrTribeId,
) {
  final overtures = game.overtureStates
      .where((o) => !(o.gpId == gpId && o.targetId == minorOrTribeId))
      .toList();
  if (overtures.length == game.overtureStates.length) return game;
  return game.copyWith(overtureStates: overtures);
}

_InterventionResolutionResult _processInterventionsForAggressorDefender(
  Game game, {
  required String aggressorGpId,
  required String defenderMinorOrTribeId,
  required int turn,
  List<InterventionDecision>? interventionDecisions,
}) {
  final eligible = <String>[];
  for (final p in game.players) {
    if (!isGreatPower(game, p.id) || p.id == aggressorGpId) continue;
    if (!_gpHasEmbassyOrPurchasedLandInMinorTribe(
      game,
      p.id,
      defenderMinorOrTribeId,
    )) {
      continue;
    }
    eligible.add(p.id);
  }
  eligible.sort();
  var g = game;
  final pending = <InterventionPrompt>[];
  for (final interveningId in eligible) {
    if (_interventionChoiceRecordedForTurn(g, turn, interveningId, aggressorGpId)) {
      continue;
    }
    final player = g.playerById(interveningId);
    if (player == null) continue;
    if (player.isHuman) {
      final d = _findInterventionDecision(
        interventionDecisions,
        aggressorGpId,
        defenderMinorOrTribeId,
        interveningId,
      );
      if (d == null) {
        pending.add(
          InterventionPrompt(
            aggressorGpId: aggressorGpId,
            defenderMinorOrTribeId: defenderMinorOrTribeId,
            interveningGpId: interveningId,
          ),
        );
        continue;
      }
      g = applyInterventionAgainstAggressor(
        g,
        aggressorGpId: aggressorGpId,
        defenderMinorOrTribeId: defenderMinorOrTribeId,
        interveningGpId: interveningId,
        choice: d.choice,
      );
      continue;
    }
    final aiChoice = _chooseAiIntervention(
      g,
      interveningId,
      aggressorGpId,
      defenderMinorOrTribeId,
      turn,
    );
    g = applyInterventionAgainstAggressor(
      g,
      aggressorGpId: aggressorGpId,
      defenderMinorOrTribeId: defenderMinorOrTribeId,
      interveningGpId: interveningId,
      choice: aiChoice,
    );
  }
  if (pending.isNotEmpty) {
    return _InterventionResolutionResult(g, pendingInterventions: pending);
  }
  return _InterventionResolutionResult(g);
}

_InterventionResolutionResult _resolveOutstandingInterventionsForMinorTribeWars(
  Game game,
  Map<String, List<DiplomaticOrder>> diploByPlayer,
  int turn, {
  List<InterventionDecision>? interventionDecisions,
}) {
  final seen = <String>{};
  var g = game;
  for (final entry in diploByPlayer.entries) {
    final gpId = entry.key;
    for (final order in entry.value) {
      if (order.type != DiplomaticOrderType.declareWar) continue;
      final targetId = order.targetFactionId;
      if (!isGreatPower(g, gpId) || !isMinorOrTribe(g, targetId)) continue;
      final rel = getRelation(g, gpId, targetId);
      if (rel == null || !rel.atWar) continue;
      final key = '$gpId|$targetId';
      if (seen.contains(key)) continue;
      seen.add(key);
      if (!_interventionsOutstanding(g, turn, gpId, targetId)) continue;
      final pass = _processInterventionsForAggressorDefender(
        g,
        aggressorGpId: gpId,
        defenderMinorOrTribeId: targetId,
        turn: turn,
        interventionDecisions: interventionDecisions,
      );
      g = pass.game;
      if (pass.pendingInterventions != null &&
          pass.pendingInterventions!.isNotEmpty) {
        return pass;
      }
    }
  }
  return _InterventionResolutionResult(g);
}

/// GP–GP war pairs from declare-war orders that are at war after step 5.
List<({String aggressor, String defender})> _gpGpWarPairsFromOrders(
  Game game,
  Map<String, List<DiplomaticOrder>> diploByPlayer,
) {
  final seen = <String>{};
  final out = <({String aggressor, String defender})>[];
  for (final e in diploByPlayer.entries) {
    final aggressor = e.key;
    if (!isGreatPower(game, aggressor)) continue;
    for (final o in e.value) {
      if (o.type != DiplomaticOrderType.declareWar) continue;
      final defender = o.targetFactionId;
      if (!isGreatPower(game, defender)) continue;
      if (!factionsAtWar(game, aggressor, defender)) continue;
      final key = '$aggressor|$defender';
      if (seen.add(key)) {
        out.add((aggressor: aggressor, defender: defender));
      }
    }
  }
  return out;
}

Game _cancelSubsidiesBetweenGps(
  Game game,
  String id1,
  String id2,
  int turn,
) {
  var subsidyStates = List<SubsidyState>.from(game.subsidyStates);
  final cancelled = subsidyStates
      .where(
        (s) =>
            (s.payerId == id1 && s.targetId == id2) ||
            (s.payerId == id2 && s.targetId == id1),
      )
      .toList();
  if (cancelled.isEmpty) return game;
  subsidyStates = subsidyStates
      .where(
        (s) =>
            !((s.payerId == id1 && s.targetId == id2) ||
                (s.payerId == id2 && s.targetId == id1)),
      )
      .toList();
  var g = game.copyWith(subsidyStates: subsidyStates);
  for (final s in cancelled) {
    _diploLog.i(
      'diplomacy subsidies cancelled due to war ${s.payerId} vs ${s.targetId}',
    );
    g = _appendDiplomaticEvent(
      g,
      turn,
      DiplomaticEventType.subsidyCancelled,
      {s.payerId, s.targetId},
      fromFactionId: s.payerId,
      toFactionId: s.targetId,
      reason: 'war',
      wasAiInitiator: isAiControlledForEvidence(g, s.payerId),
    );
  }
  return g;
}

Game _applyCallToArmsAccept(
  Game game,
  String allyGpId,
  String aggressorGpId,
  int turn,
) {
  var relations = List<DiplomacyRelation>.from(game.diplomacyRelations);
  relations = setWarStateForPair(
    relations: relations,
    gpId: allyGpId,
    targetId: aggressorGpId,
    turn: turn,
  );
  var g = game.copyWith(diplomacyRelations: relations);
  g = _cancelSubsidiesBetweenGps(g, allyGpId, aggressorGpId, turn);
  g = _appendDiplomaticEvent(
    g,
    turn,
    DiplomaticEventType.callToArmsAccepted,
    {allyGpId, aggressorGpId},
    fromFactionId: allyGpId,
    toFactionId: aggressorGpId,
    wasAiInitiator: isAiControlledForEvidence(g, allyGpId),
  );
  _diploLog.i(
    'diplomacy call to arms accept $allyGpId joins war vs $aggressorGpId',
  );
  return g;
}

Game _applyCallToArmsRefuse(
  Game game,
  String allyGpId,
  String defenderGpId,
  int turn,
) {
  var relations = List<DiplomacyRelation>.from(game.diplomacyRelations);
  relations = upsertRelation(relations, allyGpId, defenderGpId, (existing) {
    final base = existing?.score ?? relationScoreNeutral;
    var newScore =
        (base - callToArmsRefusalScorePenalty).clamp(relationScoreMin, relationScoreMax);
    var newLevel = scoreToLevel(newScore);
    if (newLevel == RelationLevel.allied) {
      newScore = relationScoreLevelFriendlyMax;
      newLevel = RelationLevel.friendly;
    }
    final ids = canonicalPairIds(allyGpId, defenderGpId);
    if (existing == null) {
      return DiplomacyRelation(
        factionId1: ids.id1,
        factionId2: ids.id2,
        score: newScore,
        level: newLevel,
        lastInteractionTurn: turn,
      );
    }
    return existing.copyWith(
      score: newScore,
      level: newLevel,
      lastInteractionTurn: turn,
    );
  });
  var g = game.copyWith(diplomacyRelations: relations);
  g = _appendDiplomaticEvent(
    g,
    turn,
    DiplomaticEventType.callToArmsRefused,
    {allyGpId, defenderGpId},
    fromFactionId: allyGpId,
    toFactionId: defenderGpId,
    wasAiInitiator: isAiControlledForEvidence(g, allyGpId),
  );
  _diploLog.i(
    'diplomacy call to arms refuse $allyGpId breaks alliance with $defenderGpId',
  );
  return g;
}

_CallToArmsResult _processCallToArms(
  Game game,
  Map<String, List<DiplomaticOrder>> diploByPlayer,
  int turn, {
  List<CallToArmsDecision>? callToArmsDecisions,
}) {
  var state = game;
  final warPairs = _gpGpWarPairsFromOrders(state, diploByPlayer);
  final pending = <CallToArmsPending>[];

  for (final pair in warPairs) {
    final aggressorGpId = pair.aggressor;
    final defenderGpId = pair.defender;
    for (final p in state.players) {
      final allyGpId = p.id;
      if (allyGpId == defenderGpId || allyGpId == aggressorGpId) continue;
      if (factionsAtWar(state, allyGpId, aggressorGpId)) continue;
      final rel = getRelation(state, allyGpId, defenderGpId);
      if (rel == null ||
          !rel.atPeace ||
          rel.level != RelationLevel.allied) {
        continue;
      }

      if (isAiControlled(state, allyGpId)) {
        final accept = rel.score >= callToArmsAiAcceptMinRelationScore;
        if (accept) {
          state = _applyCallToArmsAccept(state, allyGpId, aggressorGpId, turn);
        } else {
          state = _applyCallToArmsRefuse(
            state,
            allyGpId,
            defenderGpId,
            turn,
          );
        }
        continue;
      }

      final decision = _findCallToArmsDecision(
        callToArmsDecisions,
        allyGpId,
        defenderGpId,
        aggressorGpId,
      );
      if (decision == null) {
        pending.add(
          CallToArmsPending(
            allyGpId: allyGpId,
            defenderGpId: defenderGpId,
            aggressorGpId: aggressorGpId,
          ),
        );
      } else if (decision.accepted) {
        state = _applyCallToArmsAccept(state, allyGpId, aggressorGpId, turn);
      } else {
        state = _applyCallToArmsRefuse(state, allyGpId, defenderGpId, turn);
      }
    }
  }

  pending.sort((a, b) {
    final c1 = a.allyGpId.compareTo(b.allyGpId);
    if (c1 != 0) return c1;
    final c2 = a.defenderGpId.compareTo(b.defenderGpId);
    if (c2 != 0) return c2;
    return a.aggressorGpId.compareTo(b.aggressorGpId);
  });

  if (pending.isNotEmpty) {
    return _CallToArmsResult(state, pendingCallToArms: pending);
  }
  return _CallToArmsResult(state);
}

Game _terminateAgreementsOnWar(Game game) {
  final turn = game.worldState.turnState.turnNumber;
  var overtures = game.overtureStates;
  for (final rel in game.diplomacyRelations) {
    if (!rel.atWar) continue;
    final id1 = rel.factionId1;
    final id2 = rel.factionId2;
    overtures = overtures
        .where(
          (o) =>
              !((o.gpId == id1 && o.targetId == id2) ||
                  (o.gpId == id2 && o.targetId == id1)),
        )
        .toList();
  }
  if (overtures.length != game.overtureStates.length) {
    final removed = game.overtureStates
        .where(
          (o) => !overtures.any(
            (n) => n.gpId == o.gpId && n.targetId == o.targetId,
          ),
        )
        .toList();
    game = game.copyWith(overtureStates: overtures);
    for (final o in removed) {
      game = _appendDiplomaticEvent(
        game,
        turn,
        DiplomaticEventType.agreementsClearedOnWar,
        {o.gpId, o.targetId},
        fromFactionId: o.gpId,
        toFactionId: o.targetId,
        reason: 'war',
      );
    }
    _diploLog.i('diplomacy agreements terminated (war)');
  }
  return game;
}

Game _applyRelationModifiersAndUpdateScores(
  Game game,
  Map<String, List<DiplomaticOrder>> diploByPlayer,
  int turn,
) {
  var players = game.players;
  var relations = List<DiplomacyRelation>.from(game.diplomacyRelations);

  // GrantAid: deduct treasury, add relation modifier (+5 per grant). Requires Embassy.
  for (final entry in diploByPlayer.entries) {
    final gpId = entry.key;
    final player = game.playerById(gpId);
    if (player == null) continue;

    for (final order in entry.value) {
      if (order.type != DiplomaticOrderType.grantAid) continue;
      final amount = order.amount ?? 0;
      if (amount > 0 && amount % grantAidAmountStep != 0) {
        throw StateError(
          'GrantAid at resolution must be a positive multiple of '
          '£$grantAidAmountStep (was $amount)',
        );
      }
      if (amount <= 0 || player.treasury < amount) continue;
      if (amount < grantAidAmountStep || amount % grantAidAmountStep != 0) {
        continue;
      }

      final targetId = order.targetFactionId;
      final overture = getOverture(game, gpId, targetId);
      if (overture == null || !overture.hasEmbassy) continue;

      final playerIdx = players.indexWhere((p) => p.id == gpId);
      if (playerIdx >= 0) {
        players = List<Player>.from(players);
        players[playerIdx] = players[playerIdx].copyWith(
          treasury: players[playerIdx].treasury - amount,
        );
      }

      relations = applyGrantAidModifier(
        relations: relations,
        gpId: gpId,
        targetId: targetId,
        turn: turn,
      );
      game = game.copyWith(players: players, diplomacyRelations: relations);
      game = _appendDiplomaticEvent(
        game,
        turn,
        DiplomaticEventType.grantAidApplied,
        {gpId, targetId},
        fromFactionId: gpId,
        toFactionId: targetId,
        amount: amount,
        wasAiInitiator: isAiControlledForEvidence(game, gpId),
      );
      _diploLog.i(
        'diplomacy GrantAid $gpId -> $targetId amount $amount',
      );
    }
  }

  // SetSubsidy: Create or update ongoing subsidy. Requires Consulate or Embassy.
  // Deducts initial payment immediately; ongoing payments processed each turn.
  var subsidyStates = List<SubsidyState>.from(game.subsidyStates);
  for (final entry in diploByPlayer.entries) {
    final gpId = entry.key;

    for (final order in entry.value) {
      if (order.type != DiplomaticOrderType.setSubsidy) continue;
      final amount = order.amount ?? 0;
      final player = game.playerById(gpId);
      if (amount > 0 && amount % setSubsidyAmountStep != 0) {
        throw StateError(
          'SetSubsidy at resolution must be a positive multiple of '
          '£$setSubsidyAmountStep (was $amount)',
        );
      }
      if (player == null || amount <= 0 || player.treasury < amount) continue;
      if (amount < setSubsidyAmountStep || amount % setSubsidyAmountStep != 0) {
        continue;
      }

      final targetId = order.targetFactionId;
      final overture = getOverture(game, gpId, targetId);
      if (overture == null || !overture.hasConsulate) continue;

      // Deduct initial payment
      final payerIdx = players.indexWhere((p) => p.id == gpId);
      if (payerIdx >= 0) {
        players = List<Player>.from(players);
        players[payerIdx] = players[payerIdx].copyWith(
          treasury: players[payerIdx].treasury - amount,
        );
      }

      // Store/update ongoing subsidy state
      final existingSubsidyIdx = subsidyStates.indexWhere(
        (s) => s.payerId == gpId && s.targetId == targetId,
      );
      final isUpdate = existingSubsidyIdx >= 0;
      if (isUpdate) {
        subsidyStates[existingSubsidyIdx] = subsidyStates[existingSubsidyIdx]
            .copyWith(amountPerTurn: amount);
      } else {
        subsidyStates.add(
          SubsidyState(
            payerId: gpId,
            targetId: targetId,
            amountPerTurn: amount,
          ),
        );
      }

      game = game.copyWith(players: players, subsidyStates: subsidyStates);
      game = _appendDiplomaticEvent(
        game,
        turn,
        isUpdate
            ? DiplomaticEventType.subsidyUpdated
            : DiplomaticEventType.subsidySet,
        {gpId, targetId},
        fromFactionId: gpId,
        toFactionId: targetId,
        amount: amount,
        wasAiInitiator: isAiControlledForEvidence(game, gpId),
      );
      final targetPlayer = game.playerById(targetId);
      if (targetPlayer != null) {
        _diploLog.i(
          'diplomacy SetSubsidy $gpId -> $targetId amount $amount/turn (ongoing)',
        );
      } else {
        _diploLog.i(
          'diplomacy SetSubsidy $gpId -> $targetId amount $amount/turn (ongoing relation boost)',
        );
      }
    }
  }

  return game;
}

/// Process ongoing subsidies each turn.
/// Deducts amount from payer treasury and improves relation by +2 per 500 ducats (max +8).
/// Per SPEC/game/diplomacy.md.
Game _processOngoingSubsidies(Game game, int turn) {
  var players = game.players;
  var relations = List<DiplomacyRelation>.from(game.diplomacyRelations);
  var subsidyStates = List<SubsidyState>.from(game.subsidyStates);

  for (final subsidy in subsidyStates) {
    final payerId = subsidy.payerId;
    final targetId = subsidy.targetId;
    final amount = subsidy.amountPerTurn;

    // Check if payer can afford subsidy
    final payer = game.playerById(payerId);
    if (payer == null || payer.treasury < amount) {
      game = _appendDiplomaticEvent(
        game,
        turn,
        DiplomaticEventType.subsidyCancelled,
        {payerId, targetId},
        fromFactionId: payerId,
        toFactionId: targetId,
        reason: 'insufficient funds',
        wasAiInitiator: isAiControlledForEvidence(game, payerId),
      );
      subsidyStates = subsidyStates
          .where((s) => s.payerId != payerId || s.targetId != targetId)
          .toList();
      _diploLog.i(
        'diplomacy subsidy cancelled $payerId -> $targetId (insufficient funds)',
      );
      continue;
    }

    // Check if still at peace (subsidies cancel on war)
    final rel = getRelation(game, payerId, targetId);
    if (rel != null && rel.atWar) {
      game = _appendDiplomaticEvent(
        game,
        turn,
        DiplomaticEventType.subsidyCancelled,
        {payerId, targetId},
        fromFactionId: payerId,
        toFactionId: targetId,
        reason: 'war declared',
        wasAiInitiator: isAiControlledForEvidence(game, payerId),
      );
      subsidyStates = subsidyStates
          .where((s) => s.payerId != payerId || s.targetId != targetId)
          .toList();
      _diploLog.i(
        'diplomacy subsidy cancelled $payerId -> $targetId (war declared)',
      );
      continue;
    }

    // Deduct subsidy payment
    final payerIdx = players.indexWhere((p) => p.id == payerId);
    if (payerIdx >= 0) {
      players = List<Player>.from(players);
      players[payerIdx] = players[payerIdx].copyWith(
        treasury: players[payerIdx].treasury - amount,
      );
    }

    // Calculate relation boost: +subsidyBoostRelationPerStep per subsidyBoostDucatsPerStep ducats, max subsidyBoostMax
    final boost =
        ((amount ~/ subsidyBoostDucatsPerStep) * subsidyBoostRelationPerStep)
            .clamp(0, subsidyBoostMax);

    // Apply relation boost (only for Minors/Tribes - GPs get treasury transfer)
    if (isMinorOrTribe(game, targetId)) {
      relations = applySubsidyBoost(
        relations: relations,
        payerId: payerId,
        targetId: targetId,
        boost: boost,
        turn: turn,
      );
      _diploLog.i(
        'diplomacy subsidy processed $payerId -> $targetId amount=$amount boost=+$boost',
      );
    } else {
      // GP target: transfer treasury
      final targetIdx = players.indexWhere((p) => p.id == targetId);
      if (targetIdx >= 0) {
        players[targetIdx] = players[targetIdx].copyWith(
          treasury: players[targetIdx].treasury + amount,
        );
      }
      _diploLog.i(
        'diplomacy subsidy processed $payerId -> $targetId amount=$amount (treasury transfer)',
      );
    }
  }

  return game.copyWith(
    players: players,
    diplomacyRelations: relations,
    subsidyStates: subsidyStates,
  );
}

/// Apply relation convergence: all non-war relations move +/-1 toward neutral.
/// Per SPEC/game/diplomacy.md.
Game _applyRelationConvergence(Game game, int turn) {
  var relations = List<DiplomacyRelation>.from(game.diplomacyRelations);

  for (var i = 0; i < relations.length; i++) {
    final rel = relations[i];
    // Skip war relations - they don't converge and scores stay fixed at war declaration
    if (rel.atWar) continue;

    // Converge toward neutral
    int newScore;
    if (rel.score < relationScoreNeutral) {
      newScore = (rel.score + 1).clamp(relationScoreMin, relationScoreMax);
    } else if (rel.score > relationScoreNeutral) {
      newScore = (rel.score - 1).clamp(relationScoreMin, relationScoreMax);
    } else {
      continue; // Already at neutral
    }

    final newLevel = scoreToLevel(newScore);
    relations[i] = rel.copyWith(score: newScore, level: newLevel);
  }

  return game.copyWith(diplomacyRelations: relations);
}

/// Trade slots gated by embassy. Stub: 0 without embassy, 1 with embassy.
/// Per diplomacy-resolution: trade slots gated by embassy level.
int tradeSlotsForGp(Game game, String gpId, String targetFactionId) {
  final o = getOverture(game, gpId, targetFactionId);
  return o != null && o.hasEmbassy ? 1 : 0;
}

bool _gpHasPurchasedLandInFactionProvinces(
  Game game,
  String gpId,
  String factionId,
) {
  if (game.worldState.purchasedTilesByTileKey.isEmpty) return false;
  final worldState = game.worldState;
  for (final entry in worldState.purchasedTilesByTileKey.entries) {
    if (entry.value != gpId) continue;
    final provinceId = Unit.provinceIdFromTileKey(entry.key);
    if (provinceId == null) continue;
    final province = tryGetProvince(worldState, provinceId);
    if (province != null && province.ownerId == factionId) {
      return true;
    }
  }
  return false;
}

/// Applies intervention for one aggressor GP (Diplomacy phase when a GP declares
/// war on a Minor/Tribe; legacy combat hook may use [applyInterventionChoice]).
/// SPEC/game/diplomacy.md § Intervention.
Game applyInterventionAgainstAggressor(
  Game game, {
  required String aggressorGpId,
  required String defenderMinorOrTribeId,
  required String interveningGpId,
  required InterventionChoice choice,
}) {
  final turn = game.worldState.turnState.turnNumber;
  if (!isGreatPower(game, aggressorGpId)) return game;

  if (choice == InterventionChoice.doNothing) {
    var g = _clearOverturesBetweenGpAndMinorTribe(
      game,
      interveningGpId,
      defenderMinorOrTribeId,
    );
    g = _appendDiplomaticEvent(
      g,
      turn,
      DiplomaticEventType.interventionDoNothing,
      {interveningGpId, aggressorGpId},
      fromFactionId: interveningGpId,
      toFactionId: aggressorGpId,
    );
    return g;
  }

  var relations = List<DiplomacyRelation>.from(game.diplomacyRelations);

  if (choice == InterventionChoice.intervene) {
    final ids = canonicalPairIds(interveningGpId, aggressorGpId);
    relations = upsertRelation(relations, interveningGpId, aggressorGpId, (
      existing,
    ) {
      if (existing == null) {
        return DiplomacyRelation(
          factionId1: ids.id1,
          factionId2: ids.id2,
          score: 40,
          level: RelationLevel.neutral,
          state: RelationState.atWar,
          sinceTurn: turn,
          lastInteractionTurn: turn,
        );
      }
      if (!existing.atPeace) return existing;
      final newScore = (existing.score - relationScoreWarDelta).clamp(
        relationScoreMin,
        relationScoreMax,
      );
      return existing.copyWith(
        state: RelationState.atWar,
        sinceTurn: turn,
        lastInteractionTurn: turn,
        score: newScore,
        level: scoreToLevel(newScore),
      );
    });
  } else if (choice == InterventionChoice.protest) {
    final ids = canonicalPairIds(interveningGpId, aggressorGpId);
    relations = upsertRelation(relations, interveningGpId, aggressorGpId, (
      existing,
    ) {
      final newScore =
          ((existing?.score ?? relationScoreNeutral) - relationScoreWarDelta)
              .clamp(relationScoreMin, relationScoreMax);
      final newLevel = scoreToLevel(newScore);
      if (existing == null) {
        return DiplomacyRelation(
          factionId1: ids.id1,
          factionId2: ids.id2,
          score: newScore,
          level: newLevel,
          lastInteractionTurn: turn,
        );
      }
      return existing.copyWith(
        score: newScore,
        level: newLevel,
        lastInteractionTurn: turn,
      );
    });
  }

  var g = game.copyWith(diplomacyRelations: relations);
  final eventType = choice == InterventionChoice.intervene
      ? DiplomaticEventType.interventionIntervene
      : DiplomaticEventType.interventionProtest;
  g = _appendDiplomaticEvent(
    g,
    turn,
    eventType,
    {interveningGpId, aggressorGpId},
    fromFactionId: interveningGpId,
    toFactionId: aggressorGpId,
  );
  return g;
}

/// Returns gpId of a human GP with Embassy or purchased land for the
/// Minor/Tribe defender, or null. Used for tests and legacy combat hooks;
/// primary intervention flow runs in the Diplomacy phase.
String? needsInterventionChoice(Game game, BattleContext ctx) {
  final defenderId = ctx.defenderFactionId;
  final defenderIsMinorOrTribe = isMinorOrTribe(game, defenderId);
  if (!defenderIsMinorOrTribe) return null;

  final attackerIds = ctx.attackers.map((a) => a.factionId).toSet();
  final attackerIsGp = attackerIds.any(
    (id) => game.players.any((p) => p.id == id),
  );
  if (!attackerIsGp) return null;

  for (final p in game.players) {
    if (!p.isHuman) continue;
    if (attackerIds.contains(p.id)) continue;

    final o = getOverture(game, p.id, defenderId);
    final hasEmbassy = o != null && o.hasEmbassy;
    final hasInvestment = _gpHasPurchasedLandInFactionProvinces(
      game,
      p.id,
      defenderId,
    );
    if (hasEmbassy || hasInvestment) return p.id;
  }
  return null;
}

/// Applies intervention for each Great Power attacker in [ctx] (legacy combat hook).
/// Prefer [applyInterventionAgainstAggressor] for Diplomacy-phase declaration flow.
Game applyInterventionChoice(
  Game game,
  BattleContext ctx,
  String gpIdWithEmbassy,
  InterventionChoice choice,
) {
  var g = game;
  for (final a in ctx.attackers) {
    final attackerId = a.factionId;
    if (!isGreatPower(game, attackerId)) continue;
    g = applyInterventionAgainstAggressor(
      g,
      aggressorGpId: attackerId,
      defenderMinorOrTribeId: ctx.defenderFactionId,
      interveningGpId: gpIdWithEmbassy,
      choice: choice,
    );
  }
  return g;
}
