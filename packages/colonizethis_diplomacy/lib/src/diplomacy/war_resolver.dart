import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../dossier/evidence_rules.dart'
    show evidenceForDeclareWar, evidenceForOfferPeace;
import 'diplomacy_relation_updates.dart';
import 'diplomacy_resolver.dart';
import 'diplomacy_shared_helpers.dart';
import 'intervention_resolver.dart';
import 'diplomacy_event_logging.dart';

Game processWarAndPeace(
  Game game,
  Map<String, List<DiplomaticOrder>> diploByPlayer,
  int turn, {
  required DiplomacyFactionMembership factionMembership,
  void Function(DialogueEvent)? onDialogue,
  IntraTurnEventTally? eventTally,
}) {
  final peaceOffersByPairKey = _peaceOfferPairKeysForGreatPowers(
    game,
    diploByPlayer,
    factionMembership,
  );
  return _runWarAndPeaceOrders(
    game,
    diploByPlayer,
    turn,
    peaceOffersByPairKey,
    factionMembership,
    onDialogue,
    eventTally,
  );
}

Game _runWarAndPeaceOrders(
  Game game,
  Map<String, List<DiplomaticOrder>> diploByPlayer,
  int turn,
  Map<String, Set<String>> peaceOffersByPairKey,
  DiplomacyFactionMembership factionMembership,
  void Function(DialogueEvent)? onDialogue,
  IntraTurnEventTally? eventTally,
) {
  // Single per-phase relation index so each declare-war / offer-peace upsert is
  // amortized O(1) instead of rebuilding the pair-key index per order (Refs #3837).
  final relationsIndex = RelationUpsertIndex(game.diplomacyRelations);
  final warOrders = <({String gpId, DiplomaticOrder order})>[];
  final peaceOrders = <({String gpId, DiplomaticOrder order})>[];
  for (final entry in diploByPlayer.entries) {
    final gpId = entry.key;
    for (final order in entry.value) {
      if (order.type == DiplomaticOrderType.offerPeace) {
        peaceOrders.add((gpId: gpId, order: order));
      } else {
        warOrders.add((gpId: gpId, order: order));
      }
    }
  }
  for (final item in warOrders) {
    game = _applyWarPhaseOrder(
      game: game,
      relationsIndex: relationsIndex,
      gpId: item.gpId,
      order: item.order,
      turn: turn,
      peaceOffersByPairKey: peaceOffersByPairKey,
      factionMembership: factionMembership,
      onDialogue: onDialogue,
      eventTally: eventTally,
    );
  }
  for (final item in peaceOrders) {
    game = _applyWarPhaseOrder(
      game: game,
      relationsIndex: relationsIndex,
      gpId: item.gpId,
      order: item.order,
      turn: turn,
      peaceOffersByPairKey: peaceOffersByPairKey,
      factionMembership: factionMembership,
      onDialogue: onDialogue,
      eventTally: eventTally,
    );
  }
  return game;
}

/// GP–GP peace offers by unordered pair (both sides must offer in same phase).
Map<String, Set<String>> _peaceOfferPairKeysForGreatPowers(
  Game game,
  Map<String, List<DiplomaticOrder>> diploByPlayer,
  DiplomacyFactionMembership factionMembership,
) {
  final peaceOffersByPairKey = <String, Set<String>>{};
  for (final entry in diploByPlayer.entries) {
    final gpId = entry.key;
    for (final order in entry.value) {
      if (order.type != DiplomaticOrderType.offerPeace) continue;
      final targetId = order.targetFactionId;
      if (!factionMembership.isGreatPower(gpId) ||
          !factionMembership.isGreatPower(targetId)) {
        continue;
      }
      final key = pairKey(gpId, targetId);
      peaceOffersByPairKey.putIfAbsent(key, () => <String>{}).add(gpId);
    }
  }
  return peaceOffersByPairKey;
}

Game _applyWarPhaseOrder({
  required Game game,
  required RelationUpsertIndex relationsIndex,
  required String gpId,
  required DiplomaticOrder order,
  required int turn,
  required Map<String, Set<String>> peaceOffersByPairKey,
  required DiplomacyFactionMembership factionMembership,
  void Function(DialogueEvent)? onDialogue,
  IntraTurnEventTally? eventTally,
}) {
  if (order.type == DiplomaticOrderType.declareWar) {
    return _applyDeclareWarOrder(
      game: game,
      relationsIndex: relationsIndex,
      gpId: gpId,
      order: order,
      turn: turn,
      onDialogue: onDialogue,
      eventTally: eventTally,
    );
  }
  if (order.type == DiplomaticOrderType.offerPeace) {
    return _applyOfferPeaceOrder(
      game: game,
      relationsIndex: relationsIndex,
      gpId: gpId,
      order: order,
      turn: turn,
      peaceOffersByPairKey: peaceOffersByPairKey,
      factionMembership: factionMembership,
      onDialogue: onDialogue,
      eventTally: eventTally,
    );
  }
  return game;
}

