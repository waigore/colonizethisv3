// Table-driven remaining work handler scenarios (Refs #3949 wave 3).

import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_orders/src/orders/work_handlers/simple_work_order_handler.dart';
import 'package:colonizethis_orders/src/orders/work_handlers/standard_work_handler.dart';
import 'package:colonizethis_orders/src/orders/work_handlers/work_order_handler_registry.dart';
import 'package:colonizethis_test/test.dart';
import '../scenario_runner.dart';

import 'remaining_work_handlers_fixtures.dart';
// dart format off

void rwhRunSupportsOnlyCounterSpy() {final h = counterSpyWorkOrderHandler; expect(h.supports(kWorkTargetCounterSpy),isTrue); expect(h.supports('steal_tech'),isFalse);}

void rwhRunTryApplyCounterSpy() {final spy = Unit(id: 'spy2',type: kUnitTypeSpy,ownerId: 'p1',locationProvinceId: remainingWorkHandlersProvinceId,tileKey: remainingWorkHandlersTileKey,); final game = remainingWorkHandlersCounterSpyGame(spy); final context = remainingWorkHandlersContext(game: game,oldWorldUnits: {spy.id: spy},); final handler = counterSpyWorkOrderHandler; const order = WorkOrder(unitId: 'spy2',target: kWorkTargetCounterSpy,targetTileKey: remainingWorkHandlersTileKey,); expect(handler.tryApply(context,order,spy,remainingWorkHandlersTileKey,true),isTrue,); final u = context.state.work.unitById('spy2'); expect(u?.currentWork?.workTarget,kWorkTargetCounterSpy);}

void rwhRunSupportsOnlyProspect() {final h = prospectWorkOrderHandler; expect(h.supports(kWorkTargetProspect),isTrue); expect(h.supports(kWorkTargetExplore),isFalse);}

void rwhRunTryApplyProspectNonMineral() {final explorer = Unit(id: 'ex1',type: kUnitTypeExplorer,ownerId: 'p1',locationProvinceId: remainingWorkHandlersProvinceId,tileKey: remainingWorkHandlersTileKey,); final game = remainingWorkHandlersProspectGame(explorer); final context = remainingWorkHandlersContext(game: game,oldWorldUnits: {'ex1': explorer},); final handler = prospectWorkOrderHandler; const order = WorkOrder(unitId: 'ex1',target: kWorkTargetProspect,targetTileKey: remainingWorkHandlersTileKey,); expect(handler.tryApply(context,order,explorer,remainingWorkHandlersTileKey,true,),isFalse,); expect(context.state.game.worldState.playerProspectedTiles['p1'] ?? const <String>{},isEmpty,);}

void rwhRunStandardWorkOrderAlreadyWorking() {
  final unit = Unit(
    id: 'b1',
    type: kUnitTypeBuilder,
    ownerId: 'p1',
    locationProvinceId: remainingWorkHandlersProvinceId,
    tileKey: remainingWorkHandlersTileKey,
    currentWork: const CurrentWork(
      workTarget: kWorkTargetBuildRoad,
      tileKey: remainingWorkHandlersTileKey,
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
      targetTileKey: remainingWorkHandlersTileKey,
    ),
    unit: unit,
    targetTileKey: remainingWorkHandlersTileKey,
    hasValidTarget: true,
    orderTarget: kWorkTargetBuildImprovement,
    tileState: TileMapState(),
    provincesById: const {},
    canAffordMaterialCost: (_) => true,
    deductMaterialCost: (_) {},
    updateUnit: (_, __) => fail('no update'),
  );
  expect(applied, isFalse);
}

void rwhRunSkipFortMissingTech() {final province = Province(id: remainingWorkHandlersProvinceId,regionId: remainingWorkHandlersOw,ownerId: 'p1',fortLevel: 1,); expect(shouldSkipBuildFortForMissingTech(province: province,techUnlocked: const {},),isTrue,);}

void rwhRunStandardBuildSupportsOnlyTarget() {expect(standardBuildRoadWorkOrderHandler.supports(kWorkTargetBuildRoad),isTrue,); expect(standardBuildRoadWorkOrderHandler.supports(kWorkTargetBuildFort),isFalse,); expect(standardBuildFortWorkOrderHandler.supports(kWorkTargetBuildFort),isTrue,); expect(standardBuildImprovementWorkOrderHandler.supports(kWorkTargetBuildImprovement,),isTrue,); expect(standardBuildImprovementWorkOrderHandler.supports(kWorkTargetBuildRoad),isFalse,);}

void rwhRunRegistryMapsAllTargets() {expect(workOrderHandlersByTarget.keys,containsAll(<String>[kWorkTargetPurchaseLand,kWorkTargetCounterSpy,kWorkTargetProspect,kWorkTargetExplore,kWorkTargetBuildImprovement,kWorkTargetBuildRoad,kWorkTargetBuildPort,kWorkTargetUpgradeTown,kWorkTargetBuildFort,kWorkTargetBuildRail,]),);}

void rwhRunSingletonNoCrossSupport() {expect(counterSpyWorkOrderHandler.supports('steal_tech'),isFalse); expect(prospectWorkOrderHandler.supports(kWorkTargetPurchaseLand),isFalse); expect(purchaseLandWorkOrderHandler.supports(kWorkTargetProspect),isFalse); expect(exploreWorkOrderHandler.supports(kWorkTargetProspect),isFalse); expect(prospectWorkOrderHandler.supports(kWorkTargetExplore),isFalse);}

/// Canonical scenarios for remaining_work_handlers family tests.
List<RunnableScenario> remainingWorkHandlersScenarios() => [
  rs('supports only counter_spy', rwhRunSupportsOnlyCounterSpy),
  rs('tryApply assigns counter_spy work for spy unit', rwhRunTryApplyCounterSpy),
  rs('supports only prospect', rwhRunSupportsOnlyProspect),
  rs('tryApply returns false for non-mineral tile', rwhRunTryApplyProspectNonMineral),
  rs('returns false when unit already has currentWork', rwhRunStandardWorkOrderAlreadyWorking),
  rs('skips fort level 2 when Mine Engineering not unlocked', rwhRunSkipFortMissingTech),
  rs('each standard build handler supports only its target', rwhRunStandardBuildSupportsOnlyTarget),
  rs('maps every standard and simple work target to a handler', rwhRunRegistryMapsAllTargets),
  rs('singleton handlers do not cross-support other simple targets', rwhRunSingletonNoCrossSupport),
];
