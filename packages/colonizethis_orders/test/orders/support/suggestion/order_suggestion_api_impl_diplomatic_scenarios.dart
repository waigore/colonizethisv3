// Table-driven diplomatic GP API impl suggestion scenarios (Refs #3949 wave 3).

import '../scenario_runner.dart';
import 'order_suggestion_api_impl_diplomatic_expectations.dart';

/// One row in [orderSuggestionApiImplDiplomaticScenarios].
class OrderSuggestionApiImplDiplomaticScenario implements RefsScenario {
  const OrderSuggestionApiImplDiplomaticScenario({
    required this.label,
    required this.target,
    this.refs,
  });

  @override
  final String label;
  final OrderSuggestionApiImplDiplomaticTarget target;
  @override
  final String? refs;
}

void runOrderSuggestionApiImplDiplomaticScenario(
  OrderSuggestionApiImplDiplomaticScenario scenario,
) {
  runOrderSuggestionApiImplDiplomaticExpectation(scenario.target);
}

List<OrderSuggestionApiImplDiplomaticScenario>
    orderSuggestionApiImplDiplomaticScenarios() => const [
          OrderSuggestionApiImplDiplomaticScenario(
            label: 'returns alliance (single diplo per target) for other GP when at peace and not allied',
            target: OrderSuggestionApiImplDiplomaticTarget
                .returnsAllianceSingleDiploPerTarget,
            refs: '#3949',
          ),
          OrderSuggestionApiImplDiplomaticScenario(
            label: 'returns declareWar toward GP when at peace and already allied',
            target:
                OrderSuggestionApiImplDiplomaticTarget.returnsDeclareWarWhenAllied,
            refs: '#3949',
          ),
          OrderSuggestionApiImplDiplomaticScenario(
            label: 'returns breakAlliance toward GP when a formal alliance exists at peace',
            target: OrderSuggestionApiImplDiplomaticTarget
                .returnsBreakAllianceWhenFormalAllianceExists,
            refs: '#3949',
          ),
          OrderSuggestionApiImplDiplomaticScenario(
            label: 'does not return alliance toward a GP when a formal alliance exists',
            target: OrderSuggestionApiImplDiplomaticTarget
                .doesNotReturnAllianceWhenFormalAllianceExists,
            refs: '#3949',
          ),
          OrderSuggestionApiImplDiplomaticScenario(
            label: 'does not return breakAlliance when relation level is allied but no formal alliance',
            target: OrderSuggestionApiImplDiplomaticTarget
                .doesNotReturnBreakAllianceWithoutFormalAlliance,
            refs: '#3949',
          ),
          OrderSuggestionApiImplDiplomaticScenario(
            label: 'returns offerPeace when at war with another GP',
            target:
                OrderSuggestionApiImplDiplomaticTarget.returnsOfferPeaceWhenAtWar,
            refs: '#3949',
          ),
          OrderSuggestionApiImplDiplomaticScenario(
            label: 'returns alliance candidate when at peace and not allied',
            target: OrderSuggestionApiImplDiplomaticTarget
                .returnsAllianceCandidateWhenAtPeace,
            refs: '#3949',
          ),
        ];
