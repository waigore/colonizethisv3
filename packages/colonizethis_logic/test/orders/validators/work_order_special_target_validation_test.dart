import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/src/constants.dart';
import 'package:colonizethis_logic/src/orders/order_validation_result.dart';
import 'package:colonizethis_logic/src/orders/validators/work_order_special_target_validation.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

void main() {
  group('workOrderSpecialTargetChecks', () {
    test('registers steal_tech, counter_spy, and purchase_land only', () {
      expect(
        workOrderSpecialTargetChecks.keys.toSet(),
        {
          kWorkTargetStealTech,
          kWorkTargetCounterSpy,
          kWorkTargetPurchaseLand,
        },
      );
    });

    test('unknown work target is not in the map (falls through to generic rules)', () {
      expect(workOrderSpecialTargetChecks['build_road'], isNull);
      expect(workOrderSpecialTargetChecks['unknown_target'], isNull);
    });
  });

  group('validateStealTechWorkTarget', () {
    const ow = 'oldWorld';
    final p1 = Player(
      id: 'p1',
      displayName: 'P1',
      isHuman: true,
      capitalProvinceId: '$ow|P1',
      stockpile: const Stockpile(),
      treasury: 0,
    );
    final emptyGame = Game(
      id: 'g1',
      worldState: WorldState(
        turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
        oldWorld: const RegionData(),
        newWorld: const RegionData(),
      ),
      players: [p1],
    );

    test('rejects when targetProvinceId is null', () {
      const o = WorkOrder(
        unitId: 'u1',
        target: kWorkTargetStealTech,
        targetTileKey: '$ow|P2|0|0',
      );
      final ctx = WorkOrderSpecialTargetContext(
        game: emptyGame,
        player: p1,
        playerId: 'p1',
        treasury: 0,
      );
      final r = validateStealTechWorkTarget(ctx, o, null, null);
      expect(r?.status, OrderValidationStatus.rejected);
      expect(r?.reason, contains('Invalid target'));
    });

    test('rejects when no other GP holds that capital province', () {
      const o = WorkOrder(
        unitId: 'u1',
        target: kWorkTargetStealTech,
        targetTileKey: '$ow|M1|0|0',
      );
      final ctx = WorkOrderSpecialTargetContext(
        game: emptyGame,
        player: p1,
        playerId: 'p1',
        treasury: 0,
      );
      final r = validateStealTechWorkTarget(ctx, o, '$ow|M1', null);
      expect(r?.status, OrderValidationStatus.rejected);
      expect(r?.reason, contains('Great Power capital'));
    });
  });

  group('validateCounterSpyWorkTarget', () {
    const ow = 'oldWorld';
    final p1 = Player(
      id: 'p1',
      displayName: 'P1',
      isHuman: true,
      capitalProvinceId: '$ow|P1',
      stockpile: const Stockpile(),
      treasury: 0,
    );
    final game = Game(
      id: 'g1',
      worldState: WorldState(
        turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
        oldWorld: const RegionData(),
        newWorld: const RegionData(),
      ),
      players: [p1],
    );

    test('rejects when province is not owned by submitting player', () {
      const o = WorkOrder(
        unitId: 'u1',
        target: kWorkTargetCounterSpy,
        targetTileKey: '$ow|P2|0|0',
      );
      final ctx = WorkOrderSpecialTargetContext(
        game: game,
        player: p1,
        playerId: 'p1',
        treasury: 0,
      );
      final r = validateCounterSpyWorkTarget(ctx, o, null, 'p2');
      expect(r?.status, OrderValidationStatus.rejected);
      expect(r?.reason, contains('your own province'));
    });

    test('returns null when province owner matches player', () {
      const o = WorkOrder(
        unitId: 'u1',
        target: kWorkTargetCounterSpy,
        targetTileKey: '$ow|P1|0|0',
      );
      final ctx = WorkOrderSpecialTargetContext(
        game: game,
        player: p1,
        playerId: 'p1',
        treasury: 0,
      );
      expect(validateCounterSpyWorkTarget(ctx, o, null, 'p1'), isNull);
    });
  });

  group('validatePurchaseLandWorkTarget', () {
    const ow = 'oldWorld';
    const minorProvinceId = '$ow|M1';
    const tileKey = '$ow|M1|0|0';
    final p1 = Player(
      id: 'p1',
      displayName: 'P1',
      isHuman: true,
      capitalProvinceId: '$ow|P1',
      stockpile: const Stockpile(),
      treasury: 500,
      techUnlocked: {'merchant_companies': true},
    );
    final game = Game(
      id: 'g1',
      worldState: WorldState(
        turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
        oldWorld: RegionData(
          provinces: [
            Province(id: '$ow|P1', regionId: ow, ownerId: 'p1'),
            Province(id: minorProvinceId, regionId: ow, ownerId: 'minor1'),
          ],
          units: const [],
        ),
        newWorld: const RegionData(),
        resourceByTileKey: const {tileKey: 'grain'},
        playerProspectedTiles: const {},
        purchasedTilesByTileKey: const {},
      ),
      players: [p1],
      minorNations: const [
        MinorNation(id: 'minor1', displayName: 'Minor 1'),
      ],
      overtureStates: const [],
      diplomacyRelations: const [],
    );

    test('rejects when there is no embassy with Minor/Tribe owner', () {
      const o = WorkOrder(
        unitId: 'm1',
        target: kWorkTargetPurchaseLand,
        targetTileKey: tileKey,
      );
      final ctx = WorkOrderSpecialTargetContext(
        game: game,
        player: p1,
        playerId: 'p1',
        treasury: 500,
      );
      final r = validatePurchaseLandWorkTarget(ctx, o, null, 'minor1');
      expect(r?.status, OrderValidationStatus.rejected);
      expect(r?.reason, contains('embassy'));
    });
  });
}
