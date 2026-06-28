import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'package:colonizethis_world/colonizethis_world.dart';
import 'diplomacy_relation_updates.dart';
import 'diplomacy_resolver.dart';
import 'diplomacy_shared_helpers.dart';
import 'overture_resolver.dart';

String _subsidyPairKey(String payerId, String targetId) =>
    '$payerId\x1F$targetId';

Game terminateAgreementsOnWar(Game game, {IntraTurnEventTally? eventTally}) {
  final turn = game.worldState.turnState.turnNumber;
  final membership = DiplomacyFactionMembership.from(game);
  final clearedForEvents = <OvertureState>[];

  for (final rel in game.diplomacyRelations) {
    if (!rel.atWar) continue;
    final f1 = rel.factionId1;
    final f2 = rel.factionId2;
    final bothGp =
        membership.isGreatPower(f1) && membership.isGreatPower(f2);
    if (bothGp) {
      final result = applyGpGpWarOvertureRules(game, f1, f2);
      game = result.game;
      clearedForEvents.addAll(result.changed);
    } else {
      final result = clearOverturesBetweenGpAndFaction(
        game,
        f1,
        f2,
        bidirectional: true,
      );
      game = result.game;
      clearedForEvents.addAll(result.removed);
    }
  }

  if (clearedForEvents.isNotEmpty) {
    for (final o in clearedForEvents) {
      game = appendDiplomaticEvent(
        game,
        turn,
        DiplomaticEventType.agreementsClearedOnWar,
        {o.gpId, o.targetId},
        fromFactionId: o.gpId,
        toFactionId: o.targetId,
        reason: 'war',
        eventTally: eventTally,
      );
    }
    diploLog.i('diplomacy agreements terminated (war)');
  }
  return game;
}

Game applyRelationModifiersAndUpdateScores(
  Game game,
  Map<String, List<DiplomaticOrder>> diploByPlayer,
  int turn, {
  IntraTurnEventTally? eventTally,
}) {
  var players = game.players;
  // Stable id → row index while [players] order/count is unchanged (Refs #2394).
  final playerIndexById = indexByKey(players, (p) => p.id);
  // Pair-key index built once for the phase; grant-aid upserts are amortized
  // O(1) instead of rebuilding the index per order (Refs #3419 step 5).
  final relationsIndex = RelationUpsertIndex(game.diplomacyRelations);

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

      players = debitPlayerTreasury(
        players,
        playerIndexById[gpId] ?? -1,
        amount,
      );

      relationsIndex.upsert(
        gpId,
        targetId,
        grantAidRelationUpdater(gpId, targetId, turn),
      );
      game = game.copyWith(
        players: players,
        diplomacyRelations: relationsIndex.toList(),
      );
      game = logDiplomaticEvent(
        game,
        turn,
        DiplomaticEventType.grantAidApplied,
        {gpId, targetId},
        fromFactionId: gpId,
        toFactionId: targetId,
        amount: amount,
        wasAiInitiator: isAiControlledForEvidence(game, gpId),
        eventTally: eventTally,
        logMessage: 'diplomacy GrantAid $gpId -> $targetId amount $amount',
      );
    }
  }

  // SetSubsidy: Create or update ongoing subsidy. Requires Consulate or Embassy.
  // Deducts initial payment immediately; ongoing payments processed each turn.
  var subsidyStates = List<SubsidyState>.from(game.subsidyStates);
  var subsidyIndexByPair = indexByKey(
    subsidyStates,
    (s) => _subsidyPairKey(s.payerId, s.targetId),
  );
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
      players = debitPlayerTreasury(
        players,
        playerIndexById[gpId] ?? -1,
        amount,
      );

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
      final subsidyTargetIsPlayer = game.playerById(targetId) != null;
      final subsidyLogSuffix = subsidyTargetIsPlayer
          ? '(ongoing)'
          : '(ongoing relation boost)';
      game = logDiplomaticEvent(
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
        eventTally: eventTally,
        logMessage:
            'diplomacy SetSubsidy $gpId -> $targetId amount $amount/turn $subsidyLogSuffix',
      );
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
  IntraTurnEventTally? eventTally,
}) {
  var players = game.players;
  final playerIndexById = indexByKey(players, (p) => p.id);
  // Single index built once for the whole phase; each boost is amortized O(1)
  // and the list is copied only at the end (Refs #3419 step 5).
  final relationsIndex = RelationUpsertIndex(game.diplomacyRelations);
  var subsidyStates = List<SubsidyState>.from(game.subsidyStates);

  for (final subsidy in subsidyStates) {
    final payerId = subsidy.payerId;
    final targetId = subsidy.targetId;
    final amount = subsidy.amountPerTurn;

    // Check if payer can afford subsidy
    final payer = game.playerById(payerId);
    if (payer == null || payer.treasury < amount) {
      game = logDiplomaticEvent(
        game,
        turn,
        DiplomaticEventType.subsidyCancelled,
        {payerId, targetId},
        fromFactionId: payerId,
        toFactionId: targetId,
        reason: 'insufficient funds',
        wasAiInitiator: isAiControlledForEvidence(game, payerId),
        eventTally: eventTally,
        logMessage:
            'diplomacy subsidy cancelled $payerId -> $targetId (insufficient funds)',
      );
      subsidyStates = subsidyStates
          .where((s) => s.payerId != payerId || s.targetId != targetId)
          .toList();
      continue;
    }

    // Check if still at peace (subsidies cancel on war)
    final rel = getRelation(game, payerId, targetId);
    if (rel != null && rel.atWar) {
      game = logDiplomaticEvent(
        game,
        turn,
        DiplomaticEventType.subsidyCancelled,
        {payerId, targetId},
        fromFactionId: payerId,
        toFactionId: targetId,
        reason: 'war declared',
        wasAiInitiator: isAiControlledForEvidence(game, payerId),
        eventTally: eventTally,
        logMessage:
            'diplomacy subsidy cancelled $payerId -> $targetId (war declared)',
      );
      subsidyStates = subsidyStates
          .where((s) => s.payerId != payerId || s.targetId != targetId)
          .toList();
      continue;
    }

    // Deduct subsidy payment
    players = debitPlayerTreasury(
      players,
      playerIndexById[payerId] ?? -1,
      amount,
    );

    // Calculate relation boost: +subsidyBoostRelationPerStep per subsidyBoostDucatsPerStep ducats, max subsidyBoostMax
    final boost =
        ((amount ~/ subsidyBoostDucatsPerStep) * subsidyBoostRelationPerStep)
            .clamp(0, subsidyBoostMax);

    // Apply relation boost (only for Minors/Tribes - GPs get treasury transfer)
    if (factionMembership.isMinorOrTribe(targetId)) {
      relationsIndex.upsert(
        payerId,
        targetId,
        subsidyBoostRelationUpdater(payerId, targetId, boost, turn),
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
    diplomacyRelations: relationsIndex.toList(),
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
