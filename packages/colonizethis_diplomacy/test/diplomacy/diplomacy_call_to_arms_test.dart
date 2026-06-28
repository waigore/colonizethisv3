import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_diplomacy/colonizethis_diplomacy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../support/call_to_arms_fixtures.dart';

void main() {
  group('call to arms (alliance mutual defence)', () {
    test(
      'human ally gets pending call to arms when ally GP is declared upon',
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
        final result = resolveDiplomacyPhase(game, orders);
        expect(result.isPending, isTrue);
        expect(result.pendingCallToArms, isNotNull);
        expect(result.pendingCallToArms!.length, 1);
        expect(result.pendingCallToArms!.first.allyGpId, 'gp1');
        expect(result.pendingCallToArms!.first.defenderGpId, 'gp2');
        expect(result.pendingCallToArms!.first.aggressorGpId, 'gp3');
      },
    );

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

    test(
      'AI ally refuses when B–A score < 50 (allied level edge): no war with aggressor',
      () {
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
        // Refuse applies the unified −50 ally penalty: 40 − 50 → clamp 0. The
        // pair was modified by an event this turn, so per-turn decay is skipped
        // (Refs #3753 R9.4) and the score stays at 0.
        expect(rel.score, 0);
      },
    );

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

    test('human refuse on resume: score drops by 50 and leaves Allied band', () {
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
      // Unified −50 ally penalty: 80 − 50 = 30. The pair was modified by an
      // event this turn, so per-turn decay is skipped (Refs #3753 R9.4) and the
      // score stays at 30.
      expect(rel!.score, 30);
      expect(rel.level, RelationLevel.neutral);
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

    // R11: refusal applies the unified break penalty — −10 to every other GP the
    // refuser has a relation with, except the defended ally (−50) and the
    // aggressor (unchanged by the break rule).
    test(
      'human refuse applies -10 to other GPs but leaves the aggressor unchanged',
      () {
        final game = Game(
          id: 'g-cascade',
          worldState: WorldState(
            turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 5),
            oldWorld: const RegionData(),
            newWorld: const RegionData(),
          ),
          players: const [
            Player(id: 'gp1', displayName: 'GP1', isHuman: true),
            Player(id: 'gp2', displayName: 'GP2', isHuman: true),
            Player(id: 'gp3', displayName: 'GP3', isHuman: false),
            Player(id: 'gp4', displayName: 'GP4', isHuman: false),
          ],
          diplomacyRelations: [
            DiplomacyRelation(
              factionId1: 'gp1',
              factionId2: 'gp2',
              score: 80,
              level: RelationLevel.allied,
              state: RelationState.atPeace,
              formalAlliance: true,
            ),
            // Aggressor: excluded from the -10 cascade (only per-turn decay applies).
            DiplomacyRelation(
              factionId1: 'gp1',
              factionId2: 'gp3',
              score: 60,
              level: RelationLevel.friendly,
              state: RelationState.atPeace,
            ),
            // Bystander GP: receives the -10 cascade.
            DiplomacyRelation(
              factionId1: 'gp1',
              factionId2: 'gp4',
              score: 60,
              level: RelationLevel.friendly,
              state: RelationState.atPeace,
            ),
          ],
        );
        const orders = Orders(
          diplomaticOrdersByPlayerId: {
            'gp3': [
              DiplomaticOrder(
                type: DiplomaticOrderType.declareWar,
                targetFactionId: 'gp2',
              ),
            ],
          },
        );
        final pending = resolveDiplomacyPhase(game, orders);
        expect(pending.pendingCallToArms, isNotNull);
        final resumed = resolveDiplomacyPhase(
          pending.game,
          orders,
          callToArmsDecisions: [
            const CallToArmsDecision(
              allyGpId: 'gp1',
              defenderGpId: 'gp2',
              aggressorGpId: 'gp3',
              accepted: false,
            ),
          ],
        );
        // Bystander gp4: −10 cascade event applied (60 − 10 = 50); decay is
        // skipped for event-modified pairs (Refs #3753 R9.4) → 50.
        expect(getRelation(resumed.game, 'gp1', 'gp4')!.score, 50);
        // Aggressor gp3: excluded from the −10 cascade, so no event delta this
        // turn → per-turn decay applies (−4 toward 50): 60 → 56.
        expect(getRelation(resumed.game, 'gp1', 'gp3')!.score, 56.0);
      },
    );
  });
}
