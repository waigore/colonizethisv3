/// Diplomacy phase resolution. SPEC/program/diplomacy-resolution.md.
/// Steps: overture payments, advance overtures, Join Empire/Colony,
/// alliance proposals, Declare War/Peace, relation modifiers, score update.

import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:logger/logger.dart';

import '../combat/conflict_detection.dart';
import '../dossier/evidence_rules.dart';

final Logger _diploLog = Logger();

/// Overture costs per diplomacy-resolution. Consulate £500, Embassy £1000.
const int overtureConsulateCost = 500;
const int overtureEmbassyCost = 1000;

/// Relation score thresholds for level. 0–25 Hostile, 26–50 Neutral, 51–75 Friendly, 76–100 Allied.
RelationLevel scoreToLevel(int score) {
  if (score <= 25) return RelationLevel.hostile;
  if (score <= 50) return RelationLevel.neutral;
  if (score <= 75) return RelationLevel.friendly;
  return RelationLevel.allied;
}

/// Normalizes faction pair for lookup (consistent ordering).
String _pairKey(String a, String b) =>
    a.compareTo(b) <= 0 ? '$a|$b' : '$b|$a';

/// Returns relation for faction pair, or null if not found.
DiplomacyRelation? getRelation(Game game, String factionId1, String factionId2) {
  final key = _pairKey(factionId1, factionId2);
  for (final r in game.diplomacyRelations) {
    if (_pairKey(r.factionId1, r.factionId2) == key) return r;
  }
  return null;
}

/// Finds the relation between [factionId1] and [factionId2] in [relations],
/// passes it (or null if absent) to [updater], and replaces or appends the result.
List<DiplomacyRelation> upsertRelation(
  List<DiplomacyRelation> relations,
  String factionId1,
  String factionId2,
  DiplomacyRelation Function(DiplomacyRelation?) updater,
) {
  final key = _pairKey(factionId1, factionId2);
  final idx = relations.indexWhere(
      (r) => _pairKey(r.factionId1, r.factionId2) == key);
  final existing = idx >= 0 ? relations[idx] : null;
  final updated = updater(existing);
  final result = List<DiplomacyRelation>.from(relations);
  if (idx >= 0) {
    result[idx] = updated;
  } else {
    result.add(updated);
  }
  return result;
}

/// Canonical faction pair IDs for a pair key.
({String id1, String id2}) _pairIds(String a, String b) {
  final key = _pairKey(a, b);
  final parts = key.split('|');
  return (id1: parts[0], id2: parts[1]);
}

/// Returns overture state for GP–Minor/Tribe, or null.
OvertureState? getOverture(Game game, String gpId, String targetId) {
  for (final o in game.overtureStates) {
    if (o.gpId == gpId && o.targetId == targetId) return o;
  }
  return null;
}

/// Returns player by id, or null.
Player? getPlayer(Game game, String playerId) {
  for (final p in game.players) {
    if (p.id == playerId) return p;
  }
  return null;
}

bool _isMinorOrTribe(Game game, String factionId) {
  return game.minorNations.any((m) => m.id == factionId) ||
      game.tribes.any((t) => t.id == factionId);
}

bool _isGreatPower(Game game, String factionId) {
  return game.players.any((p) => p.id == factionId);
}

/// Resolves Diplomacy phase. Runs before Movement per turn-resolution-phases.
/// When an AI applies declare war or offer peace, [onDialogue] is invoked with
/// a [DialogueEvent] (SPEC/ai/dialogue-and-mood.md).
Game resolveDiplomacyPhase(
  Game game,
  Orders orders, {
  void Function(DialogueEvent)? onDialogue,
}) {
  _diploLog.d('logic: diplomacy phase start');
  final turn = game.worldState.turnState.turnNumber;
  var state = game;

  final diploByPlayer = orders.diplomaticOrdersByPlayerId;

  // 1. Process overture payments (Consulate, Embassy)
  state = _processOverturePayments(state, diploByPlayer, turn);

  // 2. Advance in-progress overtures (turn delays)
  state = _advanceOvertures(state, turn);

  // 3. Resolve Join Empire/Colony
  state = _resolveJoinEmpireColony(state, diploByPlayer, turn);

  // 4. Process alliance proposals and responses
  state = _processAlliances(state, diploByPlayer, turn);

  // 5. Process Declare War and Peace
  state = _processWarAndPeace(state, diploByPlayer, turn, onDialogue: onDialogue);

  // 6. War terminates agreements with target
  state = _terminateAgreementsOnWar(state);

  // 7. Apply relation modifiers (grants, etc.) and update scores
  state = _applyRelationModifiersAndUpdateScores(state, diploByPlayer, turn);

  _diploLog.d('logic: diplomacy phase end');
  return state;
}

