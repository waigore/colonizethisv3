import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/src/constants.dart';
import 'package:colonizethis_logic/src/orders/orders_application_context.dart';
import 'package:colonizethis_logic/src/orders/work_handlers/counter_spy_work_handler.dart';
import 'package:colonizethis_logic/src/orders/work_handlers/prospect_work_handler.dart';
import 'package:colonizethis_logic/src/orders/work_handlers/standard_work_handler.dart';
import 'package:colonizethis_logic/src/orders/work_handlers/steal_tech_work_handler.dart';
import 'package:colonizethis_logic/src/orders/work_handlers/work_order_handler.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

void main() {
  group('StealTechWorkOrderHandler', () {
    test('supports only steal_tech', () {
      const h = StealTechWorkOrderHandler();
      expect(h.supports(kWorkTargetStealTech), isTrue);
      expect(h.supports(kWorkTargetCounterSpy), isFalse);
    });

    test('tryApply assigns steal_tech work for spy unit', () {
      const ow = 'oldWorld';
      const provinceId = '$ow|P1';
      const tileKey = '$ow|P1|0|0';
      final spy = Unit(
        id: 'spy1',
        type: kUnitTypeSpy,
        ownerId: 'p1',
        locationProvinceId: provinceId,
        tileKey: tileKey,
      );
      final game = Game(
        id: 'g',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(
            provinces: [Province(id: provinceId, regionId: ow, ownerId: 'p1')],
            units: [spy],
          ),
          newWorld: const RegionData(),
        ),
        players: const [Player(id: 'p1', displayName: 'P1', isHuman: true)],
      );
      final work = WorkOrderState(
        oldUnitsById: {spy.id: spy},
        newUnitsById: const {},
        tileState: game.worldState.tileState,
        visibilityByTile: const {},
        portsByProvinceSeaboard: const {},
        purchasedTilesByTileKey: const {},
        oldProvinces: game.worldState.oldWorld.provinces,
        newProvinces: const [],
      );
      final state = BuildWorkState(
        game: game,
        buildOrders: const {},
        workOrders: const {},
        work: work,
      );
      final context = WorkOrderExecutionContext(
        state: state,
        player: game.players.single,
      );
      const handler = StealTechWorkOrderHandler();
      const order = WorkOrder(
        unitId: 'spy1',
        target: kWorkTargetStealTech,
        targetTileKey: tileKey,
      );
      expect(handler.tryApply(context, order, spy, tileKey, true), isTrue);
      final u =
          context.state.work.oldUnitsById['spy1'] ??
          context.state.work.newUnitsById['spy1'];
      expect(u?.currentWork?.workTarget, kWorkTargetStealTech);
    });
  });

  group('CounterSpyWorkOrderHandler', () {
    test('supports only counter_spy', () {
      const h = CounterSpyWorkOrderHandler();
      expect(h.supports(kWorkTargetCounterSpy), isTrue);
      expect(h.supports(kWorkTargetStealTech), isFalse);
    });

    test('tryApply assigns counter_spy work for spy unit', () {
      const ow = 'oldWorld';
      const provinceId = '$ow|P1';
      const tileKey = '$ow|P1|0|0';
      final spy = Unit(
        id: 'spy2',
        type: kUnitTypeSpy,
        ownerId: 'p1',
        locationProvinceId: provinceId,
        tileKey: tileKey,
      );
      final game = Game(
        id: 'g',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(
            provinces: [Province(id: provinceId, regionId: ow, ownerId: 'p1')],
            units: [spy],
          ),
          newWorld: const RegionData(),
        ),
        players: const [Player(id: 'p1', displayName: 'P1', isHuman: true)],
      );
      final work = WorkOrderState(
        oldUnitsById: {spy.id: spy},
        newUnitsById: const {},
        tileState: game.worldState.tileState,
        visibilityByTile: const {},
        portsByProvinceSeaboard: const {},
        purchasedTilesByTileKey: const {},
        oldProvinces: game.worldState.oldWorld.provinces,
        newProvinces: const [],
      );
      final state = BuildWorkState(
        game: game,
        buildOrders: const {},
        workOrders: const {},
        work: work,
      );
      final context = WorkOrderExecutionContext(
        state: state,
        player: game.players.single,
      );
      const handler = CounterSpyWorkOrderHandler();
      const order = WorkOrder(
        unitId: 'spy2',
        target: kWorkTargetCounterSpy,
        targetTileKey: tileKey,
      );
      expect(handler.tryApply(context, order, spy, tileKey, true), isTrue);
      final u =
          context.state.work.oldUnitsById['spy2'] ??
          context.state.work.newUnitsById['spy2'];
      expect(u?.currentWork?.workTarget, kWorkTargetCounterSpy);
    });
  });

  group('ProspectWorkOrderHandler', () {
    test('supports only prospect', () {
      const h = ProspectWorkOrderHandler();
      expect(h.supports(kWorkTargetProspect), isTrue);
      expect(h.supports(kWorkTargetExplore), isFalse);
    });

    test(
      'tryApplyProspectWorkOrder leaves game unchanged for non-mineral tile',
      () {
        const ow = 'oldWorld';
        const provinceId = '$ow|P1';
        const tileKey = '$ow|P1|0|0';
        final explorer = Unit(
          id: 'ex1',
          type: kUnitTypeExplorer,
          ownerId: 'p1',
          locationProvinceId: provinceId,
          tileKey: tileKey,
        );
        final game = Game(
          id: 'g',
          worldState: WorldState(
            turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
            oldWorld: RegionData(
              provinces: [
                Province(id: provinceId, regionId: ow, ownerId: 'p1'),
              ],
              units: [explorer],
            ),
            newWorld: const RegionData(),
            resourceByTileKey: const {tileKey: 'grain'},
          ),
          players: const [Player(id: 'p1', displayName: 'P1', isHuman: true)],
        );
        final next = tryApplyProspectWorkOrder(
          game: game,
          tileMapByRegion: null,
          player: game.players.single,
          unit: explorer,
          targetTileKey: tileKey,
          updateUnit: (_, __) => fail('should not update unit'),
        );
        expect(identical(next, game), isTrue);
        expect(
          next.worldState.playerProspectedTiles['p1'] ?? const {},
          isEmpty,
        );
      },
    );
  });

  group('applyStandardWorkOrder', () {
    test('returns false when unit already has currentWork', () {
      const tileKey = 'oldWorld|P1|0|0';
      final unit = Unit(
        id: 'b1',
        type: kUnitTypeBuilder,
        ownerId: 'p1',
        locationProvinceId: 'oldWorld|P1',
        tileKey: tileKey,
        currentWork: const CurrentWork(
          workTarget: kWorkTargetBuildRoad,
          tileKey: tileKey,
          totalTurns: 2,
          remainingTurns: 1,
        ),
      );
      final applied = applyStandardWorkOrder(
        order: const WorkOrder(
          unitId: 'b1',
          target: kWorkTargetBuildImprovement,
          targetTileKey: tileKey,
        ),
        unit: unit,
        targetTileKey: tileKey,
        hasValidTarget: true,
        orderTarget: kWorkTargetBuildImprovement,
        tileState: TileMapState(),
        provinceById: (_) => null,
        canAffordMaterialCost: (_) => true,
        deductMaterialCost: (_) {},
        updateUnit: (_, __) => fail('no update'),
      );
      expect(applied, isFalse);
    });
  });

  group('shouldSkipBuildFortForMissingTech', () {
    test('skips fort level 2 when Mine Engineering not unlocked', () {
      final province = Province(
        id: 'oldWorld|P1',
        regionId: 'oldWorld',
        ownerId: 'p1',
        fortLevel: 1,
      );
      expect(
        shouldSkipBuildFortForMissingTech(
          province: province,
          techUnlocked: const {},
        ),
        isTrue,
      );
    });
  });

  group('RemainingStandardBuildTargetsWorkOrderHandler', () {
    test('supports build_road and build_fort among others', () {
      const h = RemainingStandardBuildTargetsWorkOrderHandler();
      expect(h.supports(kWorkTargetBuildRoad), isTrue);
      expect(h.supports(kWorkTargetBuildFort), isTrue);
      expect(h.supports(kWorkTargetBuildImprovement), isFalse);
    });
  });

  group('BuildImprovementWorkOrderHandler', () {
    test('supports only build_improvement', () {
      const h = BuildImprovementWorkOrderHandler();
      expect(h.supports(kWorkTargetBuildImprovement), isTrue);
      expect(h.supports(kWorkTargetBuildRoad), isFalse);
    });
  });
}
