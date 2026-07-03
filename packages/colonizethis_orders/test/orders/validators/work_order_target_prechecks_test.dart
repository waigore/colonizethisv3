import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_orders/src/orders/validators/work_order_target_prechecks.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import '../order_engine_purchase_land_test_support.dart';

void main() {
  group('workOrderTargetPrechecks', () {
    test('registers expected work targets', () {
      expect(workOrderTargetPrechecks.keys, contains(kWorkTargetUpgradeTown));
      expect(workOrderTargetPrechecks.keys, contains(kWorkTargetCounterSpy));
      expect(workOrderTargetPrechecks.keys, contains(kWorkTargetPurchaseLand));
      expect(workOrderTargetPrechecks.keys, contains(kWorkTargetBuildImprovement));
      expect(workOrderTargetPrechecks.length, 4);
    });

    test('runWorkOrderTargetPrecheck returns null for unregistered target', () {
      const ow = 'oldWorld';
      const provinceId = '$ow|P1';
      const tileKey = '$provinceId|0|0';
      final game = Game(
        id: 'g',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
          oldWorld: RegionData(
            provinces: [Province(id: provinceId, regionId: ow, ownerId: 'p1')],
          ),
          newWorld: const RegionData(),
          tileKeysByRegionAndProvince: const {},
        ),
        players: [
          Player(
            id: 'p1',
            displayName: 'P1',
            isHuman: true,
            capitalProvinceId: provinceId,
          ),
        ],
      );
      final player = game.players.single;
      final ctx = WorkOrderTargetPrecheckContext(
        game: game,
        player: player,
        playerId: 'p1',
        treasury: 0,
        civilianEmbassyWorkAllowed: (_, _) => false,
      );
      final order = WorkOrder(
        unitId: 'u1',
        target: kWorkTargetBuildRoad,
        targetTileKey: tileKey,
      );
      expect(
        runWorkOrderTargetPrecheck(ctx, order, provinceId, 'p1', kUnitTypeBuilder),
        isNull,
      );
    });

    test('precheckUpgradeTown rejects without National Bureaucracy', () {
      const ow = 'oldWorld';
      const provinceId = '$ow|P1';
      final game = Game(
        id: 'g',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
          oldWorld: RegionData(
            provinces: [Province(id: provinceId, regionId: ow, ownerId: 'p1')],
          ),
          newWorld: const RegionData(),
          tileKeysByRegionAndProvince: const {},
        ),
        players: [
          Player(
            id: 'p1',
            displayName: 'P1',
            isHuman: true,
            capitalProvinceId: provinceId,
            techUnlocked: const {},
          ),
        ],
      );
      final player = game.players.single;
      final ctx = WorkOrderTargetPrecheckContext(
        game: game,
        player: player,
        playerId: 'p1',
        treasury: 0,
        civilianEmbassyWorkAllowed: (_, _) => false,
      );
      final order = WorkOrder(
        unitId: 'b1',
        target: kWorkTargetUpgradeTown,
        targetTileKey: '$provinceId|0|0',
      );
      final r = runWorkOrderTargetPrecheck(
        ctx,
        order,
        provinceId,
        'p1',
        kUnitTypeBuilder,
      );
      expect(r, isNotNull);
      expect(r!.status, OrderValidationStatus.rejected);
      expect(r.reason, contains('National Bureaucracy'));
    });

    test(
      'kWorkTargetsSkippingDefaultForeignProvinceCheck lists dedicated targets',
      () {
        expect(
          kWorkTargetsSkippingDefaultForeignProvinceCheck,
          equals({
            kWorkTargetCounterSpy,
            kWorkTargetPurchaseLand,
            kWorkTargetBuildImprovement,
          }),
        );
      },
    );

    test(
      'precheckPurchaseLand matches with or without DiplomacyFactionMembership '
      '(Refs #2394)',
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
        final player = game.players.single;
        final membership = DiplomacyFactionMembership.from(game);
        WorkOrderTargetPrecheckContext ctx({required bool withSnap}) =>
            WorkOrderTargetPrecheckContext(
              game: game,
              player: player,
              playerId: 'p1',
              treasury: 500,
              civilianEmbassyWorkAllowed: (_, __) => false,
              factionMembership: withSnap ? membership : null,
            );
        final order = WorkOrder(
          unitId: 'merchant1',
          target: kWorkTargetPurchaseLand,
          targetTileKey: PurchaseLandTestFixture.tileKey,
        );
        final withSnap = runWorkOrderTargetPrecheck(
          ctx(withSnap: true),
          order,
          PurchaseLandTestFixture.minorProvinceId,
          'minor1',
          kUnitTypeMerchant,
        );
        final linear = runWorkOrderTargetPrecheck(
          ctx(withSnap: false),
          order,
          PurchaseLandTestFixture.minorProvinceId,
          'minor1',
          kUnitTypeMerchant,
        );
        expect(withSnap, isNull);
        expect(linear, isNull);
      },
    );

    test('precheckBuildImprovement rejects unprospected mineral tile', () {
      const ow = 'oldWorld';
      const provinceId = '$ow|P1';
      const tileKey = '$provinceId|0|0';
      final game = Game(
        id: 'g',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
          oldWorld: RegionData(
            provinces: [Province(id: provinceId, regionId: ow, ownerId: 'p1')],
          ),
          newWorld: const RegionData(),
          resourceByTileKey: {tileKey: 'iron'},
          tileKeysByRegionAndProvince: {
            ow: {provinceId: [tileKey]},
          },
        ),
        players: [
          Player(
            id: 'p1',
            displayName: 'P1',
            isHuman: true,
            capitalProvinceId: provinceId,
            techUnlocked: const {},
          ),
        ],
      );
      final player = game.players.single;
      final ctx = WorkOrderTargetPrecheckContext(
        game: game,
        player: player,
        playerId: 'p1',
        treasury: 0,
        civilianEmbassyWorkAllowed: (_, _) => false,
      );
      final order = WorkOrder(
        unitId: 'b1',
        target: kWorkTargetBuildImprovement,
        targetTileKey: tileKey,
      );
      final r = runWorkOrderTargetPrecheck(
        ctx,
        order,
        provinceId,
        'p1',
        kUnitTypeBuilder,
      );
      expect(r, isNotNull);
      expect(r!.status, OrderValidationStatus.rejected);
      expect(r.reason, contains('prospected'));
    });
  });
}