Game _processOverturePayments(
  Game game,
  Map<String, List<DiplomaticOrder>> diploByPlayer,
  int turn,
) {
  var players = List<Player>.from(game.players);
  var overtures = List<OvertureState>.from(game.overtureStates);

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
      if (!_isMinorOrTribe(game, targetId)) continue;

      OvertureState? existing;
      for (final o in overtures) {
        if (o.gpId == gpId && o.targetId == targetId) {
          existing = o;
          break;
        }
      }
      int cost;
      if (stage == OvertureStage.tradeConsulate) {
        cost = overtureConsulateCost;
      } else if (stage == OvertureStage.embassy) {
        cost = overtureEmbassyCost;
      } else {
        continue; // NAP and Join Empire are free
      }

      // Must be at previous stage to advance to this one.
      final prevStage = _previousStage(stage);
      final atPrevStage = (existing == null && prevStage == OvertureStage.none) ||
          (existing != null && existing.stage == prevStage);
      final canAdvance = atPrevStage && player.treasury >= cost;

      if (!canAdvance) continue;

      // Deduct treasury and advance overture
      player = player.copyWith(treasury: player.treasury - cost);
      players[playerIdx] = player;

      final osIdx = overtures.indexWhere((o) => o.gpId == gpId && o.targetId == targetId);
      if (osIdx >= 0) {
        overtures = List<OvertureState>.from(overtures);
        overtures[osIdx] = overtures[osIdx].copyWith(stage: stage, sinceTurn: turn);
      } else {
        overtures = [...overtures, OvertureState(gpId: gpId, targetId: targetId, stage: stage, sinceTurn: turn)];
      }
      _diploLog.i('logic: diplomacy overture $gpId -> $targetId $stage');
    }
  }

  return game.copyWith(players: players, overtureStates: overtures);
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
      final existing = getOverture(game, gpId, targetId);
      if (existing == null || existing.stage != OvertureStage.nap) continue;

      final rel = getRelation(game, gpId, targetId);
      final score = rel?.score ?? 50;
      if (score < 51) continue; // Must be Friendly or Allied

      // Join Empire: absorb Minor/Tribe into GP. Per diplomacy.md:
      // Minor -> absorption (provinces to requester); Tribe -> colony.
      // Full implementation would transfer provinces; stub for Phase 4.
      var overtures = List<OvertureState>.from(game.overtureStates);
      final idx = overtures.indexWhere((o) => o.gpId == gpId && o.targetId == targetId);
      if (idx >= 0) {
        overtures = List<OvertureState>.from(overtures);
        overtures[idx] = overtures[idx].copyWith(stage: OvertureStage.joinEmpire, sinceTurn: turn);
        game = game.copyWith(overtureStates: overtures);
        _diploLog.i('logic: diplomacy join empire $gpId $targetId');
      }
    }
  }
  return game;
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

      final ids = _pairIds(gpId, targetId);
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
      if (!_isGreatPower(game, gpId) || !_isGreatPower(game, targetId)) continue;
      final key = _pairKey(gpId, targetId);
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
          final ids = _pairIds(gpId, targetId);
          relations = upsertRelation(relations, gpId, targetId, (existing) {
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
            final newScore = (existing.score - 10).clamp(0, 100);
            return existing.copyWith(
              state: RelationState.atWar,
              sinceTurn: turn,
              lastInteractionTurn: turn,
              score: newScore,
              level: scoreToLevel(newScore),
            );
          });
          game = game.copyWith(
            diplomacyRelations: relations,
            dossierEvidenceEntries: [...game.dossierEvidenceEntries, ...evidence],
          );
          _diploLog.i('logic: diplomacy war declared $gpId vs $targetId');
        }
      } else if (order.type == DiplomaticOrderType.offerPeace) {
        final targetId = order.targetFactionId;
        final rel = getRelation(game, gpId, targetId);
        if (rel != null && rel.atWar) {
          // SPEC/game/diplomacy.md:
          // - GP–GP peace: both sides must agree (both offer peace in this phase).
          // - Minors never refuse peace offers.
          var bothSidesAgreed = true;
          final isGpTarget = _isGreatPower(game, targetId);
          if (isGpTarget && _isGreatPower(game, gpId)) {
            final key = _pairKey(gpId, targetId);
            final offerers = peaceOffersByPairKey[key] ?? const <String>{};
            bothSidesAgreed = offerers.contains(gpId) && offerers.contains(targetId);
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
          relations = upsertRelation(relations, gpId, targetId, (existing) {
            return existing!.copyWith(
              state: RelationState.atPeace,
              sinceTurn: turn,
              lastInteractionTurn: turn,
            );
          });
          game = game.copyWith(
            diplomacyRelations: relations,
            dossierEvidenceEntries: [...game.dossierEvidenceEntries, ...evidence],
          );
          _diploLog.i('logic: diplomacy peace $gpId-$targetId');
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
        .where((o) => !((o.gpId == id1 && o.targetId == id2) || (o.gpId == id2 && o.targetId == id1)))
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
    final player = getPlayer(game, gpId);
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
        players[playerIdx] = players[playerIdx].copyWith(treasury: players[playerIdx].treasury - amount);
      }

      final ids = _pairIds(gpId, targetId);
      relations = upsertRelation(relations, gpId, targetId, (existing) {
        final newScore = ((existing?.score ?? 50) + 5).clamp(0, 100);
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
        return existing.copyWith(score: newScore, level: newLevel, lastInteractionTurn: turn);
      });
      game = game.copyWith(players: players, diplomacyRelations: relations);
      _diploLog.i('logic: diplomacy GrantAid $gpId -> $targetId amount $amount');
    }
  }

  // SetSubsidy: deduct treasury, transfer to target GP or apply relation modifier for Minor/Tribe. Requires Consulate or Embassy.
  for (final entry in diploByPlayer.entries) {
    final gpId = entry.key;

    for (final order in entry.value) {
      if (order.type != DiplomaticOrderType.setSubsidy) continue;
      final amount = order.amount ?? 0;
      final player = getPlayer(game, gpId);
      if (player == null || amount <= 0 || player.treasury < amount) continue;

      final targetId = order.targetFactionId;
      final overture = getOverture(game, gpId, targetId);
      if (overture == null || !overture.hasConsulate) continue;

      final payerIdx = players.indexWhere((p) => p.id == gpId);
      if (payerIdx >= 0) {
        players = List<Player>.from(players);
        players[payerIdx] = players[payerIdx].copyWith(treasury: players[payerIdx].treasury - amount);
      }

      final targetPlayer = getPlayer(game, targetId);
      if (targetPlayer != null) {
        final receiverIdx = players.indexWhere((p) => p.id == targetId);
        if (receiverIdx >= 0) {
          players[receiverIdx] = players[receiverIdx].copyWith(treasury: players[receiverIdx].treasury + amount);
        }
        _diploLog.i('logic: diplomacy SetSubsidy $gpId -> $targetId amount $amount (treasury)');
      } else {
        // Minor/Tribe: no treasury; apply relation modifier (+3 per subsidy per diplomacy.md-style)
        final ids = _pairIds(gpId, targetId);
        relations = upsertRelation(relations, gpId, targetId, (existing) {
          final newScore = ((existing?.score ?? 50) + 3).clamp(0, 100);
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
          return existing.copyWith(score: newScore, level: newLevel, lastInteractionTurn: turn);
        });
        _diploLog.i('logic: diplomacy SetSubsidy $gpId -> $targetId amount $amount (relation)');
      }
      game = game.copyWith(players: players, diplomacyRelations: relations);
    }
  }

  return game;
}

