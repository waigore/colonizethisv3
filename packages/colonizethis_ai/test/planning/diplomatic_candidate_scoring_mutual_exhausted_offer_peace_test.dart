// Pins the offer-peace mutual-exhausted GP stalemate bonus added at the scoring
// entrypoint for issue #2509 (feature merged in PR #2631).
//
// The peace-target collector `mutualExhaustedBelowQuotaGpStalematePeaceTargets`
// is already pinned by `diplomacy_planner_mutual_exhausted_peace_test.dart`.
// This file pins the **scoring-side mirror**
// `_mutualExhaustedBelowQuotaSoleGpStalemate` in
// `diplomatic_candidate_scoring_offer_peace.dart`, which adds
// `kOfferPeaceMutualExhaustedGpStalemateBonus` (280) onto the offerPeace score
// when the same SPEC-authorized exhaustion conditions hold for both sides.
// Without this pin, a refactor of the collector helper could leave the scoring
// bonus stale (firing under wrong conditions, or not firing at all) while every
// collector-side test stayed green.
//
// SPEC (`SPEC/ai/ai-architecture.md` § Diplomacy targeting / Observer goal
// phases): both sides must hold >= `kMutualExhaustedGpStalemateMinOw` OW
// provinces, both below the observer quota and within the stalled OW band,
// in a sole at-war GP pair with |gap| <= 1, both at or under the exhaustion
// regiment and treasury ceilings. When any single one of these conditions
// fails, the scoring bonus must not fire (and the score must drop by exactly
// `kOfferPeaceMutualExhaustedGpStalemateBonus` relative to the all-conditions
// fixture, since treasury / regiment-id counts above the exhaustion ceilings
// are otherwise inert in the offer-peace scoring path).
//
// Coverage:
//   - Positive presence: gp4/gp3-like exhausted plateau scores offerPeace
//     toward the peer enemy strictly above 0 (must remain a viable candidate).
//   - Delta (own treasury): same fixture except own treasury one above the
//     mutual-exhausted ceiling -> score drops by exactly the bonus value.
//   - Delta (enemy treasury): same fixture except enemy treasury one above the
//     mutual-exhausted ceiling -> score drops by exactly the bonus value.
//   - Delta (own regiments): same fixture except own regiment id count one
//     above the regiment ceiling -> score drops by exactly the bonus value
//     (regiment id count above the ceiling does not affect the strength-based
//     `greatPowerPowerScore` because the fixture has no `Unit` objects, so the
//     mutual-exhausted bonus is the only term that shifts).
//   - Delta (enemy regiments): same as above with the enemy side broken.
//   - Determinism (must-have #7): identical inputs across three invocations
//     produce identical score lists.
import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import '../support/mutual_exhausted_stalemate_test_support.dart';

const _offerPeaceCandidates = <DiplomaticOrder>[
  DiplomaticOrder(
    type: DiplomaticOrderType.offerPeace,
    targetFactionId: kMutualExhaustedStalemateEnemyNationId,
  ),
];

// Personality / agenda kept neutral so personality and agenda peace modifiers
// (`getAgendaPeaceAcceptanceModifier` / `thresholds.peaceTendency - 50`) are
// the same on both sides of every delta comparison below.
const _config = AIConfig(
  leaderId: 'victoria',
  personalityId: 'victoria',
  hiddenAgendaId: 'peacemaker',
);

int _scoreOfferPeaceTowardEnemy(Game game) {
  return computeDiplomaticCandidateScores(
    DiplomaticCandidateScoringInput(
      candidates: _offerPeaceCandidates,
      nationId: kMutualExhaustedStalemateOwnNationId,
      game: game,
      snapshot: kMutualExhaustedStalemateDefaultSnapshot,
      config: _config,
    ),
  ).single;
}

