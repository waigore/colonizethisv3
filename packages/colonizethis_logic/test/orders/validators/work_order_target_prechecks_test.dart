import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_logic/src/orders/validators/work_order_target_prechecks.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

void main() {
  group('workOrderTargetPrechecks', () {
    test('registers expected work targets', () {
      expect(workOrderTargetPrechecks.keys, contains('upgrade_town'));
      expect(workOrderTargetPrechecks.keys, contains(kWorkTargetStealTech));
      expect(workOrderTargetPrechecks.keys, contains(kWorkTargetCounterSpy));
      expect(workOrderTargetPrechecks.keys, contains(kWorkTargetPurchaseLand));
      expect(workOrderTargetPrechecks.keys, contains('build_improvement'));
      expect(workOrderTargetPrechecks.length, 5);
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
        target: 'build_road',
        targetTileKey: tileKey,
      );
      expect(
        runWorkOrderTargetPrecheck(ctx, order, provinceId, 'p1', 'Builder'),
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
        target: 'upgrade_town',
        targetTileKey: '$provinceId|0|0',
      );
      final r = runWorkOrderTargetPrecheck(
        ctx,
        order,
        provinceId,
        'p1',
        'Builder',
      );
      expect(r, isNotNull);
      expect(r!.status, OrderValidationStatus.rejected);
      expect(r.reason, contains('National Bureaucracy'));
    });

    test('precheckStealTech rejects when no rival GP at target capital', () {
      const ow = 'oldWorld';
      const p1Capital = '$ow|P1';
      const p2Province = '$ow|P2';
      final game = Game(
        id: 'g',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
          oldWorld: RegionData(
            provinces: [
              Province(id: p1Capital, regionId: ow, ownerId: 'p1'),
              Province(id: p2Province, regionId: ow, ownerId: 'p2'),
            ],
          ),
          newWorld: const RegionData(),
          tileKeysByRegionAndProvince: const {},
        ),
        players: [
          Player(
            id: 'p1',
            displayName: 'P1',
            isHuman: true,
            capitalProvinceId: p1Capital,
            techUnlocked: const {'a': true},
          ),
          Player(
            id: 'p2',
            displayName: 'P2',
            isHuman: true,
            capitalProvinceId: p1Capital,
            techUnlocked: const {'a': true, 'b': true},
          ),
        ],
      );
      final p1 = game.players.first;
      final ctx = WorkOrderTargetPrecheckContext(
        game: game,
        player: p1,
        playerId: 'p1',
        treasury: 0,
        civilianEmbassyWorkAllowed: (_, _) => false,
      );
      final order = WorkOrder(
        unitId: 'spy1',
        target: kWorkTargetStealTech,
        targetTileKey: '$p2Province|0|0',
      );
      final r = runWorkOrderTargetPrecheck(ctx, order, p2Province, 'p2', 'Spy');
      expect(r, isNotNull);
      expect(r!.status, OrderValidationStatus.rejected);
      expect(r.reason, contains('Great Power capital'));
    });

    test(
      'kWorkTargetsSkippingDefaultForeignProvinceCheck lists dedicated targets',
      () {
        expect(
          kWorkTargetsSkippingDefaultForeignProvinceCheck,
          equals({
            kWorkTargetStealTech,
            kWorkTargetCounterSpy,
            kWorkTargetPurchaseLand,
            'build_improvement',
          }),
        );
      },
    );
  });
}
