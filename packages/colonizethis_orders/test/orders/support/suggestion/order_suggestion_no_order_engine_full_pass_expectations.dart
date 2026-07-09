// Compact no-OrderEngine-full-pass assertions (Refs #3949 wave 3).

import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'order_suggestion_no_order_engine_full_pass_fixtures.dart';

/// Pins for [orderSuggestionNoOrderEngineFullPassScenarios] rows.
enum OrderSuggestionNoOrderEngineFullPassTarget {
  suggestBuildOrdersSkipsFullPass,
  orderEngineAddWithContextInvokesFullValidation,
}

void runOrderSuggestionNoOrderEngineFullPassExpectation(
  OrderSuggestionNoOrderEngineFullPassTarget target,
) {
  switch (target) {
    case OrderSuggestionNoOrderEngineFullPassTarget.suggestBuildOrdersSkipsFullPass:
      setOrderEngineValidatePlayerOrdersWithContextTrackingForTests(true);
      final fixture = noefpBuildSuggestionGame();
      suggestBuildOrders(
        fixture.view,
        fixture.game,
        fixture.topology,
        const Orders(),
      );
      expect(
        orderEngineValidatePlayerOrdersWithContextInvocationCountForTests,
        0,
        reason:
            'Build suggestions must use incremental candidate validation, not '
            'OrderEngine full-pass per candidate (Refs #2237 AC2).',
      );

    case OrderSuggestionNoOrderEngineFullPassTarget
        .orderEngineAddWithContextInvokesFullValidation:
      setOrderEngineValidatePlayerOrdersWithContextTrackingForTests(true);
      final fixture = noefpAddWithContextGame();
      final engine = OrderEngine();
      engine.addMoveOrderWithContext(
        fixture.game,
        fixture.topology,
        'gp1',
        const MoveOrder(unitId: 'u1', destinationTileKey: 'oldWorld|P2|0|0'),
      );
      expect(
        orderEngineValidatePlayerOrdersWithContextInvocationCountForTests,
        greaterThan(0),
      );
  }
}
