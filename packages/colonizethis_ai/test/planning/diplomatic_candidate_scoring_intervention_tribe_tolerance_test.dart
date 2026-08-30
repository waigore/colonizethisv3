// Pins issue #2509 **must-have #6** (intervention tolerance) at the
// `computeDiplomaticCandidateScores` scoring boundary.
//
// Existing related coverage (not redundant with this pin):
//   - `war_desire_score_test.dart` group `computeWarDesireScore`
//   - `domain_planner_orchestrator_colonial_tribe_declare_war_test.dart`
//   - `diplomatic_candidate_scoring_personality_colonial_divergence_test.dart`
//
// Coverage layers:
//   - Positive (presence): tribe declare-war score stays > 0 under max intervention risk
//   - Negative (delta): score strictly higher without intervention overtures
//   - Determinism (must-have #7): repeat invocations yield identical score lists

import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import '../support/diplomatic_candidate_scoring_colonial_test_support.dart';
import 'diplomatic_candidate_scoring_intervention_tribe_tolerance_support.dart';

void main() {
  group(
    'computeDiplomaticCandidateScores COLONIAL tribe intervention '
    'tolerance (Refs #2509 must-have #6)',
    () {
      test(
        'tribe declareWar candidate stays in the candidate set under '
        'max intervention risk (3 other-GP embassies)',
        () {
          final scores = scoreInterventionTribeDeclareWar(
            overtureStates: <OvertureState>[
              kDiplomaticCandidateScoringGp1TribeEmbassy,
              ...kDiplomaticCandidateScoringInterventionEmbassies,
            ],
          );

          expect(
            scores.length,
            kInterventionTribeDeclareWarCandidates.length,
            reason:
                '`computeDiplomaticCandidateScores` must return one score '
                'per input candidate — a refactor that filters out the '
                'tribe declare-war slot under intervention risk would '
                'silently break must-have #6 by reshaping the list.',
          );
          expect(
            scores.single,
            greaterThan(0),
            reason:
                'Issue #2509 must-have #6 forbids a hard "never declare" '
                'guard on tribe declare-war candidates under elevated '
                'intervention-risk preconditions. The score may be low '
                '(intervention risk is applied as a graded war-desire '
                'penalty in `_interventionRiskPenalty`, -8 per other-GP '
                'embassy, capped at -24) but it **must remain > 0** so '
                'the candidate stays selectable by the weighted-random '
                'pick downstream of `computeDiplomaticCandidateScores`.',
          );
        },
      );

      test(
        'tribe declareWar score is strictly higher without intervention '
        'overtures (intervention risk applied as graded penalty, not a '
        'hard skip nor a no-op)',
        () {
          final withoutIntervention = scoreInterventionTribeDeclareWar(
            overtureStates: const <OvertureState>[
              kDiplomaticCandidateScoringGp1TribeEmbassy,
            ],
          );
          final withIntervention = scoreInterventionTribeDeclareWar(
            overtureStates: <OvertureState>[
              kDiplomaticCandidateScoringGp1TribeEmbassy,
              ...kDiplomaticCandidateScoringInterventionEmbassies,
            ],
          );

          expect(
            withoutIntervention.single,
            greaterThan(withIntervention.single),
            reason:
                'Removing the three other-GP embassies must raise the '
                'tribe declare-war score, proving intervention risk is '
                'still applied as a graded scoring penalty rather than '
                'collapsed into a no-op or upgraded into a hard skip. '
                'If both scores are equal a tuning slice has silently '
                'dropped the `_interventionRiskPenalty` contribution; if '
                'the high-intervention score is zero must-have #6 has '
                'regressed.',
          );
          expect(
            withIntervention.single,
            greaterThan(0),
            reason:
                'Cross-check: the high-intervention variant must still be '
                '> 0 alongside the strictly-greater delta, so the test '
                'fails distinctly for the hard-skip regression versus '
                'the no-op regression.',
          );
        },
      );

      test(
        'tribe declareWar score is deterministic for the same inputs '
        'under high intervention risk (must-have #7)',
        () {
          final first = scoreInterventionTribeDeclareWar(
            overtureStates: <OvertureState>[
              kDiplomaticCandidateScoringGp1TribeEmbassy,
              ...kDiplomaticCandidateScoringInterventionEmbassies,
            ],
          );
          final second = scoreInterventionTribeDeclareWar(
            overtureStates: <OvertureState>[
              kDiplomaticCandidateScoringGp1TribeEmbassy,
              ...kDiplomaticCandidateScoringInterventionEmbassies,
            ],
          );

          expect(
            second,
            equals(first),
            reason:
                'Issue #2509 must-have #7 — same `Game` state + same '
                '`computeDiplomaticCandidateScores` inputs must produce '
                'identical score lists across repeat invocations. A '
                'refactor that introduces non-determinism in the '
                'intervention-risk path (e.g. iterating overture states '
                'in non-stable order) would surface here.',
          );
        },
      );
    },
  );
}
