// Table-driven work-order target precheck scenarios (Refs #3949 wave 3).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_orders/src/orders/validators/work_order_target_prechecks.dart';
import 'package:colonizethis_test/test.dart';
import '../scenario_runner.dart';

import '../engine/order_engine_purchase_land_test_support.dart';
import 'work_order_target_prechecks_fixtures.dart';
// dart format off

void wotpRunRegistersExpectedTargets() {expect(workOrderTargetPrechecks.keys,contains(kWorkTargetUpgradeTown)); expect(workOrderTargetPrechecks.keys,contains(kWorkTargetCounterSpy)); expect(workOrderTargetPrechecks.keys,contains(kWorkTargetPurchaseLand)); expect(workOrderTargetPrechecks.keys,contains(kWorkTargetBuildImprovement)); expect(workOrderTargetPrechecks.length,4);}

void wotpRunUnregisteredTargetReturnsNull() {final game = workOrderPrecheckBaseGame(); final ctx = workOrderPrecheckContext(game); final order = WorkOrder(unitId: 'u1',target: kWorkTargetBuildRoad,targetTileKey: workOrderPrecheckTileKey,); expect(runWorkOrderTargetPrecheck(ctx,order,workOrderPrecheckProvinceId,'p1',kUnitTypeBuilder,),isNull,);}

void wotpRunUpgradeTownRejectsNoNationalBureaucracy() {final game = workOrderPrecheckBaseGame(player: Player(id: 'p1',displayName: 'P1',isHuman: true,capitalProvinceId: workOrderPrecheckProvinceId,techUnlocked: const {},),); final ctx = workOrderPrecheckContext(game); final order = WorkOrder(unitId: 'b1',target: kWorkTargetUpgradeTown,targetTileKey: workOrderPrecheckTileKey,); final r = runWorkOrderTargetPrecheck(ctx,order,workOrderPrecheckProvinceId,'p1',kUnitTypeBuilder,); expect(r,isNotNull); expect(r!.status,OrderValidationStatus.rejected); expect(r.reason,contains('National Bureaucracy'));}

void wotpRunUpgradeTownRejectsMaxDevelopment() {final game = workOrderPrecheckBaseGame(province: Province(id: workOrderPrecheckProvinceId,regionId: 'oldWorld',ownerId: 'p1',townTileKey: workOrderPrecheckTileKey,townDevelopmentLevel: 4,),player: Player(id: 'p1',displayName: 'P1',isHuman: true,capitalProvinceId: workOrderPrecheckProvinceId,techUnlocked: const {kTechIdNationalBureaucracy: true},),); final ctx = workOrderPrecheckContext(game,treasury: 1000); final order = WorkOrder(unitId: 'b1',target: kWorkTargetUpgradeTown,targetTileKey: workOrderPrecheckTileKey,); final r = runWorkOrderTargetPrecheck(ctx,order,workOrderPrecheckProvinceId,'p1',kUnitTypeBuilder,); expect(r,isNotNull); expect(r!.status,OrderValidationStatus.rejected); expect(r.reason,contains('maximum (4)'));}

void wotpRunSkippingDefaultForeignCheckSet() {expect(kWorkTargetsSkippingDefaultForeignProvinceCheck,equals({kWorkTargetCounterSpy,kWorkTargetPurchaseLand,kWorkTargetBuildImprovement,kWorkTargetUpgradeTown,}),);}

void wotpRunPurchaseLandFactionMembershipParity() {final game = workOrderPrecheckPurchaseLandGame(); final player = game.players.single; final membership = DiplomacyFactionMembership.from(game); WorkOrderTargetPrecheckContext ctx({required bool withSnap}) => WorkOrderTargetPrecheckContext( game: game, player: player, playerId: 'p1', treasury: 500, civilianEmbassyWorkAllowed: (_, __) => false, factionMembership: withSnap ? membership : null, devExclusiveTiles: const {}, ); final order = WorkOrder( unitId: 'merchant1', target: kWorkTargetPurchaseLand, targetTileKey: PurchaseLandTestFixture.tileKey, ); final withSnap = runWorkOrderTargetPrecheck( ctx(withSnap: true), order, PurchaseLandTestFixture.minorProvinceId, 'minor1', kUnitTypeMerchant, ); final linear = runWorkOrderTargetPrecheck( ctx(withSnap: false), order, PurchaseLandTestFixture.minorProvinceId, 'minor1', kUnitTypeMerchant, ); expect(withSnap, isNull); expect(linear, isNull);}

