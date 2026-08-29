// Case bodies for `diplomatic_candidate_scoring_ftp_competition_overture_test.dart`.
// Refs #3758 S10/R11; #3753 R7.

import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'diplomatic_candidate_scoring_ftp_competition_overture_gp_target_cases.dart';
import 'diplomatic_candidate_scoring_ftp_competition_overture_support.dart';

void registerDiplomaticCandidateScoringFtpCompetitionOvertureCases() {
  group('computeDiplomaticCandidateScores establishOverture FTP competition', () {
    Game gameWithMinorRelations({
      required num ownScore,
      required num competitorScore,
    }) => Game(
      id: 'g-ftp-overture',
      worldState: WorldState(
        turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 5),
        oldWorld: const RegionData(
          provinces: [
            Province(id: 'oldWorld|p1', regionId: 'oldWorld', ownerId: 'gp1'),
            Province(id: 'oldWorld|p2', regionId: 'oldWorld', ownerId: 'gp2'),
          ],
        ),
        newWorld: const RegionData(),
      ),
      players: const [
        Player(id: 'gp1', displayName: 'A', isHuman: false),
        Player(id: 'gp2', displayName: 'B', isHuman: false),
      ],
      minorNations: const [MinorNation(id: 'minor1', displayName: 'M')],
      diplomacyRelations: [
        DiplomacyRelation(
          factionId1: 'gp1',
          factionId2: 'minor1',
          score: ownScore,
          level: scoreToLevel(ownScore),
          state: RelationState.atPeace,
        ),
        DiplomacyRelation(
          factionId1: 'gp2',
          factionId2: 'minor1',
          score: competitorScore,
          level: scoreToLevel(competitorScore),
          state: RelationState.atPeace,
        ),
      ],
    );

    const overtureToMinor = [
      DiplomaticOrder(
        type: DiplomaticOrderType.establishOverture,
        targetFactionId: 'minor1',
        overtureStage: OvertureStage.tradeConsulate,
      ),
    ];

    int overtureScore({required num ownScore, required num competitorScore}) =>
        scoreFtpCompetitionOvertureCandidate(
          game: gameWithMinorRelations(
            ownScore: ownScore,
            competitorScore: competitorScore,
          ),
          candidates: overtureToMinor,
        );

    test('trailing the favoured partner adds exactly the competition bonus', () {
      final trailing = overtureScore(ownScore: 60, competitorScore: 60.3);
      final favoured = overtureScore(ownScore: 60, competitorScore: 40);
      expect(trailing - favoured, kEstablishOvertureFtpCompetitionBonus);
    });

    test('already the favoured partner gets no competition boost', () {
      final favoured = overtureScore(ownScore: 60, competitorScore: 40);
      final tied = overtureScore(ownScore: 60, competitorScore: 60);
      expect(tied, favoured);
    });

    test('a strictly-higher competitor scores above a tie', () {
      expect(
        overtureScore(ownScore: 60, competitorScore: 60.3),
        greaterThan(overtureScore(ownScore: 60, competitorScore: 60)),
      );
    });

    test(
      'colony suzerain is already favoured despite a higher competitor relation '
      '(Refs #3753 R7.1)',
      () {
        Game tribeGame({required bool colonyOfGp1}) => Game(
          id: 'g-ftp-colony',
          worldState: WorldState(
            turnState: const TurnState(
              phase: TurnPhase.orders,
              turnNumber: 5,
            ),
            oldWorld: const RegionData(),
            newWorld: const RegionData(
              provinces: [
                Province(
                  id: 'newWorld|t1',
                  regionId: 'newWorld',
                  ownerId: 'tribe1',
                ),
              ],
            ),
          ),
          players: const [
            Player(id: 'gp1', displayName: 'A', isHuman: false),
            Player(id: 'gp2', displayName: 'B', isHuman: false),
          ],
          tribes: const [Tribe(id: 'tribe1', displayName: 'T1')],
          diplomacyRelations: [
            DiplomacyRelation(
              factionId1: 'gp1',
              factionId2: 'tribe1',
              score: 40,
              level: scoreToLevel(40),
              state: RelationState.atPeace,
            ),
            DiplomacyRelation(
              factionId1: 'gp2',
              factionId2: 'tribe1',
              score: 90,
              level: scoreToLevel(90),
              state: RelationState.atPeace,
            ),
          ],
          colonyStates: colonyOfGp1
              ? const [
                  ColonyState(
                    tribeId: 'tribe1',
                    colonyOfGpId: 'gp1',
                    sinceTurn: 1,
                  ),
                ]
              : const [],
        );

        const overtureToTribe = [
          DiplomaticOrder(
            type: DiplomaticOrderType.establishOverture,
            targetFactionId: 'tribe1',
            overtureStage: OvertureStage.tradeConsulate,
          ),
        ];

        final independentTrailing = scoreFtpCompetitionOvertureCandidate(
          game: tribeGame(colonyOfGp1: false),
          candidates: overtureToTribe,
          snapshot: ftpCompetitionTribeOvertureSnapshot(),
        );
        final colonySuzerain = scoreFtpCompetitionOvertureCandidate(
          game: tribeGame(colonyOfGp1: true),
          candidates: overtureToTribe,
          snapshot: ftpCompetitionTribeOvertureSnapshot(),
        );
        expect(
          independentTrailing - colonySuzerain,
          kEstablishOvertureFtpCompetitionBonus,
        );
      },
    );
  });

  registerDiplomaticCandidateScoringFtpCompetitionOvertureGpTargetCases();
}
