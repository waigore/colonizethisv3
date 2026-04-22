import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../ai/ai_control.dart';
import '../dossier/evidence_rules.dart';
import 'diplomacy_relation_lookup.dart';
import 'diplomacy_relation_updates.dart';
import 'diplomacy_resolver.dart';
import 'intervention_resolver.dart';
import 'overture_resolver.dart';

Game processWarAndPeace(
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
          game = cancelSubsidiesBetweenGps(game, gpId, targetId, turn);
          game = appendDiplomaticEvent(
            game,
            turn,
            DiplomaticEventType.declareWar,
            {gpId, targetId},
            fromFactionId: gpId,
            toFactionId: targetId,
            wasAiInitiator: isAiControlledForEvidence(game, gpId),
          );
          diploLog.i(
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
            game = appendDiplomaticEvent(
              game,
              turn,
              DiplomaticEventType.peace,
              {gpId, targetId},
              fromFactionId: gpId,
              toFactionId: targetId,
              wasAiInitiator: isAiControlledForEvidence(game, gpId),
            );
            diploLog.i('diplomacy peace $gpId-$targetId');
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
