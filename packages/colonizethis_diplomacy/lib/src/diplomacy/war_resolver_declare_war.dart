import 'package:colonizethis_models/colonizethis_models.dart';

import '../dossier/evidence_rules.dart' show evidenceForDeclareWar;
import 'diplomacy_relation_lookup.dart';
import 'diplomacy_relation_updates.dart';
import 'diplomacy_shared_helpers.dart';
import 'diplomacy_event_logging.dart';
import 'intervention_resolver.dart';

/// Applies a single declare-war order during the war/peace phase (Refs #4130).
Game applyDeclareWarOrder({
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
    diplomacyRelations: committedRelations(relationsIndex),
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
