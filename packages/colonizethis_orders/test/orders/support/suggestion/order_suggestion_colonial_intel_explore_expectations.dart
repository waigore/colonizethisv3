// Compact colonial intel explore assertions (Refs #3949 wave 3).

import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_test/test.dart';

import 'order_suggestion_colonial_intel_explore_fixtures.dart';

/// Pins for [orderSuggestionColonialIntelExploreScenarios] rows.
enum OrderSuggestionColonialIntelExploreTarget {
  listsSeaReachableNw,
}

void runOrderSuggestionColonialIntelExploreExpectation(
  OrderSuggestionColonialIntelExploreTarget target,
) {
  switch (target) {
    case OrderSuggestionColonialIntelExploreTarget.listsSeaReachableNw:
      final fixture = colonialIntelSeaReachableNwFixture();
      expect(
        colonialIntelExploreProvinceIdsSorted(
          view: fixture.view,
          topology: fixture.topology,
        ),
        ['newWorld|colony'],
      );
  }
}
