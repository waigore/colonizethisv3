import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

void main() {
  group('computeDiplomaticCandidateScores boycott (Refs #3758 R5)', () {
    // Minimal two-GP game at peace. The boycott score depends only on the
    // agenda treaty-breaking / peace-acceptance modifiers and the personality
    // warLikelihood, so a minimal world suffices.
    Game gameWithTwoGreatPowers() => Game(
      id: 'g-boycott',
      worldState: WorldState(
        turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
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
      diplomacyRelations: const [
        DiplomacyRelation(
          factionId1: 'gp1',
          factionId2: 'gp2',
          score: 50,
          level: RelationLevel.neutral,
          state: RelationState.atPeace,
        ),
      ],
    );

    const boycottCandidate = [
      DiplomaticOrder(
        type: DiplomaticOrderType.boycott,
        targetFactionId: 'gp2',
      ),
    ];

    // `isabella` has a neutral base `warLikelihood` of 50, so an unset override
    // leaves the neutral baseline. A high-warLikelihood override (80) differs
    // from the registry default (50) and therefore applies.
    int boycottScore({required String agendaId, int? warLikelihoodOverride}) {
      final game = gameWithTwoGreatPowers();
      const topology = MapTopology(nodes: [], edges: []);
      final snapshot = AIWorldSnapshot.fromPlayerView(
        buildPlayerView(game, topology, 'gp1'),
      );
      final config = AIConfig(
        leaderId: 'isabella',
        personalityId: 'isabella',
        hiddenAgendaId: agendaId,
        parameterOverrides: warLikelihoodOverride == null
            ? null
            : {'personalityThresholds.warLikelihood': warLikelihoodOverride},
      );
      return computeDiplomaticCandidateScores(
        candidates: boycottCandidate,
        nationId: 'gp1',
        game: game,
        snapshot: snapshot,
        config: config,
      ).single;
    }

    test(
      'default agenda with neutral warLikelihood yields the neutral base',
      () {
        expect(boycottScore(agendaId: 'merchant'), 50);
      },
    );

    test('backstabber scores boycott higher than default agenda', () {
      expect(
        boycottScore(agendaId: 'backstabber'),
        greaterThan(boycottScore(agendaId: 'merchant')),
      );
    });

    test('warmonger scores boycott higher than default agenda', () {
      expect(
        boycottScore(agendaId: 'warmonger'),
        greaterThan(boycottScore(agendaId: 'merchant')),
      );
    });

    test('peacemaker scores boycott lower than default agenda', () {
      expect(
        boycottScore(agendaId: 'peacemaker'),
        lessThan(boycottScore(agendaId: 'merchant')),
      );
    });

    test(
      'high warLikelihood scores boycott higher than neutral warLikelihood',
      () {
        expect(
          boycottScore(agendaId: 'merchant', warLikelihoodOverride: 80),
          greaterThan(boycottScore(agendaId: 'merchant')),
        );
      },
    );
  });
}
