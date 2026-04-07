import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

void main() {
  group('OrderEngine', () {
    group('validateDiplomatic', () {
      final emptyTopology = MapTopology(nodes: const [], edges: const []);

      Game gpMinorBaseGame({
        RelationState relationState = RelationState.atPeace,
        int relationScore = 50,
        OvertureStage overtureStage = OvertureStage.none,
        int treasury = 5000,
        Map<String, bool>? techUnlocked,
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
              techUnlocked: techUnlocked ?? const {'diplomatic_expertise': true},
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

      test(
        'establishOverture second order for same faction in same turn rejected',
        () {
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
            contains(
              'Already have a diplomatic order for this faction this turn',
            ),
          );
        },
      );

      test(
        'second diplomatic order to same target different type is rejected',
        () {
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
        },
      );

      test('grantAid requires embassy and sufficient treasury', () {
        final game = gpMinorBaseGame(
          relationState: RelationState.atPeace,
          overtureStage: OvertureStage.tradeConsulate,
          treasury: 5000,
        );
        // No embassy yet: should be rejected (amount is valid £1000).
        final noEmbassy = OrderEngine().addDiplomaticOrderWithContext(
          game,
          emptyTopology,
          'gp1',
          const DiplomaticOrder(
            type: DiplomaticOrderType.grantAid,
            targetFactionId: 'minor1',
            amount: 1000,
          ),
        );
        expect(noEmbassy.status, OrderValidationStatus.rejected);
        expect(noEmbassy.reason, contains('Embassy required'));

        // With embassy but insufficient treasury.
        final gameWithEmbassy = gpMinorBaseGame(
          relationState: RelationState.atPeace,
          overtureStage: OvertureStage.embassy,
          treasury: 500,
        );
        final insufficient = OrderEngine().addDiplomaticOrderWithContext(
          gameWithEmbassy,
          emptyTopology,
          'gp1',
          const DiplomaticOrder(
            type: DiplomaticOrderType.grantAid,
            targetFactionId: 'minor1',
            amount: 1000,
          ),
        );
        expect(insufficient.status, OrderValidationStatus.rejected);
        expect(insufficient.reason, contains('Insufficient treasury'));
      });

      test('grantAid rejects amounts not a multiple of £1000', () {
        final game = gpMinorBaseGame(
          relationState: RelationState.atPeace,
          overtureStage: OvertureStage.embassy,
          treasury: 5000,
        );
        final bad = OrderEngine().addDiplomaticOrderWithContext(
          game,
          emptyTopology,
          'gp1',
          const DiplomaticOrder(
            type: DiplomaticOrderType.grantAid,
            targetFactionId: 'minor1',
            amount: 1500,
          ),
        );
        expect(bad.status, OrderValidationStatus.rejected);
        expect(bad.reason, contains('multiple'));
      });

      test('grantAid then setSubsidy toward same target both accepted', () {
        final game = gpMinorBaseGame(
          relationState: RelationState.atPeace,
          overtureStage: OvertureStage.embassy,
          treasury: 5000,
        );
        final eng = OrderEngine();
        final g = eng.addDiplomaticOrderWithContext(
          game,
          emptyTopology,
          'gp1',
          const DiplomaticOrder(
            type: DiplomaticOrderType.grantAid,
            targetFactionId: 'minor1',
            amount: 1000,
          ),
        );
        expect(g.status, OrderValidationStatus.accepted);
        final s = eng.addDiplomaticOrderWithContext(
          game,
          emptyTopology,
          'gp1',
          const DiplomaticOrder(
            type: DiplomaticOrderType.setSubsidy,
            targetFactionId: 'minor1',
            amount: 1000,
          ),
        );
        expect(s.status, OrderValidationStatus.accepted);
      });

      test(
        'setSubsidy requires consulate or embassy and sufficient treasury',
        () {
          final gameNoOverture = gpMinorBaseGame(
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
              amount: 100,
            ),
          );
          expect(noConsulate.status, OrderValidationStatus.rejected);
          expect(noConsulate.reason, contains('Consulate or Embassy required'));

          final gameLowTreasury = gpMinorBaseGame(
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
              amount: 500,
            ),
          );
          expect(insufficient.status, OrderValidationStatus.rejected);
          expect(insufficient.reason, contains('Insufficient treasury'));
        },
      );

      test('grantAid rejects amount not a multiple of 1000', () {
        final game = gpMinorBaseGame(
          relationState: RelationState.atPeace,
          overtureStage: OvertureStage.embassy,
          treasury: 5000,
        );
        final engine = OrderEngine();
        final r = engine.addDiplomaticOrderWithContext(
          game,
          emptyTopology,
          'gp1',
          const DiplomaticOrder(
            type: DiplomaticOrderType.grantAid,
            targetFactionId: 'minor1',
            amount: 1500,
          ),
        );
        expect(r.status, OrderValidationStatus.rejected);
        expect(r.reason, contains('multiple'));
      });

      test('setSubsidy rejects amount not a multiple of 100', () {
        final game = gpMinorBaseGame(
          relationState: RelationState.atPeace,
          overtureStage: OvertureStage.tradeConsulate,
          treasury: 5000,
        );
        final engine = OrderEngine();
        final r = engine.addDiplomaticOrderWithContext(
          game,
          emptyTopology,
          'gp1',
          const DiplomaticOrder(
            type: DiplomaticOrderType.setSubsidy,
            targetFactionId: 'minor1',
            amount: 150,
          ),
        );
        expect(r.status, OrderValidationStatus.rejected);
        expect(r.reason, contains('multiple'));
      });

      test('grantAid and setSubsidy toward same target accepted in one turn', () {
        final game = gpMinorBaseGame(
          relationState: RelationState.atPeace,
          overtureStage: OvertureStage.embassy,
          treasury: 5000,
        );
        final engine = OrderEngine();
        final g = engine.addDiplomaticOrderWithContext(
          game,
          emptyTopology,
          'gp1',
          const DiplomaticOrder(
            type: DiplomaticOrderType.grantAid,
            targetFactionId: 'minor1',
            amount: 1000,
          ),
        );
        expect(g.status, OrderValidationStatus.accepted);
        final s = engine.addDiplomaticOrderWithContext(
          game,
          emptyTopology,
          'gp1',
          const DiplomaticOrder(
            type: DiplomaticOrderType.setSubsidy,
            targetFactionId: 'minor1',
            amount: 1000,
          ),
        );
        expect(s.status, OrderValidationStatus.accepted);
      });

      test('second grantAid toward same target rejected', () {
        final game = gpMinorBaseGame(
          relationState: RelationState.atPeace,
          overtureStage: OvertureStage.embassy,
          treasury: 5000,
        );
        final engine = OrderEngine();
        engine.addDiplomaticOrderWithContext(
          game,
          emptyTopology,
          'gp1',
          const DiplomaticOrder(
            type: DiplomaticOrderType.grantAid,
            targetFactionId: 'minor1',
            amount: 1000,
          ),
        );
        final second = engine.addDiplomaticOrderWithContext(
          game,
          emptyTopology,
          'gp1',
          const DiplomaticOrder(
            type: DiplomaticOrderType.grantAid,
            targetFactionId: 'minor1',
            amount: 1000,
          ),
        );
        expect(second.status, OrderValidationStatus.rejected);
      });

      test('declareWar then grantAid toward same target rejected', () {
        final game = gpMinorBaseGame(
          relationState: RelationState.atPeace,
          overtureStage: OvertureStage.embassy,
          treasury: 5000,
        );
        final engine = OrderEngine();
        engine.addDiplomaticOrderWithContext(
          game,
          emptyTopology,
          'gp1',
          const DiplomaticOrder(
            type: DiplomaticOrderType.declareWar,
            targetFactionId: 'minor1',
          ),
        );
        final g = engine.addDiplomaticOrderWithContext(
          game,
          emptyTopology,
          'gp1',
          const DiplomaticOrder(
            type: DiplomaticOrderType.grantAid,
            targetFactionId: 'minor1',
            amount: 1000,
          ),
        );
        expect(g.status, OrderValidationStatus.rejected);
      });
    });
  });
}
