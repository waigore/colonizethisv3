import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_world/src/game_player_lookup.dart';
import 'package:colonizethis_diplomacy/colonizethis_diplomacy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

void main() {
  group('dialogue (Phase 6)', () {
    test('AI declare war invokes onDialogue with diplomatic declare_war', () {
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 2),
          oldWorld: const RegionData(),
          newWorld: const RegionData(),
        ),
        players: const [
          Player(id: 'gp1', displayName: 'Human', isHuman: true),
          Player(id: 'gp2', displayName: 'AI', isHuman: false),
          Player(id: 'gp3', displayName: 'Other', isHuman: false),
        ],
        diplomacyRelations: [
          DiplomacyRelation(
            factionId1: 'gp2',
            factionId2: 'gp3',
            score: 50,
            level: RelationLevel.neutral,
            state: RelationState.atPeace,
          ),
        ],
      );
      final orders = Orders(
        diplomaticOrdersByPlayerId: {
          'gp2': const [
            DiplomaticOrder(type: DiplomaticOrderType.declareWar, targetFactionId: 'gp3'),
          ],
        },
      );
      DialogueEvent? captured;
      resolveDiplomacyPhase(game, orders, onDialogue: (e) => captured = e);
      expect(captured, isNotNull);
      expect(captured!.leaderId, 'gp2');
      expect(captured!.category, 'diplomatic');
      expect(captured!.situation, 'declare_war');
      expect(captured!.era, 'earlyModern');
      expect(captured!.variables['otherNation'], 'gp3');
    });

    test('AI offer peace invokes onDialogue with diplomatic peace_offer', () {
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 2),
          oldWorld: const RegionData(),
          newWorld: const RegionData(),
        ),
        players: const [
          Player(id: 'gp1', displayName: 'Human', isHuman: true),
          Player(id: 'gp2', displayName: 'AI', isHuman: false),
          Player(id: 'gp3', displayName: 'Other', isHuman: false),
        ],
        diplomacyRelations: [
          DiplomacyRelation(
            factionId1: 'gp2',
            factionId2: 'gp3',
            score: 40,
            level: RelationLevel.neutral,
            state: RelationState.atWar,
          ),
        ],
      );
      // GP–GP peace requires both sides to offer peace (SPEC/game/diplomacy.md).
      final orders = Orders(
        diplomaticOrdersByPlayerId: {
          'gp2': const [
            DiplomaticOrder(type: DiplomaticOrderType.offerPeace, targetFactionId: 'gp3'),
          ],
          'gp3': const [
            DiplomaticOrder(type: DiplomaticOrderType.offerPeace, targetFactionId: 'gp2'),
          ],
        },
      );
      DialogueEvent? captured;
      resolveDiplomacyPhase(game, orders, onDialogue: (e) => captured = e);
      expect(captured, isNotNull);
      expect(captured!.leaderId, 'gp2');
      expect(captured!.category, 'diplomatic');
      expect(captured!.situation, 'peace_offer');
      expect(captured!.variables['otherNation'], 'gp3');
    });

    test('human declare war does not invoke onDialogue', () {
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: const RegionData(),
          newWorld: const RegionData(),
        ),
        players: const [
          Player(id: 'gp1', displayName: 'Human', isHuman: true),
          Player(id: 'gp2', displayName: 'AI', isHuman: false),
        ],
        diplomacyRelations: [
          DiplomacyRelation(
            factionId1: 'gp1',
            factionId2: 'gp2',
            score: 50,
            level: RelationLevel.neutral,
            state: RelationState.atPeace,
          ),
        ],
      );
      final orders = Orders(
        diplomaticOrdersByPlayerId: {
          'gp1': const [
            DiplomaticOrder(type: DiplomaticOrderType.declareWar, targetFactionId: 'gp2'),
          ],
        },
      );
      var callCount = 0;
      resolveDiplomacyPhase(game, orders, onDialogue: (_) => callCount++);
      expect(callCount, 0);
    });

    test('overture to human GP returns pending; resume with accept applies overture',
        () {
      // gp1 offers Consulate to gp2 (human). Phase should return pending.
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
          oldWorld: const RegionData(),
          newWorld: const RegionData(),
        ),
        players: [
          const Player(id: 'gp1', displayName: 'GP1', isHuman: false)
              .copyWith(treasury: overtureConsulateCost + 100),
          const Player(id: 'gp2', displayName: 'GP2', isHuman: true),
        ],
        diplomacyRelations: [
          DiplomacyRelation(
            factionId1: 'gp1',
            factionId2: 'gp2',
            score: 50,
            level: RelationLevel.neutral,
            state: RelationState.atPeace,
            sinceTurn: 0,
            lastInteractionTurn: 0,
          ),
        ],
        overtureStates: const [],
      );
      final orders = Orders(
        diplomaticOrdersByPlayerId: {
          'gp1': const [
            DiplomaticOrder(
              type: DiplomaticOrderType.establishOverture,
              targetFactionId: 'gp2',
              overtureStage: OvertureStage.tradeConsulate,
            ),
          ],
        },
      );
      final result = resolveDiplomacyPhase(game, orders);
      expect(result.isPending, isTrue);
      expect(result.pendingOvertures, isNotNull);
      expect(result.pendingOvertures!.length, 1);
      expect(result.pendingOvertures!.first.offererGpId, 'gp1');
      expect(result.pendingOvertures!.first.targetFactionId, 'gp2');
      expect(result.pendingOvertures!.first.stage, OvertureStage.tradeConsulate);

      // Resume with accept: overture should be applied.
      final gp1Before = game.playerById('gp1')!;
      final afterAccept = resolveDiplomacyPhase(
        game,
        orders,
        overtureDecisions: [
          const OvertureDecision(
            offererGpId: 'gp1',
            targetFactionId: 'gp2',
            stage: OvertureStage.tradeConsulate,
            accepted: true,
          ),
        ],
      );
      expect(afterAccept.isPending, isFalse);
      final overture = getOverture(afterAccept.game, 'gp1', 'gp2');
      expect(overture, isNotNull);
      expect(overture!.stage, OvertureStage.tradeConsulate);
      final gp1After = afterAccept.game.playerById('gp1')!;
      expect(gp1After.treasury, gp1Before.treasury - overtureConsulateCost);
    });
  });
}
