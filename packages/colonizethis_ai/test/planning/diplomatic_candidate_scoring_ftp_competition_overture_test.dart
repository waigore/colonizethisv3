import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

void main() {
  // Favoured-trading-partner competition boost on `establishOverture` scoring
  // (Refs #3758 S10/R11; #3753 R7). For a Minor/Tribe seller the favoured
  // trading partner (highest GP→seller relation) wins the world-market
  // sell-priority tiebreaker among consulate-holding buyers, so a trailing AI
  // is nudged to invest in the relationship.
  // SPEC/ai/phase-planner-architecture.md § Favoured-trading-partner
  // competition overture; SPEC/game/world-market.md § Favored Trading Partner.
  const config = AIConfig(
    leaderId: 'frederick',
    personalityId: 'frederick',
    hiddenAgendaId: 'merchant',
  );
  const topology = MapTopology(nodes: [], edges: []);

  int scoreCandidate({
    required Game game,
    required List<DiplomaticOrder> candidates,
  }) {
    final snapshot = AIWorldSnapshot.fromPlayerView(
      buildPlayerView(game, topology, 'gp1'),
    );
    return computeDiplomaticCandidateScores(
      candidates: candidates,
      nationId: 'gp1',
      game: game,
      snapshot: snapshot,
      config: config,
    ).single;
  }

  group('computeDiplomaticCandidateScores establishOverture FTP competition', () {
    // Minimal symmetric two-GP world plus one Minor seller. gp1 (AI) and gp2
    // each own one Old World province so the power basis is identical; the AI's
    // own relation with the Minor is held fixed across cases so only the
    // competitor's relation (and therefore the FTP-competition boost) varies.
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
        scoreCandidate(
          game: gameWithMinorRelations(
            ownScore: ownScore,
            competitorScore: competitorScore,
          ),
          candidates: overtureToMinor,
        );

    test('trailing the favoured partner adds exactly the competition bonus', () {
      // Own score fixed at 60 (above neutral, so the decay discount never
      // applies and the war-desire base is identical across cases). A
      // strictly-higher competitor (60.3) makes the AI a trailing partner and
      // adds kEstablishOvertureFtpCompetitionBonus; a strictly-lower competitor
      // (40) leaves the AI as the favoured partner with no boost.
      final trailing = overtureScore(ownScore: 60, competitorScore: 60.3);
      final favoured = overtureScore(ownScore: 60, competitorScore: 40);
      expect(trailing - favoured, kEstablishOvertureFtpCompetitionBonus);
    });

    test('already the favoured partner gets no competition boost', () {
      // Competitor strictly below the AI -> AI is the favoured partner.
      final favoured = overtureScore(ownScore: 60, competitorScore: 40);
      // A tie (competitor equal to the AI) is also "already favoured" because
      // the boost requires another GP to be *strictly* higher (>= keeps the
      // favoured status). Both must therefore score identically.
      final tied = overtureScore(ownScore: 60, competitorScore: 60);
      expect(tied, favoured);
    });

    test('a strictly-higher competitor scores above a tie', () {
      // Negative/positive split around the strict-inequality threshold: a
      // competitor at 60.3 boosts, a competitor at exactly 60 does not.
      expect(
        overtureScore(ownScore: 60, competitorScore: 60.3),
        greaterThan(overtureScore(ownScore: 60, competitorScore: 60)),
      );
    });
  });

  group('computeDiplomaticCandidateScores establishOverture FTP non-minor', () {
    // The favoured-trading-partner tiebreaker applies only to Minor/Tribe
    // sellers, so an overture toward a Great Power must never receive the
    // FTP-competition boost regardless of a third GP's relation with the
    // target. SPEC/game/world-market.md § Favored Trading Partner.
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
        // AI relation with the GP target (held fixed across cases).
        DiplomacyRelation(
          factionId1: 'gp1',
          factionId2: 'gp2',
          score: 60,
          level: scoreToLevel(60),
          state: RelationState.atPeace,
        ),
        // Third GP's relation with the GP target — varied across cases.
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
        // gp3 far outranks the AI with gp2 (90 vs 60); because gp2 is a Great
        // Power (not a Minor/Tribe seller) no FTP-competition boost applies, so
        // the score equals the case where gp3 trails the AI.
        final outranked = scoreCandidate(
          game: gameWithGpTarget(thirdGpScoreWithTarget: 90),
          candidates: overtureToGp,
        );
        final notOutranked = scoreCandidate(
          game: gameWithGpTarget(thirdGpScoreWithTarget: 40),
          candidates: overtureToGp,
        );
        expect(outranked, notOutranked);
      },
    );
  });
}
