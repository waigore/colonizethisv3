// Dossier projection: PlayerView-safe read API. SPEC/ai/ai-dossier.md.

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

/// Suspicion band for display. Never exposes true agenda.
enum SuspicionBand {
  unknown,   // 0–2
  possible, // 3–5
  likely,   // 6–8
  almostCertain, // 9–10
  confirmed, // 10+
}

/// Relative strength for basic intel (observer vs subject).
enum RelativeStrength {
  weaker,
  even,
  stronger,
}

/// Basic intel section: personality/archetype, relation, relative strength. PlayerView-safe.
class DossierBasicIntel {
  const DossierBasicIntel({
    this.relationLevel,
    this.relationState,
    this.relativeMilitaryStrength,
    this.relativeEconomicStrength,
    this.personalityArchetype,
  });

  final RelationLevel? relationLevel;
  final RelationState? relationState;
  final RelativeStrength? relativeMilitaryStrength;
  final RelativeStrength? relativeEconomicStrength;
  /// Human-readable archetype (e.g. "Fortifier"). From config; never exposes true agenda.
  final String? personalityArchetype;
}

/// Best-guess hidden agenda from suspicion bands. Never exposes true agenda. SPEC/ai/ai-dossier.md.
class DossierBestGuessAgenda {
  const DossierBestGuessAgenda({
    required this.agendaType,
    required this.confidencePercent,
  });

  final String agendaType;
  final int confidencePercent;
}

/// PlayerView-safe dossier view for one subject. No hidden agenda exposed.
class DossierView {
  const DossierView({
    required this.subjectId,
    required this.suspicionByAgendaType,
    required this.evidenceList,
    this.basicIntel,
    this.bestGuessAgenda,
    this.behavioralNotes = const [],
    this.timeline = const [],
  });

  final String subjectId;
  final Map<String, SuspicionBand> suspicionByAgendaType;
  final List<String> evidenceList;
  final DossierBasicIntel? basicIntel;
  final DossierBestGuessAgenda? bestGuessAgenda;
  final List<String> behavioralNotes;
  final List<String> timeline;
}

/// Returns suspicion band for a raw score (0–2 unknown, 3–5 possible, etc.).
SuspicionBand suspicionBandFromScore(int score) {
  if (score <= 2) return SuspicionBand.unknown;
  if (score <= 5) return SuspicionBand.possible;
  if (score <= 8) return SuspicionBand.likely;
  if (score <= 10) return SuspicionBand.almostCertain;
  return SuspicionBand.confirmed;
}

/// Confidence % for display from raw suspicion score. SPEC/ai/ai-dossier.md bands.
int confidencePercentFromScore(int score) {
  if (score <= 2) return 0;
  if (score <= 5) return 25;
  if (score <= 8) return 60;
  if (score <= 10) return 85;
  return 100;
}

Player? _player(Game game, String playerId) {
  for (final p in game.players) {
    if (p.id == playerId) return p;
  }
  return null;
}

RelativeStrength _relativeStrength(int observerValue, int subjectValue) {
  if (subjectValue < observerValue) return RelativeStrength.weaker;
  if (subjectValue > observerValue) return RelativeStrength.stronger;
  return RelativeStrength.even;
}

/// Builds basic intel from game state (relation, relative strength, personality archetype).
DossierBasicIntel? _buildBasicIntel(Game game, String observerId, String subjectId) {
  final rel = getRelation(game, observerId, subjectId);
  final obs = _player(game, observerId);
  final subj = _player(game, subjectId);
  if (obs == null || subj == null) {
    final archetype = getArchetypeDisplayNameForLeader(subjectId) ??
        (subj?.leaderKey != null ? getArchetypeDisplayNameForLeader(subj!.leaderKey!) : null);
    return DossierBasicIntel(
      relationLevel: rel?.level,
      relationState: rel?.state,
      personalityArchetype: archetype,
    );
  }
  final militaryObs = obs.militaryLevel ?? 0;
  final militarySubj = subj.militaryLevel ?? 0;
  final economicObs = obs.treasury;
  final economicSubj = subj.treasury;
  final archetype = getArchetypeDisplayNameForLeader(subjectId) ??
      getArchetypeDisplayNameForLeader(subj.leaderKey ?? '');
  return DossierBasicIntel(
    relationLevel: rel?.level,
    relationState: rel?.state,
    relativeMilitaryStrength: _relativeStrength(militaryObs, militarySubj),
    relativeEconomicStrength: _relativeStrength(economicObs, economicSubj),
    personalityArchetype: archetype,
  );
}

