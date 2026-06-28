import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

void main() {
  group('computeDiplomaticCandidateScores breakAlliance (Refs #3758 R6)', () {
    // Minimal two-GP game with a formal alliance at peace. The breakAlliance
    // score depends only on the agenda and personality allianceTendency, so a
    // minimal world suffices.
    Game gameWithFormalAlliance() => Game(
      id: 'g-break-alliance',
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
          score: 80,
          level: RelationLevel.allied,
          state: RelationState.atPeace,
          formalAlliance: true,
        ),
      ],
    );

    const breakAllianceCandidate = [
      DiplomaticOrder(
        type: DiplomaticOrderType.breakAlliance,
        targetFactionId: 'gp2',
      ),
    ];

    // `frederick` has a neutral base `allianceTendency` of 50, so an unset
    // override leaves the neutral baseline. A high-tendency override (80)
    // differs from the registry default (50) and therefore applies.
    int breakAllianceScore({
      required String agendaId,
      int? allianceTendencyOverride,
    }) {
      final game = gameWithFormalAlliance();
      const topology = MapTopology(nodes: [], edges: []);
      final snapshot = AIWorldSnapshot.fromPlayerView(
        buildPlayerView(game, topology, 'gp1'),
      );
      final config = AIConfig(
        leaderId: 'frederick',
        personalityId: 'frederick',
        hiddenAgendaId: agendaId,
        parameterOverrides: allianceTendencyOverride == null
            ? null
            : {
                'personalityThresholds.allianceTendency':
                    allianceTendencyOverride,
              },
      );
      return computeDiplomaticCandidateScores(
        candidates: breakAllianceCandidate,
        nationId: 'gp1',
        game: game,
        snapshot: snapshot,
        config: config,
      ).single;
    }

    test('backstabber scores breakAlliance higher than default agenda', () {
      expect(
        breakAllianceScore(agendaId: 'backstabber'),
        greaterThan(breakAllianceScore(agendaId: 'merchant')),
      );
    });

    test('peacemaker scores breakAlliance lower than default agenda', () {
      expect(
        breakAllianceScore(agendaId: 'peacemaker'),
        lessThan(breakAllianceScore(agendaId: 'merchant')),
      );
    });

    test('isolationist scores breakAlliance higher than default agenda', () {
      // The isolationist "cancels alliances": its negative alliance-acceptance
      // modifier inverts to a break boost.
      expect(
        breakAllianceScore(agendaId: 'isolationist'),
        greaterThan(breakAllianceScore(agendaId: 'merchant')),
      );
    });

    test('high alliance tendency resists breaking vs neutral tendency', () {
      expect(
        breakAllianceScore(agendaId: 'merchant', allianceTendencyOverride: 80),
        lessThan(breakAllianceScore(agendaId: 'merchant')),
      );
    });

    test('default agenda with neutral tendency yields the neutral base score', () {
      expect(breakAllianceScore(agendaId: 'merchant'), 50);
    });
  });
}
