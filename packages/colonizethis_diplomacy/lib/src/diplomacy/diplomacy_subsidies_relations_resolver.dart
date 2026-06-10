import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'package:colonizethis_world/colonizethis_world.dart';
import '../dossier/evidence_rules.dart';
import 'diplomacy_relation_updates.dart';
import 'diplomacy_resolver.dart';
import 'overture_resolver.dart';

/// O(1) lookup of list index by player id for [players] snapshots.
///
/// Callers that replace [players] with `List<Player>.from(players)` preserve
/// index order, so the returned map remains valid for the new list instance.
Map<String, int> _playerListIndexById(List<Player> players) {
  final out = <String, int>{};
  for (var i = 0; i < players.length; i++) {
    out[players[i].id] = i;
  }
  return out;
}

String _subsidyPairKey(String payerId, String targetId) =>
    '$payerId\x1F$targetId';

Map<String, int> _subsidyStateIndexByPair(List<SubsidyState> states) {
  final out = <String, int>{};
  for (var i = 0; i < states.length; i++) {
    final s = states[i];
    out[_subsidyPairKey(s.payerId, s.targetId)] = i;
  }
  return out;
}

Game terminateAgreementsOnWar(Game game) {
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
      game = appendDiplomaticEvent(
        game,
        turn,
        DiplomaticEventType.agreementsClearedOnWar,
        {o.gpId, o.targetId},
        fromFactionId: o.gpId,
        toFactionId: o.targetId,
        reason: 'war',
      );
    }
    diploLog.i('diplomacy agreements terminated (war)');
  }
  return game;
}

Game applyRelationModifiersAndUpdateScores(
  Game game,
  Map<String, List<DiplomaticOrder>> diploByPlayer,
  int turn,
) {
  var players = game.players;
  // Stable id → row index while [players] order/count is unchanged (Refs #2394).
  final playerIndexById = _playerListIndexById(players);
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

      final playerIdx = playerIndexById[gpId] ?? -1;
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
      game = appendDiplomaticEvent(
        game,
        turn,
        DiplomaticEventType.grantAidApplied,
        {gpId, targetId},
        fromFactionId: gpId,
        toFactionId: targetId,
        amount: amount,
        wasAiInitiator: isAiControlledForEvidence(game, gpId),
      );
      diploLog.i('diplomacy GrantAid $gpId -> $targetId amount $amount');
    }
  }

  // SetSubsidy: Create or update ongoing subsidy. Requires Consulate or Embassy.
  // Deducts initial payment immediately; ongoing payments processed each turn.
  var subsidyStates = List<SubsidyState>.from(game.subsidyStates);
  var subsidyIndexByPair = _subsidyStateIndexByPair(subsidyStates);
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
      final payerIdx = playerIndexById[gpId] ?? -1;
      if (payerIdx >= 0) {
        players = List<Player>.from(players);
        players[payerIdx] = players[payerIdx].copyWith(
          treasury: players[payerIdx].treasury - amount,
        );
      }

      // Store/update ongoing subsidy state
      final pairKey = _subsidyPairKey(gpId, targetId);
      final existingSubsidyIdx = subsidyIndexByPair[pairKey] ?? -1;
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
        subsidyIndexByPair[pairKey] = subsidyStates.length - 1;
      }

      game = game.copyWith(players: players, subsidyStates: subsidyStates);
      game = appendDiplomaticEvent(
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
        diploLog.i(
          'diplomacy SetSubsidy $gpId -> $targetId amount $amount/turn (ongoing)',
        );
      } else {
        diploLog.i(
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
Game processOngoingSubsidies(
  Game game,
  int turn, {
  required DiplomacyFactionMembership factionMembership,
}) {
  var players = game.players;
  final playerIndexById = _playerListIndexById(players);
  var relations = List<DiplomacyRelation>.from(game.diplomacyRelations);
  var subsidyStates = List<SubsidyState>.from(game.subsidyStates);

  for (final subsidy in subsidyStates) {
    final payerId = subsidy.payerId;
    final targetId = subsidy.targetId;
    final amount = subsidy.amountPerTurn;

    // Check if payer can afford subsidy
    final payer = game.playerById(payerId);
    if (payer == null || payer.treasury < amount) {
      game = appendDiplomaticEvent(
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
      diploLog.i(
        'diplomacy subsidy cancelled $payerId -> $targetId (insufficient funds)',
      );
      continue;
    }

    // Check if still at peace (subsidies cancel on war)
    final rel = getRelation(game, payerId, targetId);
    if (rel != null && rel.atWar) {
      game = appendDiplomaticEvent(
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
      diploLog.i(
        'diplomacy subsidy cancelled $payerId -> $targetId (war declared)',
      );
      continue;
    }

    // Deduct subsidy payment
    final payerIdx = playerIndexById[payerId] ?? -1;
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
    if (factionMembership.isMinorOrTribe(targetId)) {
      relations = applySubsidyBoost(
        relations: relations,
        payerId: payerId,
        targetId: targetId,
        boost: boost,
        turn: turn,
      );
      diploLog.i(
        'diplomacy subsidy processed $payerId -> $targetId amount=$amount boost=+$boost',
      );
    } else {
      // GP target: transfer treasury
      final targetIdx = playerIndexById[targetId] ?? -1;
      if (targetIdx >= 0) {
        players[targetIdx] = players[targetIdx].copyWith(
          treasury: players[targetIdx].treasury + amount,
        );
      }
      diploLog.i(
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
Game applyRelationConvergence(Game game, int turn) {
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

/// Commodity slots for trade agreements: 0 without embassy; baseline **3** with
/// embassy; **6** when [kTechIdTradeFairs] is unlocked. SPEC/program/diplomacy-resolution.md.
int tradeSlotsForGp(Game game, String gpId, String targetFactionId) {
  final o = getOverture(game, gpId, targetFactionId);
  if (o == null || !o.hasEmbassy) {
    return 0;
  }
  final p = game.playerById(gpId);
  if (p == null) {
    return 0;
  }
  final u = p.techUnlocked ?? const <String, bool>{};
  return u[kTechIdTradeFairs] == true ? 6 : 3;
}
