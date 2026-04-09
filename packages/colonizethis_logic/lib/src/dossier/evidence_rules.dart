// Evidence rules for dossier. SPEC/ai/hidden-agendas.md, SPEC/program/ai-events-and-dossier.md.
// When diplomatic (or other) actions are applied, evidence rules add suspicion points per agenda type.
// Evidence is stored per (observer, subject, agenda type); only human observers receive entries.

import 'package:colonizethis_logic/package_logger.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../constants.dart';
import '../diplomacy/diplomacy_relation_lookup.dart';

final _log = packageLogger();

/// Human Great Power ids (observers for whom we store evidence).
List<String> _humanObserverIds(Game game) {
  return game.players.where((p) => p.isHuman).map((p) => p.id).toList();
}

/// True if [playerId] is AI-controlled (evidence/dialogue only for AI subjects).
/// Named to avoid export clash with ai_planner.isAiControlled.
bool isAiControlledForEvidence(Game game, String playerId) {
  final explicit = game.aiControlByGpId[playerId];
  if (explicit != null) return explicit;
  final p = game.playerById(playerId);
  return p != null && !p.isHuman;
}

/// Returns true if [targetId] is a weaker GP than [actorId] by military level (for warmonger evidence).
bool _isWeakerGp(Game game, String actorId, String targetId) {
  final actor = game.playerById(actorId);
  final target = game.playerById(targetId);
  if (actor == null || target == null) return false;
  final aLevel = actor.militaryLevel ?? 0;
  final tLevel = target.militaryLevel ?? 0;
  return tLevel < aLevel;
}

/// Evidence entries for "AI declared war". Warmonger if target is weaker GP; backstabber if was allied.
List<DossierEvidenceEntry> evidenceForDeclareWar(
  Game game,
  String actorGpId,
  String targetFactionId,
  int turnNumber,
) {
  if (!isAiControlledForEvidence(game, actorGpId)) return [];
  final observers = _humanObserverIds(game);
  if (observers.isEmpty) return [];

  final rel = getRelation(game, actorGpId, targetFactionId);
  final wasAllied = rel != null && rel.level == RelationLevel.allied;
  final targetIsGp = game.playerById(targetFactionId) != null;
  final weaker = targetIsGp && _isWeakerGp(game, actorGpId, targetFactionId);

  final entries = <DossierEvidenceEntry>[];
  for (final observerId in observers) {
    if (wasAllied) {
      entries.add(
        DossierEvidenceEntry(
          observerId: observerId,
          subjectId: actorGpId,
          agendaType: 'backstabber',
          turnNumber: turnNumber,
          description: 'declared war on ally',
          scoreDelta: 3,
        ),
      );
    }
    if (weaker) {
      entries.add(
        DossierEvidenceEntry(
          observerId: observerId,
          subjectId: actorGpId,
          agendaType: 'warmonger',
          turnNumber: turnNumber,
          description: 'declared war on weaker neighbor',
          scoreDelta: 2,
        ),
      );
    }
  }
  if (entries.isNotEmpty) {
    _log.d(
      'evidence for declareWar actor=$actorGpId target=$targetFactionId entries=${entries.length}',
    );
  }
  return entries;
}

/// Evidence entries for "AI offered peace". Peacemaker tendency.
List<DossierEvidenceEntry> evidenceForOfferPeace(
  Game game,
  String actorGpId,
  String targetFactionId,
  int turnNumber,
) {
  if (!isAiControlledForEvidence(game, actorGpId)) return [];
  final observers = _humanObserverIds(game);
  if (observers.isEmpty) return [];

  final entries = <DossierEvidenceEntry>[];
  for (final observerId in observers) {
    entries.add(
      DossierEvidenceEntry(
        observerId: observerId,
        subjectId: actorGpId,
        agendaType: 'peacemaker',
        turnNumber: turnNumber,
        description: 'offered peace',
        scoreDelta: 1,
      ),
    );
  }
  _log.d(
    'evidence for offerPeace actor=$actorGpId target=$targetFactionId entries=${entries.length}',
  );
  return entries;
}

