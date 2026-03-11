/// Diplomacy phase resolution. SPEC/program/diplomacy-resolution.md.
/// Steps: overture payments (two-way accept/reject), advance overtures,
/// Join Empire/Colony, alliance proposals, Declare War/Peace, relation modifiers, score update.

import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:logger/logger.dart';

import '../constants.dart';
import '../combat/conflict_detection.dart';
import '../dossier/evidence_rules.dart';
import '../turn/turn_resolution_result.dart';
import '../world/province_lookup.dart';
import 'diplomacy_relation_lookup.dart';
import 'diplomacy_relation_updates.dart';

export 'diplomacy_relation_lookup.dart';

final Logger _diploLog = Logger();

bool _isMinorOrTribe(Game game, String factionId) {
  return game.minorNations.any((m) => m.id == factionId) ||
      game.tribes.any((t) => t.id == factionId);
}

bool _isGreatPower(Game game, String factionId) {
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
DiplomacyPhaseResult resolveDiplomacyPhase(
  Game game,
  Orders orders, {
  void Function(DialogueEvent)? onDialogue,
  List<OvertureDecision>? overtureDecisions,
}) {
  _diploLog.d('logic: diplomacy phase start');
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
    _diploLog.d('logic: diplomacy phase suspended (pending overture decisions)');
    return DiplomacyPhaseResult(state, overtureResult.pendingOvertures);
  }

  // 2. Advance in-progress overtures (turn delays)
  state = _advanceOvertures(state, turn);

  // 3. Resolve Join Empire/Colony
  state = _resolveJoinEmpireColony(state, diploByPlayer, turn);

  // 4. Process alliance proposals and responses
  state = _processAlliances(state, diploByPlayer, turn);

  // 5. Process Declare War and Peace
  state =
      _processWarAndPeace(state, diploByPlayer, turn, onDialogue: onDialogue);

  // 6. War terminates agreements with target
  state = _terminateAgreementsOnWar(state);

  // 7. Process ongoing subsidies (+2 per 500 ducats, max +8 per turn)
  // Note: Convergence happens AFTER subsidies
  state = _processOngoingSubsidies(state, turn);

  // 8. Apply relation convergence (+/1 toward 50 for all non-war relations)
  state = _applyRelationConvergence(state, turn);

  // 9. Apply relation modifiers (grants, etc.)
  state = _applyRelationModifiersAndUpdateScores(state, diploByPlayer, turn);

  _diploLog.d('logic: diplomacy phase end');
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

/// AI GP target: accept if relation score >= 50 (Neutral or better). MVP rule.
bool _aiGpAccepts(Game game, String offererGpId, String targetGpId) {
  final rel = getRelation(game, offererGpId, targetGpId);
  final score = rel?.score ?? 50;
  return score >= 50;
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
      final targetIsMinorOrTribe = _isMinorOrTribe(state, targetId);
      final targetIsGp = _isGreatPower(state, targetId);
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
        final decision = _findDecision(overtureDecisions, gpId, targetId, stage);
        if (decision != null) {
          accepted = decision.accepted;
        } else if (_isTargetHumanGp(state, targetId)) {
          // Suspend: need human response.
          final pending = [OvertureOffer(offererGpId: gpId, targetFactionId: targetId, stage: stage)];
          state = state.copyWith(players: players, overtureStates: overtures);
          return _OverturePaymentsResult(state, pending);
        } else {
          accepted = _aiGpAccepts(state, gpId, targetId);
        }
      }

      if (!accepted) continue;

      if (cost > 0) {
        player = player.copyWith(treasury: player.treasury - cost);
        players[playerIdx] = player;
      }

      final osIdx =
          overtures.indexWhere((o) => o.gpId == gpId && o.targetId == targetId);
      if (osIdx >= 0) {
        overtures = List<OvertureState>.from(overtures);
        overtures[osIdx] =
            overtures[osIdx].copyWith(stage: stage, sinceTurn: turn);
      } else {
        overtures = [
          ...overtures,
          OvertureState(
              gpId: gpId, targetId: targetId, stage: stage, sinceTurn: turn)
        ];
      }
      _diploLog.i('logic: diplomacy overture $gpId -> $targetId $stage (accepted)');
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
      if (!_isMinorOrTribe(game, targetId)) continue;

      final player = game.playerById(gpId);
      if (player == null) continue;

      final existing = getOverture(game, gpId, targetId);
      if (existing == null || existing.stage != OvertureStage.nap) continue;

      final rel = getRelation(game, gpId, targetId);
      final score = rel?.score ?? 50;
      if (score < 51) continue; // Must be Friendly or Allied

      final cost = joinEmpireCostForMinorOrTribe(game, targetId);
      if (player.treasury < cost) continue;

      // Absorb Minor/Tribe: transfer provinces, units, fleets to GP; remove faction.
      game = _absorbMinorOrTribeIntoGp(game, gpId, targetId, turn);
      _diploLog.i('logic: diplomacy join empire $gpId $targetId cost=$cost');
    }
  }
  return game;
}

