// Scenario run tear-offs for purchase-land work handler (Refs #3949 wave 3).

import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_orders/src/orders/orders_application_context.dart';
import 'package:colonizethis_orders/src/orders/purchase_land_work_completion.dart';
import 'package:colonizethis_orders/src/orders/work_handlers/simple_work_order_handler.dart';
import 'package:colonizethis_orders/src/orders/work_handlers/work_order_handler.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_test/game_test_fixtures.dart';

import 'purchase_land_work_handler_fixtures.dart';

void plwhRunSupportsOnlyPurchaseLand() {
  final handler = purchaseLandWorkOrderHandler;
  expect(handler.supports(kWorkTargetPurchaseLand), isTrue);
  expect(handler.supports(kWorkTargetExplore), isFalse);
}

void plwhRunTryApplyWithoutTreasuryDeduction() {
  final game = purchaseLandTryApplyGame();
  final merchant = game.worldState.oldWorld.units.single;
  final work = WorkOrderState(
    unitsById: (oldWorld: {merchant.id: merchant}, newWorld: const {}),
    tileState: game.worldState.tileState,
    visibilityByTile: const {},
    portsByProvinceSeaboard: const {},
    purchasedTilesByTileKey: const {},
    oldProvinces: List<Province>.from(game.worldState.oldWorld.provinces),
    newProvinces: const [],
  );
  var state = BuildWorkState(
    game: game,
    buildOrders: const {},
    workOrders: const {},
    work: work,
  );
  final player = game.players.single;
  final context = WorkOrderExecutionContext(state: state, player: player);
  final handler = purchaseLandWorkOrderHandler;
  const order = WorkOrder(
    unitId: 'merchant1',
    target: kWorkTargetPurchaseLand,
    targetTileKey: purchaseLandTileKey,
  );

  final applied = handler.tryApply(
    context,
    order,
    merchant,
    purchaseLandTileKey,
    true,
  );

  expect(applied, isTrue);
  expect(context.treasury, 500);
  expect(
    context.purchasedTilesByTileKey.containsKey(purchaseLandTileKey),
    isFalse,
  );
  final updatedMerchant = context.state.work.unitById('merchant1');
  expect(updatedMerchant, isNotNull);
  expect(updatedMerchant!.status, UnitStatus.working);
  expect(updatedMerchant.tileKey, purchaseLandTileKey);
  expect(updatedMerchant.currentWork?.workTarget, kWorkTargetPurchaseLand);
  expect(updatedMerchant.currentWork?.remainingTurns, 1);
}

void plwhRunUnchangedTreasuryNoResource() {
  final game = TestFixtures.minimalGame(players: const []);
  final unit = Unit(
    id: 'u1',
    type: kUnitTypeMerchant,
    ownerId: 'p1',
    locationProvinceId: 'oldWorld|P1',
    tileKey: 'oldWorld|P1|0|0',
  );
  final out = applyPurchaseLandCompletion(
    state: purchaseLandMinimalBuildState(game),
    player: const Player(id: 'p1', displayName: 'P1', isHuman: true),
    unit: unit,
    targetTileKey: 'oldWorld|P1|0|0',
    treasury: 100,
    purchasedTilesByTileKey: const {},
    provinceById: (_) => null,
  );
  expect(out.treasury, 100);
  expect(out.purchasedTilesByTileKey, isEmpty);
}
