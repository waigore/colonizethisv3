import 'package:colonizethis_models/colonizethis_models.dart';

import 'package:colonizethis_world/colonizethis_world.dart';
import 'diplomacy_event_logging.dart';
import 'diplomacy_relation_lookup.dart';
import 'diplomacy_shared_helpers.dart';

String subsidyPairKey(String payerId, String targetId) =>
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
      game = logDiplomaticEvent(
        game,
        turn,
        DiplomaticEventType.agreementsClearedOnWar,
        {o.gpId, o.targetId},
        fromFactionId: o.gpId,
        toFactionId: o.targetId,
        reason: 'war',
        eventTally: eventTally,
        logMessage:
            'diplomacy agreements cleared on war ${o.gpId}-${o.targetId}',
      );
    }
  }
  return game;
}

/// Maintain ongoing percentage subsidies each turn (Refs #3753 R3). The percent
/// model charges **no** per-turn treasury payment and applies no per-turn
/// relation boost (the relation effect is the scaled trade-deal boost, R10).
/// This pass only **clears** subsidies that are no longer valid: a subsidy is
/// cancelled when the pair goes to `AT_WAR` (existing agreements-on-war rule) or
/// when the payer loses the Embassy with the subsidised Minor/Tribe (R3.5). A
/// `subsidyCancelled` event is appended for each cleared subsidy.
/// SPEC/game/diplomacy.md § Diplomatic Order Types.
Game processOngoingSubsidies(
  Game game,
  int turn, {
  required DiplomacyFactionMembership factionMembership,
  IntraTurnEventTally? eventTally,
}) {
  var subsidyStates = List<SubsidyState>.from(game.subsidyStates);
  final retained = <SubsidyState>[];

  for (final subsidy in subsidyStates) {
    final payerId = subsidy.payerId;
    final targetId = subsidy.targetId;

    String? cancelReason;
    final rel = getRelation(game, payerId, targetId);
    if (rel != null && rel.atWar) {
      cancelReason = 'war declared';
    } else {
      final overture = getOverture(game, payerId, targetId);
      if (overture == null || !overture.hasEmbassy) {
        cancelReason = 'embassy lost';
      }
    }

    if (cancelReason == null) {
      retained.add(subsidy);
      continue;
    }

    game = logDiplomaticEvent(
      game,
      turn,
      DiplomaticEventType.subsidyCancelled,
      {payerId, targetId},
      fromFactionId: payerId,
      toFactionId: targetId,
      reason: cancelReason,
      wasAiInitiator: isAiControlledForEvidence(game, payerId),
      eventTally: eventTally,
      logMessage:
          'diplomacy subsidy cancelled $payerId -> $targetId ($cancelReason)',
    );
  }

  if (retained.length == subsidyStates.length) return game;
  return game.copyWith(subsidyStates: retained);
}

/// Subsidy percentage in effect between [id1] and [id2] (either direction;
/// subsidies are GP→Minor/Tribe), or 0 when no subsidy exists. Used by the
/// trade-deal relation boost (Refs #3753 R10). SPEC/game/diplomacy.md.
int subsidyPercentBetween(Game game, String id1, String id2) {
  for (final s in game.subsidyStates) {
    final between =
        (s.payerId == id1 && s.targetId == id2) ||
        (s.payerId == id2 && s.targetId == id1);
    if (between) return s.percent;
  }
  return 0;
}

/// Process SetSubsidy orders: create or update an ongoing **percentage** subsidy
/// from a GP to a Minor/Tribe (Refs #3753 R3 / #4037). Requires an Embassy (R2).
/// The percent model charges **no** per-turn treasury payment. GP→GP subsidies
/// are ignored. `DiplomaticOrder.amount` carries the subsidy percentage.
/// SPEC/game/diplomacy.md § Diplomatic Order Types.
Game applySetSubsidyOrders(
  Game game,
  Map<String, List<DiplomaticOrder>> diploByPlayer,
  int turn, {
  IntraTurnEventTally? eventTally,
}) {
  var subsidyStates = List<SubsidyState>.from(game.subsidyStates);
  var subsidyIndexByPair = indexByKey(
    subsidyStates,
    (s) => subsidyPairKey(s.payerId, s.targetId),
  );
  for (final entry in diploByPlayer.entries) {
    final gpId = entry.key;

    for (final order in entry.value) {
      if (order.type != DiplomaticOrderType.setSubsidy) continue;
      final percent = order.amount ?? 0;
      final player = game.playerById(gpId);
      if (player == null) continue;
      if (!isValidSubsidyPercent(percent)) continue;

      final targetId = order.targetFactionId;
      // Subsidies are GP → Minor/Tribe only; never GP → GP.
      if (game.playerById(targetId) != null) continue;
      final overture = getOverture(game, gpId, targetId);
      if (overture == null || !overture.hasEmbassy) continue;

      final pairKey = subsidyPairKey(gpId, targetId);
      final existingSubsidyIdx = subsidyIndexByPair[pairKey] ?? -1;
      final isUpdate = existingSubsidyIdx >= 0;
      if (isUpdate) {
        subsidyStates[existingSubsidyIdx] = subsidyStates[existingSubsidyIdx]
            .copyWith(percent: percent);
      } else {
        subsidyStates.add(
          SubsidyState(
            payerId: gpId,
            targetId: targetId,
            percent: percent,
          ),
        );
        subsidyIndexByPair[pairKey] = subsidyStates.length - 1;
      }

      game = game.copyWith(subsidyStates: subsidyStates);
      game = logDiplomaticEvent(
        game,
        turn,
        isUpdate
            ? DiplomaticEventType.subsidyUpdated
            : DiplomaticEventType.subsidySet,
        {gpId, targetId},
        fromFactionId: gpId,
        toFactionId: targetId,
        amount: percent,
        wasAiInitiator: isAiControlledForEvidence(game, gpId),
        eventTally: eventTally,
        logMessage:
            'diplomacy SetSubsidy $gpId -> $targetId percent $percent%',
      );
    }
  }
  return game;
}