/// Evidence entries for "AI won land battle as attacker". Warmonger; +2 if defender was weaker GP.
/// SPEC/ai/hidden-agendas.md: observable actions add suspicion (e.g. attacks weaker neighbors).
List<DossierEvidenceEntry> evidenceForLandBattleVictory(
  Game game,
  String victorGpId,
  String defenderFactionId,
  int turnNumber,
) {
  if (!isAiControlledForEvidence(game, victorGpId)) return [];
  final observers = _humanObserverIds(game);
  if (observers.isEmpty) return [];

  final targetIsGp = game.playerById(defenderFactionId) != null;
  final weaker = targetIsGp && _isWeakerGp(game, victorGpId, defenderFactionId);
  final scoreDelta = weaker ? 2 : 1;

  final entries = <DossierEvidenceEntry>[];
  for (final observerId in observers) {
    entries.add(
      DossierEvidenceEntry(
        observerId: observerId,
        subjectId: victorGpId,
        agendaType: 'warmonger',
        turnNumber: turnNumber,
        description: weaker
            ? 'won battle vs weaker neighbor'
            : 'won battle as attacker',
        scoreDelta: scoreDelta,
      ),
    );
  }
  if (entries.isNotEmpty) {
    _log.d(
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
  if (!isAiControlledForEvidence(game, victorOwnerId)) return [];
  final observers = _humanObserverIds(game);
  if (observers.isEmpty) return [];

  final entries = <DossierEvidenceEntry>[];
  for (final observerId in observers) {
    entries.add(
      DossierEvidenceEntry(
        observerId: observerId,
        subjectId: victorOwnerId,
        agendaType: 'warmonger',
        turnNumber: turnNumber,
        description: 'won naval battle',
        scoreDelta: 1,
      ),
    );
  }
  if (entries.isNotEmpty) {
    _log.d(
      'evidence for naval battle victory victor=$victorOwnerId loser=$loserOwnerId entries=${entries.length}',
    );
  }
  return entries;
}

/// Isolationist agenda: AI declines call to arms while still at peace with defender.
/// SPEC/ai/hidden-agendas.md.
List<DossierEvidenceEntry> evidenceForIsolationistCallToArmsRefuse(
  Game game,
  String allyGpId,
  String defenderGpId,
  int turnNumber,
) {
  if (!isAiControlledForEvidence(game, allyGpId)) {
    return [];
  }
  final observers = _humanObserverIds(game);
  if (observers.isEmpty) {
    return [];
  }
  final rel = getRelation(game, allyGpId, defenderGpId);
  if (rel == null || !rel.atPeace) {
    return [];
  }

  final entries = <DossierEvidenceEntry>[];
  for (final observerId in observers) {
    entries.add(
      DossierEvidenceEntry(
        observerId: observerId,
        subjectId: allyGpId,
        agendaType: 'isolationist',
        turnNumber: turnNumber,
        description: 'declined call to arms while at peace',
        scoreDelta: 2,
      ),
    );
  }
  return entries;
}

/// Tech Thief agenda: resolved steal_tech spy work against another Great Power.
/// SPEC/ai/hidden-agendas.md.
List<DossierEvidenceEntry> evidenceForAiStealTechResolved(
  Game game,
  String aiSpyOwnerGpId,
  int turnNumber, {
  required bool success,
}) {
  if (!isAiControlledForEvidence(game, aiSpyOwnerGpId)) {
    return [];
  }
  final observers = _humanObserverIds(game);
  if (observers.isEmpty) {
    return [];
  }
  final scoreDelta = success ? 3 : 1;
  final entries = <DossierEvidenceEntry>[];
  for (final observerId in observers) {
    entries.add(
      DossierEvidenceEntry(
        observerId: observerId,
        subjectId: aiSpyOwnerGpId,
        agendaType: 'tech_thief',
        turnNumber: turnNumber,
        description: success
            ? 'spy steal tech succeeded'
            : 'spy steal tech attempt',
        scoreDelta: scoreDelta,
      ),
    );
  }
  return entries;
}
