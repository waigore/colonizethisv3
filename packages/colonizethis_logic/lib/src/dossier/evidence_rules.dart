// Evidence rules for dossier. SPEC/ai/hidden-agendas.md, SPEC/program/ai-events-and-dossier.md.
// When diplomatic (or other) actions are applied, evidence rules add suspicion points per agenda type.
// Evidence is stored per (observer, subject, agenda type); only human observers receive entries.

import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:logger/logger.dart';

final _log = Logger();

/// Human Great Power ids (observers for whom we store evidence).
List<String> _humanObserverIds(Game game) {
  return game.players
      .where((p) => p.isHuman)
      .map((p) => p.id)
      .toList();
}

/// True if [playerId] is AI-controlled (evidence/dialogue only for AI subjects).
/// Named to avoid export clash with ai_planner.isAiControlled.
bool isAiControlledForEvidence(Game game, String playerId) {
  final explicit = game.aiControlByGpId[playerId];
  if (explicit != null) return explicit;
  final p = _getPlayer(game, playerId);
  return p != null && !p.isHuman;
}

Player? _getPlayer(Game game, String playerId) {
  for (final p in game.players) {
    if (p.id == playerId) return p;
  }
  return null;
}

/// Returns true if [targetId] is a weaker GP than [actorId] by military level (for warmonger evidence).
bool _isWeakerGp(Game game, String actorId, String targetId) {
  final actor = _getPlayer(game, actorId);
  final target = _getPlayer(game, targetId);
  if (actor == null || target == null) return false;
  final aLevel = actor.militaryLevel ?? 0;
  final tLevel = target.militaryLevel ?? 0;
  return tLevel < aLevel;
}

DiplomacyRelation? _getRelation(Game game, String factionId1, String factionId2) {
  final key = factionId1.compareTo(factionId2) <= 0 ? '$factionId1|$factionId2' : '$factionId2|$factionId1';
  for (final r in game.diplomacyRelations) {
    final rKey = r.factionId1.compareTo(r.factionId2) <= 0 ? '${r.factionId1}|${r.factionId2}' : '${r.factionId2}|${r.factionId1}';
    if (rKey == key) return r;
  }
  return null;
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

  final rel = _getRelation(game, actorGpId, targetFactionId);
  final wasAllied = rel != null && rel.level == RelationLevel.allied;
  final targetIsGp = _getPlayer(game, targetFactionId) != null;
  final weaker = targetIsGp && _isWeakerGp(game, actorGpId, targetFactionId);

  final entries = <DossierEvidenceEntry>[];
  for (final observerId in observers) {
    if (wasAllied) {
      entries.add(DossierEvidenceEntry(
        observerId: observerId,
        subjectId: actorGpId,
        agendaType: 'backstabber',
        turnNumber: turnNumber,
        description: 'declared war on ally',
        scoreDelta: 2,
      ));
    }
    if (weaker) {
      entries.add(DossierEvidenceEntry(
        observerId: observerId,
        subjectId: actorGpId,
        agendaType: 'warmonger',
        turnNumber: turnNumber,
        description: 'declared war on weaker neighbor',
        scoreDelta: 2,
      ));
    }
  }
  if (entries.isNotEmpty) {
    _log.d('data: evidence for declareWar actor=$actorGpId target=$targetFactionId entries=${entries.length}');
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
    entries.add(DossierEvidenceEntry(
      observerId: observerId,
      subjectId: actorGpId,
      agendaType: 'peacemaker',
      turnNumber: turnNumber,
      description: 'offered peace',
      scoreDelta: 1,
    ));
  }
  _log.d('data: evidence for offerPeace actor=$actorGpId target=$targetFactionId entries=${entries.length}');
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

  final targetIsGp = _getPlayer(game, defenderFactionId) != null;
  final weaker = targetIsGp && _isWeakerGp(game, victorGpId, defenderFactionId);
  final scoreDelta = weaker ? 2 : 1;

  final entries = <DossierEvidenceEntry>[];
  for (final observerId in observers) {
    entries.add(DossierEvidenceEntry(
      observerId: observerId,
      subjectId: victorGpId,
      agendaType: 'warmonger',
      turnNumber: turnNumber,
      description: weaker ? 'won battle vs weaker neighbor' : 'won battle as attacker',
      scoreDelta: scoreDelta,
    ));
  }
  if (entries.isNotEmpty) {
    _log.d('data: evidence for land battle victory victor=$victorGpId defender=$defenderFactionId entries=${entries.length}');
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
    entries.add(DossierEvidenceEntry(
      observerId: observerId,
      subjectId: victorOwnerId,
      agendaType: 'warmonger',
      turnNumber: turnNumber,
      description: 'won naval battle',
      scoreDelta: 1,
    ));
  }
  if (entries.isNotEmpty) {
    _log.d('data: evidence for naval battle victory victor=$victorOwnerId loser=$loserOwnerId entries=${entries.length}');
  }
  return entries;
}