/// Builds best-guess agenda and confidence from suspicion scores. Highest score wins.
DossierBestGuessAgenda? _buildBestGuessAgenda(Map<String, int> scoreByAgenda) {
  if (scoreByAgenda.isEmpty) return null;
  var bestType = '';
  var bestScore = -1;
  for (final e in scoreByAgenda.entries) {
    if (e.value > bestScore) {
      bestScore = e.value;
      bestType = e.key;
    }
  }
  if (bestType.isEmpty) return null;
  return DossierBestGuessAgenda(
    agendaType: bestType,
    confidencePercent: confidencePercentFromScore(bestScore),
  );
}

/// Builds short behavioral notes from evidence (war history, peace offers, etc.).
List<String> _buildBehavioralNotes(List<DossierEvidenceEntry> entries) {
  final byDesc = <String, int>{};
  for (final e in entries) {
    final key = e.description;
    byDesc[key] = (byDesc[key] ?? 0) + 1;
  }
  final notes = <String>[];
  if ((byDesc['declared war on weaker neighbor'] ?? 0) + (byDesc['declared war on ally'] ?? 0) > 0) {
    final n = (byDesc['declared war on weaker neighbor'] ?? 0) + (byDesc['declared war on ally'] ?? 0);
    notes.add('Declared war ($n).');
  }
  if ((byDesc['offered peace'] ?? 0) > 0) {
    notes.add('Offered peace (${byDesc['offered peace']}).');
  }
  return notes;
}

/// Dossier projection: given [observerId] and [subjectId], returns PlayerView-safe dossier.
/// Never includes true hidden agenda from game state.
DossierView getDossierForSubject(
  Game game,
  String observerId,
  String subjectId,
) {
  final entries = game.dossierEvidenceEntries
      .where((e) => e.observerId == observerId && e.subjectId == subjectId)
      .toList();
  entries.sort((a, b) => a.turnNumber.compareTo(b.turnNumber));
  final cappedEntries = entries.length > kMaxDossierEvidenceEntries
      ? entries.sublist(entries.length - kMaxDossierEvidenceEntries)
      : entries;
  final scoreByAgenda = <String, int>{};
  for (final e in cappedEntries) {
    scoreByAgenda[e.agendaType] = (scoreByAgenda[e.agendaType] ?? 0) + e.scoreDelta;
  }
  final suspicionByAgendaType = <String, SuspicionBand>{};
  for (final e in scoreByAgenda.entries) {
    suspicionByAgendaType[e.key] = suspicionBandFromScore(e.value);
  }
  final evidenceList = cappedEntries
      .map((e) => 'Turn ${e.turnNumber}: ${e.description}')
      .toList();
  final timeline = cappedEntries
      .map((e) => 'Turn ${e.turnNumber}: ${e.description}')
      .toList();
  return DossierView(
    subjectId: subjectId,
    suspicionByAgendaType: suspicionByAgendaType,
    evidenceList: evidenceList,
    basicIntel: _buildBasicIntel(game, observerId, subjectId),
    bestGuessAgenda: _buildBestGuessAgenda(scoreByAgenda),
    behavioralNotes: _buildBehavioralNotes(cappedEntries),
    timeline: timeline,
  );
}
