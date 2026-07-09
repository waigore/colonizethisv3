// Compact order-resolution context assertions (Refs #3949 wave 3).

import 'package:colonizethis_orders/src/orders/order_resolution_context.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_world/colonizethis_world.dart';

import 'order_resolution_context_fixtures.dart';

/// Pins for [orderResolutionContextScenarios] rows.
enum OrderResolutionContextTarget {
  buildContextReusesViewAndCachedUnits,
  fromViewAliasesProvincesById,
}

void runOrderResolutionContextExpectation(OrderResolutionContextTarget target) {
  switch (target) {
    case OrderResolutionContextTarget.buildContextReusesViewAndCachedUnits:
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

    case OrderResolutionContextTarget.fromViewAliasesProvincesById:
      final game = orcMinimalGame();
      final view = orcPlayerView(game);

      final ctx = orderResolutionContextFromView(view, game);

      expect(identical(ctx.view, view), isTrue);
      expect(identical(ctx.provinceById, view.provincesById), isTrue);
      expect(identical(ctx.unitsById, game.worldState.allUnitsById), isTrue);
  }
}
