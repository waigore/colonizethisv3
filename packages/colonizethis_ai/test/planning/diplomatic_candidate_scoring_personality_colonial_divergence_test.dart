// Pins **must-have #4** (personality-consistent means) from issue #2509 at
// the `computeDiplomaticCandidateScores` scoring boundary.
// Tail cases: `diplomatic_candidate_scoring_personality_colonial_divergence_tail_cases.dart`.

import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'diplomatic_candidate_scoring_personality_colonial_divergence_support.dart';
import 'diplomatic_candidate_scoring_personality_colonial_divergence_tail_cases.dart';

void main() {
  group(
    'computeDiplomaticCandidateScores COLONIAL personality divergence '
    '(Refs #2509 must-have #4)',
    () {
      test(
        'napoleon ranks declareWar above establishOverture for COLONIAL '
        'tribe target',
        () {
          final scores = personalityColonialDivergenceScoresFor(
            kPersonalityColonialDivergenceNapoleonConfig,
          );

          expect(scores.length, kPersonalityColonialDivergenceCandidates.length);
          expect(
            scores[kPersonalityColonialDivergenceDeclareWarIdx],
            greaterThan(
              scores[kPersonalityColonialDivergenceEstablishOvertureIdx],
            ),
            reason:
                'napoleon (`warLikelihood`=80, `allianceTendency`=25 per '
                '`SPEC/ai/ai-personalities.md`) must rank `declareWar` above '
                '`establishOverture` for a COLONIAL tribe target where both '
                'paths are valid candidates (issue #2509 must-have #4).',
          );
          expect(
            scores[kPersonalityColonialDivergenceDeclareWarIdx],
            greaterThan(0),
            reason:
                'napoleon `declareWar` must remain a viable colonial '
                'acquisition order in COLONIAL — a regression that zeroes the '
                'tribe declare-war path would silently break the must-have #4 '
                'ranking contract.',
          );
        },
      );

      test(
        'henry ranks establishOverture above declareWar for COLONIAL tribe '
        'target',
        () {
          final scores = personalityColonialDivergenceScoresFor(
            kPersonalityColonialDivergenceHenryConfig,
          );

          expect(scores.length, kPersonalityColonialDivergenceCandidates.length);
          expect(
            scores[kPersonalityColonialDivergenceEstablishOvertureIdx],
            greaterThan(scores[kPersonalityColonialDivergenceDeclareWarIdx]),
            reason:
                'henry (`warLikelihood`=10, `allianceTendency`=75 per '
                '`SPEC/ai/ai-personalities.md`) must rank '
                '`establishOverture(joinEmpire)` above `declareWar` for the '
                'same COLONIAL tribe target (issue #2509 must-have #4).',
          );
          expect(
            scores[kPersonalityColonialDivergenceEstablishOvertureIdx],
            greaterThan(0),
            reason:
                'henry `establishOverture(joinEmpire)` must remain a viable '
                'colonial acquisition order in COLONIAL — a regression that '
                'zeroes the overture path would silently break the '
                'must-have #4 ranking contract.',
          );
        },
      );

      test(
        'highest-ranked colonial acquisition order TYPE flips between '
        'napoleon and henry on identical COLONIAL inputs',
        () {
          final napoleonScores = personalityColonialDivergenceScoresFor(
            kPersonalityColonialDivergenceNapoleonConfig,
          );
          final henryScores = personalityColonialDivergenceScoresFor(
            kPersonalityColonialDivergenceHenryConfig,
          );

          final napoleonTopType = kPersonalityColonialDivergenceCandidates[
              personalityColonialDivergenceIndexOfMax(napoleonScores)].type;
          final henryTopType = kPersonalityColonialDivergenceCandidates[
              personalityColonialDivergenceIndexOfMax(henryScores)].type;

          expect(
            napoleonTopType,
            DiplomaticOrderType.declareWar,
            reason:
                'Napoleon (high war / low alliance per '
                '`SPEC/ai/ai-personalities.md` § Canonical leaders) must '
                'top-rank `declareWar` among colonial acquisition orders.',
          );
          expect(
            henryTopType,
            DiplomaticOrderType.establishOverture,
            reason:
                'Henry (very-low war / high alliance per '
                '`SPEC/ai/ai-personalities.md` § Canonical leaders) must '
                'top-rank `establishOverture(joinEmpire)` among colonial '
                'acquisition orders.',
          );
          expect(
            napoleonTopType,
            isNot(henryTopType),
            reason:
                'Must-have #4: the highest-ranked colonial acquisition '
                'order type must differ between personalities for the same '
                'COLONIAL tribe target (war vs alliance personality '
                'modifiers).',
          );
        },
      );
    },
  );

  registerDiplomaticCandidateScoringPersonalityColonialDivergenceTailCases();
}
