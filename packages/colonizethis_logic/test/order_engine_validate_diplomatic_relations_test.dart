import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'order_engine_validate_diplomatic_test_support.dart';

void main() {
  group('OrderEngine validateDiplomatic relation and overture rules', () {
    test('declareWar rejected when already at war', () {
      final game = gpMinorBaseGame(relationState: RelationState.atWar);
      final engine = OrderEngine();
      final result = engine.addDiplomaticOrderWithContext(
        game,
        emptyTopology,
        'gp1',
        const DiplomaticOrder(
          type: DiplomaticOrderType.declareWar,
          targetFactionId: 'minor1',
        ),
      );
      expect(result.status, OrderValidationStatus.rejected);
      expect(result.reason, contains('Already at war'));
    });

    test('offerPeace rejected when not at war', () {
      final game = gpMinorBaseGame(relationState: RelationState.atPeace);
      final engine = OrderEngine();
      final result = engine.addDiplomaticOrderWithContext(
        game,
        emptyTopology,
        'gp1',
        const DiplomaticOrder(
          type: DiplomaticOrderType.offerPeace,
          targetFactionId: 'minor1',
        ),
      );
      expect(result.status, OrderValidationStatus.rejected);
      expect(result.reason, contains('not at war'));
    });

    test('establishOverture rejected when target is at war with GP', () {
      final game = gpMinorBaseGame(
        relationState: RelationState.atWar,
        overtureStage: OvertureStage.none,
        treasury: overtureConsulateCost + 100,
      );
      final engine = OrderEngine();
      final result = engine.addDiplomaticOrderWithContext(
        game,
        emptyTopology,
        'gp1',
        const DiplomaticOrder(
          type: DiplomaticOrderType.establishOverture,
          targetFactionId: 'minor1',
          overtureStage: OvertureStage.tradeConsulate,
        ),
      );
      expect(result.status, OrderValidationStatus.rejected);
      expect(result.reason, contains('at war'));
    });

    test(
      'establishOverture trade consulate rejected without diplomatic_expertise',
      () {
        final game = gpMinorBaseGame(
          relationState: RelationState.atPeace,
          overtureStage: OvertureStage.none,
          treasury: overtureConsulateCost + 100,
          techUnlocked: const {},
        );
        final engine = OrderEngine();
        final result = engine.addDiplomaticOrderWithContext(
          game,
          emptyTopology,
          'gp1',
          const DiplomaticOrder(
            type: DiplomaticOrderType.establishOverture,
            targetFactionId: 'minor1',
            overtureStage: OvertureStage.tradeConsulate,
          ),
        );
        expect(result.status, OrderValidationStatus.rejected);
        expect(result.reason, contains('Diplomatic Expertise'));
      },
    );

    test('establishOverture consulate rejected when treasury too low', () {
      final game = gpMinorBaseGame(
        relationState: RelationState.atPeace,
        overtureStage: OvertureStage.none,
        treasury: overtureConsulateCost - 1,
      );
      final engine = OrderEngine();
      final result = engine.addDiplomaticOrderWithContext(
        game,
        emptyTopology,
        'gp1',
        const DiplomaticOrder(
          type: DiplomaticOrderType.establishOverture,
          targetFactionId: 'minor1',
          overtureStage: OvertureStage.tradeConsulate,
        ),
      );
      expect(result.status, OrderValidationStatus.rejected);
      expect(result.reason, contains('Insufficient treasury'));
    });

    test('establishOverture embassy requires existing consulate', () {
      final game = gpMinorBaseGame(
        relationState: RelationState.atPeace,
        overtureStage: OvertureStage.none,
        treasury: overtureEmbassyCost + 1000,
      );
      final engine = OrderEngine();
      final result = engine.addDiplomaticOrderWithContext(
        game,
        emptyTopology,
        'gp1',
        const DiplomaticOrder(
          type: DiplomaticOrderType.establishOverture,
          targetFactionId: 'minor1',
          overtureStage: OvertureStage.embassy,
        ),
      );
      expect(result.status, OrderValidationStatus.rejected);
      expect(result.reason, contains('requires existing Trade Consulate'));
    });

    test('establishOverture second order for same faction in same turn rejected', () {
      final game = gpMinorBaseGame(
        relationState: RelationState.atPeace,
        overtureStage: OvertureStage.none,
        treasury: overtureConsulateCost * 3,
      );
      final engine = OrderEngine();
      final first = engine.addDiplomaticOrderWithContext(
        game,
        emptyTopology,
        'gp1',
        const DiplomaticOrder(
          type: DiplomaticOrderType.establishOverture,
          targetFactionId: 'minor1',
          overtureStage: OvertureStage.tradeConsulate,
        ),
      );
      expect(first.status, OrderValidationStatus.accepted);
      final second = engine.addDiplomaticOrderWithContext(
        game,
        emptyTopology,
        'gp1',
        const DiplomaticOrder(
          type: DiplomaticOrderType.establishOverture,
          targetFactionId: 'minor1',
          overtureStage: OvertureStage.tradeConsulate,
        ),
      );
      expect(second.status, OrderValidationStatus.rejected);
      expect(
        second.reason,
        contains('Already have a diplomatic order for this faction this turn'),
      );
    });

    test('second diplomatic order to same target different type is rejected', () {
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: const RegionData(),
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
            state: RelationState.atPeace,
            level: RelationLevel.neutral,
          ),
        ],
      );
      final engine = OrderEngine();
      final first = engine.addDiplomaticOrderWithContext(
        game,
        emptyTopology,
        'gp1',
        const DiplomaticOrder(
          type: DiplomaticOrderType.declareWar,
          targetFactionId: 'gp2',
        ),
      );
      expect(first.status, OrderValidationStatus.accepted);
      final second = engine.addDiplomaticOrderWithContext(
        game,
        emptyTopology,
        'gp1',
        const DiplomaticOrder(
          type: DiplomaticOrderType.alliance,
          targetFactionId: 'gp2',
        ),
      );
      expect(second.status, OrderValidationStatus.rejected);
      expect(
        second.reason,
        contains('Already have a diplomatic order for this faction this turn'),
      );
    });
  });
}
