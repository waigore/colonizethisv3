// Compact work-order target precheck assertions (Refs #3949 wave 3).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_orders/src/orders/validators/work_order_target_prechecks.dart';
import 'package:colonizethis_test/test.dart';

import '../engine/order_engine_purchase_land_test_support.dart';
import 'work_order_target_prechecks_fixtures.dart';

/// Pins for [workOrderTargetPrechecksScenarios] rows.
enum WorkOrderTargetPrecheckTarget {
  registersExpectedTargets,
  unregisteredTargetReturnsNull,
  upgradeTownRejectsNoNationalBureaucracy,
  upgradeTownRejectsMaxDevelopment,
  skippingDefaultForeignCheckSet,
  purchaseLandFactionMembershipParity,
  buildImprovementRejectsUnprospectedMineral,
  defaultForeignProvinceRejectsBuilder,
  devExclusiveTileConflict,
}

void runWorkOrderTargetPrecheckExpectation(
  WorkOrderTargetPrecheckTarget target,
) {
  switch (target) {
    case WorkOrderTargetPrecheckTarget.registersExpectedTargets:
      expect(workOrderTargetPrechecks.keys, contains(kWorkTargetUpgradeTown));
      expect(workOrderTargetPrechecks.keys, contains(kWorkTargetCounterSpy));
      expect(workOrderTargetPrechecks.keys, contains(kWorkTargetPurchaseLand));
      expect(
        workOrderTargetPrechecks.keys,
        contains(kWorkTargetBuildImprovement),
      );
      expect(workOrderTargetPrechecks.length, 4);

    case WorkOrderTargetPrecheckTarget.unregisteredTargetReturnsNull:
      final game = workOrderPrecheckBaseGame();
      final ctx = workOrderPrecheckContext(game);
      final order = WorkOrder(
        unitId: 'u1',
        target: kWorkTargetBuildRoad,
        targetTileKey: workOrderPrecheckTileKey,
      );
      expect(
        runWorkOrderTargetPrecheck(
          ctx,
          order,
          workOrderPrecheckProvinceId,
          'p1',
          kUnitTypeBuilder,
        ),
        isNull,
      );

    case WorkOrderTargetPrecheckTarget.upgradeTownRejectsNoNationalBureaucracy:
      final game = workOrderPrecheckBaseGame(
        player: Player(
          id: 'p1',
          displayName: 'P1',
          isHuman: true,
          capitalProvinceId: workOrderPrecheckProvinceId,
          techUnlocked: const {},
        ),
      );
      final ctx = workOrderPrecheckContext(game);
      final order = WorkOrder(
        unitId: 'b1',
        target: kWorkTargetUpgradeTown,
        targetTileKey: workOrderPrecheckTileKey,
      );
      final r = runWorkOrderTargetPrecheck(
        ctx,
        order,
        workOrderPrecheckProvinceId,
        'p1',
        kUnitTypeBuilder,
      );
      expect(r, isNotNull);
      expect(r!.status, OrderValidationStatus.rejected);
      expect(r.reason, contains('National Bureaucracy'));

    case WorkOrderTargetPrecheckTarget.upgradeTownRejectsMaxDevelopment:
      final game = workOrderPrecheckBaseGame(
        province: Province(
          id: workOrderPrecheckProvinceId,
          regionId: 'oldWorld',
          ownerId: 'p1',
          townTileKey: workOrderPrecheckTileKey,
          townDevelopmentLevel: 4,
        ),
        player: Player(
          id: 'p1',
          displayName: 'P1',
          isHuman: true,
          capitalProvinceId: workOrderPrecheckProvinceId,
          techUnlocked: const {kTechIdNationalBureaucracy: true},
        ),
      );
      final ctx = workOrderPrecheckContext(game, treasury: 1000);
      final order = WorkOrder(
        unitId: 'b1',
        target: kWorkTargetUpgradeTown,
        targetTileKey: workOrderPrecheckTileKey,
      );
      final r = runWorkOrderTargetPrecheck(
        ctx,
        order,
        workOrderPrecheckProvinceId,
        'p1',
        kUnitTypeBuilder,
      );
      expect(r, isNotNull);
      expect(r!.status, OrderValidationStatus.rejected);
      expect(r.reason, contains('maximum (4)'));

    case WorkOrderTargetPrecheckTarget.skippingDefaultForeignCheckSet:
      expect(
        kWorkTargetsSkippingDefaultForeignProvinceCheck,
        equals({
          kWorkTargetCounterSpy,
          kWorkTargetPurchaseLand,
          kWorkTargetBuildImprovement,
          kWorkTargetUpgradeTown,
        }),
      );

    case WorkOrderTargetPrecheckTarget.purchaseLandFactionMembershipParity:
      final game = workOrderPrecheckPurchaseLandGame();
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
            devExclusiveTiles: const {},
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

    case WorkOrderTargetPrecheckTarget.buildImprovementRejectsUnprospectedMineral:
      final game = workOrderPrecheckBaseGame(
        resourceByTileKey: {workOrderPrecheckTileKey: 'iron'},
        tileKeysByProvince: {
          workOrderPrecheckProvinceId: [workOrderPrecheckTileKey],
        },
      );
      final ctx = workOrderPrecheckContext(game);
      final order = WorkOrder(
        unitId: 'b1',
        target: kWorkTargetBuildImprovement,
        targetTileKey: workOrderPrecheckTileKey,
      );
      final r = runWorkOrderTargetPrecheck(
        ctx,
        order,
        workOrderPrecheckProvinceId,
        'p1',
        kUnitTypeBuilder,
      );
      expect(r, isNotNull);
      expect(r!.status, OrderValidationStatus.rejected);
      expect(r.reason, contains('prospected'));

    case WorkOrderTargetPrecheckTarget.defaultForeignProvinceRejectsBuilder:
      final game = workOrderPrecheckForeignProvinceGame();
      final player = game.players.first;
      final ctx = WorkOrderTargetPrecheckContext(
        game: game,
        player: player,
        playerId: 'p1',
        treasury: 0,
        civilianEmbassyWorkAllowed: (_, __) => false,
        devExclusiveTiles: const {},
      );
      final order = WorkOrder(
        unitId: 'b1',
        target: kWorkTargetBuildRoad,
        targetTileKey: workOrderPrecheckForeignTileKey,
      );
      final r = runWorkOrderTargetPrecheck(
        ctx,
        order,
        workOrderPrecheckForeignProvinceId,
        'p2',
        kUnitTypeBuilder,
      );
      expect(r, isNotNull);
      expect(r!.reason, contains('foreign province'));

    case WorkOrderTargetPrecheckTarget.devExclusiveTileConflict:
      final game = workOrderPrecheckBaseGame(
        tileKeysByProvince: {
          workOrderPrecheckProvinceId: [workOrderPrecheckTileKey],
        },
      );
      final ctx = workOrderPrecheckContext(
        game,
        devExclusiveTiles: {workOrderPrecheckTileKey},
      );
      final order = WorkOrder(
        unitId: 'b1',
        target: kWorkTargetBuildRoad,
        targetTileKey: workOrderPrecheckTileKey,
      );
      final r = runWorkOrderTargetPrecheck(
        ctx,
        order,
        workOrderPrecheckProvinceId,
        'p1',
        kUnitTypeBuilder,
      );
      expect(r, isNotNull);
      expect(r!.reason, contains('development or purchase work'));
  }
}
