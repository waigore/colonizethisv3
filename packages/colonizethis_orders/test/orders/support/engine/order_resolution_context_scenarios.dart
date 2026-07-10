// Table-driven order-resolution context scenarios (Refs #3949 wave 3).

import 'package:colonizethis_orders/src/orders/order_resolution_context.dart';
import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_world/colonizethis_world.dart';
import '../scenario_runner.dart';
import 'order_resolution_context_fixtures.dart';

void orcRunBuildContextReusesViewAndCachedUnits() {
  final game = orcMinimalGame();
  final view = orcPlayerView(game);
  final units = game.worldState.allUnitsById;
  final ctx = buildOrderResolutionContext(
    game: game,
    topology: orcEmptyTopology(),
    playerId: orcPlayerId,
    view: view,
    unitsById: units,
  );
  expect(identical(ctx.view, view), isTrue);
  expect(identical(ctx.unitsById, units), isTrue);
  expect(identical(ctx.provinceById, view.provincesById), isTrue);
}

void orcRunFromViewAliasesProvincesById() {
  final game = orcMinimalGame();
  final view = orcPlayerView(game);
  final ctx = orderResolutionContextFromView(view, game);
  expect(identical(ctx.view, view), isTrue);
  expect(identical(ctx.provinceById, view.provincesById), isTrue);
  expect(identical(ctx.unitsById, game.worldState.allUnitsById), isTrue);
}

/// Canonical scenarios for order_resolution_context family tests.
List<RunnableScenario> orderResolutionContextScenarios() => const [
  rs('buildOrderResolutionContext reuses view and cached units (Refs #2836)', orcRunBuildContextReusesViewAndCachedUnits, '#2836'),
  rs('orderResolutionContextFromView aliases provincesById', orcRunFromViewAliasesProvincesById),
];