/// Trade slots gated by embassy. Stub: 0 without embassy, 1 with embassy.
/// Per diplomacy-resolution: trade slots gated by embassy level.
int tradeSlotsForGp(Game game, String gpId, String targetFactionId) {
  final o = getOverture(game, gpId, targetFactionId);
  return o != null && o.hasEmbassy ? 1 : 0;
}

/// Returns gpId of a human GP with Embassy for the Minor defender, or null.
/// Used to determine if intervention choice is needed before combat.
String? needsInterventionChoice(Game game, BattleContext ctx) {
  final defenderId = ctx.defenderFactionId;
  final isMinor = game.minorNations.any((m) => m.id == defenderId);
  if (!isMinor) return null;

  final attackerIds = ctx.attackers.map((a) => a.factionId).toSet();
  final attackerIsGp = attackerIds.any((id) => game.players.any((p) => p.id == id));
  if (!attackerIsGp) return null;

  for (final p in game.players) {
    if (!p.isHuman) continue;
    final o = getOverture(game, p.id, defenderId);
    if (o != null && o.hasEmbassy) return p.id;
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
      final ids = _pairIds(gpIdWithEmbassy, attackerId);
      relations = upsertRelation(relations, gpIdWithEmbassy, attackerId, (existing) {
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
      final ids = _pairIds(gpIdWithEmbassy, attackerId);
      relations = upsertRelation(relations, gpIdWithEmbassy, attackerId, (existing) {
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
        return existing.copyWith(score: newScore, level: newLevel, lastInteractionTurn: turn);
      });
    }
  }
  return game.copyWith(diplomacyRelations: relations);
}
