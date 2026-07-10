// Table-driven diplomatic-minor API impl suggestion scenarios (Refs #3949 wave 3).

import '../scenario_runner.dart';
import 'order_suggestion_api_impl_diplomatic_minor_run_rows.dart';

/// One row in [orderSuggestionApiImplDiplomaticMinorScenarios].
class OrderSuggestionApiImplDiplomaticMinorScenario implements RefsScenario {
  const OrderSuggestionApiImplDiplomaticMinorScenario({
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

void runOrderSuggestionApiImplDiplomaticMinorScenario(
  OrderSuggestionApiImplDiplomaticMinorScenario scenario,
) {
  scenario.run();
}

List<OrderSuggestionApiImplDiplomaticMinorScenario>
orderSuggestionApiImplDiplomaticMinorScenarios() => const [
  OrderSuggestionApiImplDiplomaticMinorScenario(
    label: 'does not suggest diplomatic orders for completely unknown factions',
    run: osaidmRunDoesNotSuggestForCompletelyUnknownFactions,
    refs: '#3949',
  ),
  OrderSuggestionApiImplDiplomaticMinorScenario(
    label: 'returns establishOverture for minor when treasury suffices',
    run: osaidmRunReturnsEstablishOvertureWhenTreasurySuffices,
    refs: '#3949',
  ),
  OrderSuggestionApiImplDiplomaticMinorScenario(
    label:
        'does not suggest tradeConsulate/embassy/nap overture toward minor without diplomatic expertise',
    run: osaidmRunDoesNotSuggestAdvancedOvertureWithoutDiplomaticExpertise,
    refs: '#3949',
  ),
  OrderSuggestionApiImplDiplomaticMinorScenario(
    label:
        'toward minor at peace with join-empire overture suggests declareWar (primary before economic)',
    run: osaidmRunJoinEmpireOvertureSuggestsDeclareWar,
    refs: '#3949',
  ),
];
