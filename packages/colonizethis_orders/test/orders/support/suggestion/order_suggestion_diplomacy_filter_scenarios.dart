// Table-driven diplomacy-filter suggestion scenarios (Refs #3949 wave 3).

import '../scenario_runner.dart';
import 'order_suggestion_diplomacy_filter_run_rows.dart';

/// One row in diplomacy-filter scenario tables.
class OrderSuggestionDiplomacyFilterScenario implements RefsScenario {
  const OrderSuggestionDiplomacyFilterScenario({
    required this.label,
    required this.run,
    this.refs,
  });

  @override
  final String label;
  final void Function() run;
  @override
  final String? refs;
}

void runOrderSuggestionDiplomacyFilterScenario(
  OrderSuggestionDiplomacyFilterScenario scenario,
) {
  scenario.run();
}

List<OrderSuggestionDiplomacyFilterScenario>
getProvinceOwnerMapProvinceOwnerCacheScenarios() => const [
  OrderSuggestionDiplomacyFilterScenario(
    label: 'matches the projection-derived owner map across both regions',
    run: osdfRunMatchesProjectionDerivedOwnerMapAcrossBothRegions,
  ),
  OrderSuggestionDiplomacyFilterScenario(
    label: 'excludes unowned (null-owner) provinces',
    run: osdfRunExcludesUnownedNullOwnerProvinces,
  ),
  OrderSuggestionDiplomacyFilterScenario(
    label: 'excludes empty-string owner provinces (isNotEmpty parity)',
    run: osdfRunExcludesEmptyStringOwnerProvinces,
  ),
];

List<OrderSuggestionDiplomacyFilterScenario>
filterMoveOrdersByDiplomacyScenarios() => const [
  OrderSuggestionDiplomacyFilterScenario(
    label: 'getProvinceOwnerMap returns owner by full province id',
    run: osdfRunReturnsOwnerByFullProvinceId,
  ),
  OrderSuggestionDiplomacyFilterScenario(
    label: 'getProvinceOwnerMap includes newWorld provinces',
    run: osdfRunIncludesNewWorldProvinces,
  ),
  OrderSuggestionDiplomacyFilterScenario(
    label: 'filterMoveOrdersByDiplomacy does not drop civilian moves at peace',
    run: osdfRunFilterDoesNotDropCivilianMovesAtPeace,
  ),
  OrderSuggestionDiplomacyFilterScenario(
    label: 'filterMoveOrdersByDiplomacy keeps move to at-war faction',
    run: osdfRunFilterKeepsMoveToAtWarFaction,
  ),
];