Game _applyDeclareWarOrder({
  required Game game,
  required RelationUpsertIndex relationsIndex,
  required String gpId,
  required DiplomaticOrder order,
  required int turn,
  void Function(DialogueEvent)? onDialogue,
  IntraTurnEventTally? eventTally,
}) {
  final targetId = order.targetFactionId;
  final rel = getRelation(game, gpId, targetId);
  final atPeace = rel == null || rel.atPeace;
  if (!atPeace) {
    return game;
  }
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
  relationsIndex.upsert(
    gpId,
    targetId,
    warStateRelationUpdater(gpId, targetId, turn),
  );
  var nextGame = game.copyWith(
    diplomacyRelations: relationsIndex.toList(),
    dossierEvidenceEntries: [...game.dossierEvidenceEntries, ...evidence],
  );
  nextGame = cancelSubsidiesBetweenGps(
    nextGame,
    gpId,
    targetId,
    turn,
    eventTally: eventTally,
  );
  nextGame = logDiplomaticEvent(
    nextGame,
    turn,
    DiplomaticEventType.declareWar,
    {gpId, targetId},
    fromFactionId: gpId,
    toFactionId: targetId,
    wasAiInitiator: isAiControlledForEvidence(nextGame, gpId),
    eventTally: eventTally,
    logMessage:
        'diplomacy war declared $gpId vs $targetId (scores reset to 20)',
  );
  return nextGame;
}

Game _applyOfferPeaceOrder({
  required Game game,
  required RelationUpsertIndex relationsIndex,
  required String gpId,
  required DiplomaticOrder order,
  required int turn,
  required Map<String, Set<String>> peaceOffersByPairKey,
  required DiplomacyFactionMembership factionMembership,
  void Function(DialogueEvent)? onDialogue,
  IntraTurnEventTally? eventTally,
}) {
  final targetId = order.targetFactionId;
  final rel = getRelation(game, gpId, targetId);
  final key = pairKey(gpId, targetId);
  final bothGreatPowers =
      factionMembership.isGreatPower(gpId) &&
      factionMembership.isGreatPower(targetId);
  final offerers = peaceOffersByPairKey[key] ?? const <String>{};
  final collapsedSurvivalPeace = bothGreatPowers &&
      offerers.length == 1 &&
      offerers.any(
        (id) =>
            oldWorldProvinceCountOwnedBy(game, id) <=
            kStalledOldWorldProvinceThreshold,
      );
  final belowQuotaOutmatchedGpPeace = bothGreatPowers &&
      offerers.length == 1 &&
      offerers.any((id) {
        final own = oldWorldProvinceCountOwnedBy(game, id);
        final enemyOw = oldWorldProvinceCountOwnedBy(game, targetId);
        final minLead = own <= kStalledOldWorldProvinceThreshold
            ? 1
            : kUnwinnableSoleGpMinProvinceDeficit;
        return isBelowObserverConquestQuota(own) &&
            enemyOw >= own + minLead;
      });
  final multiFrontConsolidationPeace = bothGreatPowers &&
      offerers.length == 1 &&
      offerers.any(
        (id) => atWarGreatPowerCount(game, id, factionMembership) >= 2,
      );
  final soleGpWarConsolidationPeace = bothGreatPowers &&
      offerers.length == 1 &&
      offerers.any(
        (id) => atWarGreatPowerCount(game, id, factionMembership) == 1,
      );
  final oneSidedGpPeace = collapsedSurvivalPeace ||
      belowQuotaOutmatchedGpPeace ||
      multiFrontConsolidationPeace ||
      soleGpWarConsolidationPeace;
  final hasMutualOffer =
      !bothGreatPowers || offerers.length >= 2 || oneSidedGpPeace;
  if (rel == null || !rel.atWar) {
    return game;
  }
  var bothSidesAgreed = true;
  if (factionMembership.isGreatPower(targetId) &&
      factionMembership.isGreatPower(gpId)) {
    bothSidesAgreed =
        (offerers.contains(gpId) && offerers.contains(targetId)) ||
        oneSidedGpPeace;
  }
  if (!bothSidesAgreed) {
    return game;
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
  if (!hasMutualOffer) {
    return game.copyWith(
      dossierEvidenceEntries: [...game.dossierEvidenceEntries, ...evidence],
    );
  }
  relationsIndex.upsert(
    gpId,
    targetId,
    peaceRelationUpdater(gpId, targetId, turn),
  );
  var nextGame = game.copyWith(
    diplomacyRelations: relationsIndex.toList(),
    dossierEvidenceEntries: [...game.dossierEvidenceEntries, ...evidence],
  );
  nextGame = logDiplomaticEvent(
    nextGame,
    turn,
    DiplomaticEventType.peace,
    {gpId, targetId},
    fromFactionId: gpId,
    toFactionId: targetId,
    wasAiInitiator: isAiControlledForEvidence(nextGame, gpId),
    eventTally: eventTally,
    logMessage: 'diplomacy peace $gpId-$targetId',
  );
  return nextGame;
}
