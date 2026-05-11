import 'package:colonizethis_models/colonizethis_models.dart';

/// Suspicion band for display. Never exposes true agenda.
enum SuspicionBand { unknown, possible, likely, almostCertain, confirmed }

/// Score band thresholds for suspicion (inclusive max per band).
const int dossierScoreUnknownMax = 2;
const int dossierScorePossibleMax = 5;
const int dossierScoreLikelyMax = 8;
const int dossierScoreAlmostCertainMax = 10;

/// Confidence percent for display per band.
const int dossierConfidenceUnknown = 0;
const int dossierConfidencePossible = 25;
const int dossierConfidenceLikely = 60;
const int dossierConfidenceAlmostCertain = 85;
const int dossierConfidenceConfirmed = 100;

/// Relative strength for basic intel (observer vs subject).
enum RelativeStrength { weaker, even, stronger }

/// Basic intel section: personality/archetype, relation, relative strength.
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
  final String? personalityArchetype;
}

/// Best-guess hidden agenda from suspicion bands.
class DossierBestGuessAgenda {
  const DossierBestGuessAgenda({
    required this.agendaType,
    required this.confidencePercent,
  });

  final String agendaType;
  final int confidencePercent;
}

/// PlayerView-safe dossier view for one subject.
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