void main() {
  group(
    'computeDiplomaticCandidateScores mutual-exhausted offer-peace bonus',
    () {
      test('positive: exhausted-plateau offerPeace toward peer enemy scores > 0',
          () {
        final game = mutualExhaustedStalemateGame();

        expect(_scoreOfferPeaceTowardEnemy(game), greaterThan(0));
      });

      test(
        'delta: own treasury above ceiling drops score by exactly the bonus',
        () {
          final exhausted = mutualExhaustedStalemateGame();
          final ownNotExhausted = mutualExhaustedStalemateGame(
            ownTreasury: kMutualExhaustedGpTreasuryMax + 1,
          );

          final scoreWithBonus = _scoreOfferPeaceTowardEnemy(exhausted);
          final scoreWithoutBonus = _scoreOfferPeaceTowardEnemy(
            ownNotExhausted,
          );

          expect(
            scoreWithBonus - scoreWithoutBonus,
            kOfferPeaceMutualExhaustedGpStalemateBonus,
          );
        },
      );

      test(
        'delta: enemy treasury above ceiling drops score by exactly the bonus',
        () {
          final exhausted = mutualExhaustedStalemateGame();
          final enemyNotExhausted = mutualExhaustedStalemateGame(
            enemyTreasury: kMutualExhaustedGpTreasuryMax + 1,
          );

          final scoreWithBonus = _scoreOfferPeaceTowardEnemy(exhausted);
          final scoreWithoutBonus = _scoreOfferPeaceTowardEnemy(
            enemyNotExhausted,
          );

          expect(
            scoreWithBonus - scoreWithoutBonus,
            kOfferPeaceMutualExhaustedGpStalemateBonus,
          );
        },
      );

      test(
        'delta: own regiments above ceiling drops score by exactly the bonus',
        () {
          final tooManyOwnRegiments = <String>[
            for (var i = 0; i < kMutualExhaustedGpRegimentMax + 1; i++)
              'u_gp4_extra_$i',
          ];
          final exhausted = mutualExhaustedStalemateGame();
          final ownNotExhausted = mutualExhaustedStalemateGame(
            ownRegimentIds: tooManyOwnRegiments,
          );

          final scoreWithBonus = _scoreOfferPeaceTowardEnemy(exhausted);
          final scoreWithoutBonus = _scoreOfferPeaceTowardEnemy(
            ownNotExhausted,
          );

          expect(
            scoreWithBonus - scoreWithoutBonus,
            kOfferPeaceMutualExhaustedGpStalemateBonus,
          );
        },
      );

      test(
        'delta: enemy regiments above ceiling drops score by exactly the bonus',
        () {
          final tooManyEnemyRegiments = <String>[
            for (var i = 0; i < kMutualExhaustedGpRegimentMax + 1; i++)
              'u_gp3_extra_$i',
          ];
          final exhausted = mutualExhaustedStalemateGame();
          final enemyNotExhausted = mutualExhaustedStalemateGame(
            enemyRegimentIds: tooManyEnemyRegiments,
          );

          final scoreWithBonus = _scoreOfferPeaceTowardEnemy(exhausted);
          final scoreWithoutBonus = _scoreOfferPeaceTowardEnemy(
            enemyNotExhausted,
          );

          expect(
            scoreWithBonus - scoreWithoutBonus,
            kOfferPeaceMutualExhaustedGpStalemateBonus,
          );
        },
      );

      test(
        'determinism: identical inputs return identical scores (must-have #7)',
        () {
          final game = mutualExhaustedStalemateGame();

          final first = computeDiplomaticCandidateScores(
            DiplomaticCandidateScoringInput(
              candidates: _offerPeaceCandidates,
              nationId: kMutualExhaustedStalemateOwnNationId,
              game: game,
              snapshot: kMutualExhaustedStalemateDefaultSnapshot,
              config: _config,
            ),
          );
          final second = computeDiplomaticCandidateScores(
            DiplomaticCandidateScoringInput(
              candidates: _offerPeaceCandidates,
              nationId: kMutualExhaustedStalemateOwnNationId,
              game: game,
              snapshot: kMutualExhaustedStalemateDefaultSnapshot,
              config: _config,
            ),
          );
          final third = computeDiplomaticCandidateScores(
            DiplomaticCandidateScoringInput(
              candidates: _offerPeaceCandidates,
              nationId: kMutualExhaustedStalemateOwnNationId,
              game: game,
              snapshot: kMutualExhaustedStalemateDefaultSnapshot,
              config: _config,
            ),
          );

          expect(first, second);
          expect(second, third);
        },
      );
    },
  );
}
