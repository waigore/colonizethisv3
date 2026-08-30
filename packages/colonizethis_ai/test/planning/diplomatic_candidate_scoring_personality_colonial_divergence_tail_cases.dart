// Tail case bodies for COLONIAL personality divergence pins (Refs #2509 must-have #4).

import 'package:colonizethis_test/test.dart';

import 'diplomatic_candidate_scoring_personality_colonial_divergence_support.dart';

void registerDiplomaticCandidateScoringPersonalityColonialDivergenceTailCases() {
  group(
    'computeDiplomaticCandidateScores COLONIAL personality divergence '
    '(Refs #2509 must-have #4)',
    () {
      test(
        'napoleon scores declareWar strictly higher than henry; henry '
        'scores establishOverture strictly higher than napoleon',
        () {
          final napoleonScores = personalityColonialDivergenceScoresFor(
            kPersonalityColonialDivergenceNapoleonConfig,
          );
          final henryScores = personalityColonialDivergenceScoresFor(
            kPersonalityColonialDivergenceHenryConfig,
          );

          expect(
            napoleonScores[kPersonalityColonialDivergenceDeclareWarIdx],
            greaterThan(henryScores[kPersonalityColonialDivergenceDeclareWarIdx]),
            reason:
                'napoleon `warLikelihood`=80 (+30 vs centerline) must lift '
                '`declareWar` above henry `warLikelihood`=10 (-40) for the '
                'same target / state.',
          );
          expect(
            henryScores[kPersonalityColonialDivergenceEstablishOvertureIdx],
            greaterThan(
              napoleonScores[kPersonalityColonialDivergenceEstablishOvertureIdx],
            ),
            reason:
                'henry `allianceTendency`=75 (+25 vs centerline) must lift '
                '`establishOverture(joinEmpire)` above napoleon '
                '`allianceTendency`=25 (-25) for the same target / state.',
          );
        },
      );

      test(
        'identical COLONIAL inputs produce identical score lists per '
        'personality (must-have #7 determinism)',
        () {
          final napoleonFirst = personalityColonialDivergenceScoresFor(
            kPersonalityColonialDivergenceNapoleonConfig,
          );
          final napoleonSecond = personalityColonialDivergenceScoresFor(
            kPersonalityColonialDivergenceNapoleonConfig,
          );
          final henryFirst = personalityColonialDivergenceScoresFor(
            kPersonalityColonialDivergenceHenryConfig,
          );
          final henrySecond = personalityColonialDivergenceScoresFor(
            kPersonalityColonialDivergenceHenryConfig,
          );

          expect(
            napoleonSecond,
            napoleonFirst,
            reason:
                'Determinism (must-have #7): identical COLONIAL inputs must '
                'produce identical napoleon score lists across runs.',
          );
          expect(
            henrySecond,
            henryFirst,
            reason:
                'Determinism (must-have #7): identical COLONIAL inputs must '
                'produce identical henry score lists across runs.',
          );
        },
      );
    },
  );
}
