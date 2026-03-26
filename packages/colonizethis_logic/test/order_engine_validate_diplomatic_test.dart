import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

void main() {
  group('OrderEngine', () {
    group('validateDiplomatic', () {
      final emptyTopology = MapTopology(nodes: const [], edges: const []);

      Game _gpMinorBaseGame({
        RelationState relationState = RelationState.atPeace,
        int relationScore = 50,
        OvertureStage overtureStage = OvertureStage.none,
        int treasury = 5000,
      }) {
        return Game(
          id: 'g1',
          worldState: WorldState(
            turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
            oldWorld: const RegionData(),
            newWorld: const RegionData(),
          ),
          players: [
            Player(
              id: 'gp1',
              displayName: 'GP1',
              isHuman: true,
              treasury: treasury,
            ),
          ],
          minorNations: const [
            MinorNation(id: 'minor1', displayName: 'Minor 1'),
          ],
          diplomacyRelations: [
            DiplomacyRelation(
              factionId1: 'gp1',
              factionId2: 'minor1',
              state: relationState,
              score: relationScore,
            ),
          ],
          overtureStates: [
            OvertureState(
              gpId: 'gp1',
              targetId: 'minor1',
              stage: overtureStage,
              sinceTurn: 0,
            ),
          ],
        );
      }

      test('declareWar rejected when already at war', () {
        final game = _gpMinorBaseGame(relationState: RelationState.atWar);
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
        final game = _gpMinorBaseGame(relationState: RelationState.atPeace);
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
        final game = _gpMinorBaseGame(
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

      test('establishOverture consulate rejected when treasury too low', () {
        final game = _gpMinorBaseGame(
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
        final game = _gpMinorBaseGame(
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

      test(
        'establishOverture second order for same faction in same turn rejected',
        () {
          final game = _gpMinorBaseGame(
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
            contains(
              'Already have an Establish Overture order for this faction this turn',
            ),
          );
        },
      );

      test('grantAid requires embassy and sufficient treasury', () {
        final game = _gpMinorBaseGame(
          relationState: RelationState.atPeace,
          overtureStage: OvertureStage.tradeConsulate,
          treasury: 50,
        );
        // No embassy yet: should be rejected.
        final noEmbassy = OrderEngine().addDiplomaticOrderWithContext(
          game,
          emptyTopology,
          'gp1',
          const DiplomaticOrder(
            type: DiplomaticOrderType.grantAid,
            targetFactionId: 'minor1',
            amount: 10,
          ),
        );
        expect(noEmbassy.status, OrderValidationStatus.rejected);
        expect(noEmbassy.reason, contains('Embassy required'));

        // With embassy but insufficient treasury.
        final gameWithEmbassy = _gpMinorBaseGame(
          relationState: RelationState.atPeace,
          overtureStage: OvertureStage.embassy,
          treasury: 5,
        );
        final insufficient = OrderEngine().addDiplomaticOrderWithContext(
          gameWithEmbassy,
          emptyTopology,
          'gp1',
          const DiplomaticOrder(
            type: DiplomaticOrderType.grantAid,
            targetFactionId: 'minor1',
            amount: 10,
          ),
        );
        expect(insufficient.status, OrderValidationStatus.rejected);
        expect(insufficient.reason, contains('Insufficient treasury'));
      });

      test(
        'setSubsidy requires consulate or embassy and sufficient treasury',
        () {
          final gameNoOverture = _gpMinorBaseGame(
            relationState: RelationState.atPeace,
            overtureStage: OvertureStage.none,
            treasury: 100,
          );
          final noConsulate = OrderEngine().addDiplomaticOrderWithContext(
            gameNoOverture,
            emptyTopology,
            'gp1',
            const DiplomaticOrder(
              type: DiplomaticOrderType.setSubsidy,
              targetFactionId: 'minor1',
              amount: 50,
            ),
          );
          expect(noConsulate.status, OrderValidationStatus.rejected);
          expect(noConsulate.reason, contains('Consulate or Embassy required'));

          final gameLowTreasury = _gpMinorBaseGame(
            relationState: RelationState.atPeace,
            overtureStage: OvertureStage.tradeConsulate,
            treasury: 10,
          );
          final insufficient = OrderEngine().addDiplomaticOrderWithContext(
            gameLowTreasury,
            emptyTopology,
            'gp1',
            const DiplomaticOrder(
              type: DiplomaticOrderType.setSubsidy,
              targetFactionId: 'minor1',
              amount: 50,
            ),
          );
          expect(insufficient.status, OrderValidationStatus.rejected);
          expect(insufficient.reason, contains('Insufficient treasury'));
        },
      );
    });
  });
}
