import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_diplomacy/colonizethis_diplomacy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../support/call_to_arms_fixtures.dart';

void main() {
  group('call to arms (alliance mutual defence)', () {
    test('human ally gets pending call to arms when ally GP is declared upon', () {
      final game = threePowerCallToArmsGame(
        gp1Human: true,
        gp2Human: true,
        gp1gp2Score: 80,
      );
      final orders = Orders(
        diplomaticOrdersByPlayerId: {
          'gp3': const [
            DiplomaticOrder(
              type: DiplomaticOrderType.declareWar,
              targetFactionId: 'gp2',
            ),
          ],
        },
      );
      final result = resolveDiplomacyPhase(game, orders);
      expect(result.isPending, isTrue);
      expect(result.pendingCallToArms, isNotNull);
      expect(result.pendingCallToArms!.length, 1);
      expect(result.pendingCallToArms!.first.allyGpId, 'gp1');
      expect(result.pendingCallToArms!.first.defenderGpId, 'gp2');
      expect(result.pendingCallToArms!.first.aggressorGpId, 'gp3');
    });

    test(
      'AI ally refuses call to arms when already at war with another GP',
      () {
        final game = Game(
          id: 'g-multi',
          worldState: WorldState(
            turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 25),
            oldWorld: const RegionData(),
            newWorld: const RegionData(),
          ),
          players: [
            const Player(id: 'gp1', displayName: 'GP1', isHuman: false),
            const Player(id: 'gp2', displayName: 'GP2', isHuman: false),
            const Player(id: 'gp3', displayName: 'GP3', isHuman: false),
            const Player(id: 'gp4', displayName: 'GP4', isHuman: false),
          ],
          diplomacyRelations: [
            DiplomacyRelation(
              factionId1: 'gp1',
              factionId2: 'gp2',
              score: 80,
              level: RelationLevel.allied,
              state: RelationState.atPeace,
              sinceTurn: 0,
              lastInteractionTurn: 0,
              formalAlliance: true,
            ),
            DiplomacyRelation(
              factionId1: 'gp1',
              factionId2: 'gp3',
              score: 0,
              level: RelationLevel.hostile,
              state: RelationState.atWar,
              sinceTurn: 1,
              lastInteractionTurn: 1,
            ),
            DiplomacyRelation(
              factionId1: 'gp2',
              factionId2: 'gp4',
              score: 50,
              level: RelationLevel.neutral,
              state: RelationState.atPeace,
              sinceTurn: 0,
              lastInteractionTurn: 0,
            ),
          ],
        );
        final orders = Orders(
          diplomaticOrdersByPlayerId: {
            'gp4': const [
              DiplomaticOrder(
                type: DiplomaticOrderType.declareWar,
                targetFactionId: 'gp2',
              ),
            ],
          },
        );
        final result = resolveDiplomacyPhase(game, orders);
        expect(result.isPending, isFalse);
        expect(factionsAtWar(result.game, 'gp1', 'gp4'), isFalse);
      },
    );

    test('AI ally accepts when B–A score >= 50: enters war with aggressor', () {
      final game = threePowerCallToArmsGame(
        gp1Human: false,
        gp2Human: true,
        gp1gp2Score: 80,
      );
      final orders = Orders(
        diplomaticOrdersByPlayerId: {
          'gp3': const [
            DiplomaticOrder(
              type: DiplomaticOrderType.declareWar,
              targetFactionId: 'gp2',
            ),
          ],
        },
      );
      final result = resolveDiplomacyPhase(game, orders);
      expect(result.isPending, isFalse);
      final after = result.game;
      expect(factionsAtWar(after, 'gp1', 'gp3'), isTrue);
    });

    test('AI ally refuses when B–A score < 50 (allied level edge): no war with aggressor', () {
      final game = threePowerCallToArmsGame(
        gp1Human: false,
        gp2Human: true,
        gp1gp2Score: 40,
        gp1gp2Level: RelationLevel.allied,
      );
      final orders = Orders(
        diplomaticOrdersByPlayerId: {
          'gp3': const [
            DiplomaticOrder(
              type: DiplomaticOrderType.declareWar,
              targetFactionId: 'gp2',
            ),
          ],
        },
      );
      final result = resolveDiplomacyPhase(game, orders);
      expect(result.isPending, isFalse);
      final after = result.game;
      expect(factionsAtWar(after, 'gp1', 'gp3'), isFalse);
      final rel = getRelation(after, 'gp1', 'gp2');
      expect(rel, isNotNull);
      expect(rel!.level, isNot(RelationLevel.allied));
      // Refuse applies −20; relation convergence (+1 toward 50) runs later same phase.
      expect(rel.score, 21);
    });

    test('human accept on resume: at war with aggressor', () {
      final game = threePowerCallToArmsGame(
        gp1Human: true,
        gp2Human: true,
        gp1gp2Score: 80,
      );
      final orders = Orders(
        diplomaticOrdersByPlayerId: {
          'gp3': const [
            DiplomaticOrder(
              type: DiplomaticOrderType.declareWar,
              targetFactionId: 'gp2',
            ),
          ],
        },
      );
      final pendingResult = resolveDiplomacyPhase(game, orders);
      expect(pendingResult.pendingCallToArms, isNotNull);
      final resumed = resolveDiplomacyPhase(
        pendingResult.game,
        orders,
        callToArmsDecisions: [
          CallToArmsDecision(
            allyGpId: 'gp1',
            defenderGpId: 'gp2',
            aggressorGpId: 'gp3',
            accepted: true,
          ),
        ],
      );
      expect(resumed.isPending, isFalse);
      expect(factionsAtWar(resumed.game, 'gp1', 'gp3'), isTrue);
    });

    test('human refuse on resume: score drops by 20 and leaves Allied band', () {
      final game = threePowerCallToArmsGame(
        gp1Human: true,
        gp2Human: true,
        gp1gp2Score: 80,
      );
      final orders = Orders(
        diplomaticOrdersByPlayerId: {
          'gp3': const [
            DiplomaticOrder(
              type: DiplomaticOrderType.declareWar,
              targetFactionId: 'gp2',
            ),
          ],
        },
      );
      final pendingResult = resolveDiplomacyPhase(game, orders);
      final resumed = resolveDiplomacyPhase(
        pendingResult.game,
        orders,
        callToArmsDecisions: [
          CallToArmsDecision(
            allyGpId: 'gp1',
            defenderGpId: 'gp2',
            aggressorGpId: 'gp3',
            accepted: false,
          ),
        ],
      );
      expect(resumed.isPending, isFalse);
      expect(factionsAtWar(resumed.game, 'gp1', 'gp3'), isFalse);
      final rel = getRelation(resumed.game, 'gp1', 'gp2');
      // 80 − 20 = 60; convergence pulls down 1 toward 50 same phase.
      expect(rel!.score, 59);
      expect(rel.level, RelationLevel.friendly);
    });

    // AC3: refusing call to arms clears the formal alliance and records an
    // allianceBroken event in addition to callToArmsRefused.
    test(
      'human refuse on resume: formal alliance cleared and allianceBroken logged',
      () {
        final game = threePowerCallToArmsGame(
          gp1Human: true,
          gp2Human: true,
          gp1gp2Score: 80,
        );
        final orders = Orders(
          diplomaticOrdersByPlayerId: {
            'gp3': const [
              DiplomaticOrder(
                type: DiplomaticOrderType.declareWar,
                targetFactionId: 'gp2',
              ),
            ],
          },
        );
        final pendingResult = resolveDiplomacyPhase(game, orders);
        final resumed = resolveDiplomacyPhase(
          pendingResult.game,
          orders,
          callToArmsDecisions: [
            CallToArmsDecision(
              allyGpId: 'gp1',
              defenderGpId: 'gp2',
              aggressorGpId: 'gp3',
              accepted: false,
            ),
          ],
        );
        final rel = getRelation(resumed.game, 'gp1', 'gp2');
        expect(rel!.formalAlliance, isFalse);
        final broken = resumed.game.diplomaticHistoryEvents.where(
          (e) =>
              e.type == DiplomaticEventType.allianceBroken &&
              e.participants.contains('gp1') &&
              e.participants.contains('gp2'),
        );
        expect(broken.length, 1);
      },
    );
  });
}
