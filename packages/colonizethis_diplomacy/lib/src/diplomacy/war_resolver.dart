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
  var relations = List<DiplomacyRelation>.from(game.diplomacyRelations);
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
    final updated = _applyWarPhaseOrder(
      game: game,
      relations: relations,
      gpId: item.gpId,
      order: item.order,
      turn: turn,
      peaceOffersByPairKey: peaceOffersByPairKey,
      factionMembership: factionMembership,
      onDialogue: onDialogue,
      eventTally: eventTally,
    );
    game = updated.game;
    relations = updated.relations;
  }
  for (final item in peaceOrders) {
    final updated = _applyWarPhaseOrder(
      game: game,
      relations: relations,
      gpId: item.gpId,
      order: item.order,
      turn: turn,
      peaceOffersByPairKey: peaceOffersByPairKey,
      factionMembership: factionMembership,
      onDialogue: onDialogue,
      eventTally: eventTally,
    );
    game = updated.game;
    relations = updated.relations;
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

({Game game, List<DiplomacyRelation> relations}) _applyWarPhaseOrder({
  required Game game,
  required List<DiplomacyRelation> relations,
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
      relations: relations,
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
      relations: relations,
      gpId: gpId,
      order: order,
      turn: turn,
      peaceOffersByPairKey: peaceOffersByPairKey,
      factionMembership: factionMembership,
      onDialogue: onDialogue,
      eventTally: eventTally,
    );
  }
  return (game: game, relations: relations);
}

({Game game, List<DiplomacyRelation> relations}) _applyDeclareWarOrder({
  required Game game,
  required List<DiplomacyRelation> relations,
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
    return (game: game, relations: relations);
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
  var nextRelations = setWarStateForPair(
    relations: relations,
    gpId: gpId,
    targetId: targetId,
    turn: turn,
  );
  var nextGame = game.copyWith(
    diplomacyRelations: nextRelations,
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
  return (game: nextGame, relations: nextRelations);
}

({Game game, List<DiplomacyRelation> relations}) _applyOfferPeaceOrder({
  required Game game,
  required List<DiplomacyRelation> relations,
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
    return (game: game, relations: relations);
  }
  var bothSidesAgreed = true;
  if (factionMembership.isGreatPower(targetId) &&
      factionMembership.isGreatPower(gpId)) {
    bothSidesAgreed =
        (offerers.contains(gpId) && offerers.contains(targetId)) ||
        oneSidedGpPeace;
  }
  if (!bothSidesAgreed) {
    return (game: game, relations: relations);
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
    return (
      game: game.copyWith(
        dossierEvidenceEntries: [...game.dossierEvidenceEntries, ...evidence],
      ),
      relations: relations,
    );
  }
  var nextRelations = applyPeaceForPair(
    relations: relations,
    gpId: gpId,
    targetId: targetId,
    turn: turn,
  );
  var nextGame = game.copyWith(
    diplomacyRelations: nextRelations,
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
  return (game: nextGame, relations: nextRelations);
}
