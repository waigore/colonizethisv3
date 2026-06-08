import 'package:colonizethis_logic/src/constants.dart';
import 'package:colonizethis_orders/src/orders/orders_application_context.dart';
import 'package:colonizethis_orders/src/orders/work_handlers/simple_work_order_handler.dart';
import 'package:colonizethis_orders/src/orders/work_handlers/standard_work_handler.dart';
import 'package:colonizethis_orders/src/orders/work_handlers/work_order_handler.dart';
import 'package:colonizethis_orders/src/orders/work_handlers/work_order_handler_registry.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import '../../test_fixtures.dart';

void main() {
  group('SimpleWorkOrderHandler steal_tech', () {
    test('supports only steal_tech', () {
      final h = stealTechWorkOrderHandler;
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
      final game = TestFixtures.minimalGame(
        oldWorld: RegionData(
          provinces: [Province(id: provinceId, regionId: ow, ownerId: 'p1')],
          units: [spy],
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
      final handler = stealTechWorkOrderHandler;
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

  group('SimpleWorkOrderHandler counter_spy', () {
    test('supports only counter_spy', () {
      final h = counterSpyWorkOrderHandler;
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
      final game = TestFixtures.minimalGame(
        oldWorld: RegionData(
          provinces: [Province(id: provinceId, regionId: ow, ownerId: 'p1')],
          units: [spy],
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
      final handler = counterSpyWorkOrderHandler;
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

  group('SimpleWorkOrderHandler prospect', () {
    test('supports only prospect', () {
      final h = prospectWorkOrderHandler;
      expect(h.supports(kWorkTargetProspect), isTrue);
      expect(h.supports(kWorkTargetExplore), isFalse);
    });

    test('tryApply returns false for non-mineral tile', () {
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
      final game = TestFixtures.minimalGame(
        oldWorld: RegionData(
          provinces: [Province(id: provinceId, regionId: ow, ownerId: 'p1')],
          units: [explorer],
        ),
        resourceByTileKey: const {tileKey: 'grain'},
        players: const [Player(id: 'p1', displayName: 'P1', isHuman: true)],
      );
      final work = WorkOrderState(
        oldUnitsById: {'ex1': explorer},
        newUnitsById: const {},
        tileState: game.worldState.tileState,
        visibilityByTile: const {},
        portsByProvinceSeaboard: const {},
        purchasedTilesByTileKey: const {},
        oldProvinces: List<Province>.from(game.worldState.oldWorld.provinces),
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
      final handler = prospectWorkOrderHandler;
      const order = WorkOrder(
        unitId: 'ex1',
        target: kWorkTargetProspect,
        targetTileKey: tileKey,
      );
      expect(
        handler.tryApply(context, order, explorer, tileKey, true),
        isFalse,
      );
      expect(
        context.state.game.worldState.playerProspectedTiles['p1'] ??
            const <String>{},
        isEmpty,
      );
    });
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
      final game = Game(
        id: 'g',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
          oldWorld: const RegionData(),
          newWorld: const RegionData(),
        ),
        players: const [Player(id: 'p1', displayName: 'P1', isHuman: true)],
      );
      final applied = applyStandardWorkOrder(
        game: game,
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
        provincesById: const {},
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

  group('StandardBuildWorkOrderHandler', () {
    test('each standard build handler supports only its target', () {
      expect(standardBuildRoadWorkOrderHandler.supports(kWorkTargetBuildRoad), isTrue);
      expect(standardBuildRoadWorkOrderHandler.supports(kWorkTargetBuildFort), isFalse);
      expect(standardBuildFortWorkOrderHandler.supports(kWorkTargetBuildFort), isTrue);
      expect(
        standardBuildImprovementWorkOrderHandler.supports(
          kWorkTargetBuildImprovement,
        ),
        isTrue,
      );
      expect(
        standardBuildImprovementWorkOrderHandler.supports(kWorkTargetBuildRoad),
        isFalse,
      );
    });
  });

  group('workOrderHandlersByTarget', () {
    test('maps every standard and simple work target to a handler', () {
      expect(
        workOrderHandlersByTarget.keys,
        containsAll(<String>[
          kWorkTargetPurchaseLand,
          kWorkTargetStealTech,
          kWorkTargetCounterSpy,
          kWorkTargetProspect,
          kWorkTargetExplore,
          kWorkTargetBuildImprovement,
          kWorkTargetBuildRoad,
          kWorkTargetBuildPort,
          kWorkTargetUpgradeTown,
          kWorkTargetBuildFort,
          kWorkTargetBuildRail,
        ]),
      );
    });
  });

  group('SimpleWorkOrderHandler', () {
    test('singleton handlers do not cross-support other simple targets', () {
      expect(
        stealTechWorkOrderHandler.supports(kWorkTargetCounterSpy),
        isFalse,
      );
      expect(
        counterSpyWorkOrderHandler.supports(kWorkTargetStealTech),
        isFalse,
      );
      expect(
        prospectWorkOrderHandler.supports(kWorkTargetPurchaseLand),
        isFalse,
      );
      expect(
        purchaseLandWorkOrderHandler.supports(kWorkTargetProspect),
        isFalse,
      );
      expect(
        exploreWorkOrderHandler.supports(kWorkTargetProspect),
        isFalse,
      );
      expect(
        prospectWorkOrderHandler.supports(kWorkTargetExplore),
        isFalse,
      );
    });
  });
}
