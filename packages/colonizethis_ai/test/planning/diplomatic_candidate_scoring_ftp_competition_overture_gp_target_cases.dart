// GP-target FTP non-minor cases for `diplomatic_candidate_scoring_ftp_competition_overture_test.dart`.

import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'diplomatic_candidate_scoring_ftp_competition_overture_support.dart';

void registerDiplomaticCandidateScoringFtpCompetitionOvertureGpTargetCases() {
  group('computeDiplomaticCandidateScores establishOverture FTP non-minor', () {
    Game gameWithGpTarget({required num thirdGpScoreWithTarget}) => Game(
      id: 'g-ftp-gp-target',
      worldState: WorldState(
        turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 5),
        oldWorld: const RegionData(
          provinces: [
            Province(id: 'oldWorld|p1', regionId: 'oldWorld', ownerId: 'gp1'),
            Province(id: 'oldWorld|p2', regionId: 'oldWorld', ownerId: 'gp2'),
            Province(id: 'oldWorld|p3', regionId: 'oldWorld', ownerId: 'gp3'),
          ],
        ),
        newWorld: const RegionData(),
      ),
      players: const [
        Player(id: 'gp1', displayName: 'A', isHuman: false),
        Player(id: 'gp2', displayName: 'B', isHuman: false),
        Player(id: 'gp3', displayName: 'C', isHuman: false),
      ],
      diplomacyRelations: [
        DiplomacyRelation(
          factionId1: 'gp1',
          factionId2: 'gp2',
          score: 60,
          level: scoreToLevel(60),
          state: RelationState.atPeace,
        ),
        DiplomacyRelation(
          factionId1: 'gp3',
          factionId2: 'gp2',
          score: thirdGpScoreWithTarget,
          level: scoreToLevel(thirdGpScoreWithTarget),
          state: RelationState.atPeace,
        ),
      ],
    );

    const overtureToGp = [
      DiplomaticOrder(
        type: DiplomaticOrderType.establishOverture,
        targetFactionId: 'gp2',
        overtureStage: OvertureStage.tradeConsulate,
      ),
    ];

    test(
      'Great-Power overture target is invariant to other GPs outranking it',
      () {
        final outranked = scoreFtpCompetitionOvertureCandidate(
          game: gameWithGpTarget(thirdGpScoreWithTarget: 90),
          candidates: overtureToGp,
        );
        final notOutranked = scoreFtpCompetitionOvertureCandidate(
          game: gameWithGpTarget(thirdGpScoreWithTarget: 40),
          candidates: overtureToGp,
        );
        expect(outranked, notOutranked);
      },
    );
  });
}
