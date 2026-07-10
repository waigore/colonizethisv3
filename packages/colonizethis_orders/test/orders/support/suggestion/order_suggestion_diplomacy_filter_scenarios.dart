// Table-driven diplomacy-filter suggestion scenarios (Refs #3949 wave 3).

import '../scenario_runner.dart';
import 'order_suggestion_diplomacy_filter_expectations.dart';

/// One row in diplomacy-filter scenario tables.
class OrderSuggestionDiplomacyFilterScenario implements RefsScenario {
  const OrderSuggestionDiplomacyFilterScenario({
    required this.label,
    required this.target,
    this.refs,
  });

  @override
  final String label;
  final OrderSuggestionDiplomacyFilterTarget target;
  @override
  final String? refs;
}

void runOrderSuggestionDiplomacyFilterScenario(
  OrderSuggestionDiplomacyFilterScenario scenario,
) {
  runOrderSuggestionDiplomacyFilterExpectation(scenario.target);
}

List<OrderSuggestionDiplomacyFilterScenario>
getProvinceOwnerMapProvinceOwnerCacheScenarios() => const [
      OrderSuggestionDiplomacyFilterScenario(
        label: 'matches the projection-derived owner map across both regions',
        target: OrderSuggestionDiplomacyFilterTarget
            .matchesProjectionDerivedOwnerMapAcrossBothRegions,
      ),
      OrderSuggestionDiplomacyFilterScenario(
        label: 'excludes unowned (null-owner) provinces',
        target:
            OrderSuggestionDiplomacyFilterTarget.excludesUnownedNullOwnerProvinces,
      ),
      OrderSuggestionDiplomacyFilterScenario(
        label: 'excludes empty-string owner provinces (isNotEmpty parity)',
        target: OrderSuggestionDiplomacyFilterTarget
            .excludesEmptyStringOwnerProvinces,
      ),
    ];

List<OrderSuggestionDiplomacyFilterScenario>
filterMoveOrdersByDiplomacyScenarios() => const [
      OrderSuggestionDiplomacyFilterScenario(
        label: 'getProvinceOwnerMap returns owner by full province id',
        target:
            OrderSuggestionDiplomacyFilterTarget.returnsOwnerByFullProvinceId,
      ),
      OrderSuggestionDiplomacyFilterScenario(
        label: 'getProvinceOwnerMap includes newWorld provinces',
        target: OrderSuggestionDiplomacyFilterTarget.includesNewWorldProvinces,
      ),
      OrderSuggestionDiplomacyFilterScenario(
        label: 'filterMoveOrdersByDiplomacy does not drop civilian moves at peace',
        target: OrderSuggestionDiplomacyFilterTarget
            .filterDoesNotDropCivilianMovesAtPeace,
      ),
      OrderSuggestionDiplomacyFilterScenario(
        label: 'filterMoveOrdersByDiplomacy keeps move to at-war faction',
        target:
            OrderSuggestionDiplomacyFilterTarget.filterKeepsMoveToAtWarFaction,
      ),
    ];
