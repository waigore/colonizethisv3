import 'package:colonizethis_ai/package_logger.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/ai_api.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'dossier_models.dart';

final _log = packageLogger();

/// Returns suspicion band for a raw score.
SuspicionBand suspicionBandFromScore(int score) {
  if (score <= dossierScoreUnknownMax) return SuspicionBand.unknown;
  if (score <= dossierScorePossibleMax) return SuspicionBand.possible;
  if (score <= dossierScoreLikelyMax) return SuspicionBand.likely;
  if (score <= dossierScoreAlmostCertainMax) return SuspicionBand.almostCertain;
  return SuspicionBand.confirmed;
}

/// Confidence % for display from raw suspicion score.
int confidencePercentFromScore(int score) {
  if (score <= dossierScoreUnknownMax) return dossierConfidenceUnknown;
  if (score <= dossierScorePossibleMax) return dossierConfidencePossible;
  if (score <= dossierScoreLikelyMax) return dossierConfidenceLikely;
  if (score <= dossierScoreAlmostCertainMax)
    return dossierConfidenceAlmostCertain;
  return dossierConfidenceConfirmed;
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

DossierBasicIntel? _buildBasicIntel(
  Game game,
  String observerId,
  String subjectId,
) {
  final rel = getRelation(game, observerId, subjectId);
  final obs = _player(game, observerId);
  final subj = _player(game, subjectId);
  if (obs == null || subj == null) {
    final archetype =
        getArchetypeDisplayNameForLeader(subjectId) ??
        (subj?.leaderKey != null
            ? getArchetypeDisplayNameForLeader(subj!.leaderKey!)
            : null);
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
  final archetype =
      getArchetypeDisplayNameForLeader(subjectId) ??
      getArchetypeDisplayNameForLeader(subj.leaderKey ?? '');
  return DossierBasicIntel(
    relationLevel: rel?.level,
    relationState: rel?.state,
    relativeMilitaryStrength: _relativeStrength(militaryObs, militarySubj),
    relativeEconomicStrength: _relativeStrength(economicObs, economicSubj),
    personalityArchetype: archetype,
  );
}

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

List<String> _buildBehavioralNotes(List<DossierEvidenceEntry> entries) {
  final byDesc = <String, int>{};
  for (final e in entries) {
    final key = e.description;
    byDesc[key] = (byDesc[key] ?? 0) + 1;
  }
  final notes = <String>[];
  if ((byDesc['declared war on weaker neighbor'] ?? 0) +
          (byDesc['declared war on ally'] ?? 0) >
      0) {
    final n =
        (byDesc['declared war on weaker neighbor'] ?? 0) +
        (byDesc['declared war on ally'] ?? 0);
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
    scoreByAgenda[e.agendaType] =
        (scoreByAgenda[e.agendaType] ?? 0) + e.scoreDelta;
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
  final basicIntel = _buildBasicIntel(game, observerId, subjectId);
  final bestGuess = _buildBestGuessAgenda(scoreByAgenda);
  final behavioralNotes = _buildBehavioralNotes(cappedEntries);

  _log.d(
    'getDossierForSubject observerId=$observerId subjectId=$subjectId '
    'scoreByAgenda=$scoreByAgenda suspicionByAgendaType=${suspicionByAgendaType.map((k, v) => MapEntry(k, v.name))} '
    'bestGuessAgenda=${bestGuess?.agendaType} confidencePercent=${bestGuess?.confidencePercent} '
    'evidenceCount=${evidenceList.length} behavioralNotes=$behavioralNotes '
    'basicIntel.relationLevel=${basicIntel?.relationLevel} personalityArchetype=${basicIntel?.personalityArchetype}',
  );

  return DossierView(
    subjectId: subjectId,
    suspicionByAgendaType: suspicionByAgendaType,
    evidenceList: evidenceList,
    basicIntel: basicIntel,
    bestGuessAgenda: bestGuess,
    behavioralNotes: behavioralNotes,
    timeline: timeline,
  );
}