/// Transfers all provinces, units, and fleets owned by [targetId] to [gpId],
/// deducts Join Empire cost from GP treasury, removes the Minor/Tribe and
/// cleans overtures/relations. SPEC/game/diplomacy.md.
Game _absorbMinorOrTribeIntoGp(Game game, String gpId, String targetId, int turn) {
  final cost = joinEmpireCostForMinorOrTribe(game, targetId);
  var players = List<Player>.from(game.players);
  final gpIdx = players.indexWhere((p) => p.id == gpId);
  if (gpIdx >= 0) {
    players = List<Player>.from(players);
    players[gpIdx] = players[gpIdx].copyWith(treasury: players[gpIdx].treasury - cost);
  }

  // Transfer provinces: ownerId targetId -> gpId
  final owProvinces = game.worldState.oldWorld.provinces
      .map((p) => p.ownerId == targetId ? p.copyWith(ownerId: gpId) : p)
      .toList();
  final nwProvinces = game.worldState.newWorld.provinces
      .map((p) => p.ownerId == targetId ? p.copyWith(ownerId: gpId) : p)
      .toList();

  // Transfer units: ownerId targetId -> gpId
  final owUnits = game.worldState.oldWorld.units
      .map((u) => u.ownerId == targetId ? u.copyWith(ownerId: gpId) : u)
      .toList();
  final nwUnits = game.worldState.newWorld.units
      .map((u) => u.ownerId == targetId ? u.copyWith(ownerId: gpId) : u)
      .toList();

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
      if (!_isGreatPower(game, targetId)) continue;

      final ids = canonicalPairIds(gpId, targetId);
      final relations = upsertRelation(
        List<DiplomacyRelation>.from(game.diplomacyRelations),
        gpId,
        targetId,
        (existing) => existing == null
            ? DiplomacyRelation(
                factionId1: ids.id1,
                factionId2: ids.id2,
                score: 76,
                level: RelationLevel.allied,
                state: RelationState.atPeace,
                sinceTurn: turn,
                lastInteractionTurn: turn,
              )
            : existing.copyWith(
                level: RelationLevel.allied,
                score: existing.score.clamp(76, 100),
                lastInteractionTurn: turn,
              ),
      );
      game = game.copyWith(diplomacyRelations: relations);
      _diploLog.i('logic: diplomacy alliance $gpId-$targetId');
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
      if (!_isGreatPower(game, gpId) || !_isGreatPower(game, targetId))
        continue;
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
            onDialogue(DialogueEvent(
              leaderId: gpId,
              category: 'diplomatic',
              situation: 'declare_war',
              era: 'earlyModern',
              variables: {'otherNation': targetId},
            ));
          }
          final evidence = evidenceForDeclareWar(game, gpId, targetId, turn);

          relations = setWarStateForPair(
            relations: relations,
            gpId: gpId,
            targetId: targetId,
            turn: turn,
          );
          
          // Cancel any active subsidies between these factions
          var subsidyStates = List<SubsidyState>.from(game.subsidyStates);
          final beforeCount = subsidyStates.length;
          subsidyStates = subsidyStates
              .where((s) => !((s.payerId == gpId && s.targetId == targetId) ||
                  (s.payerId == targetId && s.targetId == gpId)))
              .toList();
          if (subsidyStates.length < beforeCount) {
            _diploLog.i('logic: diplomacy subsidies cancelled due to war $gpId vs $targetId');
          }
          
          game = game.copyWith(
            diplomacyRelations: relations,
            subsidyStates: subsidyStates,
            dossierEvidenceEntries: [
              ...game.dossierEvidenceEntries,
              ...evidence
            ],
          );
          _diploLog.i('logic: diplomacy war declared $gpId vs $targetId (scores reset to 20)');
        }
      } else if (order.type == DiplomaticOrderType.offerPeace) {
        final targetId = order.targetFactionId;
        final rel = getRelation(game, gpId, targetId);
        final key = pairKey(gpId, targetId);
        final bothGreatPowers =
            _isGreatPower(game, gpId) && _isGreatPower(game, targetId);
        final hasMutualOffer = bothGreatPowers
            ? (peaceOffersByPairKey[key]?.length ?? 0) >= 2
            : true;
        if (rel != null && rel.atWar) {
          // SPEC/game/diplomacy.md:
          // - GP–GP peace: both sides must agree (both offer peace in this phase).
          // - Minors never refuse peace offers.
          var bothSidesAgreed = true;
          final isGpTarget = _isGreatPower(game, targetId);
          if (isGpTarget && _isGreatPower(game, gpId)) {
            final key = pairKey(gpId, targetId);
            final offerers = peaceOffersByPairKey[key] ?? const <String>{};
            bothSidesAgreed =
                offerers.contains(gpId) && offerers.contains(targetId);
          }
          if (!bothSidesAgreed) {
            continue;
          }

          if (onDialogue != null && isAiControlledForEvidence(game, gpId)) {
            onDialogue(DialogueEvent(
              leaderId: gpId,
              category: 'diplomatic',
              situation: 'peace_offer',
              era: 'earlyModern',
              variables: {'otherNation': targetId},
            ));
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
            _diploLog.i('logic: diplomacy peace $gpId-$targetId');
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

Game _terminateAgreementsOnWar(Game game) {
  var overtures = game.overtureStates;
  for (final rel in game.diplomacyRelations) {
    if (!rel.atWar) continue;
    final id1 = rel.factionId1;
    final id2 = rel.factionId2;
    overtures = overtures
        .where((o) => !((o.gpId == id1 && o.targetId == id2) ||
            (o.gpId == id2 && o.targetId == id1)))
        .toList();
  }
  if (overtures.length != game.overtureStates.length) {
    game = game.copyWith(overtureStates: overtures);
    _diploLog.i('logic: diplomacy agreements terminated (war)');
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
      if (amount <= 0 || player.treasury < amount) continue;

      final targetId = order.targetFactionId;
      final overture = getOverture(game, gpId, targetId);
      if (overture == null || !overture.hasEmbassy) continue;

      final playerIdx = players.indexWhere((p) => p.id == gpId);
      if (playerIdx >= 0) {
        players = List<Player>.from(players);
        players[playerIdx] = players[playerIdx]
            .copyWith(treasury: players[playerIdx].treasury - amount);
      }

      relations = applyGrantAidModifier(
        relations: relations,
        gpId: gpId,
        targetId: targetId,
        turn: turn,
      );
      game = game.copyWith(players: players, diplomacyRelations: relations);
      _diploLog
          .i('logic: diplomacy GrantAid $gpId -> $targetId amount $amount');
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
      if (player == null || amount <= 0 || player.treasury < amount) continue;

      final targetId = order.targetFactionId;
      final overture = getOverture(game, gpId, targetId);
      if (overture == null || !overture.hasConsulate) continue;

      // Deduct initial payment
      final payerIdx = players.indexWhere((p) => p.id == gpId);
      if (payerIdx >= 0) {
        players = List<Player>.from(players);
        players[payerIdx] = players[payerIdx]
            .copyWith(treasury: players[payerIdx].treasury - amount);
      }

      // Store/update ongoing subsidy state
      final existingSubsidyIdx = subsidyStates.indexWhere(
          (s) => s.payerId == gpId && s.targetId == targetId);
      if (existingSubsidyIdx >= 0) {
        // Update existing subsidy
        subsidyStates[existingSubsidyIdx] = subsidyStates[existingSubsidyIdx]
            .copyWith(amountPerTurn: amount);
      } else {
        // Create new subsidy
        subsidyStates.add(SubsidyState(
          payerId: gpId,
          targetId: targetId,
          amountPerTurn: amount,
        ));
      }

      final targetPlayer = game.playerById(targetId);
      if (targetPlayer != null) {
        _diploLog.i(
            'logic: diplomacy SetSubsidy $gpId -> $targetId amount $amount/turn (ongoing)');
      } else {
        _diploLog.i(
            'logic: diplomacy SetSubsidy $gpId -> $targetId amount $amount/turn (ongoing relation boost)');
      }
      game = game.copyWith(players: players, subsidyStates: subsidyStates);
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
      // Cancel subsidy if payer can't afford it
      subsidyStates = subsidyStates
          .where((s) => s.payerId != payerId || s.targetId != targetId)
          .toList();
      _diploLog.i('logic: diplomacy subsidy cancelled $payerId -> $targetId (insufficient funds)');
      continue;
    }

    // Check if still at peace (subsidies cancel on war)
    final rel = getRelation(game, payerId, targetId);
    if (rel != null && rel.atWar) {
      // Cancel subsidy when war declared
      subsidyStates = subsidyStates
          .where((s) => s.payerId != payerId || s.targetId != targetId)
          .toList();
      _diploLog.i('logic: diplomacy subsidy cancelled $payerId -> $targetId (war declared)');
      continue;
    }

    // Deduct subsidy payment
    final payerIdx = players.indexWhere((p) => p.id == payerId);
    if (payerIdx >= 0) {
      players = List<Player>.from(players);
      players[payerIdx] = players[payerIdx]
          .copyWith(treasury: players[payerIdx].treasury - amount);
    }

    // Calculate relation boost: +2 per 500 ducats, max +8
    final boost = ((amount ~/ 500) * 2).clamp(0, 8);

    // Apply relation boost (only for Minors/Tribes - GPs get treasury transfer)
    if (_isMinorOrTribe(game, targetId)) {
      relations = applySubsidyBoost(
        relations: relations,
        payerId: payerId,
        targetId: targetId,
        boost: boost,
        turn: turn,
      );
      _diploLog.i('logic: diplomacy subsidy processed $payerId -> $targetId amount=$amount boost=+$boost');
    } else {
      // GP target: transfer treasury
      final targetIdx = players.indexWhere((p) => p.id == targetId);
      if (targetIdx >= 0) {
        players[targetIdx] = players[targetIdx]
            .copyWith(treasury: players[targetIdx].treasury + amount);
      }
      _diploLog.i('logic: diplomacy subsidy processed $payerId -> $targetId amount=$amount (treasury transfer)');
    }
  }

  return game.copyWith(players: players, diplomacyRelations: relations, subsidyStates: subsidyStates);
}

/// Apply relation convergence: all non-war relations move +/-1 toward 50 (neutral).
/// Per SPEC/game/diplomacy.md.
Game _applyRelationConvergence(Game game, int turn) {
  var relations = List<DiplomacyRelation>.from(game.diplomacyRelations);

  for (var i = 0; i < relations.length; i++) {
    final rel = relations[i];
    // Skip war relations - they don't converge and scores stay fixed at war declaration
    if (rel.atWar) continue;

    // Converge toward 50 (neutral)
    int newScore;
    if (rel.score < 50) {
      newScore = (rel.score + 1).clamp(0, 100);
    } else if (rel.score > 50) {
      newScore = (rel.score - 1).clamp(0, 100);
    } else {
      continue; // Already at 50
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

/// Returns gpId of a human GP with Embassy or purchased land for the
/// Minor/Tribe defender, or null. Used to determine if an intervention
/// choice is needed before combat.
String? needsInterventionChoice(Game game, BattleContext ctx) {
  final defenderId = ctx.defenderFactionId;
  final isMinorOrTribe = _isMinorOrTribe(game, defenderId);
  if (!isMinorOrTribe) return null;

  final attackerIds = ctx.attackers.map((a) => a.factionId).toSet();
  final attackerIsGp =
      attackerIds.any((id) => game.players.any((p) => p.id == id));
  if (!attackerIsGp) return null;

  for (final p in game.players) {
    if (!p.isHuman) continue;
    if (attackerIds.contains(p.id)) continue;

    final o = getOverture(game, p.id, defenderId);
    final hasEmbassy = o != null && o.hasEmbassy;
    final hasInvestment =
        _gpHasPurchasedLandInFactionProvinces(game, p.id, defenderId);
    if (hasEmbassy || hasInvestment) return p.id;
  }
  return null;
}

/// Applies intervention choice. Call before resolving the battle.
/// Intervene: human declares war on attacker.
/// DoNothing: no change.
/// Protest: relation penalty with attacker.
Game applyInterventionChoice(
  Game game,
  BattleContext ctx,
  String gpIdWithEmbassy,
  InterventionChoice choice,
) {
  if (choice == InterventionChoice.doNothing) return game;

  final turn = game.worldState.turnState.turnNumber;
  var relations = List<DiplomacyRelation>.from(game.diplomacyRelations);

  for (final a in ctx.attackers) {
    final attackerId = a.factionId;
    if (!_isGreatPower(game, attackerId)) continue;

    if (choice == InterventionChoice.intervene) {
      final ids = canonicalPairIds(gpIdWithEmbassy, attackerId);
      relations =
          upsertRelation(relations, gpIdWithEmbassy, attackerId, (existing) {
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
        final newScore = (existing.score - 10).clamp(0, 100);
        return existing.copyWith(
          state: RelationState.atWar,
          sinceTurn: turn,
          lastInteractionTurn: turn,
          score: newScore,
          level: scoreToLevel(newScore),
        );
      });
    } else if (choice == InterventionChoice.protest) {
      final ids = canonicalPairIds(gpIdWithEmbassy, attackerId);
      relations =
          upsertRelation(relations, gpIdWithEmbassy, attackerId, (existing) {
        final newScore = ((existing?.score ?? 50) - 10).clamp(0, 100);
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
            score: newScore, level: newLevel, lastInteractionTurn: turn);
      });
    }
  }
  return game.copyWith(diplomacyRelations: relations);
}
