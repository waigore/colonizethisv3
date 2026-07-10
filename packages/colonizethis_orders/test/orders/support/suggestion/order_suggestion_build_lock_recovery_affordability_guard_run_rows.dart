// Scenario run tear-offs for order_suggestion_build_lock_recovery_affordability_guard (Refs #3949 wave 3).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';
import 'order_suggestion_build_lock_recovery_affordability_guard_fixtures.dart';

void osblragRunPositiveControlRichesFundRegiment() {
  final game = brokeWithRichesGame();
  final view = buildPlayerView(game, buildLockRecoveryTopology, 'p1');

  final suggestions = suggestBuildOrders(
    view,
    game,
    buildLockRecoveryTopology,
    const Orders(),
  );

  expect(
    suggestions.map((o) => o.unitType),
    contains('peasant_levies'),
    reason: 'pending riches-to-treasury should fund the cheapest regiment',
  );
}

void osblragRunAiNoBypass() {
  final game = brokeNoRichesGame(isHuman: false);
  final view = buildPlayerView(game, buildLockRecoveryTopology, 'p1');

  expect(
    game.players.single.treasury,
    lessThan(cheapestRegimentBuildTreasuryCost()),
  );

  final suggestions = suggestBuildOrders(
    view,
    game,
    buildLockRecoveryTopology,
    const Orders(),
  );

  expect(
    suggestions.where(isRegimentBuild),
    isEmpty,
    reason:
        'no regiment may be suggested when treasury < cheapest build cost '
        'and there is no riches-to-treasury inflow (no affordability bypass)',
  );
}

void osblragRunHumanNoWaiverSuggestions() {
  final game = brokeNoRichesGame(isHuman: true);
  final view = buildPlayerView(game, buildLockRecoveryTopology, 'p1');

  final suggestions = suggestBuildOrders(
    view,
    game,
    buildLockRecoveryTopology,
    const Orders(),
  );

  expect(suggestions.where(isRegimentBuild), isEmpty);
}

void osblragRunHumanNoWaiverValidationPath() {
  final game = brokeNoRichesGame(isHuman: true);
  const candidate = BuildUnitOrder(
    unitType: 'peasant_levies',
    isMilitary: true,
    spawnProvinceId: 'oldWorld|p1',
  );

  final result = OrderEngine(
    initialOrders: const Orders(),
  ).addBuildOrderWithContext(game, buildLockRecoveryTopology, 'p1', candidate);

  expect(
    result.isAccepted,
    isFalse,
    reason:
        'no waiver path may accept a regiment build at zero treasury '
        'for any player, human or AI',
  );
}
