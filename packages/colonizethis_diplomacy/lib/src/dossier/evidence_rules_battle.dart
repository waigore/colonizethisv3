// Battle evidence application rules for dossier suspicion scoring.
// SPEC/ai/hidden-agendas.md, SPEC/program/ai-events-and-dossier.md.

import 'package:colonizethis_models/colonizethis_models.dart';

import 'package:colonizethis_world/colonizethis_world.dart';
import '../diplomacy/diplomacy_logging.dart';
import 'evidence_rules_predicates.dart';

/// Evidence entries for "AI won land battle as attacker". Warmonger; +2 if defender was weaker GP.
List<DossierEvidenceEntry> evidenceForLandBattleVictory(
  Game game,
  String victorGpId,
  String defenderFactionId,
  int turnNumber,
) {
  final observers = evidenceObservers(game, victorGpId);
  if (observers == null) return [];
  final weaker =
      game.playerById(defenderFactionId) != null &&
      isWeakerGpForEvidence(game, victorGpId, defenderFactionId);
  final entries = evidenceEntriesForObservers(
    observers,
    subjectId: victorGpId,
    agendaType: 'warmonger',
    turnNumber: turnNumber,
    description: weaker
        ? 'won battle vs weaker neighbor'
        : 'won battle as attacker',
    scoreDelta: weaker ? 2 : 1,
  );
  if (entries.isNotEmpty) {
    diploLog.d(
      'evidence for land battle victory victor=$victorGpId defender=$defenderFactionId entries=${entries.length}',
    );
  }
  return entries;
}

/// Evidence entries for "AI won naval battle" (one side eliminated). Warmonger tendency.
List<DossierEvidenceEntry> evidenceForNavalBattleVictory(
  Game game,
  String victorOwnerId,
  String loserOwnerId,
  int turnNumber,
) {
  final observers = evidenceObservers(game, victorOwnerId);
  if (observers == null) return [];
  final entries = evidenceEntriesForObservers(
    observers,
    subjectId: victorOwnerId,
    agendaType: 'warmonger',
    turnNumber: turnNumber,
    description: 'won naval battle',
    scoreDelta: 1,
  );
  if (entries.isNotEmpty) {
    diploLog.d(
      'evidence for naval battle victory victor=$victorOwnerId loser=$loserOwnerId entries=${entries.length}',
    );
  }
  return entries;
}