void wotpRunBuildImprovementRejectsUnprospectedMineral() {final game = workOrderPrecheckBaseGame(resourceByTileKey: {workOrderPrecheckTileKey: 'iron'},tileKeysByProvince: {workOrderPrecheckProvinceId: [workOrderPrecheckTileKey],},); final ctx = workOrderPrecheckContext(game); final order = WorkOrder(unitId: 'b1',target: kWorkTargetBuildImprovement,targetTileKey: workOrderPrecheckTileKey,); final r = runWorkOrderTargetPrecheck(ctx,order,workOrderPrecheckProvinceId,'p1',kUnitTypeBuilder,); expect(r,isNotNull); expect(r!.status,OrderValidationStatus.rejected); expect(r.reason,contains('prospected'));}

void wotpRunDefaultForeignProvinceRejectsBuilder() {final game = workOrderPrecheckForeignProvinceGame(); final player = game.players.first; final ctx = WorkOrderTargetPrecheckContext(game: game,player: player,playerId: 'p1',treasury: 0,civilianEmbassyWorkAllowed: (_,__) => false,devExclusiveTiles: const {},); final order = WorkOrder(unitId: 'b1',target: kWorkTargetBuildRoad,targetTileKey: workOrderPrecheckForeignTileKey,); final r = runWorkOrderTargetPrecheck(ctx,order,workOrderPrecheckForeignProvinceId,'p2',kUnitTypeBuilder,); expect(r,isNotNull); expect(r!.reason,contains('foreign province'));}

void wotpRunDevExclusiveTileConflict() {final game = workOrderPrecheckBaseGame(tileKeysByProvince: {workOrderPrecheckProvinceId: [workOrderPrecheckTileKey],},); final ctx = workOrderPrecheckContext(game,devExclusiveTiles: {workOrderPrecheckTileKey},); final order = WorkOrder(unitId: 'b1',target: kWorkTargetBuildRoad,targetTileKey: workOrderPrecheckTileKey,); final r = runWorkOrderTargetPrecheck(ctx,order,workOrderPrecheckProvinceId,'p1',kUnitTypeBuilder,); expect(r,isNotNull); expect(r!.reason,contains('development or purchase work'));}

/// Canonical scenarios for work-order target prechecks.
List<RunnableScenario> workOrderTargetPrechecksScenarios() => [
  rs('registers expected work targets', wotpRunRegistersExpectedTargets),
  rs('runWorkOrderTargetPrecheck returns null for unregistered target', wotpRunUnregisteredTargetReturnsNull),
  rs('precheckUpgradeTown rejects without National Bureaucracy', wotpRunUpgradeTownRejectsNoNationalBureaucracy),
  rs('precheckUpgradeTown rejects when town development is already 4', wotpRunUpgradeTownRejectsMaxDevelopment),
  rs('kWorkTargetsSkippingDefaultForeignProvinceCheck lists dedicated targets', wotpRunSkippingDefaultForeignCheckSet),
  rs('precheckPurchaseLand matches with or without DiplomacyFactionMembership (Refs #2394)', wotpRunPurchaseLandFactionMembershipParity, '#2394'),
  rs('precheckBuildImprovement rejects unprospected mineral tile', wotpRunBuildImprovementRejectsUnprospectedMineral),
  rs('precheckDefaultForeignProvince rejects builder in foreign province', wotpRunDefaultForeignProvinceRejectsBuilder),
  rs('precheckDevExclusiveTileConflict rejects duplicate dev work tile', wotpRunDevExclusiveTileConflict),
];
