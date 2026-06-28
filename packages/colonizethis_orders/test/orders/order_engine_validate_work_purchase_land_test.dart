import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'order_engine_purchase_land_test_support.dart';

void main() {
  group('OrderEngine', () {
    group('validateWork (purchase_land)', () {
      final topology = PurchaseLandTestFixture.topology();

      test('rejects purchase_land when no embassy with Minor', () {
        final game = PurchaseLandTestFixture.baseGame(treasury: 500);
        final engine = OrderEngine();
        engine.addWorkOrder(
          'p1',
          WorkOrder(
            unitId: 'merchant1',
            target: kWorkTargetPurchaseLand,
            targetTileKey: PurchaseLandTestFixture.tileKey,
          ),
        );
        final results = engine.validatePlayerOrdersWithContext(
          game,
          topology,
          'p1',
        );
        expect(results.single.status, OrderValidationStatus.rejected);
        expect(results.single.reason, contains('embassy'));
      });

      test('rejects purchase_land when at war with faction', () {
        final game = PurchaseLandTestFixture.baseGame(
          treasury: 500,
          overtureStates: [
            const OvertureState(
              gpId: 'p1',
              targetId: 'minor1',
              stage: OvertureStage.embassy,
              sinceTurn: 0,
            ),
          ],
          diplomacyRelations: [
            const DiplomacyRelation(
              factionId1: 'p1',
              factionId2: 'minor1',
              state: RelationState.atWar,
            ),
          ],
        );
        final engine = OrderEngine();
        engine.addWorkOrder(
          'p1',
          WorkOrder(
            unitId: 'merchant1',
            target: kWorkTargetPurchaseLand,
            targetTileKey: PurchaseLandTestFixture.tileKey,
          ),
        );
        final results = engine.validatePlayerOrdersWithContext(
          game,
          topology,
          'p1',
        );
        expect(results.single.status, OrderValidationStatus.rejected);
        expect(results.single.reason, contains('war'));
      });

      test('rejects purchase_land when insufficient treasury', () {
        const cost = 15 * 10; // grain default base 10
        final game = PurchaseLandTestFixture.baseGame(
          treasury: cost - 1,
          overtureStates: [
            const OvertureState(
              gpId: 'p1',
              targetId: 'minor1',
              stage: OvertureStage.embassy,
              sinceTurn: 0,
            ),
          ],
        );
        final engine = OrderEngine();
        engine.addWorkOrder(
          'p1',
          WorkOrder(
            unitId: 'merchant1',
            target: kWorkTargetPurchaseLand,
            targetTileKey: PurchaseLandTestFixture.tileKey,
          ),
        );
        final results = engine.validatePlayerOrdersWithContext(
          game,
          topology,
          'p1',
        );
        expect(results.single.status, OrderValidationStatus.rejected);
        expect(results.single.reason, contains('Insufficient treasury'));
      });

      test('rejects purchase_land when tile has no resource', () {
        final game = PurchaseLandTestFixture.baseGame(
          treasury: 500,
          overtureStates: [
            const OvertureState(
              gpId: 'p1',
              targetId: 'minor1',
              stage: OvertureStage.embassy,
              sinceTurn: 0,
            ),
          ],
          resourceByTileKey: {},
        );
        final engine = OrderEngine();
        engine.addWorkOrder(
          'p1',
          WorkOrder(
            unitId: 'merchant1',
            target: kWorkTargetPurchaseLand,
            targetTileKey: PurchaseLandTestFixture.tileKey,
          ),
        );
        final results = engine.validatePlayerOrdersWithContext(
          game,
          topology,
          'p1',
        );
        expect(results.single.status, OrderValidationStatus.rejected);
        expect(results.single.reason, contains('no resource'));
      });

      test('rejects purchase_land when mineral tile not prospected', () {
        final tk = PurchaseLandTestFixture.tileKey;
        final game = PurchaseLandTestFixture.baseGame(
          treasury: 500,
          overtureStates: [
            const OvertureState(
              gpId: 'p1',
              targetId: 'minor1',
              stage: OvertureStage.embassy,
              sinceTurn: 0,
            ),
          ],
          resourceByTileKey: {tk: 'iron'},
          playerProspectedTiles: {}, // p1 has not prospected this tile
        );
        final engine = OrderEngine();
        engine.addWorkOrder(
          'p1',
          WorkOrder(
            unitId: 'merchant1',
            target: kWorkTargetPurchaseLand,
            targetTileKey: PurchaseLandTestFixture.tileKey,
          ),
        );
        final results = engine.validatePlayerOrdersWithContext(
          game,
          topology,
          'p1',
        );
        expect(results.single.status, OrderValidationStatus.rejected);
        expect(results.single.reason, contains('prospected'));
      });

      test(
        'accepts purchase_land with embassy, at peace, sufficient treasury, tile with resource',
        () {
          final game = PurchaseLandTestFixture.baseGame(
            treasury: 500,
            overtureStates: [
              const OvertureState(
                gpId: 'p1',
                targetId: 'minor1',
                stage: OvertureStage.embassy,
                sinceTurn: 0,
              ),
            ],
          );
          final engine = OrderEngine();
          engine.addWorkOrder(
            'p1',
            WorkOrder(
              unitId: 'merchant1',
              target: kWorkTargetPurchaseLand,
              targetTileKey: PurchaseLandTestFixture.tileKey,
            ),
          );
          final results = engine.validatePlayerOrdersWithContext(
            game,
            topology,
            'p1',
          );
          expect(results.single.status, OrderValidationStatus.accepted);
        },
      );
    });
  });
}
