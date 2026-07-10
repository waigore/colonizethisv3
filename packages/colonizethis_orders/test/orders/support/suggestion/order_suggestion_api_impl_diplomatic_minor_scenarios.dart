// Table-driven diplomatic-minor API impl suggestion scenarios (Refs #3949 wave 3).

import '../scenario_runner.dart';
import 'order_suggestion_api_impl_diplomatic_minor_expectations.dart';

/// One row in [orderSuggestionApiImplDiplomaticMinorScenarios].
class OrderSuggestionApiImplDiplomaticMinorScenario implements RefsScenario {
  const OrderSuggestionApiImplDiplomaticMinorScenario({
    required this.label,
    required this.target,
    this.refs,
  });

  @override
  final String label;
  final OrderSuggestionApiImplDiplomaticMinorTarget target;
  @override
  final String? refs;
}

void runOrderSuggestionApiImplDiplomaticMinorScenario(
  OrderSuggestionApiImplDiplomaticMinorScenario scenario,
) {
  runOrderSuggestionApiImplDiplomaticMinorExpectation(scenario.target);
}

List<OrderSuggestionApiImplDiplomaticMinorScenario>
    orderSuggestionApiImplDiplomaticMinorScenarios() => const [
          OrderSuggestionApiImplDiplomaticMinorScenario(
            label: 'does not suggest diplomatic orders for completely unknown factions',
            target: OrderSuggestionApiImplDiplomaticMinorTarget
                .doesNotSuggestForCompletelyUnknownFactions,
            refs: '#3949',
          ),
          OrderSuggestionApiImplDiplomaticMinorScenario(
            label: 'returns establishOverture for minor when treasury suffices',
            target: OrderSuggestionApiImplDiplomaticMinorTarget
                .returnsEstablishOvertureWhenTreasurySuffices,
            refs: '#3949',
          ),
          OrderSuggestionApiImplDiplomaticMinorScenario(
            label: 'does not suggest tradeConsulate/embassy/nap overture toward minor without diplomatic expertise',
            target: OrderSuggestionApiImplDiplomaticMinorTarget
                .doesNotSuggestAdvancedOvertureWithoutDiplomaticExpertise,
            refs: '#3949',
          ),
          OrderSuggestionApiImplDiplomaticMinorScenario(
            label: 'toward minor at peace with join-empire overture suggests declareWar (primary before economic)',
            target: OrderSuggestionApiImplDiplomaticMinorTarget
                .joinEmpireOvertureSuggestsDeclareWar,
            refs: '#3949',
          ),
        ];
