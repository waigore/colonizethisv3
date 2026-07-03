import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_diplomacy/colonizethis_diplomacy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'package:colonizethis_diplomacy_test_support/colonizethis_diplomacy_test_support.dart';

/// Tests the voluntary `breakAlliance` order resolution and the unified
/// alliance-break penalty (R11). SPEC/game/diplomacy.md § Alliances.

Map<String, List<DiplomaticOrder>> _breakOrder(String gpId, String targetId) =>
    {
      gpId: [
        DiplomaticOrder(
          type: DiplomaticOrderType.breakAlliance,
          targetFactionId: targetId,
        ),
      ],
    };

void main() {
  group('processBreakAlliances (voluntary alliance break, R11)', () {
    test(
      'breaks formal alliance: -50 to ally, -10 to every other GP, clears flag',
      () {
        final game = fourGpGame(gp1gp2Score: 80, gp1gp2FormalAlliance: true);
        final result = processBreakAlliances(
          game,
          _breakOrder('gp1', 'gp2'),
          10,
          factionMembership: DiplomacyFactionMembership.from(game),
        );

        final ally = getRelation(result, 'gp1', 'gp2')!;
        expect(ally.formalAlliance, isFalse);
        expect(ally.score, 30); // 80 - 50
        expect(ally.level, RelationLevel.neutral);

        expect(getRelation(result, 'gp1', 'gp3')!.score, 50); // 60 - 10
        expect(getRelation(result, 'gp1', 'gp4')!.score, 50); // 60 - 10

        // Relation not involving the breaker is untouched.
        expect(getRelation(result, 'gp2', 'gp3')!.score, 50);

        final broken = result.diplomaticHistoryEvents.where(
          (e) =>
              e.type == DiplomaticEventType.allianceBroken &&
              e.participants.contains('gp1') &&
              e.participants.contains('gp2'),
        );
        expect(broken.length, 1);
      },
    );

    test('clamps the ally penalty at the relation-score minimum', () {
      final game = fourGpGame(
        gp1gp2Score: 40,
        gp1gp2FormalAlliance: true,
        gp1gp3Score: 5,
      );
      final result = processBreakAlliances(
        game,
        _breakOrder('gp1', 'gp2'),
        10,
        factionMembership: DiplomacyFactionMembership.from(game),
      );
      expect(getRelation(result, 'gp1', 'gp2')!.score, relationScoreMin); // 0
      expect(getRelation(result, 'gp1', 'gp3')!.score, relationScoreMin); // 0
    });

    test(
      'war invariant: at-war pair holds no treaty, so break is a no-op',
      () {
        // Under the war invariant (SPEC/game/diplomacy.md § Alliances) an at-war
        // pair can never hold a formal alliance, so a break order against it
        // finds nothing to break and applies no penalty / no event.
        final game = fourGpGame(
          gp1gp2Score: 30,
          gp1gp2FormalAlliance: false,
          gp1gp2State: RelationState.atWar,
        );
        final result = processBreakAlliances(
          game,
          _breakOrder('gp1', 'gp2'),
          10,
          factionMembership: DiplomacyFactionMembership.from(game),
        );
        final ally = getRelation(result, 'gp1', 'gp2')!;
        expect(ally.formalAlliance, isFalse);
        expect(ally.score, 30); // unchanged: no break occurred
        expect(getRelation(result, 'gp1', 'gp3')!.score, 60); // no cascade
        final broken = result.diplomaticHistoryEvents.where(
          (e) => e.type == DiplomaticEventType.allianceBroken,
        );
        expect(broken, isEmpty);
      },
    );

    test('no-op when no formal alliance exists (no penalty, no event)', () {
      final game = fourGpGame(gp1gp2Score: 80, gp1gp2FormalAlliance: false);
      final result = processBreakAlliances(
        game,
        _breakOrder('gp1', 'gp2'),
        10,
        factionMembership: DiplomacyFactionMembership.from(game),
      );
      expect(getRelation(result, 'gp1', 'gp2')!.score, 80);
      expect(getRelation(result, 'gp1', 'gp3')!.score, 60);
      final broken = result.diplomaticHistoryEvents.where(
        (e) => e.type == DiplomaticEventType.allianceBroken,
      );
      expect(broken, isEmpty);
    });

    test(
      'AC14: phase-4a break is idempotent after human immediate break same turn',
      () {
        final game = fourGpGame(gp1gp2Score: 80, gp1gp2FormalAlliance: true);
        final membership = DiplomacyFactionMembership.from(game);
        final afterImmediate = applyVoluntaryAllianceBreak(
          game,
          breakerId: 'gp1',
          brokenWithAllyId: 'gp2',
          turn: 10,
          factionMembership: membership,
        );
        expect(getRelation(afterImmediate, 'gp1', 'gp2')!.formalAlliance, isFalse);
        expect(getRelation(afterImmediate, 'gp1', 'gp2')!.score, 30);

        final afterPhase = processBreakAlliances(
          afterImmediate,
          _breakOrder('gp1', 'gp2'),
          10,
          factionMembership: membership,
        );
        expect(getRelation(afterPhase, 'gp1', 'gp2')!.score, 30);
        expect(getRelation(afterPhase, 'gp1', 'gp3')!.score, 50);
        final broken = afterPhase.diplomaticHistoryEvents.where(
          (e) => e.type == DiplomaticEventType.allianceBroken,
        );
        expect(broken.length, 1);
      },
    );
  });
}
