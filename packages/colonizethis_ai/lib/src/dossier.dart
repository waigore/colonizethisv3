// Dossier projection: PlayerView-safe read API. SPEC/ai/ai-dossier.md.

import 'package:colonizethis_models/colonizethis_models.dart';

/// Suspicion band for display. Never exposes true agenda.
enum SuspicionBand {
  unknown,   // 0–2
  possible, // 3–5
  likely,   // 6–8
  almostCertain, // 9–10
  confirmed, // 10+
}

/// PlayerView-safe dossier view for one subject. No hidden agenda exposed.
class DossierView {
  const DossierView({
    required this.subjectId,
    required this.suspicionByAgendaType,
    required this.evidenceList,
  });

  final String subjectId;
  final Map<String, SuspicionBand> suspicionByAgendaType;
  final List<String> evidenceList;
}

/// Returns suspicion band for a raw score (0–2 unknown, 3–5 possible, etc.).
SuspicionBand suspicionBandFromScore(int score) {
  if (score <= 2) return SuspicionBand.unknown;
  if (score <= 5) return SuspicionBand.possible;
  if (score <= 8) return SuspicionBand.likely;
  if (score <= 10) return SuspicionBand.almostCertain;
  return SuspicionBand.confirmed;
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
  final scoreByAgenda = <String, int>{};
  for (final e in entries) {
    scoreByAgenda[e.agendaType] = (scoreByAgenda[e.agendaType] ?? 0) + e.scoreDelta;
  }
  final suspicionByAgendaType = <String, SuspicionBand>{};
  for (final e in scoreByAgenda.entries) {
    suspicionByAgendaType[e.key] = suspicionBandFromScore(e.value);
  }
  final evidenceList = entries
      .map((e) => 'Turn ${e.turnNumber}: ${e.description}')
      .toList();
  return DossierView(
    subjectId: subjectId,
    suspicionByAgendaType: suspicionByAgendaType,
    evidenceList: evidenceList,
  );
}
